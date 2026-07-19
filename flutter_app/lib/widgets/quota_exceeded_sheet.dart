import 'package:flutter/material.dart';
import '../screens/paywall_screen.dart';
import '../services/premium_service.dart';
import '../utils/theme.dart';

/// Lote 27 — Sheet mostrado quando o Free estoura a quota da feature.
///
/// Visual alinhado ao EixoCard (cor do eixo, gradiente, emoji). Não é
/// bloqueio — é um convite ao Premium. Sempre dá caminho pra "Amanhã
/// tento de novo" pra não empurrar goela abaixo.
Future<bool?> mostrarQuotaExcedida(
  BuildContext context, {
  required Feature feature,
  required EixoRecorpo eixo,
  required String tituloFeature,
  required int limite,
  required String periodoLabel, // ex: "por dia", "por semana"
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => QuotaExceededSheet(
      feature: feature,
      eixo: eixo,
      tituloFeature: tituloFeature,
      limite: limite,
      periodoLabel: periodoLabel,
    ),
  );
}

class QuotaExceededSheet extends StatelessWidget {
  final Feature feature;
  final EixoRecorpo eixo;
  final String tituloFeature;
  final int limite;
  final String periodoLabel;

  const QuotaExceededSheet({
    super.key,
    required this.feature,
    required this.eixo,
    required this.tituloFeature,
    required this.limite,
    required this.periodoLabel,
  });

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;
    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(RecorpoSpacing.radiusLg),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Puxador
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            // Hero visual com cor do eixo (mesma estética do EixoCard)
            Container(
              margin: const EdgeInsets.all(RecorpoSpacing.lg),
              padding: const EdgeInsets.all(RecorpoSpacing.lg),
              height: 170,
              decoration: BoxDecoration(
                gradient: eixo.gradiente,
                borderRadius:
                    BorderRadius.circular(RecorpoSpacing.radiusXl),
                boxShadow: [
                  BoxShadow(
                    color: eixo.cor.withValues(alpha: 0.3),
                    blurRadius: 22,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: -8,
                    right: -8,
                    child: EixoIlustracaoPill(eixo: eixo),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Você está indo bem!',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const Text(
                        'Limite do plano\nGrátis atingido',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          height: 1.1,
                        ),
                      ),
                      Text(
                        'Você já usou o $tituloFeature $limite vezes $periodoLabel.',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Benefícios Premium
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: RecorpoSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Com Recorpo Premium você tem',
                    style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: RecorpoSpacing.md),
                  _beneficio(Icons.all_inclusive,
                      'Câmera de refeição e OCR sem limite'),
                  _beneficio(Icons.picture_as_pdf_outlined,
                      'PDF pro médico ilimitado'),
                  _beneficio(Icons.query_stats,
                      'Comparativos 30 / 60 / 90 dias'),
                  _beneficio(Icons.block, 'Sem anúncios'),
                ],
              ),
            ),
            const SizedBox(height: RecorpoSpacing.lg),
            // CTAs
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: RecorpoSpacing.xl),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop(true);
                        Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const PaywallScreen()),
                        );
                      },
                      icon: const Icon(Icons.workspace_premium),
                      label: const Text(
                        'Conhecer o Premium',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: eixo.cor,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(RecorpoSpacing.radiusMd),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text(
                      'Amanhã tento de novo',
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: RecorpoSpacing.md),
          ],
        ),
      ),
    );
  }

  Widget _beneficio(IconData icone, String texto) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icone, size: 18, color: eixo.cor),
          const SizedBox(width: RecorpoSpacing.md),
          Expanded(
            child: Text(texto, style: const TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

/// Versão menor da ilustração pro sheet.
class EixoIlustracaoPill extends StatelessWidget {
  final EixoRecorpo eixo;
  const EixoIlustracaoPill({super.key, required this.eixo});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 130,
      height: 130,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.white.withValues(alpha: 0.35),
                  Colors.white.withValues(alpha: 0),
                ],
              ),
            ),
          ),
          Text(
            eixo.emoji,
            style: TextStyle(
              fontSize: 72,
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
