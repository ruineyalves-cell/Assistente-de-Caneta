import 'package:flutter_test/flutter_test.dart';
import 'package:assistente_caneta/models/index.dart';
import 'package:assistente_caneta/screens/home/home_peso_sintomas_row.dart';

void main() {
  group('derivarPeso', () {
    test('sem logs → atual e delta nulos', () {
      final r = derivarPeso([]);
      expect(r.atual, isNull);
      expect(r.delta, isNull);
    });

    test('um único peso → sem delta', () {
      final r = derivarPeso([DailyLog(data: DateTime(2026, 8, 1), pesoKg: 90.0)]);
      expect(r.atual, 90.0);
      expect(r.delta, isNull);
    });

    test('dois pesos (lista desc) → delta = atual - anterior', () {
      final r = derivarPeso([
        DailyLog(data: DateTime(2026, 8, 2), pesoKg: 89.0), // topo = mais recente
        DailyLog(data: DateTime(2026, 8, 1), pesoKg: 90.5),
      ]);
      expect(r.atual, 89.0);
      expect(r.delta, closeTo(-1.5, 1e-9));
    });

    test('ignora logs sem peso ao achar atual/anterior', () {
      final r = derivarPeso([
        DailyLog(data: DateTime(2026, 8, 3)), // sem peso
        DailyLog(data: DateTime(2026, 8, 2), pesoKg: 88.0),
        DailyLog(data: DateTime(2026, 8, 1), pesoKg: 90.0),
      ]);
      expect(r.atual, 88.0);
      expect(r.delta, closeTo(-2.0, 1e-9));
    });
  });

  group('derivarSintomasHoje', () {
    final hoje = DateTime(2026, 8, 1, 10);

    test('sem logs → 0', () {
      expect(derivarSintomasHoje([], agora: hoje), 0);
    });

    test('conta os sintomas do JSON de um log de hoje', () {
      final logs = [
        DailyLog(
          data: DateTime(2026, 8, 1, 9),
          efeitosColaterais: '{"sintomas":[{"nome":"nausea"},{"nome":"refluxo"}]}',
        ),
      ];
      expect(derivarSintomasHoje(logs, agora: hoje), 2);
    });

    test('ignora log de outro dia', () {
      final logs = [
        DailyLog(
          data: DateTime(2026, 7, 31, 9),
          efeitosColaterais: '{"sintomas":[{"nome":"nausea"}]}',
        ),
      ];
      expect(derivarSintomasHoje(logs, agora: hoje), 0);
    });

    test('efeitos vazio ou nulo → 0', () {
      final logs = [
        DailyLog(data: DateTime(2026, 8, 1, 9), efeitosColaterais: ''),
        DailyLog(data: DateTime(2026, 8, 1, 9)),
      ];
      expect(derivarSintomasHoje(logs, agora: hoje), 0);
    });

    test('JSON inválido → ignora (não crasha)', () {
      final logs = [
        DailyLog(data: DateTime(2026, 8, 1, 9), efeitosColaterais: 'não é json'),
      ];
      expect(derivarSintomasHoje(logs, agora: hoje), 0);
    });

    test('soma sintomas de múltiplos logs de hoje', () {
      final logs = [
        DailyLog(
          data: DateTime(2026, 8, 1, 9),
          efeitosColaterais: '{"sintomas":[{"nome":"a"}]}',
        ),
        DailyLog(
          data: DateTime(2026, 8, 1, 20),
          efeitosColaterais: '{"sintomas":[{"nome":"b"},{"nome":"c"}]}',
        ),
      ];
      expect(derivarSintomasHoje(logs, agora: hoje), 3);
    });
  });
}
