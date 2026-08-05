import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../utils/theme.dart';

/// Bloco 1 — "Resumo de hoje" (hero de anéis).
///
/// READ-ONLY por design: espelha, num relance, os MESMOS dados que os
/// cards de eixo logo abaixo já mostram (proteína, água, score, peso,
/// streak, sintomas). Não registra nada e não abre sheets — as ações
/// continuam nos cards grandes, evitando redundância e mantendo um único
/// caminho de escrita (LogsProvider). Não faz chamada de rede, não lê
/// perfil premium: recebe tudo pronto do `DashboardPage.build`.
///
/// Os anéis são desenhados com `CustomPainter` (sem dependência nova):
///   • anel externo  = Proteína (cor do eixo Refeição)
///   • anel interno  = Água (cor do eixo Água)
///   • centro        = Score de conformidade do dia (proteína+água+registro)
class HojeHeroCard extends StatelessWidget {
  final double proteinaConsumidaG;
  final double? proteinaMetaG;
  final double aguaConsumidaMl;
  final double? aguaMetaMl;
  final int score;
  final double? pesoAtualKg;
  final double? pesoDeltaKg;
  final int streak;
  final int sintomasHoje;

  const HojeHeroCard({
    super.key,
    required this.proteinaConsumidaG,
    required this.proteinaMetaG,
    required this.aguaConsumidaMl,
    required this.aguaMetaMl,
    required this.score,
    required this.pesoAtualKg,
    required this.pesoDeltaKg,
    required this.streak,
    required this.sintomasHoje,
  });

  double _pct(double consumido, double? meta) {
    if (meta == null || meta <= 0) return 0;
    return (consumido / meta).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ehDark = Theme.of(context).brightness == Brightness.dark;

    final protPct = _pct(proteinaConsumidaG, proteinaMetaG);
    final aguaPct = _pct(aguaConsumidaMl, aguaMetaMl);

    // Rótulo de água: acima da meta vira "meta batida", em vez de exibir
    // porcentagens gigantes (ex.: 226%).
    final aguaL = (aguaConsumidaMl / 1000).toStringAsFixed(1).replaceAll('.', ',');
    final String aguaSub;
    if (aguaMetaMl == null || aguaMetaMl! <= 0) {
      aguaSub = '$aguaL L';
    } else if (aguaConsumidaMl >= aguaMetaMl!) {
      aguaSub = 'meta batida · $aguaL L';
    } else {
      final pct = (aguaConsumidaMl / aguaMetaMl! * 100).round();
      aguaSub = '$pct% · $aguaL L';
    }

    final protSub = proteinaMetaG == null
        ? '${_num(proteinaConsumidaG)} g'
        : '${_num(proteinaConsumidaG)} / ${_num(proteinaMetaG!)} g';

    final String pesoSub;
    if (pesoAtualKg == null) {
      pesoSub = 'Sem registro';
    } else if (pesoDeltaKg == null) {
      pesoSub = '${_num(pesoAtualKg!)} kg';
    } else {
      final d = pesoDeltaKg!;
      final seta = d < 0 ? '▼' : (d > 0 ? '▲' : '·');
      pesoSub = '${_num(pesoAtualKg!)} kg · $seta${_num(d.abs())}';
    }

    final sintSub = sintomasHoje == 0
        ? 'Sintomas hoje: nenhum'
        : sintomasHoje == 1
            ? 'Sintomas hoje: 1'
            : 'Sintomas hoje: $sintomasHoje';

    return Container(
      padding: const EdgeInsets.all(RecorpoSpacing.md),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(RecorpoSpacing.radiusLg),
        border: Border.all(
          color: scheme.onSurface.withValues(alpha: ehDark ? 0.10 : 0.08),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Anéis + Score no centro.
          HojeRingsView(
            size: 118,
            protPct: protPct,
            aguaPct: aguaPct,
            score: score,
            protColor: RecorpoColors.eixoRefeicao,
            aguaColor: RecorpoColors.eixoAgua,
            trackColor:
                scheme.onSurface.withValues(alpha: ehDark ? 0.12 : 0.08),
            scoreColor: RecorpoColors.confirma,
            labelColor: scheme.onSurface.withValues(alpha: 0.6),
          ),
          const SizedBox(width: RecorpoSpacing.md),
          // Stats.
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _StatLinha(
                  eixo: EixoRecorpo.refeicao,
                  titulo: 'Proteína',
                  valor: protSub,
                ),
                const SizedBox(height: RecorpoSpacing.sm),
                _StatLinha(
                  eixo: EixoRecorpo.agua,
                  titulo: 'Água',
                  valor: aguaSub,
                ),
                const SizedBox(height: RecorpoSpacing.sm),
                _StatLinha(
                  eixo: EixoRecorpo.peso,
                  titulo: 'Peso',
                  valor: pesoSub,
                ),
                const SizedBox(height: RecorpoSpacing.sm),
                _StatLinha(
                  eixo: EixoRecorpo.streak,
                  titulo: 'Streak $streak',
                  valor: sintSub,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _num(double v) {
    final s = v == v.roundToDouble()
        ? v.toStringAsFixed(0)
        : v.toStringAsFixed(1);
    return s.replaceAll('.', ',');
  }
}

class _StatLinha extends StatelessWidget {
  final EixoRecorpo eixo;
  final String titulo;
  final String valor;

  const _StatLinha({
    required this.eixo,
    required this.titulo,
    required this.valor,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: eixo.cor.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(RecorpoSpacing.sm),
          ),
          child: Icon(eixo.icone, size: 16, color: eixo.cor),
        ),
        const SizedBox(width: RecorpoSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titulo,
                style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface),
              ),
              Text(
                valor,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 11.5,
                    color: scheme.onSurface.withValues(alpha: 0.65)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Anéis concêntricos (Proteína externo, Água interno) com o Score no
/// centro. Recebe cores EXPLÍCITAS (não lê Theme) de propósito: assim o
/// mesmo widget serve para o card in-app E para ser renderizado off-screen
/// como bitmap do widget de tela inicial (HomeWidget.renderFlutterWidget),
/// onde não há um Theme herdado.
class HojeRingsView extends StatelessWidget {
  final double size;
  final double protPct;
  final double aguaPct;
  final int score;
  final Color protColor;
  final Color aguaColor;
  final Color trackColor;
  final Color scoreColor;
  final Color labelColor;

  const HojeRingsView({
    super.key,
    required this.size,
    required this.protPct,
    required this.aguaPct,
    required this.score,
    required this.protColor,
    required this.aguaColor,
    required this.trackColor,
    required this.scoreColor,
    required this.labelColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Semantics(
        label: 'Score do dia $score por cento. '
            'Proteína ${(protPct * 100).round()} por cento da meta. '
            'Água ${(aguaPct * 100).round()} por cento da meta.',
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: Size(size, size),
              painter: _RingsPainter(
                protPct: protPct,
                aguaPct: aguaPct,
                protColor: protColor,
                aguaColor: aguaColor,
                trackColor: trackColor,
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Score',
                    style: TextStyle(
                        fontSize: size * 0.085, color: labelColor)),
                Text('$score%',
                    style: TextStyle(
                        fontSize: size * 0.205,
                        fontWeight: FontWeight.w800,
                        color: scoreColor)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Desenha dois anéis concêntricos (proteína externo, água interno) com
/// trilha de fundo. Ângulo inicial no topo (-90°), sentido horário.
class _RingsPainter extends CustomPainter {
  final double protPct; // 0..1
  final double aguaPct; // 0..1
  final Color protColor;
  final Color aguaColor;
  final Color trackColor;

  _RingsPainter({
    required this.protPct,
    required this.aguaPct,
    required this.protColor,
    required this.aguaColor,
    required this.trackColor,
  });

  static const double _stroke = 11;
  static const double _start = -math.pi / 2;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final rOuter = size.width / 2 - _stroke / 2;
    final rInner = rOuter - _stroke - 5;

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke
      ..strokeCap = StrokeCap.round
      ..color = trackColor;

    _arco(canvas, center, rOuter, 0, 1, track);
    _arco(canvas, center, rInner, 0, 1, track);

    final prot = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke
      ..strokeCap = StrokeCap.round
      ..color = protColor;
    final agua = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke
      ..strokeCap = StrokeCap.round
      ..color = aguaColor;

    if (protPct > 0) _arco(canvas, center, rOuter, _start, protPct, prot);
    if (aguaPct > 0) _arco(canvas, center, rInner, _start, aguaPct, agua);
  }

  void _arco(Canvas canvas, Offset c, double r, double start, double pct,
      Paint paint) {
    final rect = Rect.fromCircle(center: c, radius: r);
    // Trilha completa quando start=0 e pct=1 desenha o círculo inteiro.
    final sweep = (start == 0 && pct >= 1) ? 2 * math.pi : pct * 2 * math.pi;
    canvas.drawArc(rect, start == 0 ? _start : start, sweep, false, paint);
  }

  @override
  bool shouldRepaint(_RingsPainter old) =>
      old.protPct != protPct ||
      old.aguaPct != aguaPct ||
      old.protColor != protColor ||
      old.aguaColor != aguaColor ||
      old.trackColor != trackColor;
}
