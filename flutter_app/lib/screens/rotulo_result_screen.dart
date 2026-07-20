import 'dart:convert';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../utils/theme.dart';

/// Lote 32.8 — Resultado do scanner de rótulo alimentar.
///
/// Recebe XFile da câmera → converte pra base64 → chama a IA →
/// exibe macros por porção. Sem chave IA no servidor: mostra fallback
/// informativo (não é erro — é o "modo grátis").
class RotuloResultScreen extends StatefulWidget {
  final XFile foto;
  const RotuloResultScreen({super.key, required this.foto});

  @override
  State<RotuloResultScreen> createState() => _RotuloResultScreenState();
}

class _RotuloResultScreenState extends State<RotuloResultScreen> {
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
      final resp = await auth.apiService.analisarRotuloIA(
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
      appBar: AppBar(title: const Text('Rótulo alimentar')),
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
            Text('Lendo o rótulo…'),
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
    return ListView(
      padding: const EdgeInsets.all(RecorpoSpacing.lg),
      children: [
        _Header(
          produto: d['produto'] as String?,
          porcao: d['porcao'] as String?,
        ),
        const SizedBox(height: RecorpoSpacing.xl),
        _TabelaMacros(dados: d),
        const SizedBox(height: RecorpoSpacing.xl),
        _AvisoLegal(),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  final String? produto;
  final String? porcao;
  const _Header({required this.produto, required this.porcao});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          produto ?? 'Produto não identificado',
          style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: scheme.onSurface),
        ),
        if (porcao != null) ...[
          const SizedBox(height: 4),
          Text('Porção: $porcao',
              style: TextStyle(
                  fontSize: 14,
                  color: scheme.onSurface.withValues(alpha: 0.7))),
        ],
      ],
    );
  }
}

class _TabelaMacros extends StatelessWidget {
  final Map<String, dynamic> dados;
  const _TabelaMacros({required this.dados});

  static const _macros = <_Macro>[
    _Macro('caloriasKcal', 'Calorias', 'kcal', RecorpoColors.eixoStreak),
    _Macro('proteinaG', 'Proteína', 'g', RecorpoColors.eixoPeso),
    _Macro('carboidratosG', 'Carboidratos', 'g', RecorpoColors.eixoRefeicao),
    _Macro('gordurasG', 'Gorduras', 'g', RecorpoColors.eixoSintomas),
    _Macro('gordurasSaturadasG', 'Sat.', 'g',
        RecorpoColors.eixoSintomasDark),
    _Macro('fibraG', 'Fibra', 'g', RecorpoColors.eixoMovimento),
    _Macro('sodioMg', 'Sódio', 'mg', RecorpoColors.alertaClinico),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final m in _macros)
          _LinhaMacro(macro: m, valor: dados[m.chave] as num?),
      ],
    );
  }
}

class _Macro {
  final String chave;
  final String rotulo;
  final String unidade;
  final Color cor;
  const _Macro(this.chave, this.rotulo, this.unidade, this.cor);
}

class _LinhaMacro extends StatelessWidget {
  final _Macro macro;
  final num? valor;
  const _LinhaMacro({required this.macro, required this.valor});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final valorFmt = valor == null
        ? '—'
        : (valor is int || valor == valor!.toInt()
            ? valor!.toInt().toString()
            : valor!.toStringAsFixed(1).replaceAll('.', ','));
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 32,
            decoration: BoxDecoration(
              color: valor == null
                  ? scheme.onSurface.withValues(alpha: 0.15)
                  : macro.cor,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(macro.rotulo,
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface)),
          ),
          Text(
            valor == null ? '—' : '$valorFmt ${macro.unidade}',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: valor == null
                    ? scheme.onSurface.withValues(alpha: 0.4)
                    : scheme.onSurface),
          ),
        ],
      ),
    );
  }
}

class _AvisoLegal extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(RecorpoSpacing.md),
      decoration: BoxDecoration(
        color: RecorpoColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(RecorpoSpacing.radiusSm),
        border: Border.all(
          color: RecorpoColors.primary.withValues(alpha: 0.28),
        ),
      ),
      child: const Text(
        'Leitura automática do rótulo. Confira os valores no produto '
        'antes de decisões nutricionais.',
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
            mensagem ?? 'IA de rótulo ainda não ativada.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
