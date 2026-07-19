import 'package:flutter/material.dart';
import '../utils/theme.dart';

/// Lote 24 — Pílula educativa reutilizável.
///
/// Componente único usado em vários lugares onde faz sentido dar
/// contexto rápido ao usuário sem interromper a jornada. Ao tocar,
/// abre um bottom sheet com o texto completo + fonte.
///
/// **Regras editoriais** (importantes por LGPD/CFN):
/// - `titulo`: até 60 chars, informativo, nunca imperativo
/// - `resumo`: até 120 chars mostrado no chip fechado
/// - `textoCompleto`: 2-4 parágrafos com fonte no final
/// - `fonte`: sempre presente (ex: "Bula Ozempic — Anvisa 2024")
class InfoPill extends StatelessWidget {
  final String titulo;
  final String resumo;
  final String textoCompleto;
  final String fonte;
  final IconData icone;
  final EixoRecorpo? eixo;

  const InfoPill({
    super.key,
    required this.titulo,
    required this.resumo,
    required this.textoCompleto,
    required this.fonte,
    this.icone = Icons.info_outline,
    this.eixo,
  });

  Color _corTema(BuildContext context) =>
      eixo?.cor ?? Theme.of(context).colorScheme.primary;

  void _abrirDetalhe(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(RecorpoSpacing.radiusLg)),
      ),
      builder: (ctx) => _DetalheSheet(
        titulo: titulo,
        textoCompleto: textoCompleto,
        fonte: fonte,
        icone: icone,
        cor: _corTema(ctx),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cor = _corTema(context);
    return InkWell(
      borderRadius: BorderRadius.circular(RecorpoSpacing.radiusMd),
      onTap: () => _abrirDetalhe(context),
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: RecorpoSpacing.md, vertical: RecorpoSpacing.sm + 2),
        decoration: BoxDecoration(
          color: cor.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(RecorpoSpacing.radiusMd),
          border: Border.all(color: cor.withValues(alpha: 0.3), width: 0.8),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icone, size: 18, color: cor),
            const SizedBox(width: RecorpoSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: cor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    resumo,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurface,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 12, color: cor),
          ],
        ),
      ),
    );
  }
}

class _DetalheSheet extends StatelessWidget {
  final String titulo;
  final String textoCompleto;
  final String fonte;
  final IconData icone;
  final Color cor;

  const _DetalheSheet({
    required this.titulo,
    required this.textoCompleto,
    required this.fonte,
    required this.icone,
    required this.cor,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(RecorpoSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: RecorpoSpacing.lg),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: cor,
                  foregroundColor: Colors.white,
                  radius: 22,
                  child: Icon(icone, size: 22),
                ),
                const SizedBox(width: RecorpoSpacing.md),
                Expanded(
                  child: Text(
                    titulo,
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: RecorpoSpacing.lg),
            Text(
              textoCompleto,
              style: const TextStyle(fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: RecorpoSpacing.lg),
            Container(
              padding: const EdgeInsets.all(RecorpoSpacing.md),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(RecorpoSpacing.radiusSm),
                border: Border.all(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified_outlined, size: 16),
                  const SizedBox(width: RecorpoSpacing.sm),
                  Expanded(
                    child: Text(
                      'Fonte: $fonte',
                      style: const TextStyle(
                          fontSize: 11, fontStyle: FontStyle.italic),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: RecorpoSpacing.md),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                style: FilledButton.styleFrom(backgroundColor: cor),
                child: const Text('Entendi'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
