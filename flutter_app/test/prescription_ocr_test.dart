import 'package:flutter_test/flutter_test.dart';

import 'package:assistente_caneta/services/prescription_ocr_service.dart';

void main() {
  test('detecta proteína com valor em g', () {
    final metas = PrescriptionOcrService.detectarMetas(
        'Consumir 120 g de proteína por dia');
    expect(metas.any((m) => m.categoria == 'Proteína'), isTrue);
  });

  test('detecta proteína em g/kg', () {
    final metas = PrescriptionOcrService.detectarMetas(
        'Meta proteica: 1,6 g/kg de peso');
    expect(metas.any((m) => m.categoria == 'Proteína'), isTrue);
  });

  test('detecta hidratação em ml e L', () {
    final ml = PrescriptionOcrService.detectarMetas(
        'Beber 2500 ml de água ao longo do dia');
    final l = PrescriptionOcrService.detectarMetas(
        'Ingesta hídrica 2,5 L');
    expect(ml.any((m) => m.categoria == 'Hidratação'), isTrue);
    expect(l.any((m) => m.categoria == 'Hidratação'), isTrue);
  });

  test('detecta calorias', () {
    final metas = PrescriptionOcrService.detectarMetas('Total: 1800 kcal');
    expect(metas.any((m) => m.categoria == 'Calorias'), isTrue);
  });

  test('detecta carboidratos e gordura em receita composta', () {
    final metas = PrescriptionOcrService.detectarMetas('''
Prescrição nutricional
- Proteína: 120 g
- Carboidratos: 200 g
- Lipídios: 60 g
- Água: 2,5 L
Total: 1800 kcal
''');
    final categorias = metas.map((m) => m.categoria).toSet();
    expect(categorias, contains('Proteína'));
    expect(categorias, contains('Carboidratos'));
    expect(categorias, contains('Gordura'));
    expect(categorias, contains('Hidratação'));
    expect(categorias, contains('Calorias'));
  });

  test('não detecta em texto sem números / sem palavras-chave', () {
    final metas = PrescriptionOcrService.detectarMetas(
        'Consulta agendada para próxima quinta-feira');
    expect(metas, isEmpty);
  });
}
