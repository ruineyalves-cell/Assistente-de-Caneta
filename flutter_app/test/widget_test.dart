// Smoke test: garante que o app monta em ambos os cenários — 1ª execução
// (Disclaimer gate) e execuções seguintes (login com a marca Recorpo).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:assistente_caneta/main.dart';
import 'package:assistente_caneta/services/auth_service.dart';
import 'package:assistente_caneta/services/premium_service.dart';
import 'package:assistente_caneta/services/theme_controller.dart';
import 'package:assistente_caneta/utils/constants.dart';

void main() {
  testWidgets('1ª execução: mostra o gate de Termos e Privacidade',
      (tester) async {
    await tester.pumpWidget(MyApp(
      authService: AuthService(),
      premiumService: PremiumService(),
      themeController: ThemeController(),
      disclaimerAceitoInicial: false,
    ));
    await tester.pump();

    expect(find.text('Termos de Uso e Privacidade'), findsOneWidget);
    expect(find.text('Compreendo e Aceito'), findsOneWidget);
  });

  testWidgets('Execuções seguintes: cai direto no login com marca Recorpo',
      (tester) async {
    await tester.pumpWidget(MyApp(
      authService: AuthService(),
      premiumService: PremiumService(),
      themeController: ThemeController(),
      disclaimerAceitoInicial: true,
    ));
    await tester.pump();

    expect(find.text(AppConstants.brandName), findsWidgets);
    expect(find.byType(TextField), findsWidgets);
  });
}
