// Smoke test do MetricChart: confirma que o widget monta com dados e
// aparece o rótulo indicando que a linha é média móvel.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:assistente_caneta/widgets/metric_chart.dart';

void main() {
  testWidgets('MetricChart mostra rótulo de média móvel quando há dados',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: MetricChart(
              scores: [80, 82, 78, 85, 88, 90, 92, 89, 91],
              title: 'Últimos 9 dias',
            ),
          ),
        ),
      ),
    );

    expect(find.text('Últimos 9 dias'), findsOneWidget);
    expect(find.textContaining('média móvel'), findsOneWidget);
  });

  testWidgets('MetricChart com scores vazio mostra placeholder',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MetricChart(scores: [], title: 'Sem dados'),
        ),
      ),
    );
    expect(find.text('Nenhum dado disponível'), findsOneWidget);
  });
}
