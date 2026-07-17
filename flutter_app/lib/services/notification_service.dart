import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Fachada única de notificações locais acolhedoras da Recorpo (Lote 19).
///
/// Categorias:
///  · **Hidratação** — 18h se ainda faltar água pra bater a meta.
///  · **Registro do dia** — 22h se o dia ficou sem log algum.
///  · **Celebração de streak** — imediata quando o app abre e o streak
///    é múltiplo de 3, 7 ou 30.
///  · **Próxima dose** — se última dose + frequência do medicamento
///    fica próximo do dia atual.
///
/// Todas as frases usam o primeiro nome do usuário. Tom acolhedor —
/// nunca passivo-agressivo (o app é clínico, não é um jogo).
class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _inicializado = false;

  static const _canalDiarioId = 'recorpo_diario';
  static const _canalDiarioNome = 'Lembretes diários';
  static const _canalCelebracaoId = 'recorpo_celebracao';
  static const _canalCelebracaoNome = 'Celebrações';
  static const _canalDoseId = 'recorpo_dose';
  static const _canalDoseNome = 'Próxima aplicação';

  bool get suportado => !kIsWeb;

  Future<void> inicializar() async {
    if (!suportado || _inicializado) return;
    tz.initializeTimeZones();
    const init = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );
    await _plugin.initialize(init);
    _inicializado = true;
  }

  /// Pede permissão POST_NOTIFICATIONS (Android 13+) e SCHEDULE_EXACT_ALARM
  /// (Android 12+). Retorna true se ambas foram concedidas.
  Future<bool> pedirPermissao() async {
    if (!suportado) return false;
    final noti = await Permission.notification.request();
    // schedule_exact_alarm só existe a partir do Android 12, mas o
    // handler retorna denied em versões anteriores sem quebrar.
    try {
      await Permission.scheduleExactAlarm.request();
    } catch (_) {}
    return noti.isGranted;
  }

  /// Cancela e re-agenda TODAS as notificações diárias do usuário.
  /// Idempotente — pode ser chamado sempre que o contexto muda
  /// (login, perfil salvo, etc).
  Future<void> reagendarDiarias({
    required String? primeiroNome,
    required bool hidratacaoAbaixoDaMeta,
    required bool jaTeveLogHoje,
  }) async {
    if (!suportado) return;
    await inicializar();
    await cancelarDiarias();

    final nome = _saudarNome(primeiroNome);

    // 1) 18h — hidratação pendente
    if (hidratacaoAbaixoDaMeta) {
      await _agendarHoje(
        id: _idHidratacao,
        hora: 18,
        minuto: 0,
        canalId: _canalDiarioId,
        canalNome: _canalDiarioNome,
        titulo: 'Ainda dá tempo de bater sua meta de hoje 💧',
        corpo:
            '$nome, um bom copo de água agora te aproxima da meta do dia.',
      );
    }

    // 2) 22h — registro do dia
    if (!jaTeveLogHoje) {
      await _agendarHoje(
        id: _idRegistroDia,
        hora: 22,
        minuto: 0,
        canalId: _canalDiarioId,
        canalNome: _canalDiarioNome,
        titulo: 'Como foi o dia?',
        corpo:
            '$nome, um registro rápido antes de dormir fecha o ciclo com carinho.',
      );
    }
  }

  /// Notificação imediata de celebração. [streakDias] usado para
  /// escolher entre celebrar streak (múltiplo de 3/7/30) OU rotacionar
  /// entre as frases de motivação/parabéns.
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
      corpo =
          '$nome, mais uma sequência fechada. Cada uma vale.';
    } else {
      // Rotação das frases motivacionais do usuário (índice por dia do ano)
      final agora = DateTime.now();
      final dayOfYear = agora
          .difference(DateTime(agora.year, 1, 1))
          .inDays;
      final entry = _frasesRotativas[dayOfYear % _frasesRotativas.length];
      titulo = entry.$1;
      corpo = entry.$2.replaceAll('{nome}', nome);
    }

    await _plugin.show(
      _idCelebracao,
      titulo,
      corpo,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _canalCelebracaoId,
          _canalCelebracaoNome,
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }

  /// Agenda notificação de próxima aplicação. Se [proximaDose] for
  /// null ou já passou, cancela.
  Future<void> agendarProximaDose({
    required String? primeiroNome,
    required String? medicamento,
    required DateTime? proximaDose,
  }) async {
    if (!suportado) return;
    await inicializar();
    await _plugin.cancel(_idProximaDose);
    if (proximaDose == null || proximaDose.isBefore(DateTime.now())) return;

    final nome = _saudarNome(primeiroNome);
    final med = medicamento ?? 'sua aplicação';
    final quando = tz.TZDateTime.from(proximaDose, tz.local);

    await _plugin.zonedSchedule(
      _idProximaDose,
      'Aplicação próxima',
      '$nome, sua próxima dose de $med está chegando. Prepare-se com calma.',
      quando,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _canalDoseId,
          _canalDoseNome,
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelarDiarias() async {
    if (!suportado) return;
    await _plugin.cancel(_idHidratacao);
    await _plugin.cancel(_idRegistroDia);
  }

  Future<void> cancelarTudo() async {
    if (!suportado) return;
    await _plugin.cancelAll();
  }

  // ---------- helpers ----------

  Future<void> _agendarHoje({
    required int id,
    required int hora,
    required int minuto,
    required String canalId,
    required String canalNome,
    required String titulo,
    required String corpo,
  }) async {
    final agora = tz.TZDateTime.now(tz.local);
    var quando =
        tz.TZDateTime(tz.local, agora.year, agora.month, agora.day, hora, minuto);
    // Se já passou da hora hoje, agenda para amanhã.
    if (quando.isBefore(agora)) {
      quando = quando.add(const Duration(days: 1));
    }
    await _plugin.zonedSchedule(
      id,
      titulo,
      corpo,
      quando,
      NotificationDetails(
        android: AndroidNotificationDetails(
          canalId,
          canalNome,
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // repete diária
    );
  }

  String _saudarNome(String? primeiroNome) {
    final n = (primeiroNome ?? '').trim();
    return n.isEmpty ? 'você' : n;
  }

  // IDs fixos das notificações — permitem cancelar/atualizar sem side-effect.
  static const int _idHidratacao = 1001;
  static const int _idRegistroDia = 1002;
  static const int _idCelebracao = 1003;
  static const int _idProximaDose = 1004;

  /// Frases rotativas de motivação/parabéns — mescla das sugestões do
  /// usuário com variações complementares. Cada tupla é (título, corpo).
  /// `{nome}` é substituído em tempo de envio.
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
