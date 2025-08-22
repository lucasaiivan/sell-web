import 'package:flutter/material.dart';

/// Clase de utilidad para manejo de diseño responsivo
/// Implementa breakpoints estándar y helpers para adaptación
class ResponsiveHelper {
  ResponsiveHelper._();

  /// Breakpoints para diferentes tamaños de pantalla
  static const double mobile = 600;
  static const double tablet = 1024;
  static const double desktop = 1440;

  /// Determina si el dispositivo es móvil
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < mobile;
  }

  /// Determina si el dispositivo es tablet
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobile && width < desktop;
  }

  /// Determina si el dispositivo es desktop
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= desktop;
  }

  /// Obtiene el tamaño de pantalla actual
  static ScreenSize getScreenSize(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < mobile) return ScreenSize.mobile;
    if (width < desktop) return ScreenSize.tablet;
    return ScreenSize.desktop;
  }

  /// Proporciona valores diferentes según el tamaño de pantalla
  static T responsive<T>({
    required BuildContext context,
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    final screenSize = getScreenSize(context);
    switch (screenSize) {
      case ScreenSize.mobile:
        return mobile;
      case ScreenSize.tablet:
        return tablet ?? mobile;
      case ScreenSize.desktop:
        return desktop ?? tablet ?? mobile;
    }
  }

  /// Obtiene padding responsivo para diálogos
  static EdgeInsets getDialogPadding(BuildContext context) {
    return responsive(
      context: context,
      mobile: const EdgeInsets.all(12),
      tablet: const EdgeInsets.all(16),
      desktop: const EdgeInsets.all(20),
    );
  }

  /// Obtiene spacing responsivo
  static double getSpacing(BuildContext context, {double scale = 1.0}) {
    return responsive(
      context: context,
      mobile: 8.0 * scale,
      tablet: 12.0 * scale,
      desktop: 16.0 * scale,
    );
  }

  /// Obtiene ancho máximo para contenido
  static double getMaxContentWidth(BuildContext context) {
    return responsive(
      context: context,
      mobile: double.infinity,
      tablet: 600,
      desktop: 800,
    );
  }
}

/// Enumeración para tamaños de pantalla
enum ScreenSize { mobile, tablet, desktop }

/// Widget que construye contenido responsivo
class ResponsiveBuilder extends StatelessWidget {
  const ResponsiveBuilder({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  @override
  Widget build(BuildContext context) {
    return ResponsiveHelper.responsive(
      context: context,
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
    );
  }
}
