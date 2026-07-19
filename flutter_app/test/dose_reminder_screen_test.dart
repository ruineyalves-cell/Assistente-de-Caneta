// Smoke test do DoseReminderScreen (Lote 30) — garante que:
//  1) monta com o header do lembrete e o Switch,
//  2) marcar o Switch expõe os chips de dia da semana e o cartão de
//     horário (elementos que só aparecem quando o lembrete está
//     habilitado).
// Não exercita `Salvar` — isso chamaria `awesome_notifications`, que
// não está inicializável no ambiente de teste.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:assistente_caneta/screens/dose_reminder_screen.dart';
import 'package:assistente_caneta/services/auth_service.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: const [Locale('pt', 'BR'), Locale('en')],
    home: ChangeNotifierProvider<AuthService>.value(
      value: AuthService(),
      child: child,
    ),
  );
}

void main() {
  setUp(() {
    // Mock in-memory do SharedPreferences para o initState resolver
    // sem depender do plugin nativo.
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('Monta com header e Switch de ativar lembrete',
      (tester) async {
    await tester.pumpWidget(_wrap(const DoseReminderScreen()));
    // Deixa o _carregar() do initState resolver.
    await tester.pumpAndSettle();

    expect(find.text('Ativar lembrete semanal'), findsOneWidget);
    expect(find.byType(Switch), findsOneWidget);
    // Header do card gradiente:
    expect(find.textContaining('Nunca mais esqueça'), findsOneWidget);
  });

  testWidgets('Ativar Switch expõe chips de dia e cartão de horário',
      (tester) async {
    await tester.pumpWidget(_wrap(const DoseReminderScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    // Chips de dia (Seg..Dom).
    expect(find.text('Seg'), findsOneWidget);
    expect(find.text('Qui'), findsOneWidget);
    expect(find.text('Dom'), findsOneWidget);
    // Cartão de horário — a hora padrão é 09:00.
    expect(find.text('09:00'), findsOneWidget);
    expect(find.text('Alterar'), findsOneWidget);
  });
}
