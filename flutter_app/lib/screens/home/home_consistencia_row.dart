import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/logs_provider.dart';
import '../../widgets/streak_badge.dart';
import '../../widgets/score_card.dart';

/// Linha "Consistência" da Home (streak + score do dia).
///
/// ─────────────────────────────────────────────────────────────────────
/// PADRÃO DE REFERÊNCIA — Fase 3 (fatia piloto do refactor de performance)
/// ─────────────────────────────────────────────────────────────────────
/// Antes, streak e score eram construídos dentro do `Consumer<LogsProvider>`
/// gigante da DashboardPage → reconstruíam a CADA `notifyListeners()` (ex.:
/// ao encher a barra de água), mesmo sem mudar de valor. Três técnicas
/// combinadas eliminam esse rebuild desnecessário:
///
///  1. **Widget `const`** — como esta linha é `const HomeConsistenciaRow()`,
///     quando o pai (dashboard) reconstrói, o Flutter reaproveita a MESMA
///     instância e NÃO desce reconstruindo a subárvore.
///  2. **`Selector<LogsProvider, int>`** — cada card só reconstrói quando o
///     SEU inteiro muda (streak OU score), ignorando os demais campos do
///     provider.
///  3. **`RepaintBoundary`** — isola a camada de pintura, então repintar um
///     card não força repintura do resto do hero.
///
/// Replicar este mesmo padrão nos outros cards (água, peso, sintomas…) é o
/// restante da Fase 3.
class HomeConsistenciaRow extends StatelessWidget {
  const HomeConsistenciaRow({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(child: _StreakSelector()),
        SizedBox(width: 12),
        Expanded(child: _ScoreSelector()),
      ],
    );
  }
}

class _StreakSelector extends StatelessWidget {
  const _StreakSelector();

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Selector<LogsProvider, int>(
        selector: (_, p) => p.streak,
        builder: (_, streak, __) => StreakBadge(days: streak, title: 'Streak'),
      ),
    );
  }
}

class _ScoreSelector extends StatelessWidget {
  const _ScoreSelector();

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Selector<LogsProvider, int>(
        selector: (_, p) => p.scoreToday,
        builder: (_, score, __) => ScoreCard(score: score, label: 'Score hoje'),
      ),
    );
  }
}
