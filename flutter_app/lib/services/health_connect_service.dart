import 'package:flutter/foundation.dart';
import 'package:health/health.dart';

/// Resumo do dia lido do Health Connect (Lote 11).
class HealthResumoDia {
  final int? bpmMedio;
  final int? bpmMax;
  final double? kcalAtivas;
  final int amostrasBpm;
  final int amostrasKcal;

  const HealthResumoDia({
    this.bpmMedio,
    this.bpmMax,
    this.kcalAtivas,
    this.amostrasBpm = 0,
    this.amostrasKcal = 0,
  });

  bool get temDados => amostrasBpm > 0 || amostrasKcal > 0;

  static const vazio = HealthResumoDia();
}

/// Fachada sobre o package `health` v13 para os dois tipos de leitura
/// que a Recorpo precisa hoje: frequência cardíaca e calorias ativas.
///
/// Isola o app do estado do plugin (Web não suporta) e traduz os
/// pontos brutos em [HealthResumoDia].
class HealthConnectService {
  final Health _health = Health();
  bool _configurado = false;

  static const List<HealthDataType> tiposLeitura = [
    HealthDataType.HEART_RATE,
    HealthDataType.ACTIVE_ENERGY_BURNED,
  ];

  /// Indica se a plataforma corrente tem chance de expor Health Connect.
  /// No web sempre `false`; nos demais casos é verificado em runtime.
  bool get suportado => !kIsWeb;

  Future<void> _garantirConfigurado() async {
    if (_configurado) return;
    await _health.configure();
    _configurado = true;
  }

  /// Solicita autorização de leitura ao Health Connect. Retorna `true`
  /// se todas as leituras necessárias foram autorizadas.
  Future<bool> pedirAutorizacao() async {
    if (!suportado) return false;
    await _garantirConfigurado();
    return await _health.requestAuthorization(tiposLeitura);
  }

  /// Verifica se o usuário já concedeu as permissões (sem re-perguntar).
  Future<bool> temAutorizacao() async {
    if (!suportado) return false;
    await _garantirConfigurado();
    final r = await _health.hasPermissions(tiposLeitura);
    return r ?? false;
  }

  /// Lê frequência cardíaca + calorias ativas do dia atual (00:00→agora)
  /// e devolve o resumo agregado.
  Future<HealthResumoDia> resumoDeHoje() async {
    if (!suportado) return HealthResumoDia.vazio;
    await _garantirConfigurado();
    final agora = DateTime.now();
    final inicio = DateTime(agora.year, agora.month, agora.day);

    final pontos = await _health.getHealthDataFromTypes(
      types: tiposLeitura,
      startTime: inicio,
      endTime: agora,
    );

    final bpms = <double>[];
    double kcal = 0;
    var amostrasKcal = 0;
    for (final p in pontos) {
      final valor = p.value;
      if (p.type == HealthDataType.HEART_RATE && valor is NumericHealthValue) {
        bpms.add(valor.numericValue.toDouble());
      } else if (p.type == HealthDataType.ACTIVE_ENERGY_BURNED &&
          valor is NumericHealthValue) {
        kcal += valor.numericValue.toDouble();
        amostrasKcal += 1;
      }
    }

    return HealthResumoDia(
      bpmMedio:
          bpms.isEmpty ? null : (bpms.reduce((a, b) => a + b) / bpms.length).round(),
      bpmMax: bpms.isEmpty ? null : bpms.reduce((a, b) => a > b ? a : b).round(),
      kcalAtivas: amostrasKcal == 0 ? null : kcal,
      amostrasBpm: bpms.length,
      amostrasKcal: amostrasKcal,
    );
  }
}
