// Unit tests do AppLockService (Lote 32.5).
// Usa FlutterSecureStorage com mock em-memória (via MethodChannel) e
// SharedPreferences com setMockInitialValues.
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:assistente_caneta/services/app_lock_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Storage em memória pra flutter_secure_storage
  late Map<String, String> memStorage;

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    memStorage = <String, String>{};
    const MethodChannel(
      'plugins.it_nomads.com/flutter_secure_storage',
    ).setMockMethodCallHandler((call) async {
      final key = call.arguments is Map
          ? (call.arguments as Map)['key'] as String?
          : null;
      switch (call.method) {
        case 'read':
          return memStorage[key];
        case 'write':
          final v = (call.arguments as Map)['value'] as String?;
          if (v == null) {
            memStorage.remove(key);
          } else if (key != null) {
            memStorage[key] = v;
          }
          return null;
        case 'delete':
          memStorage.remove(key);
          return null;
        case 'readAll':
          return Map<String, String>.from(memStorage);
        case 'deleteAll':
          memStorage.clear();
          return null;
      }
      return null;
    });
  });

  group('AppLockService — setup e verificação', () {
    test('sem PIN configurado: configurado = false, travado = false',
        () async {
      final svc = await AppLockService.criar();
      expect(svc.configurado, isFalse);
      expect(svc.travado, isFalse);
    });

    test('PIN válido só aceita 4-6 dígitos', () async {
      final svc = await AppLockService.criar();
      expect(svc.pinValido('1234'), isTrue);
      expect(svc.pinValido('12345'), isTrue);
      expect(svc.pinValido('123456'), isTrue);
      expect(svc.pinValido('123'), isFalse);
      expect(svc.pinValido('1234567'), isFalse);
      expect(svc.pinValido('12ab'), isFalse);
    });

    test('definirPin com PIN inválido lança ArgumentError', () async {
      final svc = await AppLockService.criar();
      expect(() => svc.definirPin('123'), throwsArgumentError);
    });

    test('após definirPin: configurado = true, verifica PIN correto',
        () async {
      final svc = await AppLockService.criar();
      await svc.definirPin('4321');
      expect(svc.configurado, isTrue);
      expect(await svc.verificarPin('4321'), isTrue);
    });

    test('PIN incorreto retorna false e incrementa tentativas', () async {
      final svc = await AppLockService.criar();
      await svc.definirPin('4321');
      expect(await svc.verificarPin('1111'), isFalse);
      expect(svc.tentativasErradas, 1);
      expect(await svc.verificarPin('2222'), isFalse);
      expect(svc.tentativasErradas, 2);
    });

    test('acerto zera tentativas', () async {
      final svc = await AppLockService.criar();
      await svc.definirPin('4321');
      await svc.verificarPin('1111');
      expect(svc.tentativasErradas, 1);
      await svc.verificarPin('4321');
      expect(svc.tentativasErradas, 0);
    });

    test('5 erros consecutivos bloqueia por 30s', () async {
      final svc = await AppLockService.criar();
      await svc.definirPin('4321');
      for (var i = 0; i < 5; i++) {
        await svc.verificarPin('1111');
      }
      expect(svc.estaTemporariamenteBloqueado, isTrue);
      final ate = svc.bloqueadoAte!;
      final restante = ate.difference(DateTime.now()).inSeconds;
      expect(restante, lessThanOrEqualTo(30));
      expect(restante, greaterThan(20));
    });

    test('desativar exige PIN atual correto', () async {
      final svc = await AppLockService.criar();
      await svc.definirPin('4321');
      expect(() => svc.desativar('1111'), throwsStateError);
      await svc.desativar('4321');
      expect(svc.configurado, isFalse);
    });
  });

  group('AppLockService — auto-lock', () {
    test('timeout imediato (0s) tranca em qualquer foreground', () async {
      final svc = await AppLockService.criar();
      await svc.definirPin('4321');
      await svc.definirTimeout(0);
      await svc.marcarBackground();
      await svc.avaliarForeground();
      expect(svc.travado, isTrue);
    });

    test('timeout 300s NÃO tranca com pausa curta', () async {
      final svc = await AppLockService.criar();
      await svc.definirPin('4321');
      await svc.definirTimeout(300);
      await svc.marcarBackground();
      await svc.avaliarForeground(); // sem pausa real
      expect(svc.travado, isFalse);
    });

    test('bloquearAgora força o estado', () async {
      final svc = await AppLockService.criar();
      await svc.definirPin('4321');
      svc.bloquearAgora();
      expect(svc.travado, isTrue);
    });
  });

  group('AppLockService — timeouts disponíveis', () {
    test('lista contém os 4 valores esperados', () {
      expect(
        AppLockService.timeoutsDisponiveisSeg,
        containsAllInOrder(<int>[0, 60, 300, 900]),
      );
    });

    test('definirTimeout rejeita valor fora da lista', () async {
      final svc = await AppLockService.criar();
      expect(() => svc.definirTimeout(120), throwsArgumentError);
    });
  });
}
