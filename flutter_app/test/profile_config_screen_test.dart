// Smoke test do ProfileConfigScreen — garante que a tela monta sem crash
// e passa pelo estado de carregamento sem depender de backend real.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:assistente_caneta/screens/profile_config_screen.dart';
import 'package:assistente_caneta/services/auth_service.dart';

void main() {
  testWidgets('ProfileConfigScreen monta e exibe loading inicial',
      (tester) async {
    // AuthService real, mas sem token — o `salvarPerfil` nem chega a ser
    // acionado no build. O `listarMedicacoes` do initState vai falhar por
    // rede indisponível no ambiente de teste, e a tela cai para o
    // `_ErroCarga`. Ambos os estados são válidos.
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('pt', 'BR'), Locale('en')],
        home: ChangeNotifierProvider<AuthService>.value(
          value: AuthService(),
          child: const Scaffold(body: ProfileConfigScreen()),
        ),
      ),
    );

    // Estado inicial: CircularProgressIndicator do _carregando=true.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
