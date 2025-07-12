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
  
  if (isPortrait && width < ResponsiveBreakpoints.tablet && 
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
  
  if (physicalWidth < 400 && devicePixelRatio > 2.0) {
    return true;
  }
  
  return false;
}

/// Determina si el dispositivo actual es una tablet.
/// 
/// Considera dispositivos con ancho entre 600px y 840px,
/// o dispositivos móviles en orientación landscape con suficiente espacio.
bool isTablet(BuildContext context) {
  final mediaQuery = MediaQuery.of(context);
  final size = mediaQuery.size;
  final width = size.width;
  final height = size.height;
  
  // Evitar que dispositivos móviles sean considerados tablets
  if (isMobile(context)) {
    return false;
  }
  
  // Rango típico de tablets
  if (width >= ResponsiveBreakpoints.mobile && 
      width < ResponsiveBreakpoints.desktop) {
    return true;
  }
  
  // Dispositivos en landscape que podrían ser tablets
  final isLandscape = width > height;
  final aspectRatio = width / height;
  
  if (isLandscape && width < ResponsiveBreakpoints.desktop && 
      aspectRatio <= 2.0) { // No demasiado ancho
    return true;
  }
  
  return false;
}

/// Determina si el dispositivo actual es desktop.
bool isDesktop(BuildContext context) {
  return !isMobile(context) && !isTablet(context);
}

/// Retorna el tipo de dispositivo actual.
enum DeviceType { mobile, tablet, desktop }

DeviceType getDeviceType(BuildContext context) {
  if (isMobile(context)) return DeviceType.mobile;
  if (isTablet(context)) return DeviceType.tablet;
  return DeviceType.desktop;
}

/// Utilidad para obtener valores responsivos basados en el tipo de dispositivo.
T getResponsiveValue<T>(
  BuildContext context, {
  required T mobile,
  T? tablet,
  T? desktop,
}) {
  final deviceType = getDeviceType(context);
  
  switch (deviceType) {
    case DeviceType.mobile:
      return mobile;
    case DeviceType.tablet:
      return tablet ?? mobile;
    case DeviceType.desktop:
      return desktop ?? tablet ?? mobile;
  }
}

/// Retorna el número de columnas apropiado para una grilla según el dispositivo.
int getGridColumns(BuildContext context, {
  int mobileColumns = 1,
  int tabletColumns = 2,
  int desktopColumns = 3,
}) {
  return getResponsiveValue(
    context,
    mobile: mobileColumns,
    tablet: tabletColumns,
    desktop: desktopColumns,
  );
}

/// Retorna el padding apropiado según el tipo de dispositivo.
EdgeInsets getResponsivePadding(BuildContext context, {
  EdgeInsets mobile = const EdgeInsets.all(16.0),
  EdgeInsets? tablet,
  EdgeInsets? desktop,
}) {
  return getResponsiveValue(
    context,
    mobile: mobile,
    tablet: tablet ?? const EdgeInsets.all(24.0),
    desktop: desktop ?? const EdgeInsets.all(32.0),
  );
}
