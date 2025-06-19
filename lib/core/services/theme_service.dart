import 'package:flutter/material.dart';

/// Servicio para manejar el tema dinámico de la app
class ThemeService {
  final ValueNotifier<ThemeMode> _themeMode = ValueNotifier(ThemeMode.system);

  ThemeMode get themeMode => _themeMode.value;

  /// Cambia el modo de tema de la app
  void setThemeMode(ThemeMode mode) {
    _themeMode.value = mode;
  }

  /// Notificador para escuchar cambios de tema
  ValueNotifier<ThemeMode> get themeModeNotifier => _themeMode;
}
