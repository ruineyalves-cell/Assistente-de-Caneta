import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../utils/theme.dart';

/// Ícone animado por eixo — estilo "Aurora" (glyph branco vetorial + glow),
/// desenhado sobre o card com gradiente do eixo. Substitui o emoji do
/// antigo `EixoIlustracao` na grade da Home.
///
/// Micro-animações discretas (Fase 4):
///  - Água: onda d'água escorrendo dentro da gota.
///  - Peso: agulha da balança varrendo, com brilho ao "bater" nos cantos.
///  - Sintomas: coração pulsando (batida dupla, sutil).
///  - Refeição/Registro IA: faísca de IA piscando discretamente.
///
/// Respeita o "reduzir animações" do sistema (acessibilidade + bateria):
/// nesse caso congela num quadro de descanso. Cada ícone fica isolado em
/// RepaintBoundary, então só ele repinta — não o card inteiro.
class EixoIconeAnimado extends StatefulWidget {
  final EixoRecorpo eixo;
  final double size;

  const EixoIconeAnimado({super.key, required this.eixo, this.size = 130});

  @override
  State<EixoIconeAnimado> createState() => _EixoIconeAnimadoState();
}

class _EixoIconeAnimadoState extends State<EixoIconeAnimado>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  Duration get _periodo {
    switch (widget.eixo) {
      case EixoRecorpo.agua:
        return const Duration(milliseconds: 3600);
      case EixoRecorpo.peso:
        return const Duration(milliseconds: 4200);
      case EixoRecorpo.sintomas:
        return const Duration(milliseconds: 2200);
      case EixoRecorpo.refeicao:
        return const Duration(milliseconds: 2600);
      case EixoRecorpo.streak:
      case EixoRecorpo.movimento:
      case EixoRecorpo.primary:
        return const Duration(milliseconds: 3000);
    }
  }

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: _periodo);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // MediaQuery só está disponível aqui (não no initState).
    final reduz = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduz) {
      _c.stop();
      _c.value = 0.12; // quadro de descanso levemente "vivo"
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: AnimatedBuilder(
          animation: _c,
          builder: (_, __) => CustomPaint(
            painter: _EixoIconePainter(eixo: widget.eixo, t: _c.value),
          ),
        ),
      ),
    );
  }
}

class _EixoIconePainter extends CustomPainter {
  final EixoRecorpo eixo;
  final double t; // 0..1

  _EixoIconePainter({required this.eixo, required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Glow branco radial (herdado do EixoIlustracao antigo).
    final glow = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withValues(alpha: 0.30),
          Colors.white.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: size.width / 2));
    canvas.drawCircle(center, size.width / 2, glow);

    // Glyph desenhado num espaço 24×24, escalado pra ~52% do box e centrado.
    final glyphSize = size.width * 0.52;
    canvas.save();
    canvas.translate(center.dx - glyphSize / 2, center.dy - glyphSize / 2);
    canvas.scale(glyphSize / 24);
    switch (eixo) {
      case EixoRecorpo.agua:
        _agua(canvas);
        break;
      case EixoRecorpo.peso:
        _peso(canvas);
        break;
      case EixoRecorpo.sintomas:
        _sintomas(canvas);
        break;
      case EixoRecorpo.refeicao:
        _registro(canvas);
        break;
      case EixoRecorpo.streak:
      case EixoRecorpo.movimento:
      case EixoRecorpo.primary:
        _movimento(canvas);
        break;
    }
    canvas.restore();
  }

  Paint get _fill => Paint()
    ..color = Colors.white
    ..style = PaintingStyle.fill
    ..isAntiAlias = true;

  Paint _stroke([double w = 1.6, double alpha = 0.95]) => Paint()
    ..color = Colors.white.withValues(alpha: alpha)
    ..style = PaintingStyle.stroke
    ..strokeWidth = w
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..isAntiAlias = true;

  // ── Água: gota (teardrop correta) com brilho subindo por dentro ─────────
  void _agua(Canvas canvas) {
    final drop = _gotaPath();

    // Corpo da gota — "vidro fosco".
    canvas.drawPath(
      drop,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.30)
        ..isAntiAlias = true,
    );

    // Brilho que sobe de baixo pra cima DENTRO da gota (luz escorrendo).
    // op = sin(t·π): nasce embaixo, brilha no meio, some no topo → loop suave.
    canvas.save();
    canvas.clipPath(drop);
    final yBrilho = 20.0 - t * 16.0;
    final op = math.sin(t * math.pi);
    canvas.drawCircle(
      Offset(12, yBrilho),
      3.6,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.85 * op)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.2),
    );
    canvas.restore();

    // Contorno nítido.
    canvas.drawPath(drop, _stroke(1.5, 0.95));
  }

  /// Gota (teardrop): círculo na base + topo pontudo, unidos por boolean
  /// union (sem depender de winding/arc, que antes deixava a gota torta).
  Path _gotaPath() {
    final circ = Path()
      ..addOval(Rect.fromCircle(center: const Offset(12, 14.5), radius: 6.0));
    final topo = Path()
      ..moveTo(12, 2.6)
      ..quadraticBezierTo(8.6, 8, 7.3, 12.8)
      ..lineTo(16.7, 12.8)
      ..quadraticBezierTo(15.4, 8, 12, 2.6)
      ..close();
    return Path.combine(PathOperation.union, circ, topo);
  }

  // ── Peso: balança com agulha varrendo + brilho nos extremos ─────────────
  void _peso(Canvas canvas) {
    final corpo = RRect.fromRectAndRadius(
        const Rect.fromLTWH(4, 5, 16, 14), const Radius.circular(3.5));
    canvas.drawRRect(corpo, _stroke(1.6, 0.92));

    const pivo = Offset(12, 15.5);
    canvas.drawArc(Rect.fromCircle(center: pivo, radius: 4.4), math.pi,
        math.pi, false, _stroke(1.4, 0.85));

    // Oscilação suave; próximo dos extremos (|sin|→1) o brilho acende.
    final osc = math.sin(t * 2 * math.pi); // -1..1
    final ang = -math.pi / 2 + osc * (52 * math.pi / 180);
    final tip = Offset(pivo.dx + math.cos(ang) * 3.9, pivo.dy + math.sin(ang) * 3.9);

    final brilho = math.pow(osc.abs(), 6).toDouble(); // ~0 no meio, ~1 no canto
    if (brilho > 0.02) {
      canvas.drawCircle(
        tip,
        2.4,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.85 * brilho)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.2),
      );
    }
    canvas.drawLine(pivo, tip, _stroke(1.7, 0.95));
    canvas.drawCircle(pivo, 1.2, _fill);
  }

  // ── Sintomas: coração pulsando (batida dupla) ───────────────────────────
  void _sintomas(Canvas canvas) {
    final heart = Path()
      ..moveTo(12, 19)
      ..cubicTo(12, 19, 4.5, 14, 4.5, 9.3)
      ..arcToPoint(const Offset(12, 7.7),
          radius: const Radius.circular(3.9), clockwise: true)
      ..arcToPoint(const Offset(19.5, 9.3),
          radius: const Radius.circular(3.9), clockwise: true)
      ..cubicTo(19.5, 14, 12, 19, 12, 19)
      ..close();

    // Batida dupla: dois "bumps" gaussianos no início do ciclo.
    double bump(double x, double w) =>
        math.exp(-math.pow((t - x) / w, 2).toDouble());
    final amp = bump(0.08, 0.05) + 0.65 * bump(0.20, 0.05);
    final escala = 1.0 + amp * 0.12;

    const centro = Offset(12, 13);
    canvas.save();
    canvas.translate(centro.dx, centro.dy);
    canvas.scale(escala);
    canvas.translate(-centro.dx, -centro.dy);
    canvas.drawPath(
        heart, _fill..color = Colors.white.withValues(alpha: 0.92));
    canvas.restore();

    // Leve realce no pico da batida.
    if (amp > 0.15) {
      canvas.drawPath(
        heart,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.25 * amp)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0),
      );
    }
  }

  // ── Registro IA: tigela + faísca de IA piscando ─────────────────────────
  void _registro(Canvas canvas) {
    // Tigela.
    final tigela = Path()
      ..moveTo(4.5, 12.5)
      ..arcToPoint(const Offset(17.5, 12.5),
          radius: const Radius.circular(7), clockwise: false)
      ..close();
    canvas.drawPath(
        tigela, _fill..color = Colors.white.withValues(alpha: 0.9));
    canvas.drawOval(
        Rect.fromCenter(
            center: const Offset(11, 12.5), width: 13, height: 3.4),
        _stroke(1.4, 0.9));

    // Faísca de IA (estrela 4 pontas) piscando: escala + opacidade sobem
    // e descem suavemente. Tom branco-azulado pra "cheirar" IA.
    final pulso = 0.5 + 0.5 * math.sin(t * 2 * math.pi); // 0..1
    final escala = 0.8 + 0.35 * pulso;
    final op = 0.55 + 0.45 * pulso;
    const cx = 18.0, cy = 5.2;

    canvas.save();
    canvas.translate(cx, cy);
    canvas.scale(escala);
    final estrela = _estrela4(3.0, 1.1);
    // Glow da faísca.
    canvas.drawPath(
      estrela,
      Paint()
        ..color = const Color(0xFFCFE3FF).withValues(alpha: 0.55 * op)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.8),
    );
    canvas.drawPath(
        estrela, Paint()..color = const Color(0xFFEAF3FF).withValues(alpha: op));
    canvas.restore();
  }

  // ── Movimento (e fallback): ponto orbitando um anel ─────────────────────
  void _movimento(Canvas canvas) {
    const c = Offset(12, 12);
    canvas.drawCircle(c, 6.5, _stroke(1.5, 0.8));
    final ang = t * 2 * math.pi;
    final dot = Offset(c.dx + math.cos(ang) * 6.5, c.dy + math.sin(ang) * 6.5);
    canvas.drawCircle(
      dot,
      2.6,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0),
    );
    canvas.drawCircle(dot, 1.8, _fill);
  }

  Path _estrela4(double r, double inner) {
    final p = Path();
    for (int i = 0; i < 8; i++) {
      final ang = -math.pi / 2 + i * math.pi / 4;
      final rad = i.isEven ? r : inner;
      final pt = Offset(math.cos(ang) * rad, math.sin(ang) * rad);
      if (i == 0) {
        p.moveTo(pt.dx, pt.dy);
      } else {
        p.lineTo(pt.dx, pt.dy);
      }
    }
    return p..close();
  }

  @override
  bool shouldRepaint(covariant _EixoIconePainter old) =>
      old.t != t || old.eixo != eixo;
}
