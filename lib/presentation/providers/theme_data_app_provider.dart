import 'package:flutter/material.dart';
import '../../core/services/app_data_persistence_service.dart';
import '../../core/services/theme_service.dart';

/// Proveedor para manejar el tema (brillo) de la app usando ThemeService
class ThemeDataAppProvider extends ChangeNotifier {
  final ThemeService _themeService = ThemeService();
  final AppDataPersistenceService _persistenceService =
      AppDataPersistenceService.instance;

  ThemeDataAppProvider() {
    _loadTheme();
    _themeService.themeModeNotifier.addListener(() {
      notifyListeners();
    });
  }

  ThemeMode get themeMode => _themeService.themeMode;

  /// Cambia entre modo claro y oscuro
  void toggleTheme() {
    final newMode = _themeService.themeMode == ThemeMode.light
        ? ThemeMode.dark
        : ThemeMode.light;
    _themeService.setThemeMode(newMode);
    _saveTheme();
  }

  /// Carga el tema guardado
  Future<void> _loadTheme() async {
    final mode = await _persistenceService.getThemeMode();
    if (mode == 'dark') {
      _themeService.setThemeMode(ThemeMode.dark);
    } else {
      _themeService.setThemeMode(ThemeMode.light);
    }
  }

  /// Guarda el tema seleccionado
  Future<void> _saveTheme() async {
    final themeValue =
        _themeService.themeMode == ThemeMode.dark ? 'dark' : 'light';
    await _persistenceService.saveThemeMode(themeValue);
  }
}
