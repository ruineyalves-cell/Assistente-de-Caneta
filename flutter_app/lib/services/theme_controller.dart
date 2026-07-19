import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Lote 24 — Controlador de tema. 3 posições:
///   • Automático → segue o sistema (padrão para novos usuários)
///   • Claro
///   • Escuro
///
/// Persiste em SharedPreferences (`recorpo_theme_mode`). Mudança é
/// imediata pelo `notifyListeners()`, MyApp escuta e re-renderiza.
class ThemeController extends ChangeNotifier {
  static const _kPrefs = 'recorpo_theme_mode';

  ThemeMode _mode = ThemeMode.system;
  bool _carregado = false;

  ThemeMode get mode => _mode;
  bool get carregado => _carregado;

  Future<void> inicializar() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kPrefs);
    _mode = _parse(raw);
    _carregado = true;
    notifyListeners();
  }

  Future<void> setMode(ThemeMode novo) async {
    _mode = novo;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kPrefs, _serializar(novo));
  }

  ThemeMode _parse(String? raw) {
    switch (raw) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  String _serializar(ThemeMode m) {
    switch (m) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }
}
