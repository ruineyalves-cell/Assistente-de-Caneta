import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../utils/constants.dart';

/// Câmera ao vivo para o "Escanear Refeição com IA" (Lote 9).
///
/// Retorna via `Navigator.pop(XFile?)` a foto capturada (null se o
/// usuário fechou sem capturar). Trata os três estados que impedem a
/// captura: web sem câmera, dispositivo sem câmera disponível, e
/// permissão negada.
class CameraScannerScreen extends StatefulWidget {
  const CameraScannerScreen({super.key});

  @override
  State<CameraScannerScreen> createState() => _CameraScannerScreenState();
}

class _CameraScannerScreenState extends State<CameraScannerScreen> {
  CameraController? _controller;
  Future<void>? _initFuture;
  String? _erro;
  bool _capturando = false;

  @override
  void initState() {
    super.initState();
    _initFuture = _iniciar();
  }

  Future<void> _iniciar() async {
    if (kIsWeb) {
      _erro = 'Câmera ao vivo não é suportada no navegador — abra o app '
          'no Android para escanear.';
      return;
    }
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        _erro = 'Nenhuma câmera encontrada no dispositivo.';
        return;
      }
      // Prefere traseira (typical "back" cam) para refeições.
      final camera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      _controller = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
      );
      await _controller!.initialize();
    } on CameraException catch (e) {
      _erro = e.code == 'CameraAccessDenied'
          ? 'Permissão de câmera negada. Ative nas configurações do app.'
          : 'Falha ao abrir a câmera: ${e.description ?? e.code}';
    } catch (e) {
      _erro = 'Falha ao abrir a câmera: $e';
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _capturar() async {
    final c = _controller;
    if (c == null || !c.value.isInitialized || _capturando) return;
    setState(() => _capturando = true);
    try {
      final foto = await c.takePicture();
      if (!mounted) return;
      Navigator.of(context).pop(foto);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível capturar: $e')),
      );
    } finally {
      if (mounted) setState(() => _capturando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Escanear refeição'),
      ),
      body: FutureBuilder<void>(
        future: _initFuture,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(
                child: CircularProgressIndicator(color: Colors.white));
          }
          if (_erro != null) {
            return _MensagemErro(mensagem: _erro!);
          }
          final c = _controller;
          if (c == null || !c.value.isInitialized) {
            return _MensagemErro(
                mensagem: 'Câmera não pôde ser preparada.');
          }
          return Column(
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Center(
                      child: AspectRatio(
                        aspectRatio: c.value.aspectRatio,
                        child: CameraPreview(c),
                      ),
                    ),
                    // Guia visual centralizada — só decoração para
                    // ajudar o usuário a enquadrar o prato.
                    IgnorePointer(
                      child: Center(
                        child: Container(
                          width: 260,
                          height: 260,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.6),
                                width: 2),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              _BarraCaptura(
                capturando: _capturando,
                onCapturar: _capturar,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _BarraCaptura extends StatelessWidget {
  final bool capturando;
  final VoidCallback onCapturar;
  const _BarraCaptura({required this.capturando, required this.onCapturar});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        color: Colors.black,
        child: Column(
          children: [
            const Text(
              'Enquadre a refeição dentro do quadro e toque para capturar.',
              style: TextStyle(color: Colors.white70, fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: capturando ? null : onCapturar,
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: capturando
                      ? AppColors.azulClinico.withValues(alpha: 0.5)
                      : AppColors.azulClinico,
                  border: Border.all(color: Colors.white, width: 4),
                ),
                child: capturando
                    ? const Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                      )
                    : const Icon(Icons.camera_alt,
                        color: Colors.white, size: 32),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MensagemErro extends StatelessWidget {
  final String mensagem;
  const _MensagemErro({required this.mensagem});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.no_photography,
                size: 48, color: Colors.white70),
            const SizedBox(height: 12),
            Text(
              mensagem,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close),
              label: const Text('Voltar'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white54),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
