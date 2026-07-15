class ComplianceScore {
  final DateTime data;
  final int score; // 0-100
  final Map<String, dynamic> componentes; // {proteina, hidratacao, registro} (0-100 ou null)
  final List<dynamic> alertas;

  ComplianceScore({
    required this.data,
    required this.score,
    required this.componentes,
    required this.alertas,
  });

  /// Resposta do backend (dailyLogModel.scores):
  /// { data: 'YYYY-MM-DD', score: int, componentes: {...}, alertas: [...] }
  factory ComplianceScore.fromJson(Map<String, dynamic> json) {
    return ComplianceScore(
      data: DateTime.parse(json['data'] as String),
      score: (json['score'] as num?)?.toInt() ?? 0,
      componentes: Map<String, dynamic>.from(json['componentes'] as Map? ?? {}),
      alertas: (json['alertas'] as List?) ?? const [],
    );
  }

  String get scoreLabel {
    if (score >= 90) return 'Excelente! 🌟';
    if (score >= 75) return 'Muito bom! ✅';
    if (score >= 60) return 'Bom 👍';
    if (score >= 40) return 'Precisa melhorar 🔄';
    return 'Crítico 🚨';
  }

  int? get _proteina => (componentes['proteina'] as num?)?.toInt();
  int? get _hidratacao => (componentes['hidratacao'] as num?)?.toInt();

  String get proteinStatus {
    final p = _proteina;
    if (p == null) return 'Proteína — sem dado';
    if (p >= 90) return '✅ Proteína OK';
    if (p >= 70) return '⚠️ Proteína baixa';
    return '❌ Proteína crítica';
  }

  String get hydrationStatus {
    final h = _hidratacao;
    if (h == null) return 'Hidratação — sem dado';
    if (h >= 90) return '✅ Hidratação OK';
    if (h >= 70) return '⚠️ Hidratação baixa';
    return '❌ Hidratação crítica';
  }
}
