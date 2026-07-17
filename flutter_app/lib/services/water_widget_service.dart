import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:home_widget/home_widget.dart';

/// Chaves compartilhadas entre o widget nativo (Kotlin) e o app Dart.
/// O package `home_widget` mapeia `saveWidgetData(key, val)` para o
/// SharedPreferences "HomeWidgetPreferences" do Android — o mesmo lido
/// pelo AguaWidgetProvider.kt.
class WaterWidgetKeys {
  /// Total do dia (autoritativo — atualizado tanto pelo widget quanto
  /// pelo app depois de sincronizar com backend).
  static const String hoje = 'agua_hoje_ml';

  /// Diferença que o widget acumulou local e ainda não foi sincronizada
  /// com o backend. O app zera essa chave depois de fazer POST no log.
  static const String pendente = 'agua_pendente_ml';

  /// Meta calculada (peso × metaAguaMlKg). Exibida no widget para o
  /// usuário ver quanto falta.
  static const String meta = 'agua_meta_ml';

  /// Data (yyyy-MM-dd) do valor guardado em `hoje`. Se muda o dia,
  /// zeramos automaticamente na primeira leitura.
  static const String data = 'agua_data';
}

/// Fachada de leitura/escrita dos dados do widget de água. O
/// callback background (top-level function) vive fora dessa classe,
/// mas usa as mesmas chaves.
class WaterWidgetService {
  const WaterWidgetService();

  static const String _providerName = 'AguaWidgetProvider';

  bool get suportado => !kIsWeb;

  /// Atualiza os valores exibidos no widget. Chamado sempre que o app
  /// sincroniza o log do dia com o backend.
  Future<void> publicarEstado({
    required int hojeMl,
    required int metaMl,
    required DateTime hoje,
  }) async {
    if (!suportado) return;
    try {
      final dataStr =
          '${hoje.year.toString().padLeft(4, '0')}-${hoje.month.toString().padLeft(2, '0')}-${hoje.day.toString().padLeft(2, '0')}';
      await HomeWidget.saveWidgetData<int>(WaterWidgetKeys.hoje, hojeMl);
      await HomeWidget.saveWidgetData<int>(WaterWidgetKeys.meta, metaMl);
      await HomeWidget.saveWidgetData<String>(WaterWidgetKeys.data, dataStr);
      await HomeWidget.updateWidget(name: _providerName);
    } catch (_) {
      // Sem widget na home — ignora silenciosamente.
    }
  }

  /// Lê e zera o valor pendente que o widget acumulou (em background)
  /// e ainda não foi sincronizado. Chamado pelo app na próxima
  /// abertura para consolidar no log diário.
  Future<int> lerEzerarPendente() async {
    if (!suportado) return 0;
    try {
      final pendente =
          await HomeWidget.getWidgetData<int>(WaterWidgetKeys.pendente,
                  defaultValue: 0) ??
              0;
      if (pendente > 0) {
        await HomeWidget.saveWidgetData<int>(WaterWidgetKeys.pendente, 0);
      }
      return pendente;
    } catch (_) {
      return 0;
    }
  }

  /// Registra o callback global que o home_widget dispara quando o
  /// usuário toca em +250 ou +500 na home. **Chamar apenas uma vez** no
  /// bootstrap do app.
  Future<void> registrarCallback() async {
    if (!suportado) return;
    try {
      await HomeWidget.registerInteractivityCallback(callbackAguaWidget);
    } catch (_) {}
  }
}

/// Top-level callback disparado pelo Android quando o usuário toca em
/// +250 ml ou +500 ml no widget. Precisa ser função de topo (não
/// closure) porque roda em um isolate isolado do app.
///
/// Não conseguimos falar com o backend aqui (sem tokens carregados) —
/// então apenas acumulamos localmente em `agua_pendente_ml` e
/// atualizamos o valor visível em `agua_hoje_ml`. O app faz o POST
/// definitivo quando abrir e chamar `lerEzerarPendente`.
@pragma('vm:entry-point')
Future<void> callbackAguaWidget(Uri? uri) async {
  if (uri == null) return;
  if (uri.host != 'agua') return;
  final ml = int.tryParse(uri.queryParameters['ml'] ?? '');
  if (ml == null || ml <= 0) return;

  // Se o dia mudou desde o último uso do widget, zera antes de somar.
  final agora = DateTime.now();
  final dataAgora =
      '${agora.year.toString().padLeft(4, '0')}-${agora.month.toString().padLeft(2, '0')}-${agora.day.toString().padLeft(2, '0')}';
  final dataGuardada = await HomeWidget.getWidgetData<String>(
      WaterWidgetKeys.data,
      defaultValue: dataAgora);

  int hojeAtual =
      await HomeWidget.getWidgetData<int>(WaterWidgetKeys.hoje, defaultValue: 0) ??
          0;
  int pendenteAtual = await HomeWidget.getWidgetData<int>(
          WaterWidgetKeys.pendente,
          defaultValue: 0) ??
      0;
  if (dataGuardada != dataAgora) {
    hojeAtual = 0;
    pendenteAtual = 0;
  }

  final novoHoje = hojeAtual + ml;
  final novoPendente = pendenteAtual + ml;

  await HomeWidget.saveWidgetData<int>(WaterWidgetKeys.hoje, novoHoje);
  await HomeWidget.saveWidgetData<int>(
      WaterWidgetKeys.pendente, novoPendente);
  await HomeWidget.saveWidgetData<String>(WaterWidgetKeys.data, dataAgora);

  await HomeWidget.updateWidget(name: 'AguaWidgetProvider');
}
