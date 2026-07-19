import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/patient_profile.dart';
import '../services/logs_provider.dart';
import '../utils/theme.dart';

/// Lote 32 — Bottom sheet focado só em peso.
///
/// Registro rápido: input de peso + escolha de onde pesou (casa,
/// academia, farmácia, clínica). O local é armazenado como observação
/// no campo `alimentos` do log ("Peso: X.Y kg @ local"), pra o médico
/// ver no PDF sem exigir nova coluna no backend.
///
/// A escolha do local é guardada em prefs pra que o próximo registro
/// venha pré-selecionado — a maioria pesa sempre no mesmo lugar.
Future<void> mostrarWeightQuickSheet(
  BuildContext context, {
  required double? pesoAnteriorKg,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => WeightQuickSheet(pesoAnteriorKg: pesoAnteriorKg),
  );
}

class WeightQuickSheet extends StatefulWidget {
  final double? pesoAnteriorKg;

  const WeightQuickSheet({super.key, this.pesoAnteriorKg});

  @override
  State<WeightQuickSheet> createState() => _WeightQuickSheetState();
}

class _WeightQuickSheetState extends State<WeightQuickSheet> {
  final _controller = TextEditingController();
  LocalPesagem _local = LocalPesagem.casa;
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    _carregarUltimoLocal();
  }

  Future<void> _carregarUltimoLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final nome = prefs.getString(ProfilePrefsKeys.ultimoLocalPesagem);
    if (nome == null || !mounted) return;
    for (final v in LocalPesagem.values) {
      if (v.name == nome) {
        setState(() => _local = v);
        break;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double? get _pesoDigitado {
    final txt = _controller.text.trim().replaceAll(',', '.');
    final n = double.tryParse(txt);
    if (n == null || n < 20 || n > 400) return null;
    return n;
  }

  double? get _delta {
    final novo = _pesoDigitado;
    final ant = widget.pesoAnteriorKg;
    if (novo == null || ant == null) return null;
    return novo - ant;
  }

  Future<void> _salvar() async {
    final peso = _pesoDigitado;
    if (peso == null) return;

    setState(() => _salvando = true);
    final logs = context.read<LogsProvider>();

    try {
      final observacao = 'Peso: ${peso.toStringAsFixed(1)} kg @ ${_local.label}';
      await logs.adicionarLog(
        data: DateTime.now(),
        pesoKg: peso,
        alimentos: observacao,
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          ProfilePrefsKeys.ultimoLocalPesagem, _local.name);
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Peso registrado: ${peso.toStringAsFixed(1)} kg (${_local.label}).'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _salvando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha ao salvar: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final delta = _delta;

    return SafeArea(
      top: false,
      child: Padding(
        // Sobe com o teclado
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
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
                      gradient: RecorpoGradients.peso,
                      borderRadius: BorderRadius.circular(
                          RecorpoSpacing.radiusSm),
                    ),
                    child: const Icon(Icons.monitor_weight_outlined,
                        color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: RecorpoSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Registro de peso',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 2,
                                color: scheme.onSurface
                                    .withValues(alpha: 0.65))),
                        const SizedBox(height: 2),
                        if (widget.pesoAnteriorKg != null)
                          Text(
                            'Último: ${widget.pesoAnteriorKg!.toStringAsFixed(1)} kg',
                            style: TextStyle(
                                fontSize: 13,
                                color: scheme.onSurface
                                    .withValues(alpha: 0.6)),
                          )
                        else
                          Text('Primeiro registro',
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

              // Input de peso grande e central
              TextField(
                controller: _controller,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(
                    decimal: true, signed: false),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 46,
                  fontWeight: FontWeight.w800,
                  color: scheme.onSurface,
                ),
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: '87,5',
                  hintStyle: TextStyle(
                    fontSize: 46,
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurface.withValues(alpha: 0.15),
                  ),
                  suffixText: 'kg',
                  suffixStyle: TextStyle(
                    fontSize: 20,
                    color: scheme.onSurface.withValues(alpha: 0.55),
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
              ),

              // Delta em relação ao último
              if (delta != null) ...[
                const SizedBox(height: RecorpoSpacing.sm),
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: delta < 0
                          ? RecorpoColors.confirma.withValues(alpha: 0.15)
                          : delta > 0
                              ? RecorpoColors.alertaClinico
                                  .withValues(alpha: 0.15)
                              : scheme.onSurface.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      delta == 0
                          ? 'Mesmo peso do último registro'
                          : delta < 0
                              ? '↓ ${delta.abs().toStringAsFixed(1)} kg vs último'
                              : '↑ +${delta.toStringAsFixed(1)} kg vs último',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: delta < 0
                            ? RecorpoColors.confirma
                            : delta > 0
                                ? RecorpoColors.alertaClinico
                                : scheme.onSurface
                                    .withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: RecorpoSpacing.xl),

              Text('Onde você se pesou?',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                      color: scheme.onSurface.withValues(alpha: 0.65))),
              const SizedBox(height: RecorpoSpacing.sm),

              Wrap(
                spacing: RecorpoSpacing.sm,
                runSpacing: RecorpoSpacing.sm,
                children: LocalPesagem.values.map((l) {
                  final sel = _local == l;
                  return ChoiceChip(
                    selected: sel,
                    onSelected: (_) => setState(() => _local = l),
                    avatar: Text(l.emoji,
                        style: const TextStyle(fontSize: 16)),
                    label: Text(l.label),
                    labelStyle: TextStyle(
                      fontWeight:
                          sel ? FontWeight.w700 : FontWeight.w500,
                      color: sel ? Colors.white : scheme.onSurface,
                    ),
                    selectedColor: RecorpoColors.eixoPeso,
                  );
                }).toList(),
              ),

              const SizedBox(height: RecorpoSpacing.lg),

              Container(
                padding: const EdgeInsets.all(RecorpoSpacing.md),
                decoration: BoxDecoration(
                  color: RecorpoColors.eixoPeso.withValues(alpha: 0.08),
                  borderRadius:
                      BorderRadius.circular(RecorpoSpacing.radiusSm),
                  border: Border.all(
                    color: RecorpoColors.eixoPeso.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline,
                        size: 18, color: RecorpoColors.eixoPeso),
                    const SizedBox(width: RecorpoSpacing.sm),
                    Expanded(
                      child: Text(
                        'Pesar sempre no mesmo horário e local reduz '
                        'oscilações e deixa a curva mais confiável.',
                        style: TextStyle(
                            fontSize: 12,
                            height: 1.5,
                            color: scheme.onSurface
                                .withValues(alpha: 0.75)),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: RecorpoSpacing.lg),

              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed:
                      (_pesoDigitado == null || _salvando) ? null : _salvar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: RecorpoColors.eixoPeso,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        RecorpoColors.eixoPeso.withValues(alpha: 0.4),
                  ),
                  child: _salvando
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white),
                          ),
                        )
                      : const Text('Salvar peso',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
