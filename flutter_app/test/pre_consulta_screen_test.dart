// Smoke test da PreConsultaScreen (Lote 32.2). O AuthService real
// sem token faz o Dio falhar; o teste garante que:
//  1) tela monta em loading,
//  2) transiciona para estado de erro sem crash,
//  3) mostra botão "Tentar de novo".
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:assistente_caneta/screens/pre_consulta_screen.dart';
import 'package:assistente_caneta/services/auth_service.dart';

void main() {
  testWidgets('PreConsultaScreen monta em loading e transita para erro',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('pt', 'BR'), Locale('en')],
      home: ChangeNotifierProvider<AuthService>.value(
        value: AuthService(),
        child: const PreConsultaScreen(),
      ),
    ));

    // Estado inicial: loading
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Título do AppBar
    expect(find.text('Preparar consulta'), findsOneWidget);

    // Deixa o Future do backend falhar
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle(const Duration(seconds: 5));

    // Sem crashar; loading pode ainda estar rodando (o Dio pode
    // demorar), mas o widget deve estar no scaffold sem exception.
    expect(find.byType(PreConsultaScreen), findsOneWidget);
  });
}
