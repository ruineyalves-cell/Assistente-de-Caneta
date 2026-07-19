// Smoke tests dos bottom sheets focados de Água e Peso (Lote 32).
// Não testam o salvamento real — o LogsProvider precisa de backend.
// Só validam que os controles principais aparecem quando o sheet abre.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:assistente_caneta/services/auth_service.dart';
import 'package:assistente_caneta/services/logs_provider.dart';
import 'package:assistente_caneta/widgets/water_quick_sheet.dart';
import 'package:assistente_caneta/widgets/weight_quick_sheet.dart';

Widget _wrap(Widget child) {
  final auth = AuthService();
  return MaterialApp(
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: const [Locale('pt', 'BR'), Locale('en')],
    home: MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthService>.value(value: auth),
        ChangeNotifierProvider<LogsProvider>(
          create: (_) => LogsProvider(auth.apiService),
        ),
      ],
      child: Scaffold(body: child),
    ),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('WaterQuickSheet mostra 4 botões de incremento + progresso',
      (tester) async {
    await tester.pumpWidget(_wrap(const WaterQuickSheet(
      aguaAtualMl: 1200,
      metaAguaMl: 3000,
    )));
    await tester.pumpAndSettle();

    expect(find.text('Hidratação de hoje'), findsOneWidget);
    expect(find.text('+250 ml'), findsOneWidget);
    expect(find.text('+500 ml'), findsOneWidget);
    expect(find.text('+750 ml'), findsOneWidget);
    expect(find.text('+1 L'), findsOneWidget);
    // Progresso: 1200/3000 = 40%
    expect(find.text('40% da meta'), findsOneWidget);
    expect(find.textContaining('Personalizar'), findsOneWidget);
  });

  testWidgets('WeightQuickSheet mostra input, chips de local e delta',
      (tester) async {
    await tester.pumpWidget(_wrap(const WeightQuickSheet(
      pesoAnteriorKg: 87.8,
    )));
    await tester.pumpAndSettle();

    expect(find.text('Registro de peso'), findsOneWidget);
    expect(find.text('Último: 87.8 kg'), findsOneWidget);
    expect(find.text('Onde você se pesou?'), findsOneWidget);
    // Chips de local
    expect(find.text('Casa'), findsOneWidget);
    expect(find.text('Academia'), findsOneWidget);
    expect(find.text('Farmácia'), findsOneWidget);
    expect(find.text('Clínica'), findsOneWidget);

    // Digitar peso e verificar delta
    await tester.enterText(find.byType(TextField), '87.2');
    await tester.pump();
    expect(find.textContaining('0.6 kg vs último'), findsOneWidget);
  });
}
