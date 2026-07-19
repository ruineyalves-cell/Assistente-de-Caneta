import 'dart:convert';
import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/patient_profile.dart';
import '../models/symptom.dart';

/// Relatório do Paciente (Lote 13 → Lote 28).
///
/// Lote 28 enriqueceu o relatório com o que endócrino/nutricionista
/// realmente lê primeiro num paciente GLP-1:
///   • Sumário executivo (1 parágrafo de status)
///   • IMC + variação de peso + kg/semana
///   • Adesão (% dias com registro)
///   • Regularidade da aplicação da dose (Ozempic/Wegovy = 7 dias)
///   • Alertas graves em destaque (febre, vômito ≥3, hipoglicemia)
///   • Padrão temporal dos sintomas
///   • Metas atingidas por dia (proteína/água)
///   • Referências no rodapé de cada seção clínica
///
/// Também removidos emojis Unicode (fonte default do pacote pdf não
/// renderiza — aparecia "X" em quadrado) e corrigidas colunas com
/// valores nulos.
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

    // Métricas derivadas (usadas em várias seções — computa uma vez).
    final entriesSintomas = _extrairSintomas(logs);
    final resumoPeso = _analisarPeso(logs, perfil);
    final adesao = _analisarAdesao(logs, dias: 14);
    final doseInfo = _analisarDose(logs, perfil);
    final alertasGraves = _detectarAlertasGraves(entriesSintomas);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        header: (ctx) => _cabecalho(fmtDataHora.format(agora)),
        footer: (ctx) => _rodape(ctx),
        build: (ctx) => [
          // 1. Sumário executivo — o que o médico lê primeiro
          _sumarioExecutivo(usuario, perfil, eixoLocal, resumoPeso,
              adesao, entriesSintomas, doseInfo),
          pw.SizedBox(height: 8),

          // 2. Alertas graves em destaque (se houver)
          if (alertasGraves.isNotEmpty) _alertasGravesBox(alertasGraves),

          // 3. Identificação (compacta)
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

          // 4. Perfil clínico + IMC calculado
          _secaoPerfilClinico(perfil, eixoLocal, resumoPeso),

          // 5. Evolução de peso (novo — específico)
          _secaoEvolucaoPeso(resumoPeso, fmtData),

          // 6. Aplicação da dose (novo — crítico em GLP-1)
          _secaoDose(doseInfo, fmtData),

          // 7. Adesão (novo)
          _secaoAdesao(adesao),

          // 8. Registros diários
          _secaoLogs('Registros diários (últimos 14 dias)', logs, fmtData),

          // 9. Farmacovigilância (enriquecida com padrão temporal)
          _secaoFarmacovigilancia(entriesSintomas, fmtData),

          // 10. Scores
          _secaoScores('Índice de conformidade (28 dias)', scores),

          pw.SizedBox(height: 12),
          _disclaimer(),
        ],
      ),
    );

    return doc.save();
  }

  // ============================================================================
  // 1. SUMÁRIO EXECUTIVO
  // ============================================================================
  pw.Widget _sumarioExecutivo(
    Map<String, dynamic> usuario,
    Map<String, dynamic> perfil,
    EixoFarmacologico? eixo,
    ResumoPeso peso,
    ResumoAdesao adesao,
    List<SymptomEntry> sintomas,
    ResumoDose dose,
  ) {
    final nome = (usuario['nome']?.toString() ?? 'Paciente').trim();
    final idade = _calcIdade(usuario['data_nascimento']?.toString());
    final med = _asMap(perfil['medicacao'])['nome']?.toString();
    final doseAtual = perfil['doseAtual']?.toString();

    final partes = <String>[];
    partes.add(nome);
    if (idade != null) partes.add('$idade anos');
    if (med != null && doseAtual != null) partes.add('em $med $doseAtual');
    if (eixo != null) partes.add('eixo ${eixo.label}');

    final linha1 = partes.join(' · ');

    final linha2 = <String>[];
    if (peso.pesoAtualKg != null && peso.imcAtual != null) {
      linha2.add(
          'peso ${peso.pesoAtualKg!.toStringAsFixed(1)}kg (IMC ${peso.imcAtual!.toStringAsFixed(1)})');
    }
    if (peso.variacaoTotalKg != null) {
      final sinal = peso.variacaoTotalKg! < 0 ? '' : '+';
      linha2.add(
          'variação $sinal${peso.variacaoTotalKg!.toStringAsFixed(1)}kg no período');
    }
    if (adesao.diasComRegistro > 0) {
      linha2.add(
          'adesão ${adesao.diasComRegistro}/${adesao.diasDoPeriodo} dias (${adesao.percentual.toStringAsFixed(0)}%)');
    }
    if (sintomas.isNotEmpty) {
      final moderadosOuMais = sintomas
          .where((s) => s.intensidade.valor >= 2)
          .length;
      linha2.add(
          '${sintomas.length} sintomas ($moderadosOuMais moderados/intensos)');
    }
    if (dose.diasDesdeUltima != null && dose.diasDesdeUltima! > 0) {
      linha2.add('última aplicação há ${dose.diasDesdeUltima}d');
    }

    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: PdfColors.blue200, width: 0.5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Sumário executivo',
              style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue800)),
          pw.SizedBox(height: 6),
          pw.Text(linha1,
              style: pw.TextStyle(
                  fontSize: 12, fontWeight: pw.FontWeight.bold)),
          if (linha2.isNotEmpty) ...[
            pw.SizedBox(height: 4),
            pw.Text(linha2.join(' · '),
                style: const pw.TextStyle(fontSize: 10, height: 1.35)),
          ],
        ],
      ),
    );
  }

  // ============================================================================
  // 2. ALERTAS GRAVES (box vermelho)
  // ============================================================================
  pw.Widget _alertasGravesBox(List<SymptomEntry> alertas) {
    final resumo = <SymptomType, int>{};
    for (final a in alertas) {
      resumo[a.tipo] = (resumo[a.tipo] ?? 0) + 1;
    }
    final linhas = resumo.entries
        .map((e) => '- ${infoDe(e.key).rotulo} (${e.value} ocorrência${e.value == 1 ? '' : 's'} em intensidade elevada)')
        .join('\n');
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 10),
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.red50,
        borderRadius: pw.BorderRadius.circular(4),
        border: pw.Border.all(color: PdfColors.red400, width: 1),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('ATENÇÃO CLÍNICA',
              style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.red900)),
          pw.SizedBox(height: 4),
          pw.Text(
            'Sintomas com sinal de alerta reportados no período:',
            style: const pw.TextStyle(fontSize: 9),
          ),
          pw.SizedBox(height: 3),
          pw.Text(linhas, style: const pw.TextStyle(fontSize: 9, height: 1.4)),
          pw.SizedBox(height: 4),
          pw.Text(
            'Referências: Bulas Ozempic, Mounjaro e Wegovy (Anvisa 2024).',
            style: pw.TextStyle(
                fontSize: 8,
                color: PdfColors.red800,
                fontStyle: pw.FontStyle.italic),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // 3. PERFIL CLÍNICO (+ IMC calculado)
  // ============================================================================
  pw.Widget _secaoPerfilClinico(Map<String, dynamic> perfil,
      EixoFarmacologico? eixo, ResumoPeso peso) {
    final altura = (perfil['alturaCm'] as num?)?.toDouble();
    return _secao('Perfil clínico', [
      _linha('Eixo farmacológico', eixo?.label ?? 'Não configurado'),
      _linha('Peso inicial',
          _valOr(perfil['pesoInicialKg'], 'kg', fracao: 1)),
      _linha('Altura', _valOr(altura, 'cm', fracao: 0)),
      if (peso.imcAtual != null)
        _linha('IMC atual',
            '${peso.imcAtual!.toStringAsFixed(1)}  (${_classificarImc(peso.imcAtual!)})'),
      _linha('Meta de proteína',
          _valOr(perfil['metaProteinaGkg'], 'g/kg/dia', fracao: 2)),
      _linha('Meta de hidratação',
          _valOr(perfil['metaAguaMlKg'], 'ml/kg/dia', fracao: 0)),
      _linha(
          'Medicação declarada',
          _asMap(perfil['medicacao'])['nome']?.toString() ?? 'Nenhuma'),
      _linha('Dose atual', perfil['doseAtual']?.toString() ?? '—'),
      pw.SizedBox(height: 3),
      _fonteReferencia(
          'ABESO 2023; classificação IMC OMS; posologia — bula do fabricante (Anvisa).'),
    ]);
  }

  // ============================================================================
  // 4. EVOLUÇÃO DE PESO
  // ============================================================================
  pw.Widget _secaoEvolucaoPeso(ResumoPeso p, DateFormat fmt) {
    return _secao('Evolução de peso', [
      pw.Row(
        children: [
          pw.Expanded(
              child: _kpi(
                  'Inicial',
                  p.pesoInicialKg == null
                      ? '—'
                      : '${p.pesoInicialKg!.toStringAsFixed(1)}kg')),
          pw.Expanded(
              child: _kpi(
                  'Atual',
                  p.pesoAtualKg == null
                      ? '—'
                      : '${p.pesoAtualKg!.toStringAsFixed(1)}kg')),
          pw.Expanded(
              child: _kpi(
                  'Variação',
                  p.variacaoTotalKg == null
                      ? '—'
                      : '${p.variacaoTotalKg! < 0 ? '' : '+'}${p.variacaoTotalKg!.toStringAsFixed(1)}kg')),
          pw.Expanded(
              child: _kpi(
                  'kg/semana',
                  p.kgPorSemana == null
                      ? '—'
                      : '${p.kgPorSemana! < 0 ? '' : '+'}${p.kgPorSemana!.toStringAsFixed(2)}')),
        ],
      ),
      if (p.kgPorSemana != null)
        pw.Padding(
          padding: const pw.EdgeInsets.only(top: 6),
          child: pw.Text(
            _interpretarRitmoEmagrecimento(p.kgPorSemana!),
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800),
          ),
        ),
      pw.SizedBox(height: 3),
      _fonteReferencia(
          'Ritmo saudável de perda de peso: 0,5-1kg/semana (ABESO 2023, ADA 2024). Perda >1kg/semana com GLP-1 merece avaliação nutricional para prevenir perda de massa magra.'),
    ]);
  }

  // ============================================================================
  // 5. APLICAÇÃO DA DOSE
  // ============================================================================
  pw.Widget _secaoDose(ResumoDose dose, DateFormat fmt) {
    final linhas = <pw.Widget>[];
    linhas.add(pw.Row(
      children: [
        pw.Expanded(
            child: _kpi(
                'Aplicações registradas', '${dose.aplicacoesRegistradas}')),
        pw.Expanded(
            child: _kpi(
                'Última aplicação',
                dose.ultimaAplicacao == null
                    ? '—'
                    : fmt.format(dose.ultimaAplicacao!))),
        pw.Expanded(
            child: _kpi(
                'Dias desde a última',
                dose.diasDesdeUltima == null ? '—' : '${dose.diasDesdeUltima}')),
      ],
    ));
    if (dose.intervaloMedioDias != null) {
      linhas.add(pw.SizedBox(height: 6));
      linhas.add(pw.Text(
        'Intervalo médio entre aplicações: ${dose.intervaloMedioDias!.toStringAsFixed(1)} dias.',
        style: const pw.TextStyle(fontSize: 10),
      ));
    }
    if (dose.diasDesdeUltima != null && dose.diasDesdeUltima! > 8) {
      linhas.add(pw.SizedBox(height: 4));
      linhas.add(pw.Container(
        padding: const pw.EdgeInsets.all(6),
        decoration: pw.BoxDecoration(
          color: PdfColors.amber50,
          borderRadius: pw.BorderRadius.circular(3),
          border: pw.Border.all(color: PdfColors.amber300, width: 0.5),
        ),
        child: pw.Text(
          'Última aplicação há mais de 8 dias — verificar aderência ao regime semanal (Ozempic/Mounjaro/Wegovy).',
          style: pw.TextStyle(
              fontSize: 9,
              color: PdfColors.orange900,
              fontStyle: pw.FontStyle.italic),
        ),
      ));
    }
    return _secao('Aplicação da dose', [
      ...linhas,
      pw.SizedBox(height: 3),
      _fonteReferencia(
          'Semaglutida (Ozempic/Wegovy) e tirzepatida (Mounjaro): posologia semanal. Liraglutida (Saxenda): diária. Fonte: bulas Anvisa.'),
    ]);
  }

  // ============================================================================
  // 6. ADESÃO
  // ============================================================================
  pw.Widget _secaoAdesao(ResumoAdesao a) {
    return _secao('Adesão ao acompanhamento (14 dias)', [
      pw.Row(
        children: [
          pw.Expanded(child: _kpi('Dias com registro', '${a.diasComRegistro}')),
          pw.Expanded(child: _kpi('Do período', '${a.diasDoPeriodo}')),
          pw.Expanded(
              child: _kpi('Adesão', '${a.percentual.toStringAsFixed(0)}%')),
          pw.Expanded(
              child:
                  _kpi('Dias sem registro', '${a.diasDoPeriodo - a.diasComRegistro}')),
        ],
      ),
      if (a.metaProteinaAtingidaDias != null)
        pw.Padding(
          padding: const pw.EdgeInsets.only(top: 6),
          child: pw.Text(
            'Meta de proteína atingida em ${a.metaProteinaAtingidaDias!}/${a.diasComRegistro} dias com registro. '
            'Meta de água atingida em ${a.metaAguaAtingidaDias!}/${a.diasComRegistro} dias.',
            style: const pw.TextStyle(fontSize: 10),
          ),
        ),
    ]);
  }

  // ============================================================================
  // 7. LOGS DIÁRIOS
  // ============================================================================
  pw.Widget _secaoLogs(String titulo, List<dynamic> logs, DateFormat fmt) {
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
        headerDecoration: const pw.BoxDecoration(color: PdfColors.blue50),
        headerStyle: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
        cellStyle: const pw.TextStyle(fontSize: 9),
        cellAlignment: pw.Alignment.centerLeft,
        headers: const [
          'Data',
          'Peso (kg)',
          'Proteína (g)',
          'Água (ml)',
          'Dose'
        ],
        data: ultimos.map((log) {
          final m = _asMap(log);
          return [
            _fmtDataIso(m['data']?.toString(), fmt) ?? '—',
            _num(m['pesoKg'], fracao: 1),
            _num(m['proteinaG'], fracao: 0),
            _num(m['aguaMl'], fracao: 0),
            (m['doseAplicada'] == true) ? 'Sim' : '—',
          ];
        }).toList(),
      ),
    ]);
  }

  // ============================================================================
  // 8. FARMACOVIGILÂNCIA (enriquecida com padrão temporal)
  // ============================================================================
  pw.Widget _secaoFarmacovigilancia(
      List<SymptomEntry> entries, DateFormat fmt) {
    if (entries.isEmpty) {
      return _secao('Farmacovigilância (últimos 14 dias)', [
        pw.Text('Nenhum sintoma registrado no período.',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
      ]);
    }
    entries.sort((a, b) => b.quando.compareTo(a.quando));

    // Sumário por tipo
    final resumoPorTipo = <SymptomType, ({int contagem, int maxInt})>{};
    for (final e in entries) {
      final atual = resumoPorTipo[e.tipo];
      if (atual == null) {
        resumoPorTipo[e.tipo] =
            (contagem: 1, maxInt: e.intensidade.valor);
      } else {
        resumoPorTipo[e.tipo] = (
          contagem: atual.contagem + 1,
          maxInt: atual.maxInt > e.intensidade.valor
              ? atual.maxInt
              : e.intensidade.valor,
        );
      }
    }
    final linhasResumo = resumoPorTipo.entries.toList()
      ..sort((a, b) => b.value.contagem.compareTo(a.value.contagem));

    // Padrão temporal por hora do dia (bucket 3 em 3h)
    final buckets = <String, int>{
      '00-06': 0,
      '06-12': 0,
      '12-18': 0,
      '18-24': 0,
    };
    for (final e in entries) {
      final h = e.quando.hour;
      if (h < 6) {
        buckets['00-06'] = buckets['00-06']! + 1;
      } else if (h < 12) {
        buckets['06-12'] = buckets['06-12']! + 1;
      } else if (h < 18) {
        buckets['12-18'] = buckets['12-18']! + 1;
      } else {
        buckets['18-24'] = buckets['18-24']! + 1;
      }
    }
    final horarioMax =
        buckets.entries.reduce((a, b) => a.value >= b.value ? a : b);

    // Presença de sintomas com bandeira alertaSeIntenso
    final temFlag = entries.any((e) =>
        e.intensidade == SymptomIntensity.intenso &&
        infoDe(e.tipo).alertaSeIntenso);

    return _secao('Farmacovigilância (últimos 14 dias)', [
      pw.Text(
        'Sintomas autorreportados pelo paciente. Escala 1 (leve) — 2 (moderado) — 3 (intenso).',
        style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
      ),
      pw.SizedBox(height: 6),
      // KPIs no topo
      pw.Row(
        children: [
          pw.Expanded(child: _kpi('Total', '${entries.length}')),
          pw.Expanded(
              child: _kpi(
                  'Moderados/intensos',
                  '${entries.where((e) => e.intensidade.valor >= 2).length}')),
          pw.Expanded(
              child: _kpi(
                  'Horário mais frequente',
                  '${horarioMax.key}h')),
          pw.Expanded(
              child: _kpi(
                  'Tipos distintos', '${resumoPorTipo.length}')),
        ],
      ),
      pw.SizedBox(height: 8),
      // Tabela resumo
      pw.TableHelper.fromTextArray(
        border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
        headerDecoration:
            const pw.BoxDecoration(color: PdfColors.orange50),
        headerStyle: pw.TextStyle(
            fontSize: 9,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.orange900),
        cellStyle: const pw.TextStyle(fontSize: 9),
        headers: const [
          'Sintoma',
          'Ocorrências',
          'Intensidade máx.',
          'Sinal de alerta*'
        ],
        data: linhasResumo.map((e) {
          final info = infoDe(e.key);
          return [
            info.rotulo,
            '${e.value.contagem}',
            '${e.value.maxInt}',
            (info.alertaSeIntenso && e.value.maxInt == 3) ? 'Sim' : '—',
          ];
        }).toList(),
      ),
      pw.SizedBox(height: 8),
      pw.Text('Linha do tempo',
          style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey800)),
      pw.SizedBox(height: 4),
      pw.TableHelper.fromTextArray(
        border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
        headerDecoration:
            const pw.BoxDecoration(color: PdfColors.orange50),
        headerStyle: pw.TextStyle(
            fontSize: 9,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.orange900),
        cellStyle: const pw.TextStyle(fontSize: 9),
        headers: const ['Quando', 'Sintoma', 'Intensidade', 'Contexto'],
        data: entries
            .take(40)
            .map((e) => [
                  DateFormat('dd/MM HH:mm', 'pt_BR').format(e.quando),
                  infoDe(e.tipo).rotulo,
                  '${e.intensidade.valor} · ${e.intensidade.label}',
                  (e.contexto == null || e.contexto!.isEmpty)
                      ? '—'
                      : e.contexto!,
                ])
            .toList(),
      ),
      pw.SizedBox(height: 6),
      if (temFlag)
        pw.Text(
          '* Sintomas marcados exigem observação quando persistentes ou intensos.',
          style: pw.TextStyle(
              fontSize: 8,
              color: PdfColors.grey800,
              fontStyle: pw.FontStyle.italic),
        ),
      pw.SizedBox(height: 3),
      _fonteReferencia(
          'Reações adversas listadas conforme bulas Anvisa dos análogos GLP-1 (semaglutida, tirzepatida, liraglutida). Perfil individual pode variar.'),
    ]);
  }

  // ============================================================================
  // 9. SCORES (mesmo, mas título ajustado)
  // ============================================================================
  pw.Widget _secaoScores(String titulo, List<dynamic> scores) {
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
          pw.Expanded(child: _kpi('Média', '${media.toStringAsFixed(1)}%')),
          pw.Expanded(child: _kpi('Dias', '${valores.length}')),
        ],
      ),
      pw.SizedBox(height: 3),
      _fonteReferencia(
          'Índice de conformidade — média ponderada de proteína, hidratação e regularidade de registro (interno Recorpo, não é escala clínica validada).'),
    ]);
  }

  // ============================================================================
  // HELPERS ESTRUTURAIS
  // ============================================================================
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
              style:
                  const pw.TextStyle(fontSize: 8, color: PdfColors.grey)),
          pw.Text('Página ${ctx.pageNumber}/${ctx.pagesCount}',
              style:
                  const pw.TextStyle(fontSize: 8, color: PdfColors.grey)),
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
                style: const pw.TextStyle(
                    fontSize: 10, color: PdfColors.grey700)),
          ),
          pw.Expanded(
            child: pw.Text(valor, style: const pw.TextStyle(fontSize: 10)),
          ),
        ],
      ),
    );
  }

  pw.Widget _kpi(String rotulo, String valor) {
    return pw.Column(
      children: [
        pw.Text(valor,
            style: pw.TextStyle(
                fontSize: 13, fontWeight: pw.FontWeight.bold)),
        pw.Text(rotulo,
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
            textAlign: pw.TextAlign.center),
      ],
    );
  }

  pw.Widget _fonteReferencia(String texto) {
    return pw.Text(
      texto,
      style: pw.TextStyle(
          fontSize: 8,
          fontStyle: pw.FontStyle.italic,
          color: PdfColors.grey700),
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
        'exames laboratoriais nem prescrição médica. Sintomas são '
        'autorreportados. Dados sensíveis são armazenados com criptografia '
        '(LGPD). O médico é responsável pela interpretação e decisão '
        'terapêutica.',
        style:
            const pw.TextStyle(fontSize: 8.5, color: PdfColors.red900),
      ),
    );
  }

  // ============================================================================
  // ANÁLISES (funções puras)
  // ============================================================================

  List<SymptomEntry> _extrairSintomas(List<dynamic> logs) {
    final entries = <SymptomEntry>[];
    for (final log in logs) {
      final l = _asMap(log);
      final efeitos = l['efeitos']?.toString();
      if (efeitos == null || efeitos.isEmpty) continue;
      try {
        final parsed = jsonDecode(efeitos);
        if (parsed is Map && parsed['sintomas'] is List) {
          for (final j in (parsed['sintomas'] as List)) {
            final e = SymptomEntry.fromJson(j as Map<String, dynamic>);
            if (e != null) entries.add(e);
          }
        }
      } catch (_) {}
    }
    return entries;
  }

  List<SymptomEntry> _detectarAlertasGraves(List<SymptomEntry> entries) {
    return entries.where((e) {
      final info = infoDe(e.tipo);
      return e.intensidade == SymptomIntensity.intenso && info.alertaSeIntenso;
    }).toList();
  }

  ResumoPeso _analisarPeso(
      List<dynamic> logs, Map<String, dynamic> perfil) {
    final registros = <(DateTime, double)>[];
    for (final log in logs) {
      final m = _asMap(log);
      final p = (m['pesoKg'] as num?)?.toDouble();
      final iso = m['data']?.toString();
      if (p == null || iso == null) continue;
      final dt = DateTime.tryParse(iso);
      if (dt != null) registros.add((dt, p));
    }
    registros.sort((a, b) => a.$1.compareTo(b.$1));

    final pesoInicial = registros.isNotEmpty
        ? registros.first.$2
        : (perfil['pesoInicialKg'] as num?)?.toDouble();
    final pesoAtual =
        registros.isNotEmpty ? registros.last.$2 : pesoInicial;
    final altura = (perfil['alturaCm'] as num?)?.toDouble();

    double? imcAtual;
    if (pesoAtual != null && altura != null && altura > 0) {
      final m = altura / 100.0;
      imcAtual = pesoAtual / (m * m);
    }

    double? variacaoTotal;
    double? kgPorSemana;
    if (pesoInicial != null && pesoAtual != null) {
      variacaoTotal = pesoAtual - pesoInicial;
      if (registros.length >= 2) {
        final diasEntre =
            registros.last.$1.difference(registros.first.$1).inDays;
        if (diasEntre > 0) {
          kgPorSemana = (variacaoTotal / diasEntre) * 7;
        }
      }
    }

    return ResumoPeso(
      pesoInicialKg: pesoInicial,
      pesoAtualKg: pesoAtual,
      imcAtual: imcAtual,
      variacaoTotalKg: variacaoTotal,
      kgPorSemana: kgPorSemana,
    );
  }

  ResumoAdesao _analisarAdesao(List<dynamic> logs, {required int dias}) {
    final agora = DateTime.now();
    final desde = DateTime(agora.year, agora.month, agora.day)
        .subtract(Duration(days: dias - 1));
    final diasComReg = <String>{};
    var metaProt = 0;
    var metaAgua = 0;
    for (final log in logs) {
      final m = _asMap(log);
      final iso = m['data']?.toString();
      final dt = iso == null ? null : DateTime.tryParse(iso);
      if (dt == null) continue;
      if (dt.isBefore(desde)) continue;
      final chave =
          '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
      diasComReg.add(chave);
      // Heurística simples de "meta": presença de valor não-zero.
      if ((m['proteinaG'] as num?) != null &&
          (m['proteinaG'] as num).toInt() > 0) metaProt++;
      if ((m['aguaMl'] as num?) != null && (m['aguaMl'] as num).toInt() > 0) {
        metaAgua++;
      }
    }
    final pct = dias == 0 ? 0.0 : (diasComReg.length / dias) * 100;
    return ResumoAdesao(
      diasComRegistro: diasComReg.length,
      diasDoPeriodo: dias,
      percentual: pct,
      metaProteinaAtingidaDias: metaProt,
      metaAguaAtingidaDias: metaAgua,
    );
  }

  ResumoDose _analisarDose(
      List<dynamic> logs, Map<String, dynamic> perfil) {
    final aplicacoes = <DateTime>[];
    for (final log in logs) {
      final m = _asMap(log);
      if (m['doseAplicada'] == true) {
        final iso = m['data']?.toString();
        final dt = iso == null ? null : DateTime.tryParse(iso);
        if (dt != null) aplicacoes.add(dt);
      }
    }
    aplicacoes.sort();
    DateTime? ultima = aplicacoes.isEmpty ? null : aplicacoes.last;
    int? diasDesdeUltima;
    if (ultima != null) {
      diasDesdeUltima = DateTime.now().difference(ultima).inDays;
    }
    double? intervaloMedio;
    if (aplicacoes.length >= 2) {
      var soma = 0;
      for (var i = 1; i < aplicacoes.length; i++) {
        soma += aplicacoes[i].difference(aplicacoes[i - 1]).inDays;
      }
      intervaloMedio = soma / (aplicacoes.length - 1);
    }
    return ResumoDose(
      aplicacoesRegistradas: aplicacoes.length,
      ultimaAplicacao: ultima,
      diasDesdeUltima: diasDesdeUltima,
      intervaloMedioDias: intervaloMedio,
    );
  }

  // ============================================================================
  // FORMATADORES
  // ============================================================================
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

  int? _calcIdade(String? iso) {
    if (iso == null) return null;
    final dn = DateTime.tryParse(iso);
    if (dn == null) return null;
    final hoje = DateTime.now();
    var i = hoje.year - dn.year;
    if (hoje.month < dn.month ||
        (hoje.month == dn.month && hoje.day < dn.day)) i--;
    return i < 0 || i > 130 ? null : i;
  }

  String _classificarImc(double imc) {
    if (imc < 18.5) return 'abaixo do peso';
    if (imc < 25) return 'eutrófico';
    if (imc < 30) return 'sobrepeso';
    if (imc < 35) return 'obesidade grau I';
    if (imc < 40) return 'obesidade grau II';
    return 'obesidade grau III';
  }

  String _interpretarRitmoEmagrecimento(double kgSemana) {
    final abs = kgSemana.abs();
    if (kgSemana >= 0) return 'Peso estável ou em ganho no período.';
    if (abs < 0.3) return 'Ritmo de perda lento (< 0,3kg/sem).';
    if (abs <= 1.0) return 'Ritmo saudável (0,3-1kg/sem).';
    if (abs <= 1.5) return 'Ritmo acelerado (>1kg/sem) — atenção à massa magra.';
    return 'Perda >1,5kg/sem — avaliar aporte calórico/proteico com nutricionista.';
  }
}

// ============================================================================
// TIPOS DE ANÁLISE
// ============================================================================
class ResumoPeso {
  final double? pesoInicialKg;
  final double? pesoAtualKg;
  final double? imcAtual;
  final double? variacaoTotalKg;
  final double? kgPorSemana;
  const ResumoPeso({
    this.pesoInicialKg,
    this.pesoAtualKg,
    this.imcAtual,
    this.variacaoTotalKg,
    this.kgPorSemana,
  });
}

class ResumoAdesao {
  final int diasComRegistro;
  final int diasDoPeriodo;
  final double percentual;
  final int? metaProteinaAtingidaDias;
  final int? metaAguaAtingidaDias;
  const ResumoAdesao({
    required this.diasComRegistro,
    required this.diasDoPeriodo,
    required this.percentual,
    this.metaProteinaAtingidaDias,
    this.metaAguaAtingidaDias,
  });
}

class ResumoDose {
  final int aplicacoesRegistradas;
  final DateTime? ultimaAplicacao;
  final int? diasDesdeUltima;
  final double? intervaloMedioDias;
  const ResumoDose({
    required this.aplicacoesRegistradas,
    this.ultimaAplicacao,
    this.diasDesdeUltima,
    this.intervaloMedioDias,
  });
}
