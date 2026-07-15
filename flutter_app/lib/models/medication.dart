class Medication {
  final int id;
  final String nomeComercial;
  final String? principioAtivo;
  final String? fabricante;
  final String? statusAnvisa;
  final String? categoria;
  final String? indicacoes;
  final String? frequenciaPadrao;
  final String? via;

  Medication({
    required this.id,
    required this.nomeComercial,
    this.principioAtivo,
    this.fabricante,
    this.statusAnvisa,
    this.categoria,
    this.indicacoes,
    this.frequenciaPadrao,
    this.via,
  });

  /// Resposta do backend GET /api/medicacoes -> { medicacoes: [ {...} ] }
  factory Medication.fromJson(Map<String, dynamic> json) {
    return Medication(
      id: (json['id'] as num).toInt(),
      nomeComercial: (json['nome_comercial'] ?? '') as String,
      principioAtivo: json['principio_ativo'] as String?,
      fabricante: json['fabricante'] as String?,
      statusAnvisa: json['status_anvisa'] as String?,
      categoria: json['categoria'] as String?,
      indicacoes: json['indicacoes'] as String?,
      frequenciaPadrao: json['frequencia_padrao'] as String?,
      via: json['via'] as String?,
    );
  }

  bool get aprovada => statusAnvisa == 'aprovado';

  @override
  String toString() => nomeComercial;
}
