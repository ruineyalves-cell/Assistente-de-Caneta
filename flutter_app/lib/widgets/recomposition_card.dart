import 'package:flutter/material.dart';
import '../utils/constants.dart';

/// Card de "Evolução da Composição" — semântica de recomposição corporal
/// do PRD: peso pode subir OU descer (±), gordura idealmente cai (↓) e
/// massa magra idealmente sobe (↑).
///
/// Os campos de gordura e massa magra ainda não vêm do backend (não há
/// coleta de bioimpedância neste lote); exibimos "—" quando não há dado.
/// Peso vem do último `DailyLog` disponível (via [pesoAtualKg]) — quando
/// o LogsProvider tiver histórico, computamos o delta.
class RecompositionCard extends StatelessWidget {
  /// Peso atual em kg (último log ou perfil). Null → sem dado.
  final double? pesoAtualKg;

  /// Peso da penúltima medição — usado só para calcular o delta ±.
  final double? pesoAnteriorKg;

  const RecompositionCard({
    super.key,
    this.pesoAtualKg,
    this.pesoAnteriorKg,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.fitness_center,
                    color: AppColors.azulClinico, size: 20),
                const SizedBox(width: 8),
                Text('Evolução da Composição',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _Metric(
                    label: 'Peso',
                    valor: pesoAtualKg != null
                        ? '${pesoAtualKg!.toStringAsFixed(1)} kg'
                        : '—',
                    delta: _pesoDelta,
                    corDelta: AppColors.azulClinico, // ± neutro
                    iconeDelta: _pesoIcone,
                  ),
                ),
                _divisor(),
                Expanded(
                  child: _Metric(
                    label: 'Gordura',
                    valor: '—',
                    delta: 'meta ↓',
                    corDelta: AppColors.verdeConfirma,
                    iconeDelta: Icons.trending_down,
                  ),
                ),
                _divisor(),
                Expanded(
                  child: _Metric(
                    label: 'Massa magra',
                    valor: '—',
                    delta: 'meta ↑',
                    corDelta: AppColors.verdeConfirma,
                    iconeDelta: Icons.trending_up,
                  ),
                ),
              ],
            ),
            if (pesoAtualKg == null) ...[
              const SizedBox(height: 12),
              Text(
                'Registre seu peso em "Registrar de hoje" para começar a acompanhar sua composição.',
                style: TextStyle(
                    fontSize: 11, color: Colors.grey.shade600, height: 1.35),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _divisor() => Container(
        width: 1,
        height: 44,
        color: Colors.grey.withValues(alpha: 0.25),
        margin: const EdgeInsets.symmetric(horizontal: 6),
      );

  String? get _pesoDelta {
    if (pesoAtualKg == null || pesoAnteriorKg == null) return null;
    final d = pesoAtualKg! - pesoAnteriorKg!;
    if (d.abs() < 0.05) return '= 0.0';
    final sinal = d > 0 ? '+' : '';
    return '$sinal${d.toStringAsFixed(1)} kg';
  }

  IconData get _pesoIcone {
    if (pesoAtualKg == null || pesoAnteriorKg == null) return Icons.swap_vert;
    final d = pesoAtualKg! - pesoAnteriorKg!;
    if (d.abs() < 0.05) return Icons.remove;
    return d > 0 ? Icons.arrow_upward : Icons.arrow_downward;
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String valor;
  final String? delta;
  final Color corDelta;
  final IconData iconeDelta;

  const _Metric({
    required this.label,
    required this.valor,
    required this.delta,
    required this.corDelta,
    required this.iconeDelta,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label,
            style: const TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(valor,
            style:
                const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        if (delta != null)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(iconeDelta, size: 12, color: corDelta),
              const SizedBox(width: 2),
              Flexible(
                child: Text(
                  delta!,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, color: corDelta),
                ),
              ),
            ],
          ),
      ],
    );
  }
}
