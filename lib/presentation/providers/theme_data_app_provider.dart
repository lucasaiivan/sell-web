import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Proveedor para manejar el tema (brillo) de la app
class ThemeDataAppProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;
  static const _key = 'theme_mode';

  ThemeDataAppProvider() {
    _loadTheme();
  }

  ThemeMode get themeMode => _themeMode;

  /// Cambia entre modo claro y oscuro
  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    _saveTheme();
    notifyListeners();
  }

  /// Carga el tema guardado
  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final mode = prefs.getString(_key);
    if (mode == 'dark') {
      _themeMode = ThemeMode.dark;
    } else {
      _themeMode = ThemeMode.light;
    }
    notifyListeners();
  }

  /// Guarda el tema seleccionado
  Future<void> _saveTheme() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, _themeMode == ThemeMode.dark ? 'dark' : 'light');
  }
}
