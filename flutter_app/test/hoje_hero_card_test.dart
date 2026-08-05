import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:assistente_caneta/utils/theme.dart';
import 'package:assistente_caneta/widgets/hoje_hero_card.dart';

/// Bloco 1 — Resumo de hoje. Testa que o hero read-only renderiza e
/// formata os valores (pt-BR) sem estourar layout, em dark e light.
void main() {
  Widget _wrap(HojeHeroCard card, {Brightness brilho = Brightness.dark}) {
    return MaterialApp(
      theme: brilho == Brightness.dark ? RecorpoTheme.dark() : RecorpoTheme.light(),
      home: Scaffold(
        body: Center(
          child: SizedBox(width: 360, child: card),
        ),
      ),
    );
  }

  testWidgets('mostra Score, macros, peso com delta e streak', (tester) async {
    await tester.pumpWidget(_wrap(const HojeHeroCard(
      proteinaConsumidaG: 120,
      proteinaMetaG: 140,
      aguaConsumidaMl: 6500,
      aguaMetaMl: 2877,
      score: 100,
      pesoAtualKg: 82.2,
      pesoDeltaKg: -0.3,
      streak: 5,
      sintomasHoje: 5,
    )));

    expect(find.text('Score'), findsOneWidget);
    expect(find.text('100%'), findsOneWidget);
    expect(find.text('Proteína'), findsOneWidget);
    expect(find.text('120 / 140 g'), findsOneWidget);
    expect(find.text('Água'), findsOneWidget);
    // Água acima da meta → "meta batida", não porcentagem gigante.
    expect(find.text('meta batida · 6,5 L'), findsOneWidget);
    expect(find.text('Peso'), findsOneWidget);
    expect(find.text('82,2 kg · ▼0,3'), findsOneWidget);
    expect(find.text('Streak 5'), findsOneWidget);
    expect(find.text('Sintomas hoje: 5'), findsOneWidget);
  });

  testWidgets('água abaixo da meta mostra porcentagem', (tester) async {
    await tester.pumpWidget(_wrap(const HojeHeroCard(
      proteinaConsumidaG: 0,
      proteinaMetaG: 140,
      aguaConsumidaMl: 1400,
      aguaMetaMl: 2800,
      score: 42,
      pesoAtualKg: 90,
      pesoDeltaKg: null,
      streak: 0,
      sintomasHoje: 0,
    )));

    expect(find.text('50% · 1,4 L'), findsOneWidget);
    expect(find.text('90 kg'), findsOneWidget); // sem delta
    expect(find.text('Sintomas hoje: nenhum'), findsOneWidget);
    expect(find.text('42%'), findsOneWidget);
  });

  testWidgets('sem metas e sem peso não quebra', (tester) async {
    await tester.pumpWidget(_wrap(
      const HojeHeroCard(
        proteinaConsumidaG: 0,
        proteinaMetaG: null,
        aguaConsumidaMl: 0,
        aguaMetaMl: null,
        score: 0,
        pesoAtualKg: null,
        pesoDeltaKg: null,
        streak: 0,
        sintomasHoje: 0,
      ),
      brilho: Brightness.light,
    ));

    expect(find.text('Sem registro'), findsOneWidget);
    expect(find.text('0 g'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
