import '../models/patient_profile.dart';

/// Categoria da dica — usada para leve variação visual/emocional.
enum CategoriaDica {
  motivacional,
  cuidado,
  tecnica,
  celebracao,
  hidratacao,
}

extension CategoriaDicaLabel on CategoriaDica {
  String get emoji {
    switch (this) {
      case CategoriaDica.motivacional:
        return '💪';
      case CategoriaDica.cuidado:
        return '🤍';
      case CategoriaDica.tecnica:
        return '🎯';
      case CategoriaDica.celebracao:
        return '🌟';
      case CategoriaDica.hidratacao:
        return '💧';
    }
  }

  String get rotulo {
    switch (this) {
      case CategoriaDica.motivacional:
        return 'Motivação';
      case CategoriaDica.cuidado:
        return 'Cuidado';
      case CategoriaDica.tecnica:
        return 'Técnica';
      case CategoriaDica.celebracao:
        return 'Celebração';
      case CategoriaDica.hidratacao:
        return 'Hidratação';
    }
  }
}

/// Dica humanizada apresentada na Home (Lote 15).
class DicaDoDia {
  final CategoriaDica categoria;
  final String texto;
  const DicaDoDia({required this.categoria, required this.texto});
}

/// Sorteia uma dica do dia — determinística por data (a mesma dica dura
/// o dia todo, muda de dia) — com concordância de gênero.
///
/// Cada entrada do pool tem 3 variantes: **f** (feminino), **m**
/// (masculino), **n** (neutro).
class DailyTipService {
  const DailyTipService();

  /// Devolve a dica de hoje conforme o [genero] e a [data] informados.
  /// [data] é injetada para teste; padrão = `DateTime.now()`.
  DicaDoDia dicaDoDia({IdentidadeGenero? genero, DateTime? data}) {
    final d = data ?? DateTime.now();
    final dayOfYear = _diaDoAno(d);
    final entrada = _pool[dayOfYear % _pool.length];
    return DicaDoDia(
      categoria: entrada.categoria,
      texto: _escolhe(entrada, genero),
    );
  }

  static int _diaDoAno(DateTime d) {
    final inicio = DateTime(d.year, 1, 1);
    return d.difference(inicio).inDays;
  }

  String _escolhe(_Entrada e, IdentidadeGenero? g) {
    switch (g) {
      case IdentidadeGenero.mulher:
        return e.f;
      case IdentidadeGenero.homem:
        return e.m;
      case IdentidadeGenero.naoBinario:
      case IdentidadeGenero.prefiroNaoInformar:
      case null:
        return e.n;
    }
  }

  // ---- Pool de dicas ----
  // Mistura de categorias, todas focadas em acolher e reforçar hábitos
  // saudáveis sem culpabilizar o paciente por eventuais falhas.
  static const List<_Entrada> _pool = [
    _Entrada(
      categoria: CategoriaDica.motivacional,
      f: 'Você não precisa ser perfeita hoje — só consistente. Um dia registrado já é vitória.',
      m: 'Você não precisa ser perfeito hoje — só consistente. Um dia registrado já é vitória.',
      n: 'Você não precisa ser perfeito hoje — só consistente. Um dia registrado já é vitória.',
    ),
    _Entrada(
      categoria: CategoriaDica.hidratacao,
      f: 'A água é a sua parceira invisível. Comece o dia com um copo cheio, sem pensar duas vezes.',
      m: 'A água é o seu parceiro invisível. Comece o dia com um copo cheio, sem pensar duas vezes.',
      n: 'A água é uma parceira invisível. Comece o dia com um copo cheio, sem pensar duas vezes.',
    ),
    _Entrada(
      categoria: CategoriaDica.tecnica,
      f: 'Proteína em cada refeição é o melhor escudo contra a perda de massa magra.',
      m: 'Proteína em cada refeição é o melhor escudo contra a perda de massa magra.',
      n: 'Proteína em cada refeição é o melhor escudo contra a perda de massa magra.',
    ),
    _Entrada(
      categoria: CategoriaDica.cuidado,
      f: 'Se hoje o corpo pediu descanso, ouça. Amanhã ele agradece.',
      m: 'Se hoje o corpo pediu descanso, ouça. Amanhã ele agradece.',
      n: 'Se hoje o corpo pediu descanso, ouça. Amanhã ele agradece.',
    ),
    _Entrada(
      categoria: CategoriaDica.celebracao,
      f: 'Cada semana consistente é um degrau. Você já subiu mais do que imagina.',
      m: 'Cada semana consistente é um degrau. Você já subiu mais do que imagina.',
      n: 'Cada semana consistente é um degrau. Já subiu mais do que imagina.',
    ),
    _Entrada(
      categoria: CategoriaDica.motivacional,
      f: 'Meta não é destino — é direção. Continue andando na sua.',
      m: 'Meta não é destino — é direção. Continue andando na sua.',
      n: 'Meta não é destino — é direção. Continue andando na sua.',
    ),
    _Entrada(
      categoria: CategoriaDica.tecnica,
      f: 'Ovos, iogurte grego e whey são atalhos práticos pra bater a meta de proteína.',
      m: 'Ovos, iogurte grego e whey são atalhos práticos pra bater a meta de proteína.',
      n: 'Ovos, iogurte grego e whey são atalhos práticos pra bater a meta de proteína.',
    ),
    _Entrada(
      categoria: CategoriaDica.hidratacao,
      f: 'GLP-1 desacelera o esvaziamento gástrico — beber água entre refeições ajuda a evitar mal-estar.',
      m: 'GLP-1 desacelera o esvaziamento gástrico — beber água entre refeições ajuda a evitar mal-estar.',
      n: 'GLP-1 desacelera o esvaziamento gástrico — beber água entre refeições ajuda a evitar mal-estar.',
    ),
    _Entrada(
      categoria: CategoriaDica.cuidado,
      f: 'Náusea passageira é comum. Refeições pequenas e frequentes costumam ajudar.',
      m: 'Náusea passageira é comum. Refeições pequenas e frequentes costumam ajudar.',
      n: 'Náusea passageira é comum. Refeições pequenas e frequentes costumam ajudar.',
    ),
    _Entrada(
      categoria: CategoriaDica.motivacional,
      f: 'Comparar sua trajetória com a de alguém é injusto — cada corpo responde no seu tempo.',
      m: 'Comparar sua trajetória com a de alguém é injusto — cada corpo responde no seu tempo.',
      n: 'Comparar sua trajetória com a de alguém é injusto — cada corpo responde no seu tempo.',
    ),
    _Entrada(
      categoria: CategoriaDica.tecnica,
      f: 'Aeróbico moderado + treino de força protege sua massa magra melhor que só correr.',
      m: 'Aeróbico moderado + treino de força protege sua massa magra melhor que só correr.',
      n: 'Aeróbico moderado + treino de força protege sua massa magra melhor que só correr.',
    ),
    _Entrada(
      categoria: CategoriaDica.celebracao,
      f: 'Você chegou até aqui. Isso já é sinal de que está no caminho.',
      m: 'Você chegou até aqui. Isso já é sinal de que está no caminho.',
      n: 'Você chegou até aqui. Isso já é sinal de que está no caminho.',
    ),
    _Entrada(
      categoria: CategoriaDica.cuidado,
      f: 'Balança oscila com hormônios, sono e sal. Confie na tendência, não no ponto.',
      m: 'Balança oscila com hormônios, sono e sal. Confie na tendência, não no ponto.',
      n: 'Balança oscila com hormônios, sono e sal. Confie na tendência, não no ponto.',
    ),
    _Entrada(
      categoria: CategoriaDica.hidratacao,
      f: 'Se a urina está bem clara, você está bem hidratada. Um termômetro simples e honesto.',
      m: 'Se a urina está bem clara, você está bem hidratado. Um termômetro simples e honesto.',
      n: 'Se a urina está bem clara, a hidratação está em dia. Um termômetro simples e honesto.',
    ),
    _Entrada(
      categoria: CategoriaDica.motivacional,
      f: 'Registrar hoje é um presente que você dá pra si mesma daqui a três meses.',
      m: 'Registrar hoje é um presente que você dá pra si mesmo daqui a três meses.',
      n: 'Registrar hoje é um presente que você dá pra si daqui a três meses.',
    ),
    _Entrada(
      categoria: CategoriaDica.tecnica,
      f: 'Se sentir cansaço fora do normal no treino, reduza — GLP-1 muda como o corpo produz energia.',
      m: 'Se sentir cansaço fora do normal no treino, reduza — GLP-1 muda como o corpo produz energia.',
      n: 'Se sentir cansaço fora do normal no treino, reduza — GLP-1 muda como o corpo produz energia.',
    ),
    _Entrada(
      categoria: CategoriaDica.cuidado,
      f: 'Não existe recaída — existe pausa. Volte quando puder, sem culpa.',
      m: 'Não existe recaída — existe pausa. Volte quando puder, sem culpa.',
      n: 'Não existe recaída — existe pausa. Volte quando puder, sem culpa.',
    ),
    _Entrada(
      categoria: CategoriaDica.celebracao,
      f: 'Consistência de 7 dias vale mais que perfeição de 1. Você está construindo hábito.',
      m: 'Consistência de 7 dias vale mais que perfeição de 1. Você está construindo hábito.',
      n: 'Consistência de 7 dias vale mais que perfeição de 1. Você está construindo hábito.',
    ),
  ];
}

class _Entrada {
  final CategoriaDica categoria;
  final String f;
  final String m;
  final String n;
  const _Entrada({
    required this.categoria,
    required this.f,
    required this.m,
    required this.n,
  });
}
