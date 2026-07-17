// Smoke test: garante que o app monta e mostra a identidade Recorpo no login.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:assistente_caneta/main.dart';
import 'package:assistente_caneta/services/auth_service.dart';
import 'package:assistente_caneta/utils/constants.dart';

void main() {
  testWidgets('App monta e exibe a marca Recorpo no login', (tester) async {
    await tester.pumpWidget(MyApp(authService: AuthService()));
    await tester.pump();

    // A marca principal aparece (cabeçalho da tela de login).
    expect(find.text(AppConstants.brandName), findsWidgets);
    // Campo de e-mail presente = formulário de login renderizou.
    expect(find.byType(TextField), findsWidgets);
  });
}
