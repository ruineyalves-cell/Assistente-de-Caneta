import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/prescription_ocr_service.dart';
import '../utils/constants.dart';

/// Tela do OCR de prescrição (Lote 10). Deixa o usuário escolher entre
/// tirar foto ou usar imagem da galeria e roda o Google ML Kit
/// on-device para extrair texto + destacar metas nutricionais.
class DietScannerScreen extends StatefulWidget {
  const DietScannerScreen({super.key});

  @override
  State<DietScannerScreen> createState() => _DietScannerScreenState();
}

class _DietScannerScreenState extends State<DietScannerScreen> {
  final _picker = ImagePicker();
  final _service = PrescriptionOcrService();
  OcrPrescricaoResultado? _resultado;
  String? _erro;
  bool _rodando = false;

  @override
  void dispose() {
    _service.fechar();
    super.dispose();
  }

  Future<void> _abrirCamera() => _executar(ImageSource.camera);
  Future<void> _abrirGaleria() => _executar(ImageSource.gallery);

  Future<void> _executar(ImageSource source) async {
    if (kIsWeb && source == ImageSource.camera) {
      setState(() => _erro =
          'Câmera não é suportada no navegador — use a galeria ou abra '
          'o app no Android.');
      return;
    }
    setState(() {
      _rodando = true;
      _erro = null;
    });
    try {
      final foto = await _picker.pickImage(
        source: source,
        maxWidth: 2000,
      );
      if (foto == null) {
        setState(() => _rodando = false);
        return;
      }
      final res = await _service.lerCaminho(foto.path);
      if (!mounted) return;
      setState(() {
        _resultado = res;
        _rodando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _erro = e.toString();
        _rodando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Escanear prescrição')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _Explicacao(),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _rodando ? null : _abrirCamera,
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: const Text('Foto'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.azulClinico,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _rodando ? null : _abrirGaleria,
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Galeria'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.azulClinico,
                      side: const BorderSide(
                          color: AppColors.azulClinico, width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_rodando)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              ),
            if (_erro != null) _CaixaErro(mensagem: _erro!),
            if (_resultado != null) ...[
              _MetasDestacadas(metas: _resultado!.metas),
              const SizedBox(height: 16),
              _TextoBruto(texto: _resultado!.textoCompleto),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _Explicacao extends StatelessWidget {
  const _Explicacao();

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: AppColors.azulClinico.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
            color: AppColors.azulClinico.withValues(alpha: 0.3)),
      ),
      child: const Padding(
        padding: EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline,
                color: AppColors.azulClinico, size: 20),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Fotografe (ou selecione) uma prescrição nutricional. '
                'A leitura acontece no seu aparelho, sem enviar a imagem '
                'para servidores. Metas prováveis são destacadas — '
                'confirme sempre com quem prescreveu.',
                style: TextStyle(fontSize: 12, height: 1.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetasDestacadas extends StatelessWidget {
  final List<MetaDetectada> metas;
  const _MetasDestacadas({required this.metas});

  @override
  Widget build(BuildContext context) {
    if (metas.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              const Icon(Icons.search_off, color: Colors.grey),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Nenhuma meta nutricional identificada automaticamente. '
                  'Confira o texto reconhecido abaixo.',
                  style: TextStyle(
                      fontSize: 12, color: Colors.grey.shade700),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.flag_outlined,
                    color: AppColors.verdeConfirma, size: 20),
                const SizedBox(width: 8),
                Text('Metas detectadas',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        )),
              ],
            ),
            const SizedBox(height: 8),
            ...metas.map((m) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.verdeConfirma
                              .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(m.categoria,
                            style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.verdeConfirma)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          m.trecho,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

class _TextoBruto extends StatelessWidget {
  final String texto;
  const _TextoBruto({required this.texto});

  @override
  Widget build(BuildContext context) {
    if (texto.trim().isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Text(
            'Nenhum texto reconhecido — tente outra foto ou verifique '
            'iluminação/foco.',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
          ),
        ),
      );
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.text_snippet_outlined,
                    color: Colors.grey, size: 20),
                const SizedBox(width: 8),
                Text('Texto reconhecido',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        )),
              ],
            ),
            const SizedBox(height: 8),
            SelectableText(
              texto,
              style: const TextStyle(fontSize: 13, height: 1.45),
            ),
          ],
        ),
      ),
    );
  }
}

class _CaixaErro extends StatelessWidget {
  final String mensagem;
  const _CaixaErro({required this.mensagem});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.vermelhoAlerta.withValues(alpha: 0.08),
        border: Border.all(color: AppColors.vermelhoAlerta),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline,
              color: AppColors.vermelhoAlerta),
          const SizedBox(width: 8),
          Expanded(
              child: Text(mensagem,
                  style: const TextStyle(fontSize: 12))),
        ],
      ),
    );
  }
}
