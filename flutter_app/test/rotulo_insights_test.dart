import 'package:flutter_test/flutter_test.dart';
import 'package:assistente_caneta/services/rotulo_insights.dart';

void main() {
  group('gerarInsightsRotulo — faixas determinísticas', () {
    test('rótulo pobre/vazio → nenhuma nota', () {
      expect(gerarInsightsRotulo({}), isEmpty);
      expect(
        gerarInsightsRotulo({
          'proteinaG': 1,
          'fibraG': 0.5,
          'sodioMg': 50,
          'gordurasSaturadasG': 0.5,
        }),
        isEmpty,
      );
    });

    test('proteína ≥ 8 g → nota positiva (ABESO)', () {
      final n = gerarInsightsRotulo({'proteinaG': 10});
      expect(n, hasLength(1));
      expect(n.first.atencao, isFalse);
      expect(n.first.fonte, contains('ABESO'));
    });

    test('fibra ≥ 3 g → nota positiva (bula/fibra)', () {
      final n = gerarInsightsRotulo({'fibraG': 3});
      expect(n, hasLength(1));
      expect(n.first.atencao, isFalse);
      expect(n.first.texto.toLowerCase(), contains('fibra'));
    });

    test('sódio ≥ 400 mg → ponto de ATENÇÃO (OMS + bula)', () {
      final n = gerarInsightsRotulo({'sodioMg': 400});
      expect(n, hasLength(1));
      expect(n.first.atencao, isTrue);
      expect(n.first.fonte, contains('OMS'));
    });

    test('gordura saturada ≥ 5 g → ponto de ATENÇÃO', () {
      final n = gerarInsightsRotulo({'gordurasSaturadasG': 5});
      expect(n, hasLength(1));
      expect(n.first.atencao, isTrue);
    });

    test('logo abaixo das faixas → nada dispara', () {
      expect(gerarInsightsRotulo({'proteinaG': 7.9}), isEmpty);
      expect(gerarInsightsRotulo({'fibraG': 2.9}), isEmpty);
      expect(gerarInsightsRotulo({'sodioMg': 399}), isEmpty);
      expect(gerarInsightsRotulo({'gordurasSaturadasG': 4.9}), isEmpty);
    });

    test('rótulo "cheio" → todas as 4 notas', () {
      final n = gerarInsightsRotulo({
        'proteinaG': 12,
        'fibraG': 5,
        'sodioMg': 600,
        'gordurasSaturadasG': 8,
      });
      expect(n, hasLength(4));
      // Toda nota tem fonte pública citada (nunca sem fonte).
      expect(n.every((x) => x.fonte.trim().isNotEmpty), isTrue);
    });

    test('conteúdo é educativo — nunca imperativo "coma/evite"', () {
      final n = gerarInsightsRotulo({
        'proteinaG': 12,
        'fibraG': 5,
        'sodioMg': 600,
        'gordurasSaturadasG': 8,
      });
      final proibidas = ['coma ', 'evite', 'não coma', 'pare de', 'deve comer'];
      for (final nota in n) {
        final t = nota.texto.toLowerCase();
        for (final p in proibidas) {
          expect(t.contains(p), isFalse, reason: 'nota imperativa: "${nota.texto}"');
        }
      }
    });
  });
}
