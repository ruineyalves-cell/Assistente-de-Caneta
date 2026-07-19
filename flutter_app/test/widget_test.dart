// Smoke test: garante que o app monta em ambos os cenários — 1ª execução
// (Disclaimer gate) e execuções seguintes (login com a marca Recorpo).
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:assistente_caneta/main.dart';
import 'package:assistente_caneta/services/app_lock_service.dart';
import 'package:assistente_caneta/services/auth_service.dart';
import 'package:assistente_caneta/services/premium_service.dart';
import 'package:assistente_caneta/services/theme_controller.dart';
import 'package:assistente_caneta/utils/constants.dart';

Future<AppLockService> _appLockVazio() async {
  return AppLockService.criar();
}

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues(<String, Object>{});
    // Mock do canal do flutter_secure_storage para não travar em teste.
    const MethodChannel(
      'plugins.it_nomads.com/flutter_secure_storage',
    ).setMockMethodCallHandler((call) async {
      if (call.method == 'read') return null;
      return null;
    });
  });

  testWidgets('1ª execução: mostra o gate de Termos e Privacidade',
      (tester) async {
    final lock = await _appLockVazio();
    await tester.pumpWidget(MyApp(
      authService: AuthService(),
      premiumService: PremiumService(),
      themeController: ThemeController(),
      appLockService: lock,
      disclaimerAceitoInicial: false,
      onboardingCompletoInicial: false,
    ));
    await tester.pump();

    expect(find.text('Termos de Uso e Privacidade'), findsOneWidget);
    expect(find.text('Compreendo e Aceito'), findsOneWidget);
  });

  testWidgets('Execuções seguintes: cai direto no login com marca Recorpo',
      (tester) async {
    final lock = await _appLockVazio();
    await tester.pumpWidget(MyApp(
      authService: AuthService(),
      premiumService: PremiumService(),
      themeController: ThemeController(),
      appLockService: lock,
      disclaimerAceitoInicial: true,
      onboardingCompletoInicial: true,
    ));
    await tester.pump();

    expect(find.text(AppConstants.brandName), findsWidgets);
    expect(find.byType(TextField), findsWidgets);
  });
}
