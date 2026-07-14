class DailyLog {
  final int? id;
  final int patientId;
  final DateTime data;
  final double? pesoKg;
  final int? proteinaG;
  final int? aguaMl;
  final String? alimentos;
  final bool doseAplicada;
  final String? efeitosColaterais;
  final DateTime criado_em;

  DailyLog({
    this.id,
    required this.patientId,
    required this.data,
    this.pesoKg,
    this.proteinaG,
    this.aguaMl,
    this.alimentos,
    required this.doseAplicada,
    this.efeitosColaterais,
    required this.criado_em,
  });

  factory DailyLog.fromJson(Map<String, dynamic> json) {
    return DailyLog(
      id: json['id'] as int?,
      patientId: json['patient_id'] as int,
      data: DateTime.parse(json['data'] as String),
      pesoKg: (json['peso_kg_enc'] as num?)?.toDouble(),
      proteinaG: json['proteina_g_enc'] as int?,
      aguaMl: json['agua_ml_enc'] as int?,
      alimentos: json['alimentos_enc'] as String?,
      doseAplicada: json['dose_aplicada'] as bool? ?? false,
      efeitosColaterais: json['efeitos_enc'] as String?,
      criado_em: DateTime.parse(json['criado_em'] as String? ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patient_id': patientId,
      'data': data.toIso8601String(),
      'peso_kg_enc': pesoKg,
      'proteina_g_enc': proteinaG,
      'agua_ml_enc': aguaMl,
      'alimentos_enc': alimentos,
      'dose_aplicada': doseAplicada,
      'efeitos_enc': efeitosColaterais,
      'criado_em': criado_em.toIso8601String(),
    };
  }

  bool get isComplete {
    return pesoKg != null && proteinaG != null && aguaMl != null;
  }
}
