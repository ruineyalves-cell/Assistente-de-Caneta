import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/patient_profile.dart';

/// Gera o "Relatório do Paciente" em PDF (Lote 13). Consome dados que a
/// tela `ReportScreen` já buscou (perfil do backend + logs + scores +
/// eixo local do shared_preferences) e devolve o bytes do PDF pronto
/// para preview/compartilhar via `printing`.
///
/// Sem chamada de rede aqui — o serviço é puro (facilita teste e uso
/// offline caso os dados venham em cache).
class ReportPdfService {
  const ReportPdfService();

  Future<Uint8List> gerar({
    required Map<String, dynamic> exportacao,
    required EixoFarmacologico? eixoLocal,
  }) async {
    final doc = pw.Document();
    final agora = DateTime.now();
    final fmtData = DateFormat('dd/MM/yyyy', 'pt_BR');
    final fmtDataHora = DateFormat('dd/MM/yyyy HH:mm', 'pt_BR');

    final usuario = _asMap(exportacao['usuario']);
    final perfil = _asMap(exportacao['perfil']);
    final logs = _asList(exportacao['registrosDiarios']);
    final scores = _asList(exportacao['scores']);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        header: (ctx) => _cabecalho(fmtDataHora.format(agora)),
        footer: (ctx) => _rodape(ctx),
        build: (ctx) => [
          _secao('Identificação', [
            _linha('Nome', usuario['nome']?.toString() ?? '—'),
            _linha('E-mail', usuario['email']?.toString() ?? '—'),
            _linha('ID interno', usuario['id']?.toString() ?? '—'),
            if (usuario['criado_em'] != null)
              _linha(
                  'Cadastro',
                  _fmtDataIso(usuario['criado_em']?.toString(), fmtData) ??
                      '—'),
          ]),
          _secao('Perfil clínico', [
            _linha('Eixo farmacológico',
                eixoLocal?.label ?? 'Não configurado'),
            _linha('Peso registrado',
                _valOr(perfil['pesoInicialKg'], 'kg', fracao: 1)),
            _linha('Altura', _valOr(perfil['alturaCm'], 'cm', fracao: 0)),
            _linha('Meta de proteína',
                _valOr(perfil['metaProteinaGkg'], 'g/kg/dia', fracao: 2)),
            _linha(
                'Meta de hidratação',
                _valOr(perfil['metaAguaMlKg'], 'ml/kg/dia',
                    fracao: 0)),
            _linha(
                'Medicação declarada',
                _asMap(perfil['medicacao'])['nome']?.toString() ??
                    'Nenhuma'),
            _linha('Dose atual', perfil['doseAtual']?.toString() ?? '—'),
          ]),
          _secaoLogs('Últimos registros (até 14 dias)', logs, fmtData),
          _secaoScores('Scores (últimos 28 dias)', scores, fmtData),
          pw.SizedBox(height: 12),
          _disclaimer(),
        ],
      ),
    );

    return doc.save();
  }

  // ---------- helpers estruturais ----------

  pw.Widget _cabecalho(String dataHora) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 12),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Recorpo — Relatório do Paciente',
                  style: pw.TextStyle(
                      fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.Text('Emitido em $dataHora',
                  style: const pw.TextStyle(fontSize: 9)),
            ],
          ),
          pw.Divider(thickness: 0.5),
        ],
      ),
    );
  }

  pw.Widget _rodape(pw.Context ctx) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 8),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('Recorpo · Assistente de Caneta · v0.1.0',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey)),
          pw.Text('Página ${ctx.pageNumber}/${ctx.pagesCount}',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey)),
        ],
      ),
    );
  }

  pw.Widget _secao(String titulo, List<pw.Widget> filhos) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(titulo,
              style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue800)),
          pw.SizedBox(height: 4),
          pw.Container(height: 0.5, color: PdfColors.grey400),
          pw.SizedBox(height: 6),
          ...filhos,
        ],
      ),
    );
  }

  pw.Widget _linha(String rotulo, String valor) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 140,
            child: pw.Text(rotulo,
                style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
          ),
          pw.Expanded(
            child: pw.Text(valor, style: const pw.TextStyle(fontSize: 10)),
          ),
        ],
      ),
    );
  }

  pw.Widget _secaoLogs(
      String titulo, List<dynamic> logs, DateFormat fmt) {
    if (logs.isEmpty) {
      return _secao(titulo, [
        pw.Text('Sem registros no período.',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
      ]);
    }
    final ultimos = logs.take(14).toList();
    return _secao(titulo, [
      pw.TableHelper.fromTextArray(
        border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
        headerDecoration:
            const pw.BoxDecoration(color: PdfColors.blue50),
        headerStyle: pw.TextStyle(
            fontSize: 9, fontWeight: pw.FontWeight.bold),
        cellStyle: const pw.TextStyle(fontSize: 9),
        cellAlignment: pw.Alignment.centerLeft,
        headers: const ['Data', 'Peso (kg)', 'Proteína (g)', 'Água (ml)'],
        data: ultimos.map((log) {
          final m = _asMap(log);
          return [
            _fmtDataIso(m['data']?.toString(), fmt) ?? '—',
            _num(m['pesoKg'], fracao: 1),
            _num(m['proteinaG'], fracao: 0),
            _num(m['aguaMl'], fracao: 0),
          ];
        }).toList(),
      ),
    ]);
  }

  pw.Widget _secaoScores(
      String titulo, List<dynamic> scores, DateFormat fmt) {
    if (scores.isEmpty) {
      return _secao(titulo, [
        pw.Text('Sem scores no período.',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
      ]);
    }
    final ultimos = scores.take(28).toList();
    final valores = ultimos
        .map((s) => (_asMap(s)['score'] as num?)?.toInt() ?? 0)
        .toList();
    final maximo = valores.reduce((a, b) => a > b ? a : b);
    final minimo = valores.reduce((a, b) => a < b ? a : b);
    final media = valores.reduce((a, b) => a + b) / valores.length;

    return _secao(titulo, [
      pw.Row(
        children: [
          pw.Expanded(child: _kpi('Mínimo', '$minimo%')),
          pw.Expanded(child: _kpi('Máximo', '$maximo%')),
          pw.Expanded(
              child: _kpi('Média', '${media.toStringAsFixed(1)}%')),
          pw.Expanded(child: _kpi('Dias', '${valores.length}')),
        ],
      ),
    ]);
  }

  pw.Widget _kpi(String rotulo, String valor) {
    return pw.Column(
      children: [
        pw.Text(valor,
            style: pw.TextStyle(
                fontSize: 14, fontWeight: pw.FontWeight.bold)),
        pw.Text(rotulo,
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
      ],
    );
  }

  pw.Widget _disclaimer() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.red50,
        border: pw.Border.all(color: PdfColors.red200, width: 0.5),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Text(
        'Este relatório é uma exportação educacional dos registros de '
        'conformidade do paciente. Ele NÃO substitui avaliação clínica, '
        'exames laboratoriais nem prescrição médica. Dados sensíveis são '
        'armazenados com criptografia (LGPD). O médico é responsável '
        'pela interpretação e decisão terapêutica.',
        style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.red900),
      ),
    );
  }

  // ---------- coerção / formatação ----------

  Map<String, dynamic> _asMap(dynamic v) =>
      v is Map<String, dynamic> ? v : const {};

  List<dynamic> _asList(dynamic v) => v is List ? v : const [];

  String _valOr(dynamic v, String unidade, {required int fracao}) {
    if (v == null) return '—';
    if (v is num) return '${v.toStringAsFixed(fracao)} $unidade';
    return v.toString();
  }

  String _num(dynamic v, {required int fracao}) {
    if (v == null) return '—';
    if (v is num) return v.toStringAsFixed(fracao);
    return v.toString();
  }

  String? _fmtDataIso(String? iso, DateFormat fmt) {
    if (iso == null) return null;
    final dt = DateTime.tryParse(iso);
    return dt == null ? iso : fmt.format(dt);
  }
}
