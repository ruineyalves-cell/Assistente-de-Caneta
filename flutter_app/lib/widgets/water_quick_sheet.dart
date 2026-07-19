import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/logs_provider.dart';
import '../utils/theme.dart';

/// Lote 32 — Bottom sheet focado só em água.
///
/// Substitui o antigo comportamento do card Água no dashboard, que
/// abria o formulário genérico `LogDailyPage`. Agora o usuário
/// registra apenas água, num toque, com feedback visual imediato.
///
/// UX:
///  - Círculo de progresso grande no topo (litros consumidos / meta).
///  - 4 botões grandes: +250 ml, +500 ml, +750 ml, +1 L.
///  - Cada toque soma ao total do dia e roda um pequeno haptic.
///  - Botão "personalizar" (mais discreto) abre input livre.
///  - Não fecha ao adicionar — o usuário pode empilhar toques.
Future<void> mostrarWaterQuickSheet(
  BuildContext context, {
  required int aguaAtualMl,
  int? metaAguaMl,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => WaterQuickSheet(
      aguaAtualMl: aguaAtualMl,
      metaAguaMl: metaAguaMl,
    ),
  );
}

class WaterQuickSheet extends StatefulWidget {
  final int aguaAtualMl;
  final int? metaAguaMl;

  const WaterQuickSheet({
    super.key,
    required this.aguaAtualMl,
    this.metaAguaMl,
  });

  @override
  State<WaterQuickSheet> createState() => _WaterQuickSheetState();
}

class _WaterQuickSheetState extends State<WaterQuickSheet> {
  late int _atualMl;
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    _atualMl = widget.aguaAtualMl;
  }

  double? get _progresso {
    final meta = widget.metaAguaMl;
    if (meta == null || meta == 0) return null;
    return (_atualMl / meta).clamp(0, 1.5);
  }

  Future<void> _somar(int ml) async {
    if (_salvando) return;
    final logs = context.read<LogsProvider>();
    final novoTotal = _atualMl + ml;
    setState(() {
      _salvando = true;
      _atualMl = novoTotal;
    });
    try {
      await logs.adicionarLog(
        data: DateTime.now(),
        aguaMl: novoTotal,
      );
    } catch (_) {
      // Se falhar, desfaz o incremento visual pra não iludir o usuário.
      if (!mounted) return;
      setState(() => _atualMl -= ml);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não deu para salvar agora. Tente novamente.')),
      );
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  Future<void> _personalizar() async {
    final controller = TextEditingController();
    final valor = await showDialog<int?>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Personalizar'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Quantidade (ml)',
            hintText: 'Ex.: 320',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              final n = int.tryParse(controller.text.trim());
              Navigator.of(dialogCtx).pop(n);
            },
            child: const Text('Adicionar'),
          ),
        ],
      ),
    );
    if (valor != null && valor > 0 && valor < 5000) {
      await _somar(valor);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final meta = widget.metaAguaMl;
    final litros = (_atualMl / 1000).toStringAsFixed(1);
    final metaLitros =
        meta == null ? '—' : '${(meta / 1000).toStringAsFixed(1)}L';

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          RecorpoSpacing.lg,
          RecorpoSpacing.md,
          RecorpoSpacing.lg,
          RecorpoSpacing.xl,
        ),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(RecorpoSpacing.radiusXl),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: scheme.onSurface.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: RecorpoSpacing.lg),

            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    gradient: RecorpoGradients.agua,
                    borderRadius: BorderRadius.circular(
                        RecorpoSpacing.radiusSm),
                  ),
                  child: const Icon(Icons.water_drop_outlined,
                      color: Colors.white, size: 22),
                ),
                const SizedBox(width: RecorpoSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Hidratação de hoje',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 2,
                              color: scheme.onSurface
                                  .withValues(alpha: 0.65))),
                      const SizedBox(height: 2),
                      Text('Meta: $metaLitros',
                          style: TextStyle(
                              fontSize: 13,
                              color: scheme.onSurface
                                  .withValues(alpha: 0.6))),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.close,
                      color: scheme.onSurface.withValues(alpha: 0.6)),
                  tooltip: 'Fechar',
                ),
              ],
            ),

            const SizedBox(height: RecorpoSpacing.xl),

            // Progresso grande
            Center(
              child: _ProgressoCirculo(
                progresso: _progresso ?? 0,
                temMeta: _progresso != null,
                litros: litros,
              ),
            ),

            const SizedBox(height: RecorpoSpacing.xl),

            // 4 botões grandes de incremento
            Row(
              children: [
                Expanded(child: _BotaoIncremento(ml: 250, onTap: _somar)),
                const SizedBox(width: RecorpoSpacing.sm),
                Expanded(child: _BotaoIncremento(ml: 500, onTap: _somar)),
              ],
            ),
            const SizedBox(height: RecorpoSpacing.sm),
            Row(
              children: [
                Expanded(child: _BotaoIncremento(ml: 750, onTap: _somar)),
                const SizedBox(width: RecorpoSpacing.sm),
                Expanded(child: _BotaoIncremento(ml: 1000, onTap: _somar)),
              ],
            ),

            const SizedBox(height: RecorpoSpacing.md),

            TextButton.icon(
              onPressed: _salvando ? null : _personalizar,
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text('Personalizar quantidade'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressoCirculo extends StatelessWidget {
  final double progresso;
  final bool temMeta;
  final String litros;

  const _ProgressoCirculo({
    required this.progresso,
    required this.temMeta,
    required this.litros,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 180,
      height: 180,
      child: CustomPaint(
        painter: _CircPainter(
          progresso: progresso,
          corFundo: scheme.onSurface.withValues(alpha: 0.08),
          corAtiva: RecorpoColors.eixoAgua,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(litros,
                  style: TextStyle(
                    fontSize: 46,
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurface,
                    height: 1,
                  )),
              const SizedBox(height: 4),
              Text('litros hoje',
                  style: TextStyle(
                      fontSize: 12,
                      color: scheme.onSurface.withValues(alpha: 0.6))),
              if (temMeta) ...[
                const SizedBox(height: 6),
                Text('${(progresso * 100).round()}% da meta',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: RecorpoColors.eixoAgua)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CircPainter extends CustomPainter {
  final double progresso;
  final Color corFundo;
  final Color corAtiva;

  _CircPainter({
    required this.progresso,
    required this.corFundo,
    required this.corAtiva,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centro = Offset(size.width / 2, size.height / 2);
    final raio = math.min(size.width, size.height) / 2 - 8;

    final fundo = Paint()
      ..color = corFundo
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(centro, raio, fundo);

    final ativa = Paint()
      ..color = corAtiva
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;
    final anguloVarredura = progresso.clamp(0.0, 1.0) * 2 * math.pi;
    canvas.drawArc(
      Rect.fromCircle(center: centro, radius: raio),
      -math.pi / 2,
      anguloVarredura,
      false,
      ativa,
    );
  }

  @override
  bool shouldRepaint(covariant _CircPainter old) =>
      old.progresso != progresso;
}

class _BotaoIncremento extends StatelessWidget {
  final int ml;
  final Future<void> Function(int) onTap;
  const _BotaoIncremento({required this.ml, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final label = ml >= 1000
        ? '+${(ml / 1000).toStringAsFixed(ml % 1000 == 0 ? 0 : 1)} L'
        : '+$ml ml';
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onTap(ml),
        borderRadius: BorderRadius.circular(RecorpoSpacing.radiusMd),
        child: Ink(
          decoration: BoxDecoration(
            gradient: RecorpoGradients.agua,
            borderRadius: BorderRadius.circular(RecorpoSpacing.radiusMd),
          ),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(vertical: RecorpoSpacing.lg),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
