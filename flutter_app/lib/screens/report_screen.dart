import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/patient_profile.dart';
import '../services/auth_service.dart';
import '../services/report_pdf_service.dart';
import '../utils/constants.dart';

/// Tela do Relatório do Paciente (Lote 13).
///
/// Carrega os dados via `GET /api/lgpd/exportar` (fonte única já usada
/// para portabilidade LGPD) + eixo do shared_preferences, gera o PDF via
/// [ReportPdfService] e mostra em preview interativo com opções nativas
/// de compartilhar/imprimir (no Android abre a folha de compartilhamento;
/// no web faz download).
class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final _service = const ReportPdfService();
  Uint8List? _pdfBytes;
  String? _erro;
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _gerar();
  }

  Future<void> _gerar() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final auth = context.read<AuthService>();
      final prefs = await SharedPreferences.getInstance();
      final nomeEixo = prefs.getString(ProfilePrefsKeys.eixoFarmacologico);
      final eixo = nomeEixo == null
          ? null
          : EixoFarmacologico.values
              .cast<EixoFarmacologico?>()
              .firstWhere((v) => v?.name == nomeEixo, orElse: () => null);

      final exportacao = await auth.apiService.exportarDados();
      final bytes = await _service.gerar(
        exportacao: exportacao,
        eixoLocal: eixo,
      );
      if (!mounted) return;
      setState(() {
        _pdfBytes = bytes;
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
      appBar: AppBar(
        title: const Text('Relatório para o médico'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Regerar',
            onPressed: _carregando ? null : _gerar,
          ),
        ],
      ),
      body: _erro != null
          ? _Erro(mensagem: _erro!, onTentar: _gerar)
          : _pdfBytes == null
              ? const Center(child: CircularProgressIndicator())
              : PdfPreview(
                  build: (format) async => _pdfBytes!,
                  allowPrinting: true,
                  allowSharing: true,
                  canChangeOrientation: false,
                  canChangePageFormat: false,
                  canDebug: false,
                  pdfFileName: 'recorpo-relatorio.pdf',
                  actionBarTheme: const PdfActionBarTheme(
                    backgroundColor: AppColors.azulClinico,
                    iconColor: Colors.white,
                    textStyle: TextStyle(color: Colors.white),
                  ),
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
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.picture_as_pdf,
              size: 48, color: AppColors.vermelhoAlerta),
          const SizedBox(height: 12),
          Text(
            'Não foi possível gerar o relatório.',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(mensagem,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onTentar,
            icon: const Icon(Icons.refresh),
            label: const Text('Tentar de novo'),
          ),
        ],
      ),
    );
  }
}
