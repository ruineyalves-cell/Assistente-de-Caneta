import 'package:flutter/material.dart';

import '../utils/theme.dart';

/// Skeleton do dashboard (Lote I1).
///
/// Mostrado ENQUANTO logs+perfil ainda carregam do backend. Substitui o
/// CircularProgressIndicator centralizado — visualmente já é o layout
/// real (header + 4 cards de metrics + grid de scanners), só que com
/// blocos animados no lugar dos números.
///
/// Percepção: 200ms parece 0ms; 1s parece 200ms. Trocamos ansiedade por
/// contorno familiar.
///
/// Zero deps externas: shimmer é `AnimatedBuilder + LinearGradient`
/// nativo do Flutter — conforme regra do projeto de evitar carnaval
/// de pacotes.
class DashboardSkeleton extends StatelessWidget {
  const DashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(RecorpoSpacing.lg),
      children: const [
        _SkeletonHeader(),
        SizedBox(height: RecorpoSpacing.xl),
        _SkeletonMetricasGrid(),
        SizedBox(height: RecorpoSpacing.lg),
        _SkeletonBlock(height: 96), // banner (alerta / resumo)
        SizedBox(height: RecorpoSpacing.lg),
        _SkeletonScannersRow(),
        SizedBox(height: RecorpoSpacing.lg),
        _SkeletonBlock(height: 128), // card movimento
      ],
    );
  }
}

class _SkeletonHeader extends StatelessWidget {
  const _SkeletonHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        _SkeletonBar(width: 180, height: 20),
        SizedBox(height: 10),
        _SkeletonBar(width: 260, height: 14),
      ],
    );
  }
}

class _SkeletonMetricasGrid extends StatelessWidget {
  const _SkeletonMetricasGrid();

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: RecorpoSpacing.sm,
      crossAxisSpacing: RecorpoSpacing.sm,
      childAspectRatio: 1.6,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: const [
        _SkeletonBlock(height: 96),
        _SkeletonBlock(height: 96),
        _SkeletonBlock(height: 96),
        _SkeletonBlock(height: 96),
      ],
    );
  }
}

class _SkeletonScannersRow extends StatelessWidget {
  const _SkeletonScannersRow();

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: RecorpoSpacing.sm,
      crossAxisSpacing: RecorpoSpacing.sm,
      childAspectRatio: 2.2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: const [
        _SkeletonBlock(height: 70),
        _SkeletonBlock(height: 70),
        _SkeletonBlock(height: 70),
        _SkeletonBlock(height: 70),
      ],
    );
  }
}

class _SkeletonBlock extends StatelessWidget {
  final double height;
  const _SkeletonBlock({required this.height});

  @override
  Widget build(BuildContext context) {
    return _Shimmer(
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(RecorpoSpacing.radiusMd),
        ),
      ),
    );
  }
}

class _SkeletonBar extends StatelessWidget {
  final double width;
  final double height;
  const _SkeletonBar({required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    return _Shimmer(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}

/// Shimmer nativo — gradient que desliza usando AnimationController.
/// Um único controller compartilhado por instância; o dashboard tem
/// ~10 skeletons simultâneos, mas cada um cria o seu — leve o
/// suficiente pra não valer a pena um Provider centralizado.
class _Shimmer extends StatefulWidget {
  final Widget child;
  const _Shimmer({required this.child});

  @override
  State<_Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<_Shimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final baseAlpha = scheme.brightness == Brightness.dark ? 0.10 : 0.06;
    final highlightAlpha = baseAlpha * 3;

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (rect) {
            final dx = rect.width * (2 * _ctrl.value - 1);
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                scheme.onSurface.withValues(alpha: baseAlpha),
                scheme.onSurface.withValues(alpha: highlightAlpha),
                scheme.onSurface.withValues(alpha: baseAlpha),
              ],
              stops: const [0.2, 0.5, 0.8],
              transform: GradientTranslation(dx),
            ).createShader(rect);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// GradientTransform que desliza o gradiente horizontalmente.
class GradientTranslation extends GradientTransform {
  final double dx;
  const GradientTranslation(this.dx);

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(dx, 0, 0);
  }
}
