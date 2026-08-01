import 'dart:async';
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
  // Fila durável de escritas pendentes (registros ainda não confirmados
  // pelo backend). Persiste no disco pra sobreviver a fechar o app.
  static const _kPendentes = 'pending_log_writes_v1';

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

  // Fila de escritas pendentes (payloads a enviar). Carregada do disco na
  // primeira necessidade. _flushing evita dois flushes concorrentes.
  List<Map<String, dynamic>> _pendentes = [];
  bool _pendentesCarregados = false;
  bool _flushing = false;

  LogsProvider(this._apiService);

  // Getters
  List<DailyLog> get logs => _logs;
  List<ComplianceScore> get scores => _scores;
  int get streak => _streak;
  int get scoreToday => _scoreToday;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Quantidade de registros ainda não sincronizados com o backend.
  /// A UI pode mostrar um indicador discreto "sincronizando…" se > 0.
  int get pendentesCount => _pendentes.length;

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
    // Oportunidade de drenar escritas pendentes (ex.: falharam offline).
    // Fire-and-forget: não bloqueia o carregamento do dashboard. Não
    // recursa — quando a fila esvazia, o flush chama carregarDashboard,
    // mas aí já não há pendentes pra disparar outro flush.
    unawaited(flushPendentes());

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

  /// Registra um log de forma OTIMISTA e NÃO-BLOQUEANTE.
  ///
  /// Antes, cada salvamento fazia 3 chamadas de rede sequenciais
  /// (POST /logs + GET /dashboard + GET /logs) com a UI travada em
  /// `_isLoading` — no Brasil, com o backend nos EUA, isso são segundos
  /// de tela congelada por toque. Agora:
  ///   1. Aplica a mudança na UI IMEDIATAMENTE (merge no log do dia).
  ///   2. Enfileira o payload de forma DURÁVEL (sobrevive a fechar o app).
  ///   3. Dispara o envio ao backend em BACKGROUND, sem bloquear.
  /// Se a rede falhar, o item fica na fila e é reenviado no próximo
  /// flush (nova abertura, pull-to-refresh, ou próximo salvamento). Nada
  /// se perde — sem gambiarra e sem travar o usuário.
  Future<void> adicionarLog({
    required DateTime data,
    double? pesoKg,
    int? proteinaG,
    int? aguaMl,
    String? alimentos,
    bool doseAplicada = false,
    String? efeitosColaterais,
  }) async {
    await _carregarPendentes();

    // 1. Otimista: reflete na UI na hora (sem _isLoading, sem travar).
    _upsertLogLocal(
      data: data,
      pesoKg: pesoKg,
      proteinaG: proteinaG,
      aguaMl: aguaMl,
      alimentos: alimentos,
      // dose é "grudenta" no backend (OR): só marcamos true, nunca reset.
      doseAplicada: doseAplicada ? true : null,
      efeitos: efeitosColaterais,
    );
    _error = null;
    notifyListeners();

    // 2. Enfileira durável.
    _pendentes.add({
      'data': _isoDia(data),
      'pesoKg': pesoKg,
      'proteinaG': proteinaG,
      'aguaMl': aguaMl,
      'alimentos': alimentos,
      'doseAplicada': doseAplicada,
      'efeitos': efeitosColaterais,
    });
    await _salvarPendentes();

    // 3. Sincroniza em background — a UI já seguiu em frente.
    unawaited(flushPendentes());
  }

  /// Envia a fila de pendentes ao backend, em ordem. Para no primeiro
  /// erro de rede (mantém o resto pra retry). Quando esvazia, faz UM
  /// refresh de dashboard pra trazer score/streak recalculados no server.
  Future<void> flushPendentes() async {
    if (_flushing) return;
    await _carregarPendentes();
    if (_pendentes.isEmpty) return;
    _flushing = true;
    var enviouAlgo = false;
    try {
      while (_pendentes.isNotEmpty) {
        final p = _pendentes.first;
        try {
          final resp = await _apiService.registrarLog(
            data: DateTime.parse(p['data'] as String),
            pesoKg: (p['pesoKg'] as num?)?.toDouble(),
            proteinaG: (p['proteinaG'] as num?)?.toInt(),
            aguaMl: (p['aguaMl'] as num?)?.toInt(),
            alimentos: p['alimentos'] as String?,
            doseAplicada: (p['doseAplicada'] as bool?) ?? false,
            efeitosColaterais: p['efeitos'] as String?,
          );
          if (resp['score'] != null) {
            _scoreToday = resp['score'] as int;
          }
          _pendentes.removeAt(0);
          await _salvarPendentes();
          enviouAlgo = true;
          notifyListeners();
        } catch (_) {
          // Rede fora / servidor indisponível: para e tenta no próximo
          // flush. O item continua na fila (durável).
          break;
        }
      }
    } finally {
      _flushing = false;
    }

    // Drenou tudo: um único refresh em background pra score/streak/histórico
    // ficarem coerentes com o servidor. Não bloqueia ninguém.
    if (enviouAlgo && _pendentes.isEmpty) {
      await carregarDashboard(comCache: false);
      await carregarLogs(comCache: false);
    }
  }

  // ---- Helpers da escrita otimista + fila durável ----

  String _isoDia(DateTime d) =>
      DateTime(d.year, d.month, d.day).toIso8601String();

  /// Mescla um registro no log do dia EM MEMÓRIA, espelhando a semântica
  /// do upsert do backend (COALESCE: campo enviado substitui, ausente
  /// mantém; dose é OR). Reescreve o cache de logs pra sobreviver à
  /// reabertura do app antes do sync.
  void _upsertLogLocal({
    required DateTime data,
    double? pesoKg,
    int? proteinaG,
    int? aguaMl,
    String? alimentos,
    bool? doseAplicada,
    String? efeitos,
  }) {
    final dia = DateTime(data.year, data.month, data.day);
    final idx = _logs.indexWhere((l) =>
        l.data.year == dia.year &&
        l.data.month == dia.month &&
        l.data.day == dia.day);
    final atual = idx >= 0 ? _logs[idx] : null;
    final merged = DailyLog(
      id: atual?.id,
      data: dia,
      pesoKg: pesoKg ?? atual?.pesoKg,
      proteinaG: proteinaG ?? atual?.proteinaG,
      aguaMl: aguaMl ?? atual?.aguaMl,
      alimentos: alimentos ?? atual?.alimentos,
      doseAplicada: (doseAplicada ?? false) || (atual?.doseAplicada ?? false),
      efeitosColaterais: efeitos ?? atual?.efeitosColaterais,
    );
    if (idx >= 0) {
      _logs[idx] = merged;
    } else {
      // Dia novo entra no topo (a listagem vem em ordem decrescente).
      _logs = [merged, ..._logs];
    }
    _persistirCacheLogs();
  }

  Future<void> _persistirCacheLogs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _logs
          .map((l) => {
                'id': l.id,
                'data': l.data.toIso8601String(),
                'pesoKg': l.pesoKg,
                'proteinaG': l.proteinaG,
                'aguaMl': l.aguaMl,
                'alimentos': l.alimentos,
                'doseAplicada': l.doseAplicada,
                'efeitos': l.efeitosColaterais,
              })
          .toList();
      await prefs.setString(_kCacheLogs, jsonEncode(list));
      await prefs.setInt(
          _kCacheLogsTs, DateTime.now().millisecondsSinceEpoch);
    } catch (_) {}
  }

  Future<void> _carregarPendentes() async {
    if (_pendentesCarregados) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kPendentes);
      if (raw != null) {
        _pendentes = (jsonDecode(raw) as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      }
    } catch (_) {
      _pendentes = [];
    }
    _pendentesCarregados = true;
  }

  Future<void> _salvarPendentes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kPendentes, jsonEncode(_pendentes));
    } catch (_) {}
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
      await prefs.remove(_kPendentes);
    } catch (_) {}
    _logs = [];
    _scores = [];
    _streak = 0;
    _scoreToday = 0;
    _error = null;
    _isLoading = false;
    _pendentes = [];
    _pendentesCarregados = true;
  }
}
