import 'package:shared_preferences/shared_preferences.dart';
import 'premium_service.dart';

/// Lote 27 — Contador de uso de features com quota Free.
///
/// Persiste em SharedPreferences uma tupla (data, contador) por
/// feature. Ao mudar o dia (para quotas diárias) o contador reseta
/// automaticamente na próxima leitura. Fica no cliente por
/// simplicidade — usuário Free que der jailbreak pode burlar; o
/// backend continua sendo a fonte de verdade contra abuso mesmo assim
/// (rate limit por token no Express).
class FeatureUsageService {
  static const _prefix = 'recorpo_feature_usage_';

  Future<int> usoAtual(Feature f) async {
    final prefs = await SharedPreferences.getInstance();
    final quota = FeaturePolicy.quotaFree(f);
    if (quota == null) return 0;
    final chaveContador = '$_prefix${f.name}_count';
    final chaveJanela = '$_prefix${f.name}_janela';

    final agora = DateTime.now();
    final janelaAtual = _idJanela(agora, quota.periodo);
    final janelaSalva = prefs.getString(chaveJanela);

    if (janelaSalva != janelaAtual) {
      // Janela virou → zera silenciosamente.
      await prefs.setString(chaveJanela, janelaAtual);
      await prefs.setInt(chaveContador, 0);
      return 0;
    }
    return prefs.getInt(chaveContador) ?? 0;
  }

  /// Retorna true se pode consumir a feature; false se estourou o Free.
  /// Premium sempre retorna true.
  Future<bool> podeConsumir(Feature f, {required bool premium}) async {
    if (premium) return true;
    final quota = FeaturePolicy.quotaFree(f);
    if (quota == null) return false; // feature Pro-only
    final usado = await usoAtual(f);
    return usado < quota.limite;
  }

  /// Incrementa contador. Sem-op para usuários Premium (não faz sentido
  /// medir consumo deles). Se a janela virou, começa de 1.
  Future<int> incrementar(Feature f, {required bool premium}) async {
    if (premium) return 0;
    final quota = FeaturePolicy.quotaFree(f);
    if (quota == null) return 0;
    final prefs = await SharedPreferences.getInstance();
    final chaveContador = '$_prefix${f.name}_count';
    final chaveJanela = '$_prefix${f.name}_janela';

    final agora = DateTime.now();
    final janelaAtual = _idJanela(agora, quota.periodo);
    final janelaSalva = prefs.getString(chaveJanela);
    int novoValor;
    if (janelaSalva != janelaAtual) {
      novoValor = 1;
      await prefs.setString(chaveJanela, janelaAtual);
    } else {
      novoValor = (prefs.getInt(chaveContador) ?? 0) + 1;
    }
    await prefs.setInt(chaveContador, novoValor);
    return novoValor;
  }

  /// Restante no Free ("2 sobrando"). null se Premium ou sem quota.
  Future<int?> restante(Feature f, {required bool premium}) async {
    if (premium) return null;
    final quota = FeaturePolicy.quotaFree(f);
    if (quota == null) return 0;
    final usado = await usoAtual(f);
    final r = quota.limite - usado;
    return r < 0 ? 0 : r;
  }

  /// Gera um identificador de janela a partir do período.
  /// - Períodos de 1d → "YYYY-MM-DD"
  /// - Períodos de 7d → "YYYY-Www" (semana ISO aproximada)
  /// - Períodos de 30d → "YYYY-MM"
  String _idJanela(DateTime agora, Duration periodo) {
    if (periodo == const Duration(days: 1)) {
      return '${agora.year}-${_dois(agora.month)}-${_dois(agora.day)}';
    }
    if (periodo == const Duration(days: 7)) {
      final semana = ((agora.difference(DateTime(agora.year, 1, 1)).inDays) ~/ 7) + 1;
      return '${agora.year}-W${_dois(semana)}';
    }
    if (periodo == const Duration(days: 30)) {
      return '${agora.year}-${_dois(agora.month)}';
    }
    // Fallback: dias completos desde epoch.
    return '${agora.millisecondsSinceEpoch ~/ periodo.inMilliseconds}';
  }

  String _dois(int n) => n.toString().padLeft(2, '0');
}
