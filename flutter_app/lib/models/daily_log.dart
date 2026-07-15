class DailyLog {
  final String? id;
  final DateTime data;
  final double? pesoKg;
  final int? proteinaG;
  final int? aguaMl;
  final String? alimentos;
  final bool doseAplicada;
  final String? efeitosColaterais;

  DailyLog({
    this.id,
    required this.data,
    this.pesoKg,
    this.proteinaG,
    this.aguaMl,
    this.alimentos,
    this.doseAplicada = false,
    this.efeitosColaterais,
  });

  /// Resposta do backend (dailyLogModel.descriptografar):
  /// { id, data, pesoKg, proteinaG, aguaMl, alimentos, doseAplicada, efeitos }
  factory DailyLog.fromJson(Map<String, dynamic> json) {
    return DailyLog(
      id: json['id']?.toString(),
      data: DateTime.parse(json['data'] as String),
      pesoKg: (json['pesoKg'] as num?)?.toDouble(),
      proteinaG: (json['proteinaG'] as num?)?.toInt(),
      aguaMl: (json['aguaMl'] as num?)?.toInt(),
      alimentos: json['alimentos'] as String?,
      doseAplicada: json['doseAplicada'] as bool? ?? false,
      efeitosColaterais: json['efeitos'] as String?,
    );
  }

  bool get isComplete =>
      pesoKg != null && proteinaG != null && aguaMl != null;
}
