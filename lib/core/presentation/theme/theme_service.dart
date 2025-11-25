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

  // Configuraciones personalizables para tonalidades de desenfoque
  double _dialogBarrierOpacityLight = 0.2;
  double _dialogBarrierOpacityDark = 0.15;
  double _drawerScrimOpacityLight = 0.15;
  double _drawerScrimOpacityDark = 0.1;
  double _bottomSheetBarrierOpacityLight = 0.18;
  double _bottomSheetBarrierOpacityDark = 0.12;

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

  /// Configura la opacidad del desenfoque de diálogos
  void setDialogBarrierOpacity({
    double? light,
    double? dark,
  }) {
    if (light != null) _dialogBarrierOpacityLight = light;
    if (dark != null) _dialogBarrierOpacityDark = dark;
  }

  /// Configura la opacidad del scrim de drawers
  void setDrawerScrimOpacity({
    double? light,
    double? dark,
  }) {
    if (light != null) _drawerScrimOpacityLight = light;
    if (dark != null) _drawerScrimOpacityDark = dark;
  }

  /// Configura la opacidad del barrier de bottom sheets
  void setBottomSheetBarrierOpacity({
    double? light,
    double? dark,
  }) {
    if (light != null) _bottomSheetBarrierOpacityLight = light;
    if (dark != null) _bottomSheetBarrierOpacityDark = dark;
  }

  /// Getters para acceder a las configuraciones actuales
  double get dialogBarrierOpacityLight => _dialogBarrierOpacityLight;
  double get dialogBarrierOpacityDark => _dialogBarrierOpacityDark;
  double get drawerScrimOpacityLight => _drawerScrimOpacityLight;
  double get drawerScrimOpacityDark => _drawerScrimOpacityDark;
  double get bottomSheetBarrierOpacityLight => _bottomSheetBarrierOpacityLight;
  double get bottomSheetBarrierOpacityDark => _bottomSheetBarrierOpacityDark;

  /// Restablece todas las opacidades a sus valores por defecto
  void resetBarrierOpacities() {
    _dialogBarrierOpacityLight = 0.2;
    _dialogBarrierOpacityDark = 0.15;
    _drawerScrimOpacityLight = 0.15;
    _drawerScrimOpacityDark = 0.1;
    _bottomSheetBarrierOpacityLight = 0.18;
    _bottomSheetBarrierOpacityDark = 0.12;
  }

  /// Configura tonalidades muy sutiles (apenas perceptibles)
  void setSubtleBarriers() {
    setDialogBarrierOpacity(light: 0.08, dark: 0.05);
    setDrawerScrimOpacity(light: 0.06, dark: 0.04);
    setBottomSheetBarrierOpacity(light: 0.07, dark: 0.05);
  }

  /// Configura tonalidades moderadas (equilibradas)
  void setModerateBarriers() {
    setDialogBarrierOpacity(light: 0.25, dark: 0.2);
    setDrawerScrimOpacity(light: 0.2, dark: 0.15);
    setBottomSheetBarrierOpacity(light: 0.22, dark: 0.17);
  }

  /// Configura tonalidades fuertes (mayor enfoque en modales)
  void setStrongBarriers() {
    setDialogBarrierOpacity(light: 0.4, dark: 0.35);
    setDrawerScrimOpacity(light: 0.3, dark: 0.25);
    setBottomSheetBarrierOpacity(light: 0.35, dark: 0.3);
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
    late ColorScheme colorScheme;

    // Para el color negro, crear un tema con fondo completamente negro
    if (_seedColor.value == Colors.black) {
      colorScheme = _createBlackColorScheme(Brightness.light);
    } else {
      colorScheme = ColorScheme.fromSeed(seedColor: _seedColor.value);
    }

    return _buildTheme(colorScheme, false);
  }

  /// Configuración del tema oscuro
  ThemeData get darkTheme {
    late ColorScheme colorScheme;

    // Para el color negro, crear un tema con fondo completamente negro
    if (_seedColor.value == Colors.black) {
      colorScheme = _createBlackColorScheme(Brightness.dark);
    } else {
      colorScheme = ColorScheme.fromSeed(
        seedColor: _seedColor.value,
        brightness: Brightness.dark,
      );
    }

    return _buildTheme(colorScheme, true);
  }

  /// Crea un ColorScheme personalizado para el color negro con fondo completamente negro
  ColorScheme _createBlackColorScheme(Brightness brightness) {
    if (brightness == Brightness.light) {
      // Tema claro con acentos negros pero fondo claro
      return const ColorScheme.light(
        primary: Colors.black,
        onPrimary: Colors.white,
        primaryContainer: Color(0xFF333333),
        onPrimaryContainer: Colors.white,
        secondary: Color(0xFF424242),
        onSecondary: Colors.white,
        secondaryContainer: Color(0xFF616161),
        onSecondaryContainer: Colors.white,
        tertiary: Color(0xFF757575),
        onTertiary: Colors.white,
        tertiaryContainer: Color(0xFF9E9E9E),
        onTertiaryContainer: Colors.black,
        error: Color(0xFFBA1A1A),
        onError: Colors.white,
        errorContainer: Color(0xFFFFDAD6),
        onErrorContainer: Color(0xFF410002),
        surface: Colors.white,
        onSurface: Colors.black,
        surfaceContainerHighest: Color(0xFFF3F3F3),
        onSurfaceVariant: Color(0xFF424242),
        outline: Color(0xFF757575),
        outlineVariant: Color(0xFFBDBDBD),
        shadow: Colors.black,
        scrim: Colors.black,
        inverseSurface: Colors.black,
        onInverseSurface: Colors.white,
        inversePrimary: Colors.white,
      );
    } else {
      // Tema oscuro con fondo gris muy oscuro (más claro que negro puro)
      return const ColorScheme.dark(
        primary: Colors.white,
        onPrimary: Colors.black,
        primaryContainer: Color(0xFF2C2C2C),
        onPrimaryContainer: Colors.white,
        secondary: Color(0xFFBDBDBD),
        onSecondary: Colors.black,
        secondaryContainer: Color(0xFF424242),
        onSecondaryContainer: Colors.white,
        tertiary: Color(0xFF9E9E9E),
        onTertiary: Colors.black,
        tertiaryContainer: Color(0xFF616161),
        onTertiaryContainer: Colors.white,
        error: Color(0xFFFFB4AB),
        onError: Color(0xFF690005),
        errorContainer: Color(0xFF93000A),
        onErrorContainer: Color(0xFFFFDAD6),
        surface:
            Color(0xFF1A1A1A), // Fondo gris muy oscuro en lugar de negro puro
        onSurface: Colors.white,
        surfaceContainerHighest: Color(0xFF2A2A2A),
        onSurfaceVariant: Color(0xFFBDBDBD),
        outline: Color(0xFF757575),
        outlineVariant: Color(0xFF424242),
        shadow: Colors.black,
        scrim: Colors.black,
        inverseSurface: Colors.white,
        onInverseSurface: Colors.black,
        inversePrimary: Colors.black,
      );
    }
  }

  /// Obtiene el color de fondo optimizado para ElevatedButton
  Color _getElevatedButtonBackgroundColor(
      ColorScheme colorScheme, bool isDark) {
    // Para el tema negro, usar un color que contraste bien
    if (_seedColor.value == Colors.black) {
      return isDark
          ? const Color(0xFF333333) // Gris más claro para mejor visibilidad
          : colorScheme.primary; // Negro en tema claro
    }

    // Para otros colores, usar el primaryContainer con mejor saturación
    return isDark
        // ignore: deprecated_member_use
        ? colorScheme.primaryContainer.withOpacity(0.9)
        : colorScheme.primary;
  }

  /// Obtiene el color de texto optimizado para ElevatedButton
  Color _getElevatedButtonForegroundColor(
      ColorScheme colorScheme, bool isDark) {
    // Para el tema negro, asegurar contraste máximo
    if (_seedColor.value == Colors.black) {
      return isDark
          ? Colors.white // Blanco en tema oscuro
          : colorScheme.onPrimary; // Blanco en tema claro
    }

    // Para otros colores, usar los colores apropiados del esquema
    return isDark ? colorScheme.onPrimaryContainer : colorScheme.onPrimary;
  }

  /// Obtiene el tinte de superficie para ElevatedButton
  Color _getElevatedButtonSurfaceTint(ColorScheme colorScheme, bool isDark) {
    // Para el tema negro, usar un tinte sutil
    if (_seedColor.value == Colors.black) {
      return isDark
          // ignore: deprecated_member_use
          ? Colors.white.withOpacity(0.1)
          // ignore: deprecated_member_use
          : Colors.black.withOpacity(0.1);
    }

    // Para otros colores, usar el primary con opacidad reducida
    // ignore: deprecated_member_use
    return colorScheme.primary.withOpacity(isDark ? 0.2 : 0.3);
  }

  /// Construye el tema con configuraciones personalizadas de diálogos y drawers
  ThemeData _buildTheme(ColorScheme colorScheme, bool isDark) {
    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,

      // Configuración personalizada para diálogos
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: colorScheme.surfaceTint,
        // Tonalidad personalizable para el fondo del diálogo
        // ignore: deprecated_member_use
        barrierColor: colorScheme.onSurface.withOpacity(
          isDark ? _dialogBarrierOpacityDark : _dialogBarrierOpacityLight,
        ),
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // Configuración personalizada para drawers
      drawerTheme: DrawerThemeData(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: colorScheme.surfaceTint,
        // Tonalidad personalizable para el scrim del drawer
        // ignore: deprecated_member_use
        scrimColor: colorScheme.onSurface.withOpacity(
          isDark ? _drawerScrimOpacityDark : _drawerScrimOpacityLight,
        ),
        elevation: 1,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
        ),
      ),

      // Configuración para Bottom Sheets (si los usas)
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: colorScheme.surfaceTint,
        modalBackgroundColor: colorScheme.surface,
        // ignore: deprecated_member_use
        modalBarrierColor: colorScheme.onSurface.withOpacity(
          isDark
              ? _bottomSheetBarrierOpacityDark
              : _bottomSheetBarrierOpacityLight,
        ),
        elevation: 1,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(16),
          ),
        ),
      ),

      // Configuración mejorada para ElevatedButton
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          // Color de fondo mejorado con mejor contraste
          backgroundColor:
              _getElevatedButtonBackgroundColor(colorScheme, isDark),
          foregroundColor:
              _getElevatedButtonForegroundColor(colorScheme, isDark),

          // Mejora de la elevación y sombras
          elevation: isDark ? 2 : 1,
          // ignore: deprecated_member_use
          shadowColor: colorScheme.shadow.withOpacity(isDark ? 0.3 : 0.2),

          // Configuración de superficie para Material 3
          surfaceTintColor: _getElevatedButtonSurfaceTint(colorScheme, isDark),

          // Forma consistente con el diseño general
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),

          // Padding optimizado para mejor UX
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),

          // Configuración de estados (hover, pressed, disabled)
        ).copyWith(
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              // ignore: deprecated_member_use
              return colorScheme.primary.withOpacity(0.12);
            }
            if (states.contains(WidgetState.hovered)) {
              // ignore: deprecated_member_use
              return colorScheme.primary.withOpacity(0.08);
            }
            if (states.contains(WidgetState.focused)) {
              // ignore: deprecated_member_use
              return colorScheme.primary.withOpacity(0.10);
            }
            return null;
          }),
        ),
      ),
    );
  }
}
