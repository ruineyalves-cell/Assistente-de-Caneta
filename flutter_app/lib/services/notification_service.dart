import 'dart:async';
import 'package:flutter/foundation.dart';

/// STUB temporário — o package `flutter_local_notifications` foi removido
/// enquanto identificamos qual dep quebra o build AAR no CI. Todas as
/// chamadas viram no-op sem quebrar o app. Ver commit fix(deps): bisect.
class NotificationService {
  bool get suportado => !kIsWeb;

  Future<void> inicializar() async {}

  Future<bool> pedirPermissao() async => false;

  Future<void> reagendarDiarias({
    required String? primeiroNome,
    required bool hidratacaoAbaixoDaMeta,
    required bool jaTeveLogHoje,
  }) async {}

  Future<void> celebrar({
    required String? primeiroNome,
    required int streakDias,
  }) async {}

  Future<void> agendarProximaDose({
    required String? primeiroNome,
    required String? medicamento,
    required DateTime? proximaDose,
  }) async {}

  Future<void> cancelarDiarias() async {}
  Future<void> cancelarTudo() async {}
}
