import 'package:flutter_test/flutter_test.dart';

import 'package:assistente_caneta/models/patient_profile.dart';
import 'package:assistente_caneta/services/effort_advisor.dart';

void main() {
  const advisor = EffortAdvisor();

  test('sem eixo → recomendação genérica moderada', () {
    final rec = advisor.recomendacaoPara(ModalidadeAerobica.corrida, null);
    expect(rec.intensidade, IntensidadeAerobica.moderada);
    expect(rec.justificativa, contains('Configure seu eixo'));
  });

  test('recomposição natural tolera vigorosa', () {
    final corrida = advisor.recomendacaoPara(
        ModalidadeAerobica.corrida, EixoFarmacologico.recomposicaoNatural);
    expect(corrida.intensidade, IntensidadeAerobica.vigorosa);
  });

  test('triplo reduz corrida para leve (proteção muscular)', () {
    final corrida = advisor.recomendacaoPara(
        ModalidadeAerobica.corrida, EixoFarmacologico.triplo);
    expect(corrida.intensidade, IntensidadeAerobica.leve);
  });

  test('ciclismo tolera mais que corrida no mesmo eixo (menos impacto)', () {
    final corrida = advisor.recomendacaoPara(
        ModalidadeAerobica.corrida, EixoFarmacologico.triplo);
    final ciclismo = advisor.recomendacaoPara(
        ModalidadeAerobica.ciclismo, EixoFarmacologico.triplo);
    // leve (índice 0) < moderada (índice 1)
    expect(corrida.intensidade.index, lessThan(ciclismo.intensidade.index));
  });

  test('recomendacoes() cobre todas as modalidades', () {
    final todas = advisor.recomendacoes(EixoFarmacologico.duplo);
    expect(todas.length, ModalidadeAerobica.values.length);
    expect(
        todas.map((r) => r.modalidade).toSet(),
        equals(ModalidadeAerobica.values.toSet()));
  });
}
