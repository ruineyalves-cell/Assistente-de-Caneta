import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:assistente_caneta/models/patient_profile.dart';
import 'package:assistente_caneta/models/symptom.dart';
import 'package:assistente_caneta/services/report_pdf_service.dart';

/// Regressão do achado 1 (QA teste interno): "Não foi possível gerar o
/// relatório — Out of Memory".
///
/// Causa-raiz: as seções eram montadas como `pw.Column` indivisível; o
/// `pw.MultiPage` não pagina um Column, então uma seção maior que uma página
/// (Farmacovigilância com 2 tabelas) entrava em loop de paginação e estourava
/// o heap. O fix emite as tabelas como filhos de topo (pagináveis) e limita a
/// fonte de dados (export LGPD traz até 100 mil logs).
///
/// Estes testes exercitam justamente o cenário que estourava: muitos logs,
/// cada um com vários sintomas de tipos distintos.
void main() {
  const service = ReportPdfService();

  // Header de um PDF válido: "%PDF".
  bool pareceePdf(List<int> bytes) =>
      bytes.length > 4 &&
      bytes[0] == 0x25 &&
      bytes[1] == 0x50 &&
      bytes[2] == 0x44 &&
      bytes[3] == 0x46;

  Map<String, dynamic> exportacaoComLogs(int nLogs, {int sintomasPorLog = 8}) {
    final tipos = SymptomType.values;
    final logs = <Map<String, dynamic>>[];
    final base = DateTime(2026, 8, 1, 9, 0);
    for (var i = 0; i < nLogs; i++) {
      final dia = base.subtract(Duration(days: i));
      final sintomas = <Map<String, dynamic>>[];
      for (var s = 0; s < sintomasPorLog; s++) {
        final tipo = tipos[(i + s) % tipos.length];
        sintomas.add(SymptomEntry(
          tipo: tipo,
          intensidade: SymptomIntensity.values[(i + s) % 3],
          quando: dia.add(Duration(hours: s)),
          contexto: 'Contexto de teste $i/$s — refeição registrada',
        ).toJson());
      }
      logs.add({
        'data': dia.toIso8601String(),
        'pesoKg': 98.0 - i * 0.1,
        'proteinaG': 120,
        'aguaMl': 2500,
        'doseAplicada': i % 7 == 0,
        'efeitos': jsonEncode({'sintomas': sintomas}),
      });
    }
    return {
      'usuario': {
        'nome': 'Paciente Teste',
        'email': 'teste@recorpo.com.br',
        'id': 1,
        'data_nascimento': '1985-03-10',
      },
      'perfil': {
        'pesoInicialKg': 98.0,
        'alturaCm': 172,
        'medicacao': {'nome': 'Mounjaro'},
        'doseAtual': '5mg',
      },
      'registrosDiarios': logs,
      'scores': [
        for (var i = 0; i < 28; i++)
          {'data': base.subtract(Duration(days: i)).toIso8601String(), 'score': 70 + i % 30},
      ],
    };
  }

  test('gera PDF com muitos sintomas sem estourar (fix da paginação)',
      () async {
    // 60 dias × 8 sintomas = 480 entradas: farmacovigilância ultrapassa uma
    // página. Antes do fix, isto disparava o loop de paginação/OOM.
    final exportacao = exportacaoComLogs(60);
    final bytes = await service.gerar(
      exportacao: exportacao,
      eixoLocal: EixoFarmacologico.duplo,
    );
    expect(pareceePdf(bytes), isTrue, reason: 'saída deve ser um PDF válido');
    expect(bytes.length, greaterThan(2000));
  });

  test('teto de segurança: aceita payload gigante (export LGPD sem paginação)',
      () async {
    // Simula o pior caso do endpoint LGPD (limite 100 mil). Deve gerar sem
    // travar graças ao corte interno de _maxLogs.
    final exportacao = exportacaoComLogs(1200, sintomasPorLog: 3);
    final bytes = await service.gerar(
      exportacao: exportacao,
      eixoLocal: EixoFarmacologico.glp1Simples,
    );
    expect(pareceePdf(bytes), isTrue);
  });

  test('gera PDF mesmo sem registros', () async {
    final bytes = await service.gerar(
      exportacao: const {
        'usuario': {'nome': 'Vazio'},
        'perfil': {},
        'registrosDiarios': [],
        'scores': [],
      },
      eixoLocal: null,
    );
    expect(pareceePdf(bytes), isTrue);
  });
}
