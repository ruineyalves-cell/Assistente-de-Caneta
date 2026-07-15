import 'package:flutter/foundation.dart';
import '../models/index.dart';
import 'api_service.dart';

class LogsProvider extends ChangeNotifier {
  final ApiService _apiService;

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

  Future<void> carregarDashboard() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await _apiService.dashboardLogs();

      _streak = (response['streak'] as num?)?.toInt() ?? 0;

      if (response['scores28dias'] is List) {
        _scores = (response['scores28dias'] as List)
            .map((s) => ComplianceScore.fromJson(s as Map<String, dynamic>))
            .toList();
      } else {
        _scores = [];
      }

      // Score de hoje = score mais recente (a lista vem ordenada desc).
      _scoreToday = _scores.isNotEmpty ? _scores.first.score : 0;

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> carregarLogs({DateTime? de, DateTime? ate}) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final logsData = await _apiService.listarLogs(de: de, ate: ate);
      _logs = logsData
          .map((l) => DailyLog.fromJson(l))
          .toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
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

      // Atualizar score local
      if (response['score'] != null) {
        _scoreToday = response['score'] as int;
      }

      // Recarregar dashboard para atualizar streak
      await carregarDashboard();
      await carregarLogs();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }
}
