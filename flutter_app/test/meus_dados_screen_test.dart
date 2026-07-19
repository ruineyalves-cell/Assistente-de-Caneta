// Smoke test da MeusDadosScreen (Lote 32.6). AuthService sem token
// faz o Dio falhar; o teste garante que a tela monta e a seção de
// acessos entra em estado de erro sem crash.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:assistente_caneta/screens/meus_dados_screen.dart';
import 'package:assistente_caneta/services/auth_service.dart';

void main() {
  testWidgets(
      'MeusDadosScreen renderiza as 3 seções LGPD e a AppBar',
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
        child: const MeusDadosScreen(),
      ),
    ));

    // AppBar title
    expect(find.text('Meus dados'), findsOneWidget);
    // 1ª seção visível
    expect(find.text('Portabilidade'), findsOneWidget);
    expect(find.text('Exportar meus dados'), findsOneWidget);

    // Rola até a seção de exclusão pra confirmar que existe no tree
    await tester.dragUntilVisible(
      find.text('Excluir minha conta'),
      find.byType(ListView),
      const Offset(0, -300),
    );
    expect(find.text('Excluir minha conta'), findsOneWidget);
    expect(find.text('Solicitar exclusão'), findsOneWidget);

    // Deixa o Future do backend falhar sem crash
    await tester.pumpAndSettle(const Duration(seconds: 3));
    expect(find.byType(MeusDadosScreen), findsOneWidget);
  });

  testWidgets('Diálogo de exclusão exige checkbox + palavra EXCLUIR',
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
        child: const MeusDadosScreen(),
      ),
    ));
    await tester.pump();

    // Rola até a seção de exclusão antes de tocar
    await tester.dragUntilVisible(
      find.text('Solicitar exclusão'),
      find.byType(ListView),
      const Offset(0, -300),
    );
    await tester.tap(find.text('Solicitar exclusão'));
    await tester.pumpAndSettle();

    // Diálogo abriu
    expect(find.text('Excluir conta'), findsWidgets);
    expect(find.textContaining('Digite EXCLUIR'), findsOneWidget);
    // Botão principal desabilitado sem confirmação
    final btn = tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Excluir conta'));
    expect(btn.onPressed, isNull);
  });
}
