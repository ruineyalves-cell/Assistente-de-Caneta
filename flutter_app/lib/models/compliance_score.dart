class ComplianceScore {
  final int? id;
  final int patientId;
  final DateTime data;
  final int score; // 0-100
  final Map<String, dynamic> componentes; // {protein%: 80, hydration%: 90, registration%: 100}
  final List<String> alertas;
  final DateTime criado_em;

  ComplianceScore({
    this.id,
    required this.patientId,
    required this.data,
    required this.score,
    required this.componentes,
    required this.alertas,
    required this.criado_em,
  });

  factory ComplianceScore.fromJson(Map<String, dynamic> json) {
    return ComplianceScore(
      id: json['id'] as int?,
      patientId: json['patient_id'] as int,
      data: DateTime.parse(json['data'] as String),
      score: json['score'] as int,
      componentes: Map<String, dynamic>.from(json['componentes'] as Map? ?? {}),
      alertas: List<String>.from(json['alertas'] as List? ?? []),
      criado_em: DateTime.parse(json['criado_em'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patient_id': patientId,
      'data': data.toIso8601String(),
      'score': score,
      'componentes': componentes,
      'alertas': alertas,
      'criado_em': criado_em.toIso8601String(),
    };
  }

  String get scoreLabel {
    if (score >= 90) return 'Excelente! 🌟';
    if (score >= 75) return 'Muito bom! ✅';
    if (score >= 60) return 'Bom 👍';
    if (score >= 40) return 'Precisa melhorar 🔄';
    return 'Crítico 🚨';
  }

  String get proteinStatus {
    final proteinPercent = (componentes['protein%'] as num?)?.toInt() ?? 0;
    if (proteinPercent >= 90) return '✅ Proteína OK';
    if (proteinPercent >= 70) return '⚠️ Proteína baixa';
    return '❌ Proteína crítica';
  }

  String get hydrationStatus {
    final hydrationPercent = (componentes['hydration%'] as num?)?.toInt() ?? 0;
    if (hydrationPercent >= 90) return '✅ Hidratação OK';
    if (hydrationPercent >= 70) return '⚠️ Hidratação baixa';
    return '❌ Hidratação crítica';
  }
}
