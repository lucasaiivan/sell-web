import 'package:flutter/material.dart';

/// Mixin que proporciona utilidades para diseño responsive
/// Simplifica la creación de layouts adaptativos
mixin ResponsiveMixin<T extends StatefulWidget> on State<T> {
  
  // ==========================================
  // CONSTANTES DE BREAKPOINTS
  // ==========================================
  
  static const double _mobileBreakpoint = 600;
  static const double _tabletBreakpoint = 840;
  static const double _desktopBreakpoint = 1200;
  static const double _largeDesktopBreakpoint = 1600;
  
  // ==========================================
  // GETTERS DE INFORMACIÓN DEL DISPOSITIVO
  // ==========================================
  
  /// Obtiene el ancho de la pantalla
  double get screenWidth => MediaQuery.of(context).size.width;
  
  /// Obtiene el alto de la pantalla
  double get screenHeight => MediaQuery.of(context).size.height;
  
  /// Verifica si es una pantalla móvil
  bool get isMobile => screenWidth < _mobileBreakpoint;
  
  /// Verifica si es una tablet
  bool get isTablet => screenWidth >= _mobileBreakpoint && screenWidth < _desktopBreakpoint;
  
  /// Verifica si es desktop
  bool get isDesktop => screenWidth >= _desktopBreakpoint;
  
  /// Verifica si es desktop grande
  bool get isLargeDesktop => screenWidth >= _largeDesktopBreakpoint;
  
  /// Verifica si es una pantalla pequeña (móvil)
  bool get isSmallScreen => isMobile;
  
  /// Verifica si es una pantalla mediana (tablet)
  bool get isMediumScreen => isTablet;
  
  /// Verifica si es una pantalla grande (desktop+)
  bool get isLargeScreen => isDesktop;
  
  /// Obtiene el tipo de dispositivo
  DeviceType get deviceType {
    if (isMobile) return DeviceType.mobile;
    if (isTablet) return DeviceType.tablet;
    if (isLargeDesktop) return DeviceType.largeDesktop;
    return DeviceType.desktop;
  }
  
  /// Verifica si está en modo landscape
  bool get isLandscape => MediaQuery.of(context).orientation == Orientation.landscape;
  
  /// Verifica si está en modo portrait
  bool get isPortrait => MediaQuery.of(context).orientation == Orientation.portrait;
  
  /// Obtiene la densidad de píxeles
  double get pixelRatio => MediaQuery.of(context).devicePixelRatio;
  
  // ==========================================
  // MÉTODOS DE VALORES RESPONSIVE
  // ==========================================
  
  /// Obtiene un valor basado en el tipo de dispositivo
  T responsive<T>({
    required T mobile,
    T? tablet,
    T? desktop,
    T? largeDesktop,
  }) {
    switch (deviceType) {
      case DeviceType.mobile:
        return mobile;
      case DeviceType.tablet:
        return tablet ?? mobile;
      case DeviceType.desktop:
        return desktop ?? tablet ?? mobile;
      case DeviceType.largeDesktop:
        return largeDesktop ?? desktop ?? tablet ?? mobile;
    }
  }
  
  /// Obtiene un valor basado en breakpoints personalizados
  T responsiveValue<T>({
    required T defaultValue,
    T? mobile,
    T? tablet,
    T? desktop,
    double? mobileBreakpoint,
    double? tabletBreakpoint,
    double? desktopBreakpoint,
  }) {
    final mobileBreak = mobileBreakpoint ?? _mobileBreakpoint;
    final tabletBreak = tabletBreakpoint ?? _tabletBreakpoint;
    final desktopBreak = desktopBreakpoint ?? _desktopBreakpoint;
    
    if (screenWidth < mobileBreak && mobile != null) {
      return mobile;
    } else if (screenWidth < tabletBreak && tablet != null) {
      return tablet;
    } else if (screenWidth < desktopBreak && desktop != null) {
      return desktop;
    }
    
    return defaultValue;
  }
  
  /// Obtiene un padding responsive
  EdgeInsets responsivePadding({
    EdgeInsets? mobile,
    EdgeInsets? tablet,
    EdgeInsets? desktop,
    EdgeInsets? largeDesktop,
  }) {
    return responsive(
      mobile: mobile ?? const EdgeInsets.all(16),
      tablet: tablet ?? const EdgeInsets.all(24),
      desktop: desktop ?? const EdgeInsets.all(32),
      largeDesktop: largeDesktop ?? const EdgeInsets.all(40),
    );
  }
  
  /// Obtiene un margin responsive
  EdgeInsets responsiveMargin({
    EdgeInsets? mobile,
    EdgeInsets? tablet,
    EdgeInsets? desktop,
    EdgeInsets? largeDesktop,
  }) {
    return responsive(
      mobile: mobile ?? const EdgeInsets.all(8),
      tablet: tablet ?? const EdgeInsets.all(12),
      desktop: desktop ?? const EdgeInsets.all(16),
      largeDesktop: largeDesktop ?? const EdgeInsets.all(20),
    );
  }
  
  /// Obtiene un font size responsive
  double responsiveFontSize({
    double? mobile,
    double? tablet,
    double? desktop,
    double? largeDesktop,
    double baseFontSize = 16,
  }) {
    return responsive(
      mobile: mobile ?? baseFontSize,
      tablet: tablet ?? baseFontSize * 1.1,
      desktop: desktop ?? baseFontSize * 1.2,
      largeDesktop: largeDesktop ?? baseFontSize * 1.3,
    );
  }
  
  /// Obtiene un spacing responsive
  double responsiveSpacing({
    double? mobile,
    double? tablet,
    double? desktop,
    double? largeDesktop,
  }) {
    return responsive(
      mobile: mobile ?? 8,
      tablet: tablet ?? 12,
      desktop: desktop ?? 16,
      largeDesktop: largeDesktop ?? 20,
    );
  }
  
  // ==========================================
  // MÉTODOS DE LAYOUT RESPONSIVE
  // ==========================================
  
  /// Obtiene el número de columnas para un grid responsive
  int responsiveColumns({
    int? mobile,
    int? tablet,
    int? desktop,
    int? largeDesktop,
  }) {
    return responsive(
      mobile: mobile ?? 1,
      tablet: tablet ?? 2,
      desktop: desktop ?? 3,
      largeDesktop: largeDesktop ?? 4,
    );
  }
  
  /// Obtiene el cross axis count para un GridView
  int responsiveCrossAxisCount({
    int? mobile,
    int? tablet,
    int? desktop,
    int? largeDesktop,
    double? itemWidth,
  }) {
    if (itemWidth != null) {
      // Calcula automáticamente basado en el ancho del item
      final columns = (screenWidth / itemWidth).floor();
      return columns.clamp(1, responsive(
        mobile: mobile ?? 2,
        tablet: tablet ?? 4,
        desktop: desktop ?? 6,
        largeDesktop: largeDesktop ?? 8,
      ));
    }
    
    return responsiveColumns(
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
      largeDesktop: largeDesktop,
    );
  }
  
  /// Obtiene un aspect ratio responsive
  double responsiveAspectRatio({
    double? mobile,
    double? tablet,
    double? desktop,
    double? largeDesktop,
  }) {
    return responsive(
      mobile: mobile ?? 1.0,
      tablet: tablet ?? 1.2,
      desktop: desktop ?? 1.5,
      largeDesktop: largeDesktop ?? 1.6,
    );
  }
  
  /// Obtiene un ancho máximo responsive
  double responsiveMaxWidth({
    double? mobile,
    double? tablet,
    double? desktop,
    double? largeDesktop,
  }) {
    return responsive(
      mobile: mobile ?? double.infinity,
      tablet: tablet ?? 600,
      desktop: desktop ?? 800,
      largeDesktop: largeDesktop ?? 1200,
    );
  }
  
  // ==========================================
  // WIDGETS RESPONSIVE
  // ==========================================
  
  /// Widget que se adapta automáticamente al tamaño de pantalla
  Widget responsiveBuilder({
    required Widget Function(BuildContext context, DeviceType deviceType) builder,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return builder(context, deviceType);
      },
    );
  }
  
  /// Widget que muestra diferentes layouts según el dispositivo
  Widget responsiveLayout({
    required Widget mobile,
    Widget? tablet,
    Widget? desktop,
    Widget? largeDesktop,
  }) {
    return responsiveBuilder(
      builder: (context, deviceType) {
        switch (deviceType) {
          case DeviceType.mobile:
            return mobile;
          case DeviceType.tablet:
            return tablet ?? mobile;
          case DeviceType.desktop:
            return desktop ?? tablet ?? mobile;
          case DeviceType.largeDesktop:
            return largeDesktop ?? desktop ?? tablet ?? mobile;
        }
      },
    );
  }
  
  /// Widget wrapper que aplica padding responsive
  Widget responsiveContainer({
    required Widget child,
    EdgeInsets? mobilePadding,
    EdgeInsets? tabletPadding,
    EdgeInsets? desktopPadding,
    EdgeInsets? largeDesktopPadding,
    Color? backgroundColor,
    double? maxWidth,
  }) {
    return Container(
      width: double.infinity,
      constraints: maxWidth != null 
          ? BoxConstraints(maxWidth: maxWidth)
          : null,
      padding: responsivePadding(
        mobile: mobilePadding,
        tablet: tabletPadding,
        desktop: desktopPadding,
        largeDesktop: largeDesktopPadding,
      ),
      decoration: backgroundColor != null
          ? BoxDecoration(color: backgroundColor)
          : null,
      child: child,
    );
  }
  
  /// Widget que crea un grid responsive
  Widget responsiveGrid({
    required List<Widget> children,
    int? mobileColumns,
    int? tabletColumns,
    int? desktopColumns,
    int? largeDesktopColumns,
    double? mainAxisSpacing,
    double? crossAxisSpacing,
    double? childAspectRatio,
  }) {
    final columns = responsiveColumns(
      mobile: mobileColumns,
      tablet: tabletColumns,
      desktop: desktopColumns,
      largeDesktop: largeDesktopColumns,
    );
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        mainAxisSpacing: mainAxisSpacing ?? responsiveSpacing(),
        crossAxisSpacing: crossAxisSpacing ?? responsiveSpacing(),
        childAspectRatio: childAspectRatio ?? responsiveAspectRatio(),
      ),
      itemCount: children.length,
      itemBuilder: (context, index) => children[index],
    );
  }
  
  /// Widget que crea una lista responsive (vertical u horizontal)
  Widget responsiveList({
    required List<Widget> children,
    bool? forceMobileVertical,
    double? spacing,
    MainAxisAlignment? mainAxisAlignment,
    CrossAxisAlignment? crossAxisAlignment,
  }) {
    final shouldBeVertical = forceMobileVertical == true && isMobile;
    final actualSpacing = spacing ?? responsiveSpacing();
    
    if (shouldBeVertical || isPortrait) {
      return Column(
        mainAxisAlignment: mainAxisAlignment ?? MainAxisAlignment.start,
        crossAxisAlignment: crossAxisAlignment ?? CrossAxisAlignment.center,
        children: children
            .asMap()
            .entries
            .expand((entry) => [
                  entry.value,
                  if (entry.key < children.length - 1)
                    SizedBox(height: actualSpacing),
                ])
            .toList(),
      );
    } else {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: mainAxisAlignment ?? MainAxisAlignment.start,
          crossAxisAlignment: crossAxisAlignment ?? CrossAxisAlignment.center,
          children: children
              .asMap()
              .entries
              .expand((entry) => [
                    entry.value,
                    if (entry.key < children.length - 1)
                      SizedBox(width: actualSpacing),
                  ])
              .toList(),
        ),
      );
    }
  }
  
  // ==========================================
  // UTILIDADES DE CÁLCULO
  // ==========================================
  
  /// Calcula el ancho disponible considerando padding
  double get availableWidth {
    final padding = responsivePadding();
    return screenWidth - padding.horizontal;
  }
  
  /// Calcula el alto disponible considerando padding y safe area
  double get availableHeight {
    final padding = responsivePadding();
    final mediaQuery = MediaQuery.of(context);
    final safeAreaHeight = mediaQuery.padding.top + mediaQuery.padding.bottom;
    return screenHeight - padding.vertical - safeAreaHeight;
  }
  
  /// Calcula si un ancho es suficiente para mostrar elementos
  bool hasEnoughWidth(double requiredWidth) {
    return availableWidth >= requiredWidth;
  }
  
  /// Calcula el número óptimo de columnas basado en ancho mínimo de item
  int calculateOptimalColumns(double minItemWidth, {int maxColumns = 6}) {
    final columns = (availableWidth / minItemWidth).floor();
    return columns.clamp(1, maxColumns);
  }
  
  /// Calcula si debe mostrar sidebar basado en el ancho disponible
  bool get shouldShowSidebar => isDesktop && availableWidth > 1000;
  
  /// Calcula si debe usar layout compacto
  bool get shouldUseCompactLayout => isMobile || (isTablet && isPortrait);
  
  // ==========================================
  // MÉTODOS DE ANIMACIÓN RESPONSIVE
  // ==========================================
  
  /// Duración de animación basada en el dispositivo
  Duration get responsiveAnimationDuration {
    return responsive(
      mobile: const Duration(milliseconds: 200),
      tablet: const Duration(milliseconds: 250),
      desktop: const Duration(milliseconds: 300),
    );
  }
  
  /// Curva de animación basada en el dispositivo
  Curve get responsiveAnimationCurve {
    return responsive(
      mobile: Curves.easeOut,
      tablet: Curves.easeInOut,
      desktop: Curves.easeInOutCubic,
    );
  }
}

/// Enum para tipos de dispositivo
enum DeviceType {
  mobile,
  tablet,
  desktop,
  largeDesktop,
}

/// Extension para obtener información del DeviceType
extension DeviceTypeExtension on DeviceType {
  
  /// Nombre legible del tipo de dispositivo
  String get displayName {
    switch (this) {
      case DeviceType.mobile:
        return 'Móvil';
      case DeviceType.tablet:
        return 'Tablet';
      case DeviceType.desktop:
        return 'Escritorio';
      case DeviceType.largeDesktop:
        return 'Escritorio Grande';
    }
  }
  
  /// Verifica si es móvil
  bool get isMobile => this == DeviceType.mobile;
  
  /// Verifica si es tablet
  bool get isTablet => this == DeviceType.tablet;
  
  /// Verifica si es desktop (cualquier tamaño)
  bool get isDesktop => this == DeviceType.desktop || this == DeviceType.largeDesktop;
  
  /// Verifica si es desktop pequeño
  bool get isSmallDesktop => this == DeviceType.desktop;
  
  /// Verifica si es desktop grande
  bool get isLargeDesktop => this == DeviceType.largeDesktop;
  
  /// Verifica si soporta hover
  bool get supportsHover => isDesktop;
  
  /// Verifica si debe mostrar tooltips
  bool get shouldShowTooltips => isDesktop;
  
  /// Verifica si debe usar gestos touch
  bool get supportsTouchGestures => isMobile || isTablet;
}

/// Mixin para detección de orientación
mixin OrientationMixin<T extends StatefulWidget> on State<T> {
  
  /// Callback que se ejecuta cuando cambia la orientación
  void onOrientationChanged(Orientation orientation) {
    // Override en la clase que usa el mixin
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final orientation = MediaQuery.of(context).orientation;
    onOrientationChanged(orientation);
  }
}

/// Mixin para detección de cambios de tamaño
mixin SizeChangeMixin<T extends StatefulWidget> on State<T> {
  
  Size? _previousSize;
  
  /// Callback que se ejecuta cuando cambia el tamaño
  void onSizeChanged(Size oldSize, Size newSize) {
    // Override en la clase que usa el mixin
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final currentSize = MediaQuery.of(context).size;
    
    if (_previousSize != null && _previousSize != currentSize) {
      onSizeChanged(_previousSize!, currentSize);
    }
    
    _previousSize = currentSize;
    super.didChangeDependencies();
  }
}

/// Utilidades estáticas para responsive design
class ResponsiveUtils {
  
  /// Calcula el ancho óptimo para un item en un grid
  static double calculateItemWidth(
    double screenWidth,
    int columns, {
    double spacing = 16,
    double padding = 32,
  }) {
    final availableWidth = screenWidth - padding;
    final totalSpacing = spacing * (columns - 1);
    return (availableWidth - totalSpacing) / columns;
  }
  
  /// Determina si una pantalla es considerada pequeña
  static bool isSmallScreen(double width) => width < 600;
  
  /// Determina si una pantalla es considerada mediana
  static bool isMediumScreen(double width) => width >= 600 && width < 1200;
  
  /// Determina si una pantalla es considerada grande
  static bool isLargeScreen(double width) => width >= 1200;
  
  /// Obtiene el DeviceType basado en el ancho
  static DeviceType getDeviceType(double width) {
    if (width < 600) return DeviceType.mobile;
    if (width < 840) return DeviceType.tablet;
    if (width < 1600) return DeviceType.desktop;
    return DeviceType.largeDesktop;
  }
  
  /// Calcula el número de columnas recomendado para un ancho dado
  static int getRecommendedColumns(double width) {
    if (width < 600) return 1;
    if (width < 840) return 2;
    if (width < 1200) return 3;
    if (width < 1600) return 4;
    return 5;
  }
}
