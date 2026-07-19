import 'package:flutter/material.dart';
import '../utils/theme.dart';

/// Card grande de eixo — visual estilo Samsung Health.
///
/// Cor de fundo = cor do eixo, com gradiente sutil. Título curto,
/// valor grande à esquerda, ilustração no canto direito (círculo com
/// glow + emoji). Toque abre a tela detalhada do eixo.
class EixoCard extends StatelessWidget {
  final EixoRecorpo eixo;
  final String titulo;
  final String valor;
  final String? subtitulo;
  final String? rodape;
  final VoidCallback? onTap;
  final bool destaque;

  const EixoCard({
    super.key,
    required this.eixo,
    required this.titulo,
    required this.valor,
    this.subtitulo,
    this.rodape,
    this.onTap,
    this.destaque = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(RecorpoSpacing.radiusXl),
      onTap: onTap,
      child: Container(
        height: destaque ? 190 : 160,
        decoration: BoxDecoration(
          gradient: eixo.gradiente,
          borderRadius: BorderRadius.circular(RecorpoSpacing.radiusXl),
          boxShadow: [
            BoxShadow(
              color: eixo.cor.withValues(alpha: 0.25),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Ilustração no canto (glow + emoji)
            Positioned(
              top: -12,
              right: -12,
              child: EixoIlustracao(eixo: eixo, size: 130),
            ),
            // Conteúdo
            Padding(
              padding: const EdgeInsets.all(RecorpoSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    titulo,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        valor,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: destaque ? 40 : 32,
                          fontWeight: FontWeight.w800,
                          height: 1.0,
                          letterSpacing: -0.5,
                        ),
                      ),
                      if (subtitulo != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitulo!,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (rodape != null)
                    Text(
                      rodape!,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    )
                  else
                    const SizedBox.shrink(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Ilustração "3D-lite": círculo com gradiente radial + emoji Unicode.
/// Grátis, funciona em qualquer Android, não pesa no APK.
class EixoIlustracao extends StatelessWidget {
  final EixoRecorpo eixo;
  final double size;

  const EixoIlustracao({super.key, required this.eixo, this.size = 120});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Glow
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.white.withValues(alpha: 0.35),
                  Colors.white.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
          // Emoji "3D"
          Text(
            eixo.emoji,
            style: TextStyle(
              fontSize: size * 0.55,
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
