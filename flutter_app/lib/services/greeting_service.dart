import '../models/patient_profile.dart';

/// Saudação humanizada — combina hora do dia + primeiro nome +
/// concordância com a identidade de gênero para gerar uma frase
/// acolhedora que muda ao longo do dia.
class GreetingService {
  const GreetingService();

  /// Retorna o cumprimento e uma frase de acolhimento.
  ///
  /// - [nomeCompleto]: `AuthService.nome` (usa o primeiro nome apenas).
  /// - [genero]: identidade guardada em `shared_preferences` do Lote 5;
  ///   `null` ou "prefiro não informar" → escolhe a variante neutra.
  /// - [agora]: injetado para facilitar teste.
  Saudacao gerar({
    String? nomeCompleto,
    IdentidadeGenero? genero,
    DateTime? agora,
  }) {
    final n = agora ?? DateTime.now();
    final hora = n.hour;
    final primeiroNome = (nomeCompleto ?? '').trim().split(' ').first;
    final cumprimento = _cumprimentoPor(hora);
    final complemento = _complementoAcolhedor(hora, genero);
    return Saudacao(
      titulo: primeiroNome.isEmpty
          ? '$cumprimento!'
          : '$cumprimento, $primeiroNome!',
      subtitulo: complemento,
    );
  }

  String _cumprimentoPor(int hora) {
    if (hora < 5) return 'Boa madrugada';
    if (hora < 12) return 'Bom dia';
    if (hora < 18) return 'Boa tarde';
    return 'Boa noite';
  }

  /// Complemento com concordância de gênero embutida. Cada tupla é
  /// (feminino, masculino, neutro). A escolha entre as variantes usa
  /// o [genero] informado; para hora, sorteia entre 2-3 opções por
  /// faixa para dar sensação de variedade sem virar loteria.
  String _complementoAcolhedor(int hora, IdentidadeGenero? genero) {
    final variantes = _variantesPorFaixa(hora);
    final indice = hora % variantes.length; // determinístico por hora
    final tupla = variantes[indice];
    return _escolhePorGenero(tupla, genero);
  }

  static const List<_Tupla> _manhaCedo = [
    _Tupla(
      f: 'Preparada pra hoje? Um pequeno registro agora deixa sua evolução mais clara amanhã.',
      m: 'Preparado pra hoje? Um pequeno registro agora deixa sua evolução mais clara amanhã.',
      n: 'Prepare-se pra hoje. Um pequeno registro agora deixa sua evolução mais clara amanhã.',
    ),
    _Tupla(
      f: 'Cada manhã é um recomeço. Estamos juntas nessa.',
      m: 'Cada manhã é um recomeço. Estamos juntos nessa.',
      n: 'Cada manhã é um recomeço. Vamos juntos nessa.',
    ),
    _Tupla(
      f: 'Comece o dia devagar — a consistência vale mais que a intensidade.',
      m: 'Comece o dia devagar — a consistência vale mais que a intensidade.',
      n: 'Comece o dia devagar — a consistência vale mais que a intensidade.',
    ),
  ];

  static const List<_Tupla> _manha = [
    _Tupla(
      f: 'Pequenos passos hoje somam blindagem muscular pro mês inteiro.',
      m: 'Pequenos passos hoje somam blindagem muscular pro mês inteiro.',
      n: 'Pequenos passos hoje somam blindagem muscular pro mês inteiro.',
    ),
    _Tupla(
      f: 'Você não precisa acertar tudo — só continuar cuidando de si.',
      m: 'Você não precisa acertar tudo — só continuar cuidando de si.',
      n: 'Você não precisa acertar tudo — só continuar cuidando de si.',
    ),
    _Tupla(
      f: 'Como você está se sentindo hoje? Vamos aos poucos.',
      m: 'Como você está se sentindo hoje? Vamos aos poucos.',
      n: 'Como você está se sentindo hoje? Vamos aos poucos.',
    ),
  ];

  static const List<_Tupla> _tarde = [
    _Tupla(
      f: 'Metade do dia — que tal um check-in rápido com você mesma?',
      m: 'Metade do dia — que tal um check-in rápido com você mesmo?',
      n: 'Metade do dia — que tal um check-in rápido consigo?',
    ),
    _Tupla(
      f: 'Hidratação e proteína na tarde salvam o dia. Você já registrou?',
      m: 'Hidratação e proteína na tarde salvam o dia. Você já registrou?',
      n: 'Hidratação e proteína na tarde salvam o dia. Já registrou?',
    ),
    _Tupla(
      f: 'Você está mais perto da sua meta do que ontem. Continue.',
      m: 'Você está mais perto da sua meta do que ontem. Continue.',
      n: 'Você está mais perto da sua meta do que ontem. Continue.',
    ),
  ];

  static const List<_Tupla> _noite = [
    _Tupla(
      f: 'Fim de dia é um bom momento pra registrar e descansar tranquila.',
      m: 'Fim de dia é um bom momento pra registrar e descansar tranquilo.',
      n: 'Fim de dia é um bom momento pra registrar e descansar em paz.',
    ),
    _Tupla(
      f: 'O que você fez hoje já é suficiente. Amanhã tem mais.',
      m: 'O que você fez hoje já é suficiente. Amanhã tem mais.',
      n: 'O que você fez hoje já é suficiente. Amanhã tem mais.',
    ),
    _Tupla(
      f: 'Antes de dormir, um pequeno registro fecha o ciclo do dia.',
      m: 'Antes de dormir, um pequeno registro fecha o ciclo do dia.',
      n: 'Antes de dormir, um pequeno registro fecha o ciclo do dia.',
    ),
  ];

  List<_Tupla> _variantesPorFaixa(int hora) {
    if (hora < 5) return _manhaCedo;
    if (hora < 12) return _manha;
    if (hora < 18) return _tarde;
    return _noite;
  }

  String _escolhePorGenero(_Tupla t, IdentidadeGenero? g) {
    switch (g) {
      case IdentidadeGenero.mulher:
        return t.f;
      case IdentidadeGenero.homem:
        return t.m;
      case IdentidadeGenero.naoBinario:
      case IdentidadeGenero.prefiroNaoInformar:
      case null:
        return t.n;
    }
  }
}

class Saudacao {
  final String titulo;
  final String subtitulo;
  const Saudacao({required this.titulo, required this.subtitulo});
}

class _Tupla {
  final String f;
  final String m;
  final String n;
  const _Tupla({required this.f, required this.m, required this.n});
}
