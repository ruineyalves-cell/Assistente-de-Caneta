import 'dart:async';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Color;

/// Fachada de notificações locais acolhedoras da Recorpo (Lote 19).
///
/// Usa `awesome_notifications` no lugar de `flutter_local_notifications`
/// (a linha inteira do outro package tem armadilhas de build em Flutter
/// 3.44 + compileSdk 36 — v<=16 falha `bigLargeIcon` ambíguo, v>=17
/// falha AAR metadata).
///
/// Todas as frases usam o primeiro nome; tom acolhedor, nunca
/// passivo-agressivo (o app é clínico, não é jogo de idioma).
class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  bool _inicializado = false;

  static const _canalDiario = 'recorpo_diario';
  static const _canalCelebracao = 'recorpo_celebracao';
  static const _canalDose = 'recorpo_dose';

  static const int _idHidratacao = 1001;
  static const int _idRegistroDia = 1002;
  static const int _idCelebracao = 1003;
  static const int _idProximaDose = 1004;

  bool get suportado => !kIsWeb;

  Future<void> inicializar() async {
    if (!suportado || _inicializado) return;
    await AwesomeNotifications().initialize(
      null, // usa o ic_launcher do app
      [
        NotificationChannel(
          channelKey: _canalDiario,
          channelName: 'Lembretes diários',
          channelDescription: 'Hidratação e registro do dia',
          defaultColor: const Color(0xFF2B6CB0),
          importance: NotificationImportance.High,
        ),
        NotificationChannel(
          channelKey: _canalCelebracao,
          channelName: 'Celebrações',
          channelDescription: 'Marcos de streak e mensagens motivacionais',
          defaultColor: const Color(0xFF48BB78),
          importance: NotificationImportance.High,
        ),
        NotificationChannel(
          channelKey: _canalDose,
          channelName: 'Próxima aplicação',
          channelDescription: 'Alerta antes da próxima dose da medicação',
          defaultColor: const Color(0xFFE53E3E),
          importance: NotificationImportance.Max,
        ),
      ],
      debug: false,
    );
    _inicializado = true;
  }

  Future<bool> pedirPermissao() async {
    if (!suportado) return false;
    await inicializar();
    final allowed = await AwesomeNotifications().isNotificationAllowed();
    if (allowed) return true;
    return AwesomeNotifications().requestPermissionToSendNotifications();
  }

  Future<void> reagendarDiarias({
    required String? primeiroNome,
    required bool hidratacaoAbaixoDaMeta,
    required bool jaTeveLogHoje,
  }) async {
    if (!suportado) return;
    await inicializar();
    await AwesomeNotifications().cancel(_idHidratacao);
    await AwesomeNotifications().cancel(_idRegistroDia);

    final nome = _saudarNome(primeiroNome);

    if (hidratacaoAbaixoDaMeta) {
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: _idHidratacao,
          channelKey: _canalDiario,
          title: 'Ainda dá tempo de bater sua meta de hoje 💧',
          body: '$nome, um bom copo de água agora te aproxima da meta do dia.',
          notificationLayout: NotificationLayout.Default,
        ),
        schedule: NotificationCalendar(
          hour: 18,
          minute: 0,
          second: 0,
          repeats: true,
          allowWhileIdle: true,
          preciseAlarm: true,
        ),
      );
    }

    if (!jaTeveLogHoje) {
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: _idRegistroDia,
          channelKey: _canalDiario,
          title: 'Como foi o dia?',
          body:
              '$nome, um registro rápido antes de dormir fecha o ciclo com carinho.',
          notificationLayout: NotificationLayout.Default,
        ),
        schedule: NotificationCalendar(
          hour: 22,
          minute: 0,
          second: 0,
          repeats: true,
          allowWhileIdle: true,
          preciseAlarm: true,
        ),
      );
    }
  }

  Future<void> celebrar({
    required String? primeiroNome,
    required int streakDias,
  }) async {
    if (!suportado) return;
    await inicializar();
    final nome = _saudarNome(primeiroNome);
    String titulo;
    String corpo;

    if (streakDias > 0 && streakDias % 30 == 0) {
      titulo = 'Um mês inteiro de consistência! 🎉';
      corpo =
          '$nome, você completou $streakDias dias seguidos. Isso é conquista de verdade.';
    } else if (streakDias > 0 && streakDias % 7 == 0) {
      titulo = 'Uma semana redonda 🌟';
      corpo =
          '$nome, $streakDias dias seguidos. Você está construindo hábito de verdade.';
    } else if (streakDias > 0 && streakDias % 3 == 0) {
      titulo = 'Três dias seguidos 👏';
      corpo = '$nome, mais uma sequência fechada. Cada uma vale.';
    } else {
      final agora = DateTime.now();
      final dayOfYear = agora.difference(DateTime(agora.year, 1, 1)).inDays;
      final entry = _frasesRotativas[dayOfYear % _frasesRotativas.length];
      titulo = entry.$1.replaceAll('{nome}', nome);
      corpo = entry.$2.replaceAll('{nome}', nome);
    }

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: _idCelebracao,
        channelKey: _canalCelebracao,
        title: titulo,
        body: corpo,
        notificationLayout: NotificationLayout.Default,
      ),
    );
  }

  Future<void> agendarProximaDose({
    required String? primeiroNome,
    required String? medicamento,
    required DateTime? proximaDose,
  }) async {
    if (!suportado) return;
    await inicializar();
    await AwesomeNotifications().cancel(_idProximaDose);
    if (proximaDose == null || proximaDose.isBefore(DateTime.now())) return;

    final nome = _saudarNome(primeiroNome);
    final med = medicamento ?? 'sua aplicação';

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: _idProximaDose,
        channelKey: _canalDose,
        title: 'Aplicação próxima',
        body: '$nome, sua próxima dose de $med está chegando. Prepare-se com calma.',
        notificationLayout: NotificationLayout.Default,
      ),
      schedule: NotificationCalendar.fromDate(
        date: proximaDose,
        allowWhileIdle: true,
        preciseAlarm: true,
      ),
    );
  }

  Future<void> cancelarDiarias() async {
    if (!suportado) return;
    await AwesomeNotifications().cancel(_idHidratacao);
    await AwesomeNotifications().cancel(_idRegistroDia);
  }

  Future<void> cancelarTudo() async {
    if (!suportado) return;
    await AwesomeNotifications().cancelAll();
  }

  String _saudarNome(String? primeiroNome) {
    final n = (primeiroNome ?? '').trim();
    return n.isEmpty ? 'você' : n;
  }

  /// Frases rotativas — sugestões do usuário + variações. `{nome}` é
  /// substituído em tempo de envio.
  static const List<(String, String)> _frasesRotativas = [
    (
      'Parabéns, {nome}!',
      'Nos últimos dias você tem conseguido perder peso. Não desista — o esforço aparece.'
    ),
    (
      'Mais um passo, {nome} 👣',
      'Hoje você deu mais um passo em direção ao lugar onde quer chegar.'
    ),
    (
      'Isso aí, {nome}! 👏',
      'Continue assim. Você está indo bem.'
    ),
    (
      'Consistência é a resposta',
      '{nome}, cada dia que você registra é um tijolinho a mais na sua evolução.'
    ),
    (
      'Você está cuidando de você',
      'E isso, {nome}, já é motivo de orgulho. Continue.'
    ),
  ];
}
