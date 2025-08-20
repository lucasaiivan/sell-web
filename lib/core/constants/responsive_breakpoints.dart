import 'package:flutter/material.dart';

/// Breakpoints para diferentes tamaños de pantalla siguiendo Material Design 3
class ResponsiveBreakpoints {
  static const double mobile = 600;
  static const double tablet = 840;
  static const double desktop = 1200;
  static const double largeDesktop = 1600;

  // Relaciones de aspecto típicas para dispositivos móviles
  static const double minMobileAspectRatio = 0.4; // Muy alto y estrecho
  static const double maxMobileAspectRatio = 1.2; // Casi cuadrado

  // Tamaños mínimos para componentes UI
  static const double minTouchTarget = 48.0;
  static const double cardElevation = 4.0;
  static const double borderRadius = 8.0;

  // Espaciado estándar
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXL = 32.0;
}

/// Determina si el dispositivo actual es móvil basándose en múltiples factores.
///
/// Considera:
/// - Ancho de pantalla menor a 600px (Material Design 3 breakpoint)
/// - Relación de aspecto típica de dispositivos móviles
/// - Orientación del dispositivo
/// - Densidad de píxeles para pantallas muy pequeñas
bool isMobile(BuildContext context) {
  final mediaQuery = MediaQuery.of(context);
  final size = mediaQuery.size;
  final width = size.width;
  final height = size.height;

  // Factor 1: Ancho menor al breakpoint móvil estándar
  if (width < ResponsiveBreakpoints.mobile) {
    return true;
  }

  // Factor 2: Dispositivos en orientación portrait con ancho limitado
  final aspectRatio = width / height;
  final isPortrait = height > width;

  if (isPortrait &&
      width < ResponsiveBreakpoints.tablet &&
      aspectRatio >= ResponsiveBreakpoints.minMobileAspectRatio &&
      aspectRatio <= ResponsiveBreakpoints.maxMobileAspectRatio) {
    return true;
  }

  // Factor 3: Pantallas muy pequeñas independientemente de la orientación
  final smallestDimension = width < height ? width : height;
  if (smallestDimension < 400) {
    return true;
  }

  // Factor 4: Dispositivos con alta densidad de píxeles pero pantalla física pequeña
  final devicePixelRatio = mediaQuery.devicePixelRatio;
  final physicalWidth = width / devicePixelRatio;
  if (physicalWidth < 300) {
    // Pantalla física menor a 300px
    return true;
  }

  return false;
}

/// Determina si el dispositivo actual es una tablet
bool isTablet(BuildContext context) {
  final width = MediaQuery.of(context).size.width;
  return width >= ResponsiveBreakpoints.mobile &&
      width < ResponsiveBreakpoints.desktop;
}

/// Determina si el dispositivo actual es desktop
bool isDesktop(BuildContext context) {
  final width = MediaQuery.of(context).size.width;
  return width >= ResponsiveBreakpoints.desktop;
}

/// Determina si el dispositivo actual es large desktop
bool isLargeDesktop(BuildContext context) {
  final width = MediaQuery.of(context).size.width;
  return width >= ResponsiveBreakpoints.largeDesktop;
}

/// Widget builder que adapta el layout según el tamaño de pantalla
class ResponsiveBuilder extends StatelessWidget {
  const ResponsiveBuilder({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
    this.largeDesktop,
  });

  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;
  final Widget? largeDesktop;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= ResponsiveBreakpoints.largeDesktop) {
          return largeDesktop ?? desktop ?? tablet ?? mobile;
        } else if (constraints.maxWidth >= ResponsiveBreakpoints.desktop) {
          return desktop ?? tablet ?? mobile;
        } else if (constraints.maxWidth >= ResponsiveBreakpoints.mobile) {
          return tablet ?? mobile;
        } else {
          return mobile;
        }
      },
    );
  }
}

/// Clase utilitaria para obtener valores responsivos
class ResponsiveValue<T> {
  const ResponsiveValue({
    required this.mobile,
    this.tablet,
    this.desktop,
    this.largeDesktop,
  });

  final T mobile;
  final T? tablet;
  final T? desktop;
  final T? largeDesktop;

  T getValue(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    if (width >= ResponsiveBreakpoints.largeDesktop) {
      return largeDesktop ?? desktop ?? tablet ?? mobile;
    } else if (width >= ResponsiveBreakpoints.desktop) {
      return desktop ?? tablet ?? mobile;
    } else if (width >= ResponsiveBreakpoints.mobile) {
      return tablet ?? mobile;
    } else {
      return mobile;
    }
  }
}

/// Extension para obtener breakpoints desde MediaQuery
extension ResponsiveContext on BuildContext {
  bool get isMobileDevice => isMobile(this);
  bool get isTabletDevice => isTablet(this);
  bool get isDesktopDevice => isDesktop(this);
  bool get isLargeDesktopDevice => isLargeDesktop(this);

  T responsive<T>({
    required T mobile,
    T? tablet,
    T? desktop,
    T? largeDesktop,
  }) {
    return ResponsiveValue<T>(
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
      largeDesktop: largeDesktop,
    ).getValue(this);
  }
}
