import 'dart:convert';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../utils/theme.dart';

/// Lote 32.8 — Resultado do scanner de bula.
///
/// Prompt do backend só pede TRANSCRIÇÃO da bula; nunca sugere
/// conduta. Este layout reforça o mesmo espírito: quatro seções
/// bem separadas (indicações, dose, efeitos, alertas) sem interpretação.
class BulaResultScreen extends StatefulWidget {
  final XFile foto;
  const BulaResultScreen({super.key, required this.foto});

  @override
  State<BulaResultScreen> createState() => _BulaResultScreenState();
}

class _BulaResultScreenState extends State<BulaResultScreen> {
  bool _carregando = true;
  String? _erro;
  Map<String, dynamic>? _dados;

  @override
  void initState() {
    super.initState();
    _analisar();
  }

  Future<void> _analisar() async {
    final auth = context.read<AuthService>();
    try {
      final bytes = await File(widget.foto.path).readAsBytes();
      final resp = await auth.apiService.analisarBulaIA(
        imagemBase64: base64Encode(bytes),
      );
      if (!mounted) return;
      setState(() {
        _dados = resp;
        _carregando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _erro = e.toString();
        _carregando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bula do medicamento')),
      body: _construir(),
    );
  }

  Widget _construir() {
    if (_carregando) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Transcrevendo a bula…'),
          ],
        ),
      );
    }
    if (_erro != null) {
      return _Erro(mensagem: _erro!, onTentar: _analisar);
    }
    final d = _dados!;
    if (d['iaConfigurada'] == false) {
      return _IaIndisponivel(mensagem: d['mensagem'] as String?);
    }
    final indicacoes = ((d['indicacoes'] as List?) ?? const []).cast<String>();
    final efeitos = ((d['efeitosComuns'] as List?) ?? const []).cast<String>();
    final alertas = ((d['alertas'] as List?) ?? const []).cast<String>();
    return ListView(
      padding: const EdgeInsets.all(RecorpoSpacing.lg),
      children: [
        _Header(
          medicamento: d['medicamento'] as String?,
          principio: d['principioAtivo'] as String?,
        ),
        const SizedBox(height: RecorpoSpacing.xl),
        if ((d['dose'] as String?)?.isNotEmpty ?? false)
          _Bloco(
            titulo: 'Dose padrão',
            icone: Icons.medication_outlined,
            cor: RecorpoColors.primary,
            corpo: Text(d['dose'] as String,
                style: const TextStyle(fontSize: 14, height: 1.5)),
          ),
        if (indicacoes.isNotEmpty)
          _Bloco(
            titulo: 'Indicações',
            icone: Icons.check_circle_outline,
            cor: RecorpoColors.confirma,
            corpo: _Lista(items: indicacoes),
          ),
        if (efeitos.isNotEmpty)
          _Bloco(
            titulo: 'Efeitos comuns',
            icone: Icons.info_outline,
            cor: RecorpoColors.eixoStreak,
            corpo: _Lista(items: efeitos),
          ),
        if (alertas.isNotEmpty)
          _Bloco(
            titulo: 'Alertas',
            icone: Icons.warning_amber_rounded,
            cor: RecorpoColors.alertaClinico,
            corpo: _Lista(items: alertas),
          ),
        const SizedBox(height: RecorpoSpacing.md),
        _AvisoLegal(),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  final String? medicamento;
  final String? principio;
  const _Header({required this.medicamento, required this.principio});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(medicamento ?? 'Medicamento não identificado',
            style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: scheme.onSurface)),
        if (principio != null) ...[
          const SizedBox(height: 4),
          Text('Princípio ativo: $principio',
              style: TextStyle(
                  fontSize: 14,
                  color: scheme.onSurface.withValues(alpha: 0.7))),
        ],
      ],
    );
  }
}

class _Bloco extends StatelessWidget {
  final String titulo;
  final IconData icone;
  final Color cor;
  final Widget corpo;
  const _Bloco({
    required this.titulo,
    required this.icone,
    required this.cor,
    required this.corpo,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: RecorpoSpacing.md),
      child: Container(
        padding: const EdgeInsets.all(RecorpoSpacing.md),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(RecorpoSpacing.radiusMd),
          border: Border.all(
              color: scheme.onSurface.withValues(alpha: 0.06)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icone, color: cor, size: 20),
                const SizedBox(width: 8),
                Text(titulo,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                        color: cor)),
              ],
            ),
            const SizedBox(height: 10),
            corpo,
          ],
        ),
      ),
    );
  }
}

class _Lista extends StatelessWidget {
  final List<String> items;
  const _Lista({required this.items});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final s in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('• ',
                    style: TextStyle(
                        color: scheme.onSurface.withValues(alpha: 0.6))),
                Expanded(
                  child: Text(
                    s,
                    style: const TextStyle(fontSize: 14, height: 1.5),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _AvisoLegal extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(RecorpoSpacing.md),
      decoration: BoxDecoration(
        color: RecorpoColors.alertaClinico.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(RecorpoSpacing.radiusSm),
        border: Border.all(
          color: RecorpoColors.alertaClinico.withValues(alpha: 0.32),
        ),
      ),
      child: const Text(
        'Transcrição automática da bula. Não substitui a leitura completa '
        'do documento oficial nem a orientação de quem prescreveu.',
        style: TextStyle(fontSize: 12, height: 1.5),
      ),
    );
  }
}

class _Erro extends StatelessWidget {
  final String mensagem;
  final VoidCallback onTentar;
  const _Erro({required this.mensagem, required this.onTentar});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(RecorpoSpacing.xl),
      children: [
        const SizedBox(height: 60),
        const Icon(Icons.cloud_off, size: 48, color: Colors.grey),
        const SizedBox(height: 12),
        Text(mensagem, textAlign: TextAlign.center),
        const SizedBox(height: 16),
        Center(
          child: OutlinedButton.icon(
            onPressed: onTentar,
            icon: const Icon(Icons.refresh),
            label: const Text('Tentar de novo'),
          ),
        ),
      ],
    );
  }
}

class _IaIndisponivel extends StatelessWidget {
  final String? mensagem;
  const _IaIndisponivel({required this.mensagem});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(RecorpoSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.smart_toy_outlined, size: 48, color: Colors.grey),
          const SizedBox(height: 12),
          Text(
            mensagem ?? 'IA de bula ainda não ativada.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
