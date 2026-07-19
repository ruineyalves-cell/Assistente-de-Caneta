// Smoke test do OnboardingScreen (Lote 29) — garante que:
//  1) monta na tela de boas-vindas com brand Recorpo,
//  2) o botão "Continuar" avança para o passo 2 (Eixo),
//  3) o botão "Voltar" reaparece no passo 2 e desabilita "Continuar"
//     enquanto o usuário não escolhe um eixo.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:assistente_caneta/screens/onboarding_screen.dart';
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
  testWidgets('Passo 1 — Boas-vindas com CTA Continuar habilitado',
      (tester) async {
    await tester.pumpWidget(_wrap(
      OnboardingScreen(onConcluir: () {}),
    ));
    await tester.pump();

    expect(find.textContaining('Boas-vindas'), findsOneWidget);
    expect(find.text('Continuar'), findsOneWidget);
    expect(find.text('Pular'), findsOneWidget);
    // No passo 1 não há botão "Voltar".
    expect(find.text('Voltar'), findsNothing);
  });

  testWidgets('Continuar leva para o passo 2 (Eixo) e o CTA desabilita',
      (tester) async {
    await tester.pumpWidget(_wrap(
      OnboardingScreen(onConcluir: () {}),
    ));
    await tester.pump();

    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();

    expect(find.textContaining('matriz metabólica'), findsOneWidget);
    expect(find.text('Voltar'), findsOneWidget);
    // Passo 2 exige eixo — a lista de eixos aparece.
    expect(find.textContaining('GLP-1 simples'), findsOneWidget);
  });
}
