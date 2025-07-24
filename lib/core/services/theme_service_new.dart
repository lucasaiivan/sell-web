import 'package:flutter/material.dart';

/// Servicio para manejar el tema dinámico de la app y configuración de estilos
class ThemeService {
  static ThemeService? _instance;
  static ThemeService get instance {
    _instance ??= ThemeService._();
    return _instance!;
  }

  ThemeService._();

  final ValueNotifier<ThemeMode> _themeMode = ValueNotifier(ThemeMode.system);
  final ValueNotifier<Color> _seedColor = ValueNotifier(Colors.blue);

  ThemeMode get themeMode => _themeMode.value;
  Color get seedColor => _seedColor.value;

  /// Cambia el modo de tema de la app
  void setThemeMode(ThemeMode mode) {
    _themeMode.value = mode;
  }

  /// Cambia el color semilla de la app
  void setSeedColor(Color color) {
    _seedColor.value = color;
  }

  /// Notificador para escuchar cambios de tema
  ValueNotifier<ThemeMode> get themeModeNotifier => _themeMode;

  /// Notificador para escuchar cambios de color semilla
  ValueNotifier<Color> get seedColorNotifier => _seedColor;

  /// Colores semilla predefinidos para tema claro
  static const List<Color> lightSeedColors = [
    Colors.blue,
    Colors.teal,
  ];

  /// Colores semilla predefinidos para tema oscuro
  static const List<Color> darkSeedColors = [
    Colors.deepPurple,
    Colors.indigo,
  ];

  /// Configuración del tema claro
  ThemeData get lightTheme {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: _seedColor.value),
      useMaterial3: true,
      brightness: Brightness.light,
    );
  }

  /// Configuración del tema oscuro
  ThemeData get darkTheme {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: _seedColor.value,
        brightness: Brightness.dark,
      ),
      useMaterial3: true,
      brightness: Brightness.dark,
    );
  }
}
