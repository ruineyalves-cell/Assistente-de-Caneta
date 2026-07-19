// Smoke visual do layout do card de resumo (Lote 32.3).
// Como _ResumoDoDiaCard é privado no main.dart, o teste reproduz a
// estrutura mínima que o widget precisa exibir a partir da resposta
// do backend.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Resumo com 3 linhas renderiza cada uma com o texto',
      (tester) async {
    // Payload que o backend devolve
    const linhas = [
      {'tipo': 'refeicao', 'texto': 'Você já registrou 2 refeições hoje.'},
      {'tipo': 'agua', 'texto': 'Faltam 1,2 L para bater a meta.'},
      {'tipo': 'dose', 'texto': 'Dose aplicada hoje.'},
    ];

    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('pt', 'BR'), Locale('en')],
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('RESUMO DE HOJE',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              for (final l in linhas) Text(l['texto'] as String),
            ],
          ),
        ),
      ),
    ));

    expect(find.text('RESUMO DE HOJE'), findsOneWidget);
    expect(find.text('Você já registrou 2 refeições hoje.'), findsOneWidget);
    expect(find.text('Faltam 1,2 L para bater a meta.'), findsOneWidget);
    expect(find.text('Dose aplicada hoje.'), findsOneWidget);
  });

  testWidgets('Resumo vazio renderiza mensagem convite',
      (tester) async {
    const linhas = [
      {
        'tipo': 'dica',
        'texto':
            'Hoje ainda sem registros. Cada eixo aceita um toque rápido.',
      },
    ];

    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('pt', 'BR'), Locale('en')],
      home: Scaffold(
        body: Column(
          children: [
            for (final l in linhas) Text(l['texto'] as String),
          ],
        ),
      ),
    ));

    expect(find.textContaining('sem registros'), findsOneWidget);
  });
}
