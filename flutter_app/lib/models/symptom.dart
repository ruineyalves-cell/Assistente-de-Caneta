/// Lote 25 — Modelo de sintomas para farmacovigilância.
///
/// Lista curada a partir de bulas Anvisa dos principais GLP-1
/// comercializados no Brasil (Ozempic/Wegovy — semaglutida; Mounjaro —
/// tirzepatida; Saxenda — liraglutida; Rybelsus — semaglutida oral).
///
/// **Cada sintoma tem microtexto educativo com fonte.** Isso é crucial
/// por LGPD/CFN — informativo, nunca prescritivo. A leitura sempre
/// termina com "converse com seu médico se persistir".
enum SymptomType {
  nausea,
  vomito,
  dorAbdominal,
  refluxo,
  constipacao,
  diarreia,
  dorCabeca,
  tontura,
  cansaco,
  perdaApetite,
  febre,
  reacaoLocalInjecao,
  hipoglicemia,
  batimentosAlterados,
  dificuldadeRespirar,
}

/// Intensidade autorreportada. Escala 0-3 (0 = sem sintoma, não é
/// registrado).
enum SymptomIntensity {
  leve,
  moderado,
  intenso,
}

extension SymptomIntensityLabel on SymptomIntensity {
  String get label {
    switch (this) {
      case SymptomIntensity.leve:
        return 'Leve';
      case SymptomIntensity.moderado:
        return 'Moderado';
      case SymptomIntensity.intenso:
        return 'Intenso';
    }
  }

  int get valor {
    switch (this) {
      case SymptomIntensity.leve:
        return 1;
      case SymptomIntensity.moderado:
        return 2;
      case SymptomIntensity.intenso:
        return 3;
    }
  }

  static SymptomIntensity? fromValor(int v) {
    switch (v) {
      case 1:
        return SymptomIntensity.leve;
      case 2:
        return SymptomIntensity.moderado;
      case 3:
        return SymptomIntensity.intenso;
    }
    return null;
  }
}

class SymptomInfo {
  final SymptomType tipo;
  final String rotulo;
  final String emoji;
  final String microContexto;
  final String fonteContexto;
  final bool alertaSeIntenso;

  const SymptomInfo({
    required this.tipo,
    required this.rotulo,
    required this.emoji,
    required this.microContexto,
    required this.fonteContexto,
    this.alertaSeIntenso = false,
  });
}

/// Catálogo oficial. Ordem importa (aparece na tela nessa ordem).
const List<SymptomInfo> kSintomasCatalogo = [
  SymptomInfo(
    tipo: SymptomType.nausea,
    rotulo: 'Náusea',
    emoji: '🤢',
    microContexto:
        'Sensação de enjoo é o efeito colateral mais frequente nas primeiras semanas de GLP-1. '
        'Costuma reduzir quando o corpo se ajusta à dose (2 a 4 semanas). '
        'Comer devagar, em porções menores, evitar frituras e alimentos muito gordurosos ajuda a maioria dos pacientes.',
    fonteContexto: 'Bulas Ozempic e Mounjaro — Anvisa',
  ),
  SymptomInfo(
    tipo: SymptomType.vomito,
    rotulo: 'Vômito',
    emoji: '🤮',
    microContexto:
        'Se acontece isoladamente e é leve, faz parte do ajuste inicial do GLP-1. '
        'Vômitos repetidos ou por mais de 24h podem causar desidratação — reponha líquidos em pequenos goles e converse com quem prescreveu.',
    fonteContexto: 'Bulas Ozempic e Mounjaro — Anvisa',
    alertaSeIntenso: true,
  ),
  SymptomInfo(
    tipo: SymptomType.dorAbdominal,
    rotulo: 'Dor abdominal',
    emoji: '😖',
    microContexto:
        'Desconforto abdominal leve é comum. '
        'Dor intensa, persistente e que irradia para as costas — especialmente com náusea/vômito — merece atenção médica imediata (a bula do Ozempic pede vigilância para pancreatite).',
    fonteContexto: 'Bula Ozempic — Anvisa',
    alertaSeIntenso: true,
  ),
  SymptomInfo(
    tipo: SymptomType.refluxo,
    rotulo: 'Refluxo / azia',
    emoji: '🔥',
    microContexto:
        'GLP-1 retarda o esvaziamento gástrico, o que pode intensificar refluxo em quem já tinha tendência. '
        'Refeições menores e mais frequentes, evitar deitar logo após comer e reduzir cafeína/álcool costumam ajudar.',
    fonteContexto: 'ABESO 2023 — GLP-1 na obesidade',
  ),
  SymptomInfo(
    tipo: SymptomType.constipacao,
    rotulo: 'Constipação',
    emoji: '🚻',
    microContexto:
        'Intestino mais lento é comum. Beber mais água (~35 ml por kg de peso), aumentar fibras (frutas, legumes, aveia) e caminhar ajuda. '
        'Se durar mais de uma semana, converse com seu médico.',
    fonteContexto: 'Bula Wegovy — Anvisa',
  ),
  SymptomInfo(
    tipo: SymptomType.diarreia,
    rotulo: 'Diarreia',
    emoji: '💧',
    microContexto:
        'Alterações do trânsito intestinal são comuns nas primeiras semanas. '
        'Se durar mais de 48h ou vier com febre e dor forte, procure orientação médica — hidratação é prioridade.',
    fonteContexto: 'Bulas Ozempic e Mounjaro — Anvisa',
  ),
  SymptomInfo(
    tipo: SymptomType.dorCabeca,
    rotulo: 'Dor de cabeça',
    emoji: '🤕',
    microContexto:
        'Pode aparecer no ajuste inicial da dose ou em dias com pouca hidratação/alimentação. '
        'Verifique se está bebendo água suficiente e se comeu regularmente.',
    fonteContexto: 'Bula Saxenda — Anvisa',
  ),
  SymptomInfo(
    tipo: SymptomType.tontura,
    rotulo: 'Tontura',
    emoji: '😵‍💫',
    microContexto:
        'Pode estar relacionada a queda de glicemia (especialmente se você toma outros medicamentos para diabetes) ou desidratação. '
        'Sente-se, hidrate-se, coma algo leve. Persistindo, procure orientação.',
    fonteContexto: 'Bula Ozempic — Anvisa',
    alertaSeIntenso: true,
  ),
  SymptomInfo(
    tipo: SymptomType.cansaco,
    rotulo: 'Cansaço',
    emoji: '😴',
    microContexto:
        'Redução de apetite pode diminuir a ingestão calórica além do esperado. '
        'Prestar atenção à proteína (~1,2 g/kg) e ao sono ajuda a manter energia. Cansaço persistente merece avaliação.',
    fonteContexto: 'ABESO 2023',
  ),
  SymptomInfo(
    tipo: SymptomType.perdaApetite,
    rotulo: 'Pouca fome',
    emoji: '🍽️',
    microContexto:
        'É esperado — é justamente um dos mecanismos do GLP-1. '
        'Cuidado para não pular refeições completamente: manter proteína e hidratação preserva massa muscular durante a perda de peso.',
    fonteContexto: 'ABESO 2023',
  ),
  SymptomInfo(
    tipo: SymptomType.febre,
    rotulo: 'Febre',
    emoji: '🌡️',
    microContexto:
        'Febre não é um efeito colateral esperado do GLP-1. '
        'Procure avaliação médica para investigar a causa — pode indicar infecção que não tem relação com o medicamento.',
    fonteContexto: 'Bulas Ozempic e Mounjaro — Anvisa',
    alertaSeIntenso: true,
  ),
  SymptomInfo(
    tipo: SymptomType.reacaoLocalInjecao,
    rotulo: 'Reação no local da injeção',
    emoji: '💉',
    microContexto:
        'Vermelhidão, coceira ou pequeno inchaço no local são comuns. '
        'Alterne o local a cada aplicação (abdômen, coxa, braço). Reação forte com bolha ou dor grande merece avaliação.',
    fonteContexto: 'Bula Ozempic — Anvisa',
  ),
  SymptomInfo(
    tipo: SymptomType.hipoglicemia,
    rotulo: 'Hipoglicemia',
    emoji: '📉',
    microContexto:
        'GLP-1 sozinho raramente causa hipoglicemia — mas o risco aumenta se você usa insulina ou sulfonilureia. '
        'Sinais: tremor, suor frio, confusão. Trate com carboidrato rápido e informe seu médico.',
    fonteContexto: 'Bula Ozempic — Anvisa',
    alertaSeIntenso: true,
  ),
  SymptomInfo(
    tipo: SymptomType.batimentosAlterados,
    rotulo: 'Batimentos alterados',
    emoji: '❤️',
    microContexto:
        'Alguma alteração leve de frequência cardíaca pode ocorrer. '
        'Palpitação forte, tontura ou desmaio merecem avaliação — inclusive para descartar causas não ligadas ao medicamento.',
    fonteContexto: 'Bula Saxenda — Anvisa',
    alertaSeIntenso: true,
  ),
  SymptomInfo(
    tipo: SymptomType.dificuldadeRespirar,
    rotulo: 'Falta de ar',
    emoji: '🫁',
    microContexto:
        'Falta de ar não é um efeito colateral esperado do GLP-1. '
        'Procure avaliação médica imediata — pode ser sinal de reação alérgica ou de condição sem relação com o medicamento.',
    fonteContexto: 'Bulas Anvisa',
    alertaSeIntenso: true,
  ),
];

/// Registro individual de um sintoma. Serializável para JSON — vai
/// dentro do campo `efeitos` do daily_log (backend já aceita string).
class SymptomEntry {
  final SymptomType tipo;
  final SymptomIntensity intensidade;
  final DateTime quando;
  final String? contexto; // ex: "30min após: Frango grelhado"

  const SymptomEntry({
    required this.tipo,
    required this.intensidade,
    required this.quando,
    this.contexto,
  });

  Map<String, dynamic> toJson() => {
        't': tipo.name,
        'i': intensidade.valor,
        'q': quando.toIso8601String(),
        if (contexto != null) 'c': contexto,
      };

  static SymptomEntry? fromJson(Map<String, dynamic> j) {
    try {
      final tipo = SymptomType.values.firstWhere((e) => e.name == j['t']);
      final intensidade = SymptomIntensityLabel.fromValor(j['i'] as int);
      if (intensidade == null) return null;
      return SymptomEntry(
        tipo: tipo,
        intensidade: intensidade,
        quando: DateTime.parse(j['q'] as String),
        contexto: j['c'] as String?,
      );
    } catch (_) {
      return null;
    }
  }
}

SymptomInfo infoDe(SymptomType t) =>
    kSintomasCatalogo.firstWhere((s) => s.tipo == t);
