import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/index.dart';
import 'api_service.dart';

/// Provider dos logs diários + score de compliance com CACHE LOCAL.
///
/// Cache-first: ao chamar carregarDashboard/carregarLogs, os dados
/// salvos no SharedPreferences são servidos INSTANTANEAMENTE (sem
/// aguardar backend). Em paralelo, dispara um refetch em background
/// que atualiza a UI se vier resposta nova.
///
/// TTL:
///  - < 5min: usa cache silenciosamente, refetch em background
///  - 5min–24h: usa cache mas refetch imediato (mostra dado antigo
///    enquanto atualiza)
///  - > 24h ou ausente: bloqueia com loading e faz fetch tradicional
///
/// Isso resolve a lentidão perceptível quando o backend Render frio
/// demora 5-30s pra responder no primeiro fetch do dia.
class LogsProvider extends ChangeNotifier {
  final ApiService _apiService;

  // Chaves do cache no SharedPreferences.
  static const _kCacheDashboard = 'cache_dashboard_v1';
  static const _kCacheDashboardTs = 'cache_dashboard_ts_v1';
  static const _kCacheLogs = 'cache_logs_v1';
  static const _kCacheLogsTs = 'cache_logs_ts_v1';

  // Cache válido por 24h (fetch tradicional se mais velho).
  static const _ttlMaximo = Duration(hours: 24);
  // Refresh silencioso em background se cache < 5min.
  static const _ttlSilencioso = Duration(minutes: 5);

  List<DailyLog> _logs = [];
  List<ComplianceScore> _scores = [];
  int _streak = 0;
  int _scoreToday = 0;
  bool _isLoading = false;
  String? _error;

  LogsProvider(this._apiService);

  // Getters
  List<DailyLog> get logs => _logs;
  List<ComplianceScore> get scores => _scores;
  int get streak => _streak;
  int get scoreToday => _scoreToday;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Aplica um payload de dashboard nos campos internos. Reutilizada
  /// pelo cache-load e pelo fetch de rede.
  void _aplicarDashboard(Map<String, dynamic> data) {
    _streak = (data['streak'] as num?)?.toInt() ?? 0;
    if (data['scores28dias'] is List) {
      _scores = (data['scores28dias'] as List)
          .map((s) => ComplianceScore.fromJson(s as Map<String, dynamic>))
          .toList();
    } else {
      _scores = [];
    }
    _scoreToday = _scores.isNotEmpty ? _scores.first.score : 0;
  }

  Future<void> carregarDashboard({bool comCache = true}) async {
    // 1. Cache-first: tenta hidratar UI instantaneamente.
    Duration? idade;
    if (comCache) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final raw = prefs.getString(_kCacheDashboard);
        final ts = prefs.getInt(_kCacheDashboardTs);
        if (raw != null && ts != null) {
          idade = DateTime.now()
              .difference(DateTime.fromMillisecondsSinceEpoch(ts));
          if (idade < _ttlMaximo) {
            final data = jsonDecode(raw) as Map<String, dynamic>;
            _aplicarDashboard(data);
            _error = null;
            notifyListeners();
            // Cache muito fresco: nem chama backend — economiza latência
            // e cota do Render. Próxima abertura ou pull-to-refresh vai
            // buscar de novo.
            if (idade < _ttlSilencioso) {
              return;
            }
          }
        }
      } catch (_) {
        // Cache corrompido: ignora e vai pro fetch normal.
      }
    }

    // 2. Fetch de rede. Se já tem cache, não bloqueia UI com loading.
    final temCache = _scores.isNotEmpty || _streak > 0;
    if (!temCache) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    }
    try {
      final response = await _apiService.dashboardLogs();
      _aplicarDashboard(response);
      // Grava cache.
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_kCacheDashboard, jsonEncode(response));
        await prefs.setInt(
            _kCacheDashboardTs, DateTime.now().millisecondsSinceEpoch);
      } catch (_) {}
      _error = null;
    } catch (e) {
      // Se já tinha cache, mantém dados exibidos e não mostra erro.
      if (!temCache) _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> carregarLogs({
    DateTime? de,
    DateTime? ate,
    bool comCache = true,
  }) async {
    // Cache local só serve pra listagem "sem filtro" (que é o caso
    // padrão da HistoryPage). Se tem filtro de data, ignora cache.
    final semFiltro = de == null && ate == null;

    Duration? idade;
    if (comCache && semFiltro) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final raw = prefs.getString(_kCacheLogs);
        final ts = prefs.getInt(_kCacheLogsTs);
        if (raw != null && ts != null) {
          idade = DateTime.now()
              .difference(DateTime.fromMillisecondsSinceEpoch(ts));
          if (idade < _ttlMaximo) {
            final list = jsonDecode(raw) as List;
            _logs = list
                .map((l) => DailyLog.fromJson(l as Map<String, dynamic>))
                .toList();
            _error = null;
            notifyListeners();
            if (idade < _ttlSilencioso) return;
          }
        }
      } catch (_) {}
    }

    final temCache = _logs.isNotEmpty;
    if (!temCache) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    }
    try {
      final logsData = await _apiService.listarLogs(de: de, ate: ate);
      _logs = logsData.map((l) => DailyLog.fromJson(l)).toList();
      if (semFiltro) {
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_kCacheLogs, jsonEncode(logsData));
          await prefs.setInt(
              _kCacheLogsTs, DateTime.now().millisecondsSinceEpoch);
        } catch (_) {}
      }
      _error = null;
    } catch (e) {
      if (!temCache) _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> adicionarLog({
    required DateTime data,
    double? pesoKg,
    int? proteinaG,
    int? aguaMl,
    String? alimentos,
    bool doseAplicada = false,
    String? efeitosColaterais,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await _apiService.registrarLog(
        data: data,
        pesoKg: pesoKg,
        proteinaG: proteinaG,
        aguaMl: aguaMl,
        alimentos: alimentos,
        doseAplicada: doseAplicada,
        efeitosColaterais: efeitosColaterais,
      );

      if (response['score'] != null) {
        _scoreToday = response['score'] as int;
      }

      // Após registrar, invalida cache pra próxima leitura vir fresh.
      // (poderia mesclar in-place, mas simplicidade > micro-otimização)
      await carregarDashboard(comCache: false);
      await carregarLogs(comCache: false);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Limpa cache local — chamada no logout pra não vazar dados entre
  /// contas se o mesmo aparelho for compartilhado.
  Future<void> limparCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kCacheDashboard);
      await prefs.remove(_kCacheDashboardTs);
      await prefs.remove(_kCacheLogs);
      await prefs.remove(_kCacheLogsTs);
    } catch (_) {}
    _logs = [];
    _scores = [];
    _streak = 0;
    _scoreToday = 0;
    _error = null;
    _isLoading = false;
  }
}
