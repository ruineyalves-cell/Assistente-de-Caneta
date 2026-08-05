import 'package:flutter_test/flutter_test.dart';
import 'package:assistente_caneta/services/hoje_widget_service.dart';

/// Formatação (pt-BR) do texto de água do widget "Hoje". Função pura —
/// não toca na plataforma. O mesmo formato é replicado no callback de
/// background da água (water_widget_service.dart).
void main() {
  test('acima da meta vira "meta batida"', () {
    expect(HojeWidgetService.aguaTexto(6500, 2877), 'meta batida · 6,5 L');
  });

  test('abaixo da meta mostra porcentagem', () {
    expect(HojeWidgetService.aguaTexto(1400, 2800), '50% · 1,4 L');
  });

  test('sem meta mostra só litros', () {
    expect(HojeWidgetService.aguaTexto(500, 0), '0,5 L');
  });

  test('exatamente na meta conta como batida', () {
    expect(HojeWidgetService.aguaTexto(2800, 2800), 'meta batida · 2,8 L');
  });
}
