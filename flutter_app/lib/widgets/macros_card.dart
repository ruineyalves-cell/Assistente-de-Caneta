import 'package:flutter/material.dart';
import '../utils/constants.dart';

/// Card "Macros de Blindagem" do dashboard (Lote 7).
///
/// Mostra a meta diária de proteína (g) e água (ml) — ambas derivadas do
/// peso do usuário e das metas do perfil (metaProteinaGkg × peso,
/// metaAguaMlKg × peso). O carboidrato do PRD ficou de fora enquanto o
/// backend não modela essa meta (evita hardcode sem base clínica).
class MacrosCard extends StatelessWidget {
  final double? metaProteinaG;
  final double? metaAguaMl;
  final double? consumidoProteinaG;
  final double? consumidoAguaMl;

  const MacrosCard({
    super.key,
    this.metaProteinaG,
    this.metaAguaMl,
    this.consumidoProteinaG,
    this.consumidoAguaMl,
  });

  bool get _semMetas => metaProteinaG == null && metaAguaMl == null;

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
                const Icon(Icons.local_dining,
                    color: AppColors.azulClinico, size: 20),
                const SizedBox(width: 8),
                Text('Macros de Blindagem',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            if (_semMetas)
              Text(
                'Registre seu peso e configure suas metas na aba Perfil '
                'para acompanhar suas macros diárias.',
                style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    height: 1.4),
              )
            else ...[
              _MacroLinha(
                emoji: '🥚',
                nome: 'Proteína estrutural',
                consumido: consumidoProteinaG,
                meta: metaProteinaG,
                unidade: 'g',
              ),
              const SizedBox(height: 12),
              _MacroLinha(
                emoji: '💧',
                nome: 'Hidratação',
                consumido: consumidoAguaMl,
                meta: metaAguaMl,
                unidade: 'ml',
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MacroLinha extends StatelessWidget {
  final String emoji;
  final String nome;
  final double? consumido;
  final double? meta;
  final String unidade;

  const _MacroLinha({
    required this.emoji,
    required this.nome,
    required this.consumido,
    required this.meta,
    required this.unidade,
  });

  @override
  Widget build(BuildContext context) {
    final metaEfetiva = meta ?? 0;
    final consumidoEfetivo = consumido ?? 0;
    final progresso = metaEfetiva > 0
        ? (consumidoEfetivo / metaEfetiva).clamp(0.0, 1.0)
        : 0.0;
    final completou = metaEfetiva > 0 && consumidoEfetivo >= metaEfetiva;
    final cor = completou ? AppColors.verdeConfirma : AppColors.azulClinico;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Expanded(
              child: Text(nome,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600)),
            ),
            Text(
              meta == null
                  ? '${_fmt(consumidoEfetivo)} / — $unidade'
                  : '${_fmt(consumidoEfetivo)} / ${_fmt(metaEfetiva)} $unidade',
              style: TextStyle(
                  fontSize: 12,
                  color: cor,
                  fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: meta == null ? null : progresso,
            minHeight: 6,
            backgroundColor: cor.withValues(alpha: 0.15),
            valueColor: AlwaysStoppedAnimation<Color>(cor),
          ),
        ),
      ],
    );
  }

  String _fmt(double v) {
    if (v == v.roundToDouble()) return v.toStringAsFixed(0);
    return v.toStringAsFixed(1);
  }
}
