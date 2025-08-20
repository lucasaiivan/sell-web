import 'package:flutter/material.dart';
import '../../core/services/storage/app_data_persistence_service.dart';
import '../../core/services/theme_service.dart';

/// Proveedor para manejar el tema (brillo) de la app usando ThemeService
class ThemeDataAppProvider extends ChangeNotifier {
  final ThemeService _themeService = ThemeService.instance;
  final AppDataPersistenceService _persistenceService =
      AppDataPersistenceService.instance;

  ThemeDataAppProvider() {
    _loadTheme();
    _loadSeedColor();
    _themeService.themeModeNotifier.addListener(() {
      notifyListeners();
    });
    _themeService.seedColorNotifier.addListener(() {
      notifyListeners();
    });
  }

  ThemeMode get themeMode => _themeService.themeMode;
  Color get seedColor => _themeService.seedColor;
  ThemeData get lightTheme => _themeService.lightTheme;
  ThemeData get darkTheme => _themeService.darkTheme;

  /// Cambia entre modo claro y oscuro
  void toggleTheme() {
    final newMode = _themeService.themeMode == ThemeMode.light
        ? ThemeMode.dark
        : ThemeMode.light;
    _themeService.setThemeMode(newMode);
    _saveTheme();
  }

  /// Cambia el color semilla del tema
  void changeSeedColor(Color color) {
    _themeService.setSeedColor(color);
    _saveSeedColor();
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

  /// Carga el color semilla guardado
  Future<void> _loadSeedColor() async {
    final colorValue = await _persistenceService.getSeedColor();
    if (colorValue != null) {
      _themeService.setSeedColor(Color(colorValue));
    }
  }

  /// Guarda el tema seleccionado
  Future<void> _saveTheme() async {
    final themeValue =
        _themeService.themeMode == ThemeMode.dark ? 'dark' : 'light';
    await _persistenceService.saveThemeMode(themeValue);
  }

  /// Guarda el color semilla seleccionado
  Future<void> _saveSeedColor() async {
    await _persistenceService.saveSeedColor(_themeService.seedColor.value);
  }
}
