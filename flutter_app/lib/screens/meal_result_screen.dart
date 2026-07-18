import 'dart:io';
import 'package:camera/camera.dart' show XFile;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/logs_provider.dart';
import '../services/meal_recognition_service.dart';
import '../utils/constants.dart';

/// Lote 21 — Tela de resultado da IA de refeição.
///
/// Fluxo:
///   1) Recebe a foto capturada pela CameraScannerScreen.
///   2) Roda ML Kit LOCAL na hora (rápido, roda sem chave) e mostra
///      labels de comida.
///   3) EM PARALELO, chama /api/ia/refeicao. Se o backend estiver
///      configurado (Gemini/OpenAI), mostra título, descrição e
///      estimativa de proteína/água. Se não, deixa só o local.
///   4) Usuário confirma → registra em daily_log via LogsProvider.
class MealResultScreen extends StatefulWidget {
  final XFile foto;
  const MealResultScreen({super.key, required this.foto});

  @override
  State<MealResultScreen> createState() => _MealResultScreenState();
}

class _MealResultScreenState extends State<MealResultScreen> {
  List<MealLabel>? _labelsLocais;
  MealAiResult? _resultadoBackend;
  bool _rodandoLocal = true;
  bool _rodandoBackend = true;
  String? _erroLocal;
  String? _erroBackend;

  int? _proteinaG;
  int? _aguaMl;
  final _tituloCtrl = TextEditingController();
  bool _registrando = false;

  @override
  void initState() {
    super.initState();
    _analisar();
  }

  @override
  void dispose() {
    _tituloCtrl.dispose();
    super.dispose();
  }

  Future<void> _analisar() async {
    final api = context.read<AuthService>().apiService;
    final servico = MealRecognitionService(api);
    final arquivo = File(widget.foto.path);

    // Local (rápido)
    () async {
      try {
        final locais = await servico.reconhecerLocal(arquivo);
        if (!mounted) return;
        setState(() {
          _labelsLocais = locais;
          _rodandoLocal = false;
          if (_tituloCtrl.text.isEmpty && locais.isNotEmpty) {
            _tituloCtrl.text = locais.first.labelPtBr;
          }
        });
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _erroLocal = e.toString();
          _rodandoLocal = false;
        });
      }
    }();

    // Backend (paralelo)
    () async {
      try {
        final res = await servico.analisarNoBackend(arquivo);
        if (!mounted) return;
        setState(() {
          _resultadoBackend = res;
          _rodandoBackend = false;
          if (res != null) {
            if (res.titulo != null && res.titulo!.isNotEmpty) {
              _tituloCtrl.text = res.titulo!;
            }
            _proteinaG ??= res.proteinaEstimadaG;
            _aguaMl ??= res.aguaEstimadaMl;
          }
        });
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _erroBackend = e.toString();
          _rodandoBackend = false;
        });
      }
    }();
  }

  Future<void> _registrar() async {
    setState(() => _registrando = true);
    try {
      final logs = context.read<LogsProvider>();
      await logs.adicionarLog(
        data: DateTime.now(),
        alimentos:
            _tituloCtrl.text.trim().isEmpty ? null : _tituloCtrl.text.trim(),
        proteinaG: _proteinaG,
        aguaMl: _aguaMl,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Refeição registrada. Bom apetite!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível registrar: $e')),
      );
    } finally {
      if (mounted) setState(() => _registrando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('O que tem no prato?')),
      backgroundColor: AppColors.fundoFrio,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(File(widget.foto.path)),
              ),
              const SizedBox(height: 16),
              _cardLocal(),
              const SizedBox(height: 12),
              _cardBackend(),
              const SizedBox(height: 16),
              _cardFormulario(),
              const SizedBox(height: 20),
              SizedBox(
                height: 52,
                child: FilledButton.icon(
                  onPressed: _registrando ? null : _registrar,
                  icon: const Icon(Icons.check),
                  label: const Text('Registrar refeição'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.verdeConfirma,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cardLocal() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.phone_android, color: AppColors.azulClinico),
                const SizedBox(width: 8),
                const Text('Reconhecimento no aparelho',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const Spacer(),
                if (_rodandoLocal)
                  const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2)),
              ],
            ),
            const SizedBox(height: 8),
            if (_erroLocal != null)
              Text('Falhou: $_erroLocal',
                  style: const TextStyle(fontSize: 12, color: Colors.redAccent))
            else if (_labelsLocais != null && _labelsLocais!.isEmpty)
              Text('Não identifiquei elementos claros de comida.',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700))
            else if (_labelsLocais != null)
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: _labelsLocais!
                    .map((l) => Chip(
                          label: Text(
                              '${l.labelPtBr}  ${(l.confidence * 100).round()}%'),
                        ))
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _cardBackend() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome, color: AppColors.verdeConfirma),
                const SizedBox(width: 8),
                const Text('Análise IA detalhada',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const Spacer(),
                if (_rodandoBackend)
                  const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2)),
              ],
            ),
            const SizedBox(height: 8),
            if (_erroBackend != null)
              Text('Falhou: $_erroBackend',
                  style: const TextStyle(fontSize: 12, color: Colors.redAccent))
            else if (_resultadoBackend == null && !_rodandoBackend)
              Text(
                'IA detalhada ainda não ativada no servidor — sem custo você fica com o reconhecimento local acima.',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
              )
            else if (_resultadoBackend != null) ...[
              if (_resultadoBackend!.titulo != null)
                Text(_resultadoBackend!.titulo!,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700)),
              if (_resultadoBackend!.descricao != null) ...[
                const SizedBox(height: 4),
                Text(_resultadoBackend!.descricao!,
                    style: const TextStyle(fontSize: 13, height: 1.4)),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  if (_resultadoBackend!.proteinaEstimadaG != null)
                    _chipEst('Proteína',
                        '${_resultadoBackend!.proteinaEstimadaG}g'),
                  const SizedBox(width: 8),
                  if (_resultadoBackend!.aguaEstimadaMl != null &&
                      _resultadoBackend!.aguaEstimadaMl! > 0)
                    _chipEst('Bebida', '${_resultadoBackend!.aguaEstimadaMl}ml'),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _chipEst(String rotulo, String valor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.azulClinico.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text('$rotulo: $valor',
          style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.azulClinico)),
    );
  }

  Widget _cardFormulario() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Editar antes de registrar',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            TextField(
              controller: _tituloCtrl,
              decoration: const InputDecoration(
                labelText: 'Descrição da refeição',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: _proteinaG?.toString(),
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Proteína (g)',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) => _proteinaG = int.tryParse(v),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    initialValue: _aguaMl?.toString(),
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Bebida (ml)',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) => _aguaMl = int.tryParse(v),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
