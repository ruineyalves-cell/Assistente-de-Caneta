class Medication {
  final int id;
  final String nomeComercial;
  final String nomePrincipioDivoAtivo;
  final String dosagem;
  final String viaAdministracao;
  final String frequenciaRecomendada;
  final double precoMedioUnitario;
  final String cnpjFabricante;
  final bool receituario;
  final bool ativo;
  final String? areaAtuacao;

  Medication({
    required this.id,
    required this.nomeComercial,
    required this.nomePrincipioDivoAtivo,
    required this.dosagem,
    required this.viaAdministracao,
    required this.frequenciaRecomendada,
    required this.precoMedioUnitario,
    required this.cnpjFabricante,
    required this.receituario,
    required this.ativo,
    this.areaAtuacao,
  });

  factory Medication.fromJson(Map<String, dynamic> json) {
    return Medication(
      id: json['id'] as int,
      nomeComercial: json['nome_comercial'] as String,
      nomePrincipioDivoAtivo: json['nome_principio_ativo'] as String,
      dosagem: json['dosagem'] as String,
      viaAdministracao: json['via_administracao'] as String,
      frequenciaRecomendada: json['frequencia_recomendada'] as String,
      precoMedioUnitario: (json['preco_medio_unitario'] as num).toDouble(),
      cnpjFabricante: json['cnpj_fabricante'] as String,
      receituario: json['receituario'] as bool,
      ativo: json['ativo'] as bool? ?? true,
      areaAtuacao: json['area_atuacao'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome_comercial': nomeComercial,
      'nome_principio_ativo': nomePrincipioDivoAtivo,
      'dosagem': dosagem,
      'via_administracao': viaAdministracao,
      'frequencia_recomendada': frequenciaRecomendada,
      'preco_medio_unitario': precoMedioUnitario,
      'cnpj_fabricante': cnpjFabricante,
      'receituario': receituario,
      'ativo': ativo,
      'area_atuacao': areaAtuacao,
    };
  }

  @override
  String toString() => '$nomeComercial ($dosagem)';
}
