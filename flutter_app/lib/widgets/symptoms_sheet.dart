import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/symptom.dart';
import '../services/logs_provider.dart';
import '../utils/theme.dart';

/// Lote 25 — Bottom sheet "Como você está?".
///
/// Chips clicáveis com escala 3 níveis (leve/moderado/intenso).
/// Ao confirmar, envia como daily_log com campo `efeitos` = JSON dos
/// SymptomEntry. Se qualquer sintoma marcado como `alertaSeIntenso`
/// vier em `intenso`, mostra pílula recomendando conversa médica.
Future<bool?> abrirSymptomsSheet(BuildContext context, {String? contexto}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius:
          BorderRadius.vertical(top: Radius.circular(RecorpoSpacing.radiusLg)),
    ),
    builder: (ctx) => SymptomsSheet(contexto: contexto),
  );
}

class SymptomsSheet extends StatefulWidget {
  final String? contexto;
  const SymptomsSheet({super.key, this.contexto});

  @override
  State<SymptomsSheet> createState() => _SymptomsSheetState();
}

class _SymptomsSheetState extends State<SymptomsSheet> {
  final Map<SymptomType, SymptomIntensity> _selecionados = {};
  bool _salvando = false;

  void _toggle(SymptomType t, SymptomIntensity nova) {
    setState(() {
      final atual = _selecionados[t];
      if (atual == nova) {
        _selecionados.remove(t); // desmarca se tocar de novo na mesma intensidade
      } else {
        _selecionados[t] = nova;
      }
    });
  }

  bool get _temAlertaVermelho {
    return _selecionados.entries.any((e) =>
        e.value == SymptomIntensity.intenso &&
        infoDe(e.key).alertaSeIntenso);
  }

  Future<void> _salvar() async {
    if (_selecionados.isEmpty) {
      Navigator.of(context).pop(false);
      return;
    }
    setState(() => _salvando = true);
    try {
      final logs = context.read<LogsProvider>();
      final agora = DateTime.now();
      final entries = _selecionados.entries
          .map((e) => SymptomEntry(
                tipo: e.key,
                intensidade: e.value,
                quando: agora,
                contexto: widget.contexto,
              ).toJson())
          .toList();
      final payload = jsonEncode({'sintomas': entries});
      await logs.adicionarLog(
        data: agora,
        efeitosColaterais: payload,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _temAlertaVermelho
                ? 'Registrado. Se persistir, fale com quem prescreveu.'
                : 'Registrado. Vai ficar no seu relatório.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não deu para salvar: $e')),
      );
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      top: false,
      child: DraggableScrollableSheet(
        expand: false,
        maxChildSize: 0.92,
        minChildSize: 0.5,
        initialChildSize: 0.85,
        builder: (ctx, scroll) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: RecorpoSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Puxador
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(top: 10, bottom: 14),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              // Header
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: RecorpoColors.eixoSintomas,
                    foregroundColor: Colors.white,
                    child: const Icon(Icons.medical_services_outlined),
                  ),
                  const SizedBox(width: RecorpoSpacing.md),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Como você está?',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w700)),
                        SizedBox(height: 2),
                        Text(
                          'Toque nos sintomas e escolha a intensidade.',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (widget.contexto != null) ...[
                const SizedBox(height: RecorpoSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: RecorpoColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(widget.contexto!,
                      style: const TextStyle(fontSize: 11)),
                ),
              ],
              const SizedBox(height: RecorpoSpacing.md),
              Expanded(
                child: ListView(
                  controller: scroll,
                  children: [
                    for (final s in kSintomasCatalogo)
                      _CardSintoma(
                        info: s,
                        selecionada: _selecionados[s.tipo],
                        onEscolher: (i) => _toggle(s.tipo, i),
                      ),
                    if (_temAlertaVermelho)
                      Container(
                        margin: const EdgeInsets.only(top: RecorpoSpacing.md),
                        padding: const EdgeInsets.all(RecorpoSpacing.md),
                        decoration: BoxDecoration(
                          color: RecorpoColors.alertaClinico
                              .withValues(alpha: 0.1),
                          borderRadius:
                              BorderRadius.circular(RecorpoSpacing.radiusSm),
                          border: Border.all(
                              color: RecorpoColors.alertaClinico
                                  .withValues(alpha: 0.4)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.warning_amber,
                                color: RecorpoColors.alertaClinico),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Alguns sintomas marcados como intensos merecem conversa com quem prescreveu, especialmente se persistirem.',
                                style: TextStyle(fontSize: 12, height: 1.4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: RecorpoSpacing.xl),
                  ],
                ),
              ),
              // Ações
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          _salvando ? null : () => Navigator.of(context).pop(false),
                      child: const Text('Nada agora'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _salvando ? null : _salvar,
                      style: FilledButton.styleFrom(
                        backgroundColor: RecorpoColors.eixoSintomas,
                      ),
                      icon: _salvando
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.check, size: 18),
                      label: Text(
                        _selecionados.isEmpty
                            ? 'Registrar'
                            : 'Registrar ${_selecionados.length}',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: RecorpoSpacing.md),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardSintoma extends StatelessWidget {
  final SymptomInfo info;
  final SymptomIntensity? selecionada;
  final ValueChanged<SymptomIntensity> onEscolher;

  const _CardSintoma({
    required this.info,
    required this.selecionada,
    required this.onEscolher,
  });

  @override
  Widget build(BuildContext context) {
    final ehSelecionado = selecionada != null;
    return Container(
      margin: const EdgeInsets.only(bottom: RecorpoSpacing.sm),
      padding: const EdgeInsets.all(RecorpoSpacing.md),
      decoration: BoxDecoration(
        color: ehSelecionado
            ? RecorpoColors.eixoSintomas.withValues(alpha: 0.08)
            : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(RecorpoSpacing.radiusMd),
        border: Border.all(
          color: ehSelecionado
              ? RecorpoColors.eixoSintomas.withValues(alpha: 0.5)
              : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08),
          width: ehSelecionado ? 1.2 : 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(info.emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(info.rotulo,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600)),
              ),
              if (info.alertaSeIntenso)
                Tooltip(
                  message: 'Sintoma que merece atenção se intenso',
                  child: Icon(Icons.info_outline,
                      size: 16,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.5)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            children: [
              _chipIntensidade(SymptomIntensity.leve),
              _chipIntensidade(SymptomIntensity.moderado),
              _chipIntensidade(SymptomIntensity.intenso),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chipIntensidade(SymptomIntensity i) {
    final ativo = selecionada == i;
    return ChoiceChip(
      label: Text(i.label, style: const TextStyle(fontSize: 11)),
      selected: ativo,
      onSelected: (_) => onEscolher(i),
      selectedColor: RecorpoColors.eixoSintomas,
      labelStyle: TextStyle(
        color: ativo ? Colors.white : null,
        fontSize: 11,
      ),
      visualDensity: VisualDensity.compact,
    );
  }
}
