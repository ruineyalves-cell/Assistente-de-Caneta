/// Perfil consolidado do paciente exibido no ProfileConfigScreen.
///
/// Fontes: parte vem do backend (`GET /api/pacientes/perfil`) — campos que
/// existem hoje em `patient_profiles`; a parte identidade/eixo/última dose
/// ainda não é conhecida pelo backend e é persistida em `shared_preferences`
/// (ver keys em [ProfilePrefsKeys]).

/// Identidade de gênero — lista fechada, com opção respeitosa de omissão.
enum IdentidadeGenero { mulher, homem, naoBinario, prefiroNaoInformar }

extension IdentidadeGeneroLabel on IdentidadeGenero {
  String get label {
    switch (this) {
      case IdentidadeGenero.mulher:
        return 'Mulher';
      case IdentidadeGenero.homem:
        return 'Homem';
      case IdentidadeGenero.naoBinario:
        return 'Não-binário';
      case IdentidadeGenero.prefiroNaoInformar:
        return 'Prefiro não informar';
    }
  }
}

/// Sexo biológico — variável independente da identidade de gênero
/// (necessário para cálculos metabólicos coerentes com a literatura).
enum SexoBiologico { feminino, masculino, intersexo, prefiroNaoInformar }

extension SexoBiologicoLabel on SexoBiologico {
  String get label {
    switch (this) {
      case SexoBiologico.feminino:
        return 'Feminino';
      case SexoBiologico.masculino:
        return 'Masculino';
      case SexoBiologico.intersexo:
        return 'Intersexo';
      case SexoBiologico.prefiroNaoInformar:
        return 'Prefiro não informar';
    }
  }
}

/// Eixo farmacológico usado pelo dashboard de Recomposição (Lote 6) para
/// escolher a matriz de recomendações. Fonte: docs/PRD.md.
enum EixoFarmacologico {
  glp1Simples,
  duplo,
  triplo,
  combinadaMiostatina,
  recomposicaoNatural,
}

extension EixoFarmacologicoLabel on EixoFarmacologico {
  String get label {
    switch (this) {
      case EixoFarmacologico.glp1Simples:
        return 'GLP-1 simples';
      case EixoFarmacologico.duplo:
        return 'Duplo (GLP-1 + GIP)';
      case EixoFarmacologico.triplo:
        return 'Triplo (GLP-1 + GIP + Glucagon)';
      case EixoFarmacologico.combinadaMiostatina:
        return 'Combinada c/ Miostatina';
      case EixoFarmacologico.recomposicaoNatural:
        return 'Recomposição Natural (sem farmacologia)';
    }
  }

  /// True para os eixos que envolvem medicação injetável — só nesses casos
  /// a "Data da última dose" faz sentido.
  bool get envolveMedicacao =>
      this != EixoFarmacologico.recomposicaoNatural;

  /// Categorias de medicação (coluna `categoria` da tabela medications)
  /// compatíveis com este eixo. Lista vazia = eixo sem medicação
  /// disponível no catálogo (dropdown fica vazio com CTA informativo).
  ///
  /// Referência: database/seeds/001_medications.sql — categorias reais
  /// hoje: "GLP-1", "GLP-1 oral", "GLP-1/GIP (duplo agonista)",
  /// "GLP-1/GIP/GCG (triplo agonista)".
  List<String> get categoriasAceitas {
    switch (this) {
      case EixoFarmacologico.glp1Simples:
        return const ['GLP-1', 'GLP-1 oral'];
      case EixoFarmacologico.duplo:
        return const ['GLP-1/GIP (duplo agonista)'];
      case EixoFarmacologico.triplo:
        return const ['GLP-1/GIP/GCG (triplo agonista)'];
      case EixoFarmacologico.combinadaMiostatina:
        // Sem análogos de miostatina aprovados no Brasil (jul/2026).
        return const [];
      case EixoFarmacologico.recomposicaoNatural:
        return const [];
    }
  }
}

/// Chaves usadas no `shared_preferences` para os campos que o backend ainda
/// não conhece. Prefixo `profile_` isola de outras chaves do app.
class ProfilePrefsKeys {
  static const String identidadeGenero = 'profile_identidade_genero';
  static const String sexoBiologico = 'profile_sexo_biologico';
  static const String eixoFarmacologico = 'profile_eixo_farmacologico';
  static const String ultimaDoseIso = 'profile_ultima_dose_iso';
  // Lote 29 — Meta de peso definida no onboarding. Persistida local:
  // o backend não tem coluna para meta de peso (só pesoInicialKg em
  // patient_profiles); Lote 31 pode subir isso pro backend quando o
  // sync de peso/sintomas entrar.
  static const String metaPesoKg = 'profile_meta_peso_kg';

  // Lote 30 — Lembrete semanal da dose (GLP-1 típico é 1x/semana).
  // O agendamento é local via `awesome_notifications`. Não envolve
  // backend porque o horário é privado do usuário e a notificação é
  // disparada pelo dispositivo.
  static const String doseReminderEnabled = 'profile_dose_reminder_enabled';
  static const String doseReminderWeekday = 'profile_dose_reminder_weekday';
  static const String doseReminderHour = 'profile_dose_reminder_hour';
  static const String doseReminderMinute = 'profile_dose_reminder_minute';
}

/// Dados de perfil vindos do backend (`GET /api/pacientes/perfil`).
class PerfilBackend {
  final int? medicationId;
  final String? medicationNome;
  final String? doseAtual;
  final double? pesoInicialKg;
  final int? alturaCm;
  final double metaProteinaGkg;
  final double metaAguaMlKg;
  final bool declarouPrescricao;

  const PerfilBackend({
    this.medicationId,
    this.medicationNome,
    this.doseAtual,
    this.pesoInicialKg,
    this.alturaCm,
    this.metaProteinaGkg = 1.20,
    this.metaAguaMlKg = 35.0,
    this.declarouPrescricao = false,
  });

  factory PerfilBackend.fromJson(Map<String, dynamic> json) {
    final medicacao = json['medicacao'] as Map<String, dynamic>?;
    return PerfilBackend(
      medicationId: medicacao?['id'] as int?,
      medicationNome: medicacao?['nome'] as String?,
      doseAtual: json['doseAtual'] as String?,
      pesoInicialKg: (json['pesoInicialKg'] as num?)?.toDouble(),
      alturaCm: (json['alturaCm'] as num?)?.toInt(),
      metaProteinaGkg:
          (json['metaProteinaGkg'] as num?)?.toDouble() ?? 1.20,
      metaAguaMlKg: (json['metaAguaMlKg'] as num?)?.toDouble() ?? 35.0,
      declarouPrescricao: json['declarouPrescricao'] as bool? ?? false,
    );
  }

  static const PerfilBackend vazio = PerfilBackend();
}
