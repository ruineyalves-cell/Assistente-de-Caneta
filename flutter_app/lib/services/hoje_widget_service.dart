import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/widgets.dart';
import 'package:home_widget/home_widget.dart';

import '../utils/theme.dart';
import '../widgets/hoje_hero_card.dart' show HojeRingsView;

/// Chaves compartilhadas com o `HojeWidgetProvider.kt` (SharedPreferences
/// "HomeWidgetPreferences"). **Só guardamos dados NÃO sensíveis** aqui —
/// como esse armazenamento é em texto puro e o widget aparece na home sem
/// passar pelo app-lock, peso e sintomas (dado sensível de saúde, LGPD
/// art. 11) NUNCA são publicados no widget.
class HojeWidgetKeys {
  static const String score = 'hoje_score';
  static const String proteina = 'hoje_prot';
  static const String agua = 'hoje_agua';
  static const String streak = 'hoje_streak';
  static const String data = 'hoje_data';
  static const String ringsImg = 'hoje_rings_img';
}

/// Widget "Recorpo Hoje" (Bloco 1 na tela inicial) — resumo do dia com
/// anéis (Proteína + Água), Score, Streak e atalhos +250/+500 ml.
///
/// Os botões de água reusam o MESMO fluxo seguro do widget de Água
/// (acumula local, o app consolida no backend na próxima abertura — sem
/// token de login rodando em background). Ver [callbackAguaWidget] em
/// water_widget_service.dart.
class HojeWidgetService {
  const HojeWidgetService();

  static const String providerName = 'HojeWidgetProvider';

  bool get suportado => !kIsWeb;

  /// Publica o estado atual no widget. Renderiza os anéis off-screen como
  /// PNG (RemoteViews não roda Flutter/CustomPainter) e grava os textos.
  Future<void> publicarEstado({
    required int score,
    required double proteinaHojeG,
    required double? proteinaMetaG,
    required int aguaHojeMl,
    required int aguaMetaMl,
    required int streak,
    required DateTime hoje,
  }) async {
    if (!suportado) return;
    try {
      final protPct = (proteinaMetaG == null || proteinaMetaG <= 0)
          ? 0.0
          : (proteinaHojeG / proteinaMetaG).clamp(0.0, 1.0);
      final aguaPct =
          aguaMetaMl <= 0 ? 0.0 : (aguaHojeMl / aguaMetaMl).clamp(0.0, 1.0);

      // Anéis → PNG. Cores fixas (o widget é sempre escuro). Falha aqui não
      // é fatal: o widget ainda mostra os textos.
      try {
        await HomeWidget.renderFlutterWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: HojeRingsView(
              size: 132,
              protPct: protPct,
              aguaPct: aguaPct,
              score: score,
              protColor: RecorpoColors.eixoRefeicao,
              aguaColor: RecorpoColors.eixoAgua,
              trackColor: const Color(0x3322304D),
              scoreColor: RecorpoColors.confirma,
              labelColor: const Color(0xFF8A99B5),
            ),
          ),
          key: HojeWidgetKeys.ringsImg,
          logicalSize: const Size(132, 132),
        );
      } catch (_) {}

      final protTxt = proteinaMetaG == null
          ? '${_g(proteinaHojeG)} g'
          : '${_g(proteinaHojeG)} / ${_g(proteinaMetaG)} g';

      await HomeWidget.saveWidgetData<String>(
          HojeWidgetKeys.score, 'Score $score%');
      await HomeWidget.saveWidgetData<String>(
          HojeWidgetKeys.proteina, 'Proteína · $protTxt');
      await HomeWidget.saveWidgetData<String>(
          HojeWidgetKeys.agua, 'Água · ${aguaTexto(aguaHojeMl, aguaMetaMl)}');
      await HomeWidget.saveWidgetData<String>(
          HojeWidgetKeys.streak, streak > 0 ? '🔥 $streak dias' : 'Sem streak');
      await HomeWidget.saveWidgetData<String>(
          HojeWidgetKeys.data, _isoDia(hoje));
      await HomeWidget.updateWidget(name: providerName);
    } catch (_) {
      // Sem widget na home / erro de plataforma — ignora.
    }
  }

  /// Zera o widget no logout (aparelho compartilhado não pode manter o
  /// resumo do usuário anterior).
  Future<void> limpar() async {
    if (!suportado) return;
    try {
      await HomeWidget.saveWidgetData<String>(HojeWidgetKeys.score, 'Recorpo');
      await HomeWidget.saveWidgetData<String>(HojeWidgetKeys.proteina, '');
      await HomeWidget.saveWidgetData<String>(
          HojeWidgetKeys.agua, 'Abra o app para começar');
      await HomeWidget.saveWidgetData<String>(HojeWidgetKeys.streak, '');
      await HomeWidget.saveWidgetData<String>(HojeWidgetKeys.ringsImg, '');
      await HomeWidget.updateWidget(name: providerName);
    } catch (_) {}
  }

  /// Formata "X% · Y L" ou "meta batida · Y L". Público porque o callback
  /// de background da água também atualiza o texto de água do widget Hoje.
  static String aguaTexto(int hojeMl, int metaMl) {
    final l = (hojeMl / 1000).toStringAsFixed(1).replaceAll('.', ',');
    if (metaMl <= 0) return '$l L';
    if (hojeMl >= metaMl) return 'meta batida · $l L';
    final pct = (hojeMl / metaMl * 100).round();
    return '$pct% · $l L';
  }

  static String _g(double v) {
    final s =
        v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
    return s.replaceAll('.', ',');
  }

  static String _isoDia(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
