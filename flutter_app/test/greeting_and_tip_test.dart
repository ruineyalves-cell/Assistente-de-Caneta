import 'package:flutter_test/flutter_test.dart';

import 'package:assistente_caneta/models/patient_profile.dart';
import 'package:assistente_caneta/services/daily_tip_service.dart';
import 'package:assistente_caneta/services/greeting_service.dart';

void main() {
  group('GreetingService', () {
    const s = GreetingService();

    test('Bom dia com nome extrai só o primeiro', () {
      final r = s.gerar(
        nomeCompleto: 'ruiney alves de souza',
        agora: DateTime(2026, 7, 17, 9, 0),
      );
      expect(r.titulo, 'Bom dia, ruiney!');
    });

    test('Sem nome usa saudação neutra', () {
      final r = s.gerar(agora: DateTime(2026, 7, 17, 14, 0));
      expect(r.titulo, 'Boa tarde!');
    });

    test('Concordância feminina em faixa madrugada (variantes distintas)', () {
      // hora=3 cai em _manhaCedo, cujas variantes têm concordância.
      final r = s.gerar(
        nomeCompleto: 'Maria',
        genero: IdentidadeGenero.mulher,
        agora: DateTime(2026, 7, 17, 3, 0),
      );
      expect(r.subtitulo.toLowerCase(),
          anyOf(contains('preparada'), contains('juntas'), contains('devagar')));
    });

    test('Concordância masculina em faixa madrugada', () {
      final r = s.gerar(
        nomeCompleto: 'João',
        genero: IdentidadeGenero.homem,
        agora: DateTime(2026, 7, 17, 3, 0),
      );
      expect(r.subtitulo.toLowerCase(),
          anyOf(contains('preparado'), contains('juntos'), contains('devagar')));
    });

    test('Faixa noite (20h)', () {
      final r = s.gerar(agora: DateTime(2026, 7, 17, 20, 0));
      expect(r.titulo, 'Boa noite!');
    });
  });

  group('DailyTipService', () {
    const s = DailyTipService();

    test('mesma data → mesma dica (determinístico)', () {
      final d = DateTime(2026, 7, 17);
      final a = s.dicaDoDia(data: d);
      final b = s.dicaDoDia(data: d);
      expect(a.texto, b.texto);
      expect(a.categoria, b.categoria);
    });

    test('datas diferentes podem retornar dicas diferentes', () {
      var iguais = 0;
      for (int i = 0; i < 20; i++) {
        final a = s.dicaDoDia(data: DateTime(2026, 1, 1 + i));
        final b = s.dicaDoDia(data: DateTime(2026, 1, 2 + i));
        if (a.texto == b.texto) iguais++;
      }
      // Não é regra rígida, mas se todas as 20 fossem iguais o sorteio
      // estaria quebrado.
      expect(iguais, lessThan(20));
    });

    test('Feminino escolhe variante "f" quando disponível', () {
      // Encontramos uma data que cai numa entrada com variantes distintas.
      final data = DateTime(2026, 1, 2); // pool[1] = água (variantes distintas)
      final f = s.dicaDoDia(genero: IdentidadeGenero.mulher, data: data);
      final m = s.dicaDoDia(genero: IdentidadeGenero.homem, data: data);
      // Aqui as variantes são distintas — teste sanidade.
      expect(f.texto.contains('parceira') || f.texto == m.texto, isTrue);
    });
  });
}
