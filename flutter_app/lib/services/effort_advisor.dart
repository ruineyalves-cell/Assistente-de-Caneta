import '../models/patient_profile.dart';

/// Modalidade de exercício aeróbico coberta pelo advisor.
enum ModalidadeAerobica { corrida, ciclismo }

extension ModalidadeAerobicaLabel on ModalidadeAerobica {
  String get label {
    switch (this) {
      case ModalidadeAerobica.corrida:
        return 'Corrida';
      case ModalidadeAerobica.ciclismo:
        return 'Ciclismo';
    }
  }

  String get emoji {
    switch (this) {
      case ModalidadeAerobica.corrida:
        return '🏃';
      case ModalidadeAerobica.ciclismo:
        return '🚴';
    }
  }
}

/// Nível de intensidade percebida — mapeamento simples ao invés de zonas
/// de FC precisas (que exigiriam validação clínica e coleta cardíaca real).
enum IntensidadeAerobica { leve, moderada, vigorosa }

extension IntensidadeAerobicaLabel on IntensidadeAerobica {
  String get label {
    switch (this) {
      case IntensidadeAerobica.leve:
        return 'Leve';
      case IntensidadeAerobica.moderada:
        return 'Moderada';
      case IntensidadeAerobica.vigorosa:
        return 'Vigorosa';
    }
  }

  String get descricao {
    switch (this) {
      case IntensidadeAerobica.leve:
        return 'Consegue conversar tranquilamente';
      case IntensidadeAerobica.moderada:
        return 'Fala em frases curtas';
      case IntensidadeAerobica.vigorosa:
        return 'Só palavras isoladas';
    }
  }
}

/// Recomendação educacional para uma modalidade aeróbica dado o eixo
/// farmacológico do usuário. **Não substitui orientação profissional**.
class RecomendacaoEsforco {
  final ModalidadeAerobica modalidade;
  final IntensidadeAerobica intensidade;
  final int duracaoMinutos;
  final int frequenciaSemanal;
  final String justificativa;

  const RecomendacaoEsforco({
    required this.modalidade,
    required this.intensidade,
    required this.duracaoMinutos,
    required this.frequenciaSemanal,
    required this.justificativa,
  });
}

/// Motor educacional que devolve orientação de intensidade/duração/
/// frequência por modalidade, tomando o eixo farmacológico como pivô.
///
/// A matriz reflete princípios gerais: mais medicação → mais atenção à
/// preservação de massa magra (aeróbico moderado, evita catabolismo);
/// corrida tem impacto maior que ciclismo, então quando ambos estão na
/// mesma faixa, corrida ganha 1 grau a menos de intensidade.
///
/// **Nada aqui substitui prescrição médica.** É orientação educativa.
class EffortAdvisor {
  const EffortAdvisor();

  /// Retorna recomendações para todas as modalidades cobertas.
  List<RecomendacaoEsforco> recomendacoes(EixoFarmacologico? eixo) {
    return ModalidadeAerobica.values
        .map((m) => recomendacaoPara(m, eixo))
        .toList();
  }

  RecomendacaoEsforco recomendacaoPara(
      ModalidadeAerobica modalidade, EixoFarmacologico? eixo) {
    // Sem eixo configurado: devolve orientação genérica de manutenção.
    if (eixo == null) {
      return RecomendacaoEsforco(
        modalidade: modalidade,
        intensidade: IntensidadeAerobica.moderada,
        duracaoMinutos: modalidade == ModalidadeAerobica.corrida ? 30 : 40,
        frequenciaSemanal: 3,
        justificativa:
            'Configure seu eixo farmacológico no Perfil para uma '
            'recomendação individualizada.',
      );
    }

    switch (eixo) {
      case EixoFarmacologico.recomposicaoNatural:
        // Sem eixo farmacológico → sem risco extra de catabolismo.
        return _monta(
          modalidade,
          corridaIntensidade: IntensidadeAerobica.vigorosa,
          ciclismoIntensidade: IntensidadeAerobica.vigorosa,
          duracaoCorrida: 40,
          duracaoCiclismo: 60,
          frequencia: 4,
          justificativa:
              'Recomposição natural tolera maior intensidade — foque em '
              'progressão gradual e recuperação adequada.',
        );

      case EixoFarmacologico.combinadaMiostatina:
        // Miostatina protege massa magra — aeróbico moderado é seguro.
        return _monta(
          modalidade,
          corridaIntensidade: IntensidadeAerobica.moderada,
          ciclismoIntensidade: IntensidadeAerobica.vigorosa,
          duracaoCorrida: 35,
          duracaoCiclismo: 50,
          frequencia: 4,
          justificativa:
              'A associação com miostatina ajuda a preservar massa magra '
              'mesmo com aeróbico regular.',
        );

      case EixoFarmacologico.glp1Simples:
        return _monta(
          modalidade,
          corridaIntensidade: IntensidadeAerobica.moderada,
          ciclismoIntensidade: IntensidadeAerobica.moderada,
          duracaoCorrida: 30,
          duracaoCiclismo: 45,
          frequencia: 3,
          justificativa:
              'GLP-1 favorece perda de peso — priorize sessões moderadas '
              'para preservar massa magra.',
        );

      case EixoFarmacologico.duplo:
        return _monta(
          modalidade,
          corridaIntensidade: IntensidadeAerobica.moderada,
          ciclismoIntensidade: IntensidadeAerobica.moderada,
          duracaoCorrida: 30,
          duracaoCiclismo: 45,
          frequencia: 3,
          justificativa:
              'Ação dupla (GLP-1 + GIP) intensifica a perda — mantenha '
              'sessões controladas e capriche no treino de força.',
        );

      case EixoFarmacologico.triplo:
        return _monta(
          modalidade,
          corridaIntensidade: IntensidadeAerobica.leve,
          ciclismoIntensidade: IntensidadeAerobica.moderada,
          duracaoCorrida: 25,
          duracaoCiclismo: 40,
          frequencia: 3,
          justificativa:
              'Combinação tripla tem maior potencial catabólico — reduza '
              'intensidade e priorize preservação muscular.',
        );
    }
  }

  RecomendacaoEsforco _monta(
    ModalidadeAerobica modalidade, {
    required IntensidadeAerobica corridaIntensidade,
    required IntensidadeAerobica ciclismoIntensidade,
    required int duracaoCorrida,
    required int duracaoCiclismo,
    required int frequencia,
    required String justificativa,
  }) {
    final ehCorrida = modalidade == ModalidadeAerobica.corrida;
    return RecomendacaoEsforco(
      modalidade: modalidade,
      intensidade: ehCorrida ? corridaIntensidade : ciclismoIntensidade,
      duracaoMinutos: ehCorrida ? duracaoCorrida : duracaoCiclismo,
      frequenciaSemanal: frequencia,
      justificativa: justificativa,
    );
  }
}
