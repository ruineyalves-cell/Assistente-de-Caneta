class User {
  final int? id;
  final String nome;
  final String email;
  final String? role; // paciente, profissional, admin
  final DateTime dataNascimento;
  final bool ativo;
  final String? criado_em;

  User({
    this.id,
    required this.nome,
    required this.email,
    this.role,
    required this.dataNascimento,
    this.ativo = true,
    this.criado_em,
  });

  int get idadeAnos {
    final now = DateTime.now();
    var idade = now.year - dataNascimento.year;
    if (now.month < dataNascimento.month ||
        (now.month == dataNascimento.month && now.day < dataNascimento.day)) {
      idade--;
    }
    return idade;
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int?,
      nome: json['nome'] as String,
      email: json['email'] as String,
      role: json['role'] as String?,
      dataNascimento: json['data_nascimento'] != null
          ? DateTime.parse(json['data_nascimento'] as String)
          : DateTime.now(),
      ativo: json['ativo'] as bool? ?? true,
      criado_em: json['criado_em'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'email': email,
      'role': role,
      'data_nascimento': dataNascimento.toIso8601String().split('T')[0],
      'ativo': ativo,
      'criado_em': criado_em,
    };
  }
}
