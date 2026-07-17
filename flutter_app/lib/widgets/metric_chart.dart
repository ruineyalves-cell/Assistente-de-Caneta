import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../utils/constants.dart';

class MetricChart extends StatelessWidget {
  final List<int> scores; // últimos 7-28 dias
  final String title;
  final String? subtitle;

  /// Janela da média móvel — PRD §5. 7 dias é o padrão semanal.
  static const int _janelaMediaMovel = 7;

  const MetricChart({
    super.key,
    required this.scores,
    required this.title,
    this.subtitle,
  });

  /// Média móvel simples com janela [_janelaMediaMovel]: para cada ponto,
  /// média dos últimos N valores (ou dos disponíveis até o ponto, no
  /// começo da série). Mantém o mesmo tamanho da entrada.
  List<double> _mediaMovel(List<int> valores) {
    final saida = <double>[];
    for (var i = 0; i < valores.length; i++) {
      final inicio = (i - _janelaMediaMovel + 1).clamp(0, valores.length);
      final janela = valores.sublist(inicio, i + 1);
      final soma = janela.fold<int>(0, (acc, v) => acc + v);
      saida.add(soma / janela.length);
    }
    return saida;
  }

  @override
  Widget build(BuildContext context) {
    if (scores.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 40),
              const Text(
                'Nenhum dado disponível',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    // Média móvel — corrige o PRD §5 (a linha "crua" oscilava demais).
    final suave = _mediaMovel(scores);
    final spots = <FlSpot>[
      for (var i = 0; i < suave.length; i++) FlSpot(i.toDouble(), suave[i]),
    ];

    final maxY = 100.0;
    final minY = 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 20,
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: scores.length <= 10,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            'D${(value + 1).toInt()}',
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: AppColors.azulClinico,
                      barWidth: 2,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 4,
                            color: AppColors.azulClinico,
                            strokeWidth: 2,
                            strokeColor: Colors.white,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppColors.azulClinico.withValues(alpha: 0.1),
                      ),
                    ),
                  ],
                  minY: minY,
                  maxY: maxY,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Mínimo: ${scores.reduce((a, b) => a < b ? a : b)}%',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                Text(
                  'Máximo: ${scores.reduce((a, b) => a > b ? a : b)}%',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                Text(
                  'Média: ${(scores.reduce((a, b) => a + b) / scores.length).toStringAsFixed(1)}%',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Linha suavizada — média móvel de 7 dias.',
              style: TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
