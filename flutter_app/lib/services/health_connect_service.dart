import 'package:flutter/foundation.dart';
import 'package:health/health.dart';

/// Resumo do dia lido do Health Connect (Lote 11 + Lote 22).
class HealthResumoDia {
  final int? bpmMedio;
  final int? bpmMax;
  final double? kcalAtivas;
  final int? passos;
  final double? pesoUltimoKg;
  final DateTime? pesoUltimoEm;
  final int amostrasBpm;
  final int amostrasKcal;

  const HealthResumoDia({
    this.bpmMedio,
    this.bpmMax,
    this.kcalAtivas,
    this.passos,
    this.pesoUltimoKg,
    this.pesoUltimoEm,
    this.amostrasBpm = 0,
    this.amostrasKcal = 0,
  });

  bool get temDados =>
      amostrasBpm > 0 ||
      amostrasKcal > 0 ||
      (passos != null && passos! > 0) ||
      pesoUltimoKg != null;

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
    HealthDataType.STEPS,
    HealthDataType.WEIGHT,
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

  /// Lê frequência cardíaca + calorias ativas + passos do dia atual
  /// (00:00→agora) + último peso registrado nos últimos 90 dias.
  Future<HealthResumoDia> resumoDeHoje() async {
    if (!suportado) return HealthResumoDia.vazio;
    await _garantirConfigurado();
    final agora = DateTime.now();
    final inicio = DateTime(agora.year, agora.month, agora.day);

    final pontosHoje = await _health.getHealthDataFromTypes(
      types: const [
        HealthDataType.HEART_RATE,
        HealthDataType.ACTIVE_ENERGY_BURNED,
        HealthDataType.STEPS,
      ],
      startTime: inicio,
      endTime: agora,
    );

    // Peso é medido esporadicamente — pega a leitura mais recente nos
    // últimos 90 dias para exibir a tendência mesmo quando o usuário
    // não pesa todo dia.
    final pontosPeso = await _health.getHealthDataFromTypes(
      types: const [HealthDataType.WEIGHT],
      startTime: agora.subtract(const Duration(days: 90)),
      endTime: agora,
    );

    final bpms = <double>[];
    double kcal = 0;
    var amostrasKcal = 0;
    int passos = 0;
    for (final p in pontosHoje) {
      final valor = p.value;
      if (valor is! NumericHealthValue) continue;
      switch (p.type) {
        case HealthDataType.HEART_RATE:
          bpms.add(valor.numericValue.toDouble());
          break;
        case HealthDataType.ACTIVE_ENERGY_BURNED:
          kcal += valor.numericValue.toDouble();
          amostrasKcal += 1;
          break;
        case HealthDataType.STEPS:
          passos += valor.numericValue.toInt();
          break;
        default:
          break;
      }
    }

    double? pesoUltimo;
    DateTime? pesoUltimoEm;
    if (pontosPeso.isNotEmpty) {
      pontosPeso.sort((a, b) => b.dateTo.compareTo(a.dateTo));
      final v = pontosPeso.first.value;
      if (v is NumericHealthValue) {
        pesoUltimo = v.numericValue.toDouble();
        pesoUltimoEm = pontosPeso.first.dateTo;
      }
    }

    return HealthResumoDia(
      bpmMedio:
          bpms.isEmpty ? null : (bpms.reduce((a, b) => a + b) / bpms.length).round(),
      bpmMax: bpms.isEmpty ? null : bpms.reduce((a, b) => a > b ? a : b).round(),
      kcalAtivas: amostrasKcal == 0 ? null : kcal,
      passos: passos == 0 ? null : passos,
      pesoUltimoKg: pesoUltimo,
      pesoUltimoEm: pesoUltimoEm,
      amostrasBpm: bpms.length,
      amostrasKcal: amostrasKcal,
    );
  }
}
