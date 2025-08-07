import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:sellweb/core/utils/responsive.dart';
import 'package:sellweb/core/widgets/buttons/buttons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_data_app_provider.dart';
import 'login_page.dart';
import 'dart:async';
import 'dart:ui';

/// Página de presentación de la aplicación que muestra las características principales
/// y permite al usuario iniciar sesión a través del AppBar
class AppPresentationPage extends StatefulWidget {
  const AppPresentationPage({super.key});

  @override
  State<AppPresentationPage> createState() => _AppPresentationPageState();
}

class _AppPresentationPageState extends State<AppPresentationPage> {
  final ScrollController _scrollController = ScrollController();
  bool _isScrolled = false;
  Color backgroundContainerColor = Colors.transparent;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final bool isScrolled = _scrollController.offset > 100;
    if (_isScrolled != isScrolled) {
      setState(() {
        _isScrolled = isScrolled;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    backgroundContainerColor = isDark ? Colors.black : Colors.white;
    
    // Colores mejorados para el AppBar considerando el tema
    Color accentAppbarColor = _isScrolled
        ? (isDark 
            ? colorScheme.primary.withValues(alpha: 0.9)
            : colorScheme.primary.withValues(alpha: 0.85))
        : (isDark 
            ? Colors.white.withValues(alpha: 0.95)
            : Colors.white);
            
    Color appbarColor = _isScrolled
        ? (isDark 
            ? colorScheme.surface.withValues(alpha: 0.85)
            : Colors.white.withValues(alpha: 0.9))
        : Colors.transparent;

    return Title(
      title: 'Bienvenido - Sell Web',
      color: colorScheme.primary,
      child: Scaffold(
        extendBodyBehindAppBar:
            true, // Permite que el cuerpo se extienda detrás del AppBar
        backgroundColor: backgroundContainerColor,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: ClipRect(
            child: BackdropFilter(
              filter: _isScrolled
                  ? ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0)
                  : ImageFilter.blur(sigmaX: 0.0, sigmaY: 0.0),
              child: Container(
                decoration: BoxDecoration(
                  color: appbarColor,
                  border: _isScrolled 
                      ? Border(
                          bottom: BorderSide(
                            color: isDark 
                                ? colorScheme.outline.withValues(alpha: 0.3)
                                : colorScheme.outline.withValues(alpha: 0.2),
                            width: 0.5,
                          ),
                        )
                      : null,
                ),
                child: AppBar(
                  title: Row(
                    children: [
                      // Logo con animación mejorada
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        transform: _isScrolled 
                            ? (Matrix4.identity()..scale(1.05))
                            : Matrix4.identity(),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: _isScrolled
                                ? [
                                    BoxShadow(
                                      color: colorScheme.primary.withValues(alpha: 0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.asset('assets/launcher.png', height: 32),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Título con gradiente mejorado
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 300),
                        style: TextStyle(
                          fontSize: _isScrolled ? 20 : 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                        ),
                        child: Text(
                          'Sell',
                            style: TextStyle(
                            color: _isScrolled
                              ? accentAppbarColor
                              : (isDark 
                                ? Colors.white.withValues(alpha: 0.9)
                                : Colors.white),
                            ),
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  scrolledUnderElevation: 0,
                  surfaceTintColor: Colors.transparent,
                  actions: [
                    // Botón de login con animación mejorada
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder:
                          (Widget child, Animation<double> animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: ScaleTransition(
                            scale: animation,
                            child: child,
                          ),
                        );
                      },
                      child: _isScrolled
                          ? Container(
                              key: const ValueKey('login_button'),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(25),
                                boxShadow: [
                                  BoxShadow(
                                    color: colorScheme.primary.withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: AppFilledButton(
                                onPressed: () => _navigateToLogin(
                                    context,
                                    Provider.of<AuthProvider>(context,
                                        listen: false)),
                                text: 'Iniciar Sesión',
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 12),
                                backgroundColor: isDark 
                                    ? colorScheme.primary
                                    : colorScheme.primary,
                                foregroundColor: isDark 
                                    ? colorScheme.onPrimary
                                    : Colors.white,
                              ),
                            )
                          : const SizedBox(key: ValueKey('placeholder')),
                    ),

                    // Botón para cambiar tema con diseño mejorado
                    Consumer<ThemeDataAppProvider>(
                      builder: (context, themeProvider, _) {
                        return Container(
                          margin: const EdgeInsets.only(left: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: _isScrolled
                                ? (isDark 
                                    ? colorScheme.surfaceContainerHigh.withValues(alpha: 0.8)
                                    : colorScheme.surfaceContainerHigh.withValues(alpha: 0.6))
                                : (isDark 
                                    ? Colors.white.withValues(alpha: 0.15)
                                    : Colors.black.withValues(alpha: 0.1)),
                          ),
                          child: IconButton(
                            onPressed: themeProvider.toggleTheme,
                            icon: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              transitionBuilder: (child, animation) {
                                return RotationTransition(
                                  turns: animation,
                                  child: child,
                                );
                              },
                              child: Icon(
                                themeProvider.themeMode == ThemeMode.dark
                                    ? Icons.light_mode_outlined
                                    : Icons.dark_mode_outlined,
                                key: ValueKey(themeProvider.themeMode),
                                color: _isScrolled
                                    ? accentAppbarColor
                                    : (isDark ? Colors.white.withValues(alpha: 0.9) : Colors.white),
                                size: 22,
                              ),
                            ),
                            tooltip: themeProvider.themeMode == ThemeMode.dark
                                ? 'Cambiar a tema claro'
                                : 'Cambiar a tema oscuro',
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 16),
                  ],
                ),
              ),
            ),
          ),
        ),
        body: SingleChildScrollView(
          controller: _scrollController,
          child: _buildResponsiveContent(context, width),
        ),
      ),
    );
  }

  Widget _buildResponsiveContent(BuildContext context, double width) {
    if (width < ResponsiveBreakpoints.mobile) {
      return _buildMobileLayout(context);
    } else if (width < ResponsiveBreakpoints.tablet) {
      return _buildTabletLayout(context);
    } else {
      return _buildDesktopLayout(context);
    }
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Column(
      children: [
        _buildHeroSection(context),
        _buildFeaturesSection(context, axis: Axis.vertical),
        const SizedBox(height: 48),
        _buildCallToActionSection(context),
        const SizedBox(height: 32),
        _buildFooterSection(context),
      ],
    );
  }

  Widget _buildTabletLayout(BuildContext context) {
    return Column(
      children: [
        _buildHeroSection(context),
        const SizedBox(height: 64),
        _buildFeaturesSection(context, axis: Axis.horizontal),
        const SizedBox(height: 64),
        _buildCallToActionSection(context),
        const SizedBox(height: 32),
        _buildFooterSection(context),
      ],
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Column(
      children: [
        _buildHeroSection(context),
        const SizedBox(height: 12),
        _buildFeaturesSection(context, axis: Axis.horizontal),
        const SizedBox(height: 80),
        _buildCallToActionSection(context),
        const SizedBox(height: 48),
        _buildFooterSection(context),
      ],
    );
  }

  Widget _buildHeroSection(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isMobile = screenWidth < ResponsiveBreakpoints.mobile;

    // Constantes para alineación perfecta entre clipper y dispositivo
    final deviceImageTopPadding = isMobile ? 40.0 : 60.0;
    final waveClipperOffset =
        deviceImageTopPadding; // Mismo valor para perfecta alineación

    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 90),
          child: ClipPath(
            clipper: WaveClipper(
              isMobile: isMobile,
              customWaveOffset:
                  waveClipperOffset, // Usar el mismo offset que la imagen
            ),
            child: Container(
              width: double.infinity,
              constraints: BoxConstraints(
                minHeight: isMobile ? screenHeight * 0.7 : screenHeight * 0.9,
                maxHeight: screenHeight * 1.1, // Evitar desbordamiento
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Imagen de fondo que también será cortada por el clipper con gradiente
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: const [0.0, 0.3, 0.7, 1.0],
                          colors: isDark
                              ? [
                                  // Modo oscuro - colores más sutiles
                                  colorScheme.primary.withValues(alpha: 0.4),
                                  colorScheme.primary.withValues(alpha: 0.3),
                                  colorScheme.primary.withValues(alpha: 0.4),
                                  colorScheme.primary.withValues(alpha: 0.5),
                                ]
                              : [
                                  // Modo claro - mantener los amarillos pero más suaves
                                  Colors.yellow.shade300,
                                  Colors.yellow.shade400.withValues(alpha: 0.9),
                                  Colors.yellow.shade300,
                                  Colors.yellow.shade400,
                                ],
                        ),
                      ),
                      child: Opacity(
                        opacity: 0.4,
                        child: Image.asset(
                          'assets/premium.jpeg',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                            color: Colors.transparent,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Gradiente adicional para mejorar legibilidad del texto
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: const [0.0, 0.4, 0.8, 1.0],
                          colors: isDark
                              ? [
                                  // Modo oscuro - gradiente más sutil
                                  colorScheme.surface.withValues(alpha: 0.3),
                                  Colors.transparent,
                                  colorScheme.primary.withValues(alpha: 0.2),
                                  colorScheme.primary.withValues(alpha: 0.4),
                                ]
                              : [
                                  // Modo claro - gradiente amarillo suave
                                  Colors.yellow.shade200.withValues(alpha: 0.8),
                                  Colors.yellow.shade300.withValues(alpha: 0.4),
                                  Colors.yellow.shade400,
                                  Colors.yellow.shade500,
                                ],
                        ),
                      ),
                    ),
                  ),
                  // Contenido principal con SafeArea
                  SafeArea(
                    child: Padding(
                      padding: EdgeInsets.only(
                        left: isMobile ? 16 : 24,
                        right: isMobile ? 16 : 24,
                        top: isMobile ? 20 : 64,
                        bottom: isMobile
                            ? 22
                            : 180, // Más espacio para acomodar las imágenes con texto
                      ),
                      child: _buildHeroContentOnly(context, theme, colorScheme),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Imagen del dispositivo móvil posicionada para no tapar el texto
        Positioned(
          bottom: 20,
          left: 0,
          right: 0,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: isMobile
                ? screenHeight * 0.28
                : screenHeight * 0.42, // Reducir altura ligeramente
            alignment: Alignment.topCenter,
            child: Padding(
              padding: EdgeInsets.only(
                top: deviceImageTopPadding + 15, // Reducir padding superior
                bottom: isMobile ? 10 : 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Imagen del dispositivo móvil
                  _deviceImageWithHover(
                    screenWidth: screenWidth,
                    isMobile: isMobile,
                    assetPath: 'assets/screenshot00.png',
                    widthFactor:
                        isMobile ? 0.25 : 0.15, // Ajustar ancho para el texto
                    heightFallback:
                        isMobile ? 140 : 180, // Ajustar altura para el texto
                    deviceType: DeviceType.mobile,
                    text: '✓ Móvil',
                  ),
                  // Imagen de la captura web
                  _deviceImageWithHover(
                    screenWidth: screenWidth,
                    isMobile: isMobile,
                    assetPath: 'assets/screenshot06.png',
                    widthFactor: isMobile ? 0.35 : 0.25,
                    heightFallback: isMobile ? 120 : 150,
                    deviceType: DeviceType.desktop,
                    text: '✓ Web',
                  ),
                ],
              ),
            ),
          ),
        )
            .animate(delay: 1200.ms)
            .fadeIn(duration: 800.ms)
            .scaleXY(begin: 0.8, end: 1.0, curve: Curves.easeOut)
            .slideY(begin: 0.3, end: 0.0),
      ],
    );
  }

  Widget _buildHeroContentOnly(
      BuildContext context, ThemeData theme, ColorScheme colorScheme) {
    final isDark = theme.brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 30),
        Text(
          'GESTIONA TUS VENTAS E INVENTARIO',
          textAlign: TextAlign.center,
          style: theme.textTheme.displayLarge?.copyWith(
            fontWeight: FontWeight.w800,
            fontSize: 40,
            letterSpacing: -0.5,
            foreground: Paint()
              ..shader = LinearGradient(
                colors: isDark
                    ? [
                        // Modo oscuro - gradiente con colores primarios
                        colorScheme.primary,
                        colorScheme.primaryContainer,
                        colorScheme.secondary,
                      ]
                    : [
                        // Modo claro - gradiente azul vibrante
                        Colors.blueAccent,
                        Colors.lightBlue,
                        Colors.blue.shade700,
                      ],
              ).createShader(const Rect.fromLTWH(0.0, 0.0, 400.0, 70.0)),
          ),
        ).animate().fadeIn(duration: 800.ms).slideX(begin: -0.3),
        const SizedBox(height: 16),
        // text : secundario
        TypewriterText(
          texts: const [
            'Punto de venta fácil de usar ',
            'Inventario controlado desde cualquier lugar',
            'Reportes analíticos instantáneos',
            'Concentrate en vender, nosotros hacemos el resto',
          ],
          style: theme.textTheme.headlineMedium?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.4,
            fontSize: 30,
          ),
          textAlign: TextAlign.center,
          typingSpeed: const Duration(milliseconds: 100),
          pauseDuration: const Duration(milliseconds: 2500),
          backspacingSpeed: const Duration(milliseconds: 50),
        ).animate(delay: 200.ms).fadeIn(duration: 800.ms).slideX(begin: -0.3),
        const SizedBox(height: 20),
        Text(
          'Agilizá tu proceso de ventas fácil, rápido para vender y controlar tu inventario desde cualquier lugar',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: isDark 
                ? colorScheme.onSurface.withValues(alpha: 0.85)
                : colorScheme.onSurface.withValues(alpha: 0.9),
            fontWeight: FontWeight.w500,
            height: 1.6,
            fontSize: 18,
            shadows: isDark 
                ? null
                : [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      offset: const Offset(0, 1),
                      blurRadius: 2,
                    ),
                  ],
          ),
        ).animate(delay: 400.ms).fadeIn(duration: 800.ms).slideX(begin: -0.3),
        const SizedBox(height: 50),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 40),
          height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Colors.transparent,
                colorScheme.onSurface.withValues(alpha: 0.3),
                colorScheme.onSurface.withValues(alpha: 0.6),
                colorScheme.onSurface.withValues(alpha: 0.3),
                Colors.transparent,
              ],
              stops: const [0.0, 0.2, 0.5, 0.8, 1.0],
            ),
          ),
        ).animate(delay: 800.ms).fadeIn(duration: 600.ms),
        const SizedBox(height: 50),
        // text : disponible en:
        Text(
          'Disponible en:',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: isDark
                ? colorScheme.onSurface.withValues(alpha: 0.85)
                : colorScheme.onSurface.withValues(alpha: 0.9),
            fontWeight: FontWeight.w500,
            height: 1.6,
            fontSize: 18,
            shadows: isDark
                ? null
                : [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      offset: const Offset(0, 1),
                      blurRadius: 2,
                    ),
                  ],
          ),
        ),
        const SizedBox(height: 50),
        // buttons : acciones principales
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 16,
          runSpacing: 16,
          children: [
            AppButton(
              text: 'Play Store',
              icon: Image.asset('assets/playstore.png', width: 24, height: 24),
              backgroundColor: Colors.black,
              onPressed: _launchPlayStore,
            ),
            AppFilledButton(
              text: 'Comenzar Ahora',
              icon: Icon(Icons.auto_fix_high_outlined),
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              onPressed: () => _navigateToLogin(
                  context, Provider.of<AuthProvider>(context, listen: false)),
            ).animate(delay: 600.ms).fadeIn(duration: 600.ms),
          ],
        ), 
      ],
    );
  }

  Widget _buildFeaturesSection(BuildContext context, {required Axis axis}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final features = [
      _FeatureData(
        icon: Icons.point_of_sale_outlined,
        title: 'Sistema de Ventas',
        description:
            'Automatiza tu proceso comercial con herramientas profesionales',
        checkItems: [
          'Ventas rápidas y eficientes',
          'Múltiples formas de pago',
          'Arqueo de caja',
          'Interfaz intuitiva'
        ],
        benefit: 'Reduce 78% errores',
        stats: '78%',
        color: const Color(0xFF45B7D1),
      ),
      _FeatureData(
        icon: Icons.inventory_2_outlined,
        title: 'Inventario controlado',
        description:
            'Mantén tu inventario siempre actualizado y evita pérdidas',
        checkItems: [
          'Alertas de stock mínimo o agotado',
          'Códigos de barras',
          'Reportes en tiempo real',
        ],
        benefit: 'Reduce 68% pérdidas',
        stats: '68%',
        color: const Color(0xFF4ECDC4),
      ),
      _FeatureData(
        icon: Icons.analytics_outlined,
        title: 'Reportes y Analytics',
        description:
            'Accede en donde sea, cuando sea a tus analíticas y reportes guardados de forma segura en la nube',
        checkItems: [
          'Productos y categorías populares',
          'Sigue tendencias de venta',
          'Ventas por empleado',
          'Ganancias y márgenes',
        ],
        benefit: 'Reduce 83% tiempo',
        stats: '83%',
        color: const Color(0xFF96CEB4),
      ),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 100, bottom: 64, left: 24, right: 24),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF007BFF).withValues(alpha: 0.15)
                  : const Color(0xFF007BFF).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(50),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF007BFF).withValues(alpha: 0.3)
                    : const Color(0xFF007BFF).withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Text(
              '⚡ Potencia tu negocio',
              style: theme.textTheme.bodyMedium?.copyWith(
                color:
                    isDark ? const Color(0xFF64B5F6) : const Color(0xFF007BFF),
                fontWeight: FontWeight.w600,
              ),
            ),
          ).animate().fadeIn(duration: 600.ms),
          const SizedBox(height: 24),
          Text(
            'Toma el control de tu negocio y simplifica tu operación diaria',
            style: theme.textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
              height: 1.2,
              color: isDark ? colorScheme.onSurface : null,
            ),
            textAlign: TextAlign.center,
          ).animate(delay: 200.ms).fadeIn(duration: 600.ms),
          const SizedBox(height: 16),
          Text(
            'Todo lo que necesitas para gestionar de forma profesional',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.7),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ).animate(delay: 400.ms).fadeIn(duration: 600.ms),
          const SizedBox(height: 64),
          if (axis == Axis.horizontal)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: features
                  .asMap()
                  .entries
                  .map((entry) => Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: _ModernFeatureCard(
                            feature: entry.value,
                            delay: Duration(milliseconds: entry.key * 200),
                          ),
                        ),
                      ))
                  .toList(),
            )
          else
            Column(
              children: features
                  .asMap()
                  .entries
                  .map((entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 32),
                        child: _ModernFeatureCard(
                          feature: entry.value,
                          delay: Duration(milliseconds: entry.key * 200),
                        ),
                      ))
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildCallToActionSection(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF007BFF),
            Color(0xFF0056CC),
            Color(0xFF003D99),
          ],
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF007BFF).withValues(alpha: 0.4),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(50),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Text(
              '🚀 ¡Es momento de crecer!',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ).animate().fadeIn(duration: 600.ms),
          const SizedBox(height: 24),
          Text(
            'Transforma tu negocio hoy',
            style: theme.textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ).animate(delay: 200.ms).fadeIn(duration: 600.ms),
          const SizedBox(height: 16),
          Text(
            'Únete a miles de comerciantes que ya digitalizaron su negocio\ny aumentaron la eficiencia de sus ventas',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
              height: 1.6,
              fontSize: 18,
            ),
            textAlign: TextAlign.center,
          ).animate(delay: 400.ms).fadeIn(duration: 600.ms),
          const SizedBox(height: 40),

          // Beneficios rápidos
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 24,
            runSpacing: 16,
            children: [
              _buildCTABenefit('✓ Funciones gratuitas'),
              _buildCTABenefit('✓ Soporte 24/7'),
              _buildCTABenefit('✓ Fácil de usar'),
              _buildCTABenefit('✓ Actualizaciones constantes'),
              _buildCTABenefit('✓ Acceso desde cualquier lugar'),
              _buildCTABenefit('✓ Ideal para emprendedores'),
            ],
          ).animate(delay: 600.ms).fadeIn(duration: 600.ms),
          const SizedBox(height: 40),

          // Botones principales
          Wrap(
            spacing: 20,
            runSpacing: 20,
            alignment: WrapAlignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: () => _navigateToLogin(context,
                      Provider.of<AuthProvider>(context, listen: false)),
                  icon: const Icon(Icons.rocket_launch, size: 22),
                  label: const Text(
                    'Empezar Ahora',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF007BFF),
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              ).animate(delay: 800.ms).fadeIn(duration: 600.ms).scale(),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.4),
                    width: 2,
                  ),
                ),
                child: ElevatedButton.icon(
                  onPressed: _launchPlayStore,
                  icon: Image.asset('assets/playstore.png',
                      width: 24, height: 24),
                  label: const Text(
                    'Play Store',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              ).animate(delay: 1000.ms).fadeIn(duration: 600.ms).scale(),
            ],
          ),
          const SizedBox(height: 32),

          // Garantía
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.security,
                  color: Colors.white.withValues(alpha: 0.9),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '100% Seguro y Confiable',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ).animate(delay: 1200.ms).fadeIn(duration: 600.ms),
        ],
      ),
    );
  }

  Widget _buildCTABenefit(String text) {
    return Text(
      text,
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.95),
        fontWeight: FontWeight.w600,
        fontSize: 15,
      ),
    );
  }

  Widget _buildFooterSection(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: Theme.of(context).brightness == Brightness.light
              ? [
                  Colors.white,
                  const Color(0xFFF8F9FF),
                ]
              : [
                  theme.colorScheme.surface,
                  theme.colorScheme.surfaceContainerLow,
                ],
        ),
      ),
      child: Column(
        children: [
          // Logo y descripción
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset('assets/launcher.png', height: 32),
              ),
              const SizedBox(width: 12),
              Text(
                'Sell Web',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF007BFF),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'La plataforma de punto de venta más intuitiva para hacer crecer tu negocio',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Separador
          Container(
            height: 1,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Colors.transparent,
                  theme.colorScheme.outline.withValues(alpha: 0.2),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Copyright y enlaces
          Column(
            children: [
              Text(
                '© 2025 Sell Web',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '•',
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                ),
              ),
              Text(
                'Hecho con ❤️ en Argentina',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '•',
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                ),
              ),
              Text(
                'Todos los derechos reservados',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _navigateToLogin(BuildContext context, AuthProvider authProvider) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => LoginPage(authProvider: authProvider),
      ),
    );
  }

  Future<void> _launchPlayStore() async {
    const url =
        'https://play.google.com/store/apps/details?id=com.logicabooleana.sell&pcampaignid=web_share';

    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'No se puede abrir $url';
      }
    } catch (e) {
      // En caso de error, mostrar un snackbar o manejar el error silenciosamente
      debugPrint('Error al abrir Play Store: $e');
    }
  }

  Widget _deviceImageWithHover({
    required double screenWidth,
    required bool isMobile,
    required String assetPath,
    required double widthFactor,
    required double heightFallback,
    required DeviceType deviceType,
    required String text,
  }) {
    return _DeviceScrollWidget(
      screenWidth: screenWidth,
      isMobile: isMobile,
      scrollController: _scrollController,
      assetPath: assetPath,
      widthFactor: widthFactor,
      heightFallback: heightFallback,
      deviceType: deviceType,
      text: text,
    );
  }
}

enum DeviceType {
  mobile,
  desktop,
}

class _DeviceScrollWidget extends StatefulWidget {
  final double screenWidth;
  final bool isMobile;
  final ScrollController scrollController;
  final String assetPath;
  final double widthFactor;
  final double heightFallback;
  final DeviceType deviceType;
  final String text;

  const _DeviceScrollWidget({
    required this.screenWidth,
    required this.isMobile,
    required this.scrollController,
    required this.assetPath,
    required this.widthFactor,
    required this.heightFallback,
    required this.deviceType,
    required this.text,
  });

  @override
  State<_DeviceScrollWidget> createState() => _DeviceScrollWidgetState();
}

class _DeviceScrollWidgetState extends State<_DeviceScrollWidget> {
  bool isVisible = false;
  bool isZoomed = false;

  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() {
    // Calcular si la imagen está visible en el viewport
    if (!mounted) return;

    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;
    final screenHeight = MediaQuery.of(context).size.height;

    // Verificar si el widget está visible en el viewport
    final isCurrentlyVisible =
        position.dy < screenHeight && (position.dy + size.height) > 0;

    // Verificar si está en la zona de zoom (más específico)
    final zoomThreshold = screenHeight * 0.7; // 70% del viewport
    final isInZoomZone = position.dy < zoomThreshold &&
        (position.dy + size.height) > (screenHeight * 0.3);

    if (isCurrentlyVisible != isVisible || isInZoomZone != isZoomed) {
      setState(() {
        isVisible = isCurrentlyVisible;
        isZoomed = isInZoomZone;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Texto con padding controlado
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Text(
            widget.text,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: widget.isMobile ? 12 : 14,
                ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
        const SizedBox(height: 16),
        // Contenedor de imagen flexible
        Flexible(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: widget.isMobile ? 180 : 220,
              maxWidth: widget.screenWidth * widget.widthFactor,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Overlay de atenuación del fondo cuando hay zoom
                if (isZoomed)
                  Positioned.fill(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 600),
                      child: Center(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 600),
                          width: 120,
                          height: 200,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(25),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 30,
                                spreadRadius: 10,
                                offset: const Offset(0, 15),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                // Imagen del dispositivo con zoom
                AnimatedScale(
                  scale: isZoomed ? 1.30 : 1.0,
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.elasticOut,
                  child: AnimatedOpacity(
                    opacity: isVisible ? 1.0 : 0.8,
                    duration: const Duration(milliseconds: 300),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(
                            widget.deviceType == DeviceType.desktop ? 16 : 12),
                      ),
                      child: SizedBox(
                        width: widget.screenWidth * widget.widthFactor,
                        child: widget.deviceType == DeviceType.desktop
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.asset(
                                  widget.assetPath,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) =>
                                      _buildErrorContainer(
                                    isDesktop: true,
                                  ),
                                ),
                              )
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.asset(
                                  widget.assetPath,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) =>
                                      _buildErrorContainer(
                                    isDesktop: false,
                                  ),
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorContainer({required bool isDesktop}) {
    return Container(
      height: widget.heightFallback,
      width: isDesktop ? 200 : 100,
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        isDesktop ? Icons.desktop_windows : Icons.phone_android,
        color: Colors.grey.withValues(alpha: 0.5),
        size: isDesktop ? 60 : 50,
      ),
    );
  }
}

class _FeatureData {
  final IconData icon;
  final String title;
  final String description;
  final List<String>? checkItems;
  final String? benefit;
  final String? stats;
  final Color? color;

  _FeatureData({
    required this.icon,
    required this.title,
    required this.description,
    this.checkItems,
    this.benefit,
    this.stats,
    this.color,
  });
}

class _ModernFeatureCard extends StatefulWidget {
  final _FeatureData feature;
  final Duration delay;

  const _ModernFeatureCard({
    required this.feature,
    required this.delay,
  });

  @override
  State<_ModernFeatureCard> createState() => _ModernFeatureCardState();
}

class _ModernFeatureCardState extends State<_ModernFeatureCard>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        transform: Matrix4.identity()
          ..scale(_isHovered ? 1.03 : 1.0)
          ..translate(0.0, _isHovered ? -8.0 : 0.0),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: isDark ? colorScheme.surfaceContainerHigh : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark
                  ? (widget.feature.color?.withValues(alpha: 0.3) ??
                      colorScheme.outline.withValues(alpha: 0.3))
                  : (widget.feature.color?.withValues(alpha: 0.2) ??
                      const Color(0xFF007BFF).withValues(alpha: 0.1)),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.3)
                    : _isHovered
                        ? (widget.feature.color?.withValues(alpha: 0.15) ??
                            const Color(0xFF007BFF).withValues(alpha: 0.15))
                        : Colors.black.withValues(alpha: 0.05),
                blurRadius: _isHovered ? 20 : 12,
                offset: Offset(0, _isHovered ? 12 : 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ícono con background colorido
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      widget.feature.color ?? const Color(0xFF007BFF),
                      (widget.feature.color ?? const Color(0xFF007BFF))
                          .withValues(alpha: 0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: (widget.feature.color ?? const Color(0xFF007BFF))
                          .withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  widget.feature.icon,
                  size: 32,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),

              // Título
              Text(
                widget.feature.title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 12),

              // Descripción
              Text(
                widget.feature.description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                  height: 1.5,
                  fontSize: 15,
                ),
              ),

              // Check items
              if (widget.feature.checkItems != null &&
                  widget.feature.checkItems!.isNotEmpty) ...[
                const SizedBox(height: 20),
                ...widget.feature.checkItems!
                    .map((item) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: (widget.feature.color ??
                                          const Color(0xFF007BFF))
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.check,
                                  size: 14,
                                  color: widget.feature.color ??
                                      const Color(0xFF007BFF),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  item,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurface
                                        .withValues(alpha: 0.8),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ))
                    .toList(),
              ],

              if (widget.feature.benefit != null ||
                  widget.feature.stats != null) ...[
                const SizedBox(height: 24),
                Row(
                  children: [
                    if (widget.feature.stats != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isDark
                              ? (widget.feature.color ??
                                      const Color(0xFF007BFF))
                                  .withValues(alpha: 0.2)
                              : (widget.feature.color ??
                                      const Color(0xFF007BFF))
                                  .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: isDark
                              ? Border.all(
                                  color: (widget.feature.color ??
                                          const Color(0xFF007BFF))
                                      .withValues(alpha: 0.3),
                                  width: 1,
                                )
                              : null,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.feature.stats!,
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: isDark
                                    ? (widget.feature.color ??
                                        const Color(0xFF64B5F6))
                                    : (widget.feature.color ??
                                        const Color(0xFF007BFF)),
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.trending_up,
                              size: 16,
                              color: isDark
                                  ? (widget.feature.color ??
                                      const Color(0xFF64B5F6))
                                  : (widget.feature.color ??
                                      const Color(0xFF007BFF)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    if (widget.feature.benefit != null)
                      Expanded(
                        child: Text(
                          widget.feature.benefit!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface.withValues(alpha: 0.6),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    ).animate(delay: widget.delay).fadeIn(duration: 600.ms).slideY(begin: 0.3);
  }
}

class _FeatureCard extends StatefulWidget {
  final _FeatureData feature;
  final Duration delay;

  const _FeatureCard({
    required this.feature,
    required this.delay,
  });

  @override
  State<_FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<_FeatureCard>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.identity()
          ..scale(_isHovered ? 1.02 : 1.0)
          ..translate(0.0, _isHovered ? -4.0 : 0.0),
        child: Card(
          elevation: _isHovered ? 8 : 2,
          shadowColor: colorScheme.shadow.withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: _isHovered
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        colorScheme.surface,
                        colorScheme.surfaceContainerLow,
                      ],
                    )
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    widget.feature.icon,
                    size: 32,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  widget.feature.title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.feature.description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                    height: 1.5,
                  ),
                ),
                if (widget.feature.benefit != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      widget.feature.benefit!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    ).animate(delay: widget.delay).fadeIn(duration: 600.ms).slideY(begin: 0.3);
  }
}

/// Custom clipper para crear forma de onda en la parte inferior del hero section
class WaveClipper extends CustomClipper<Path> {
  final bool isMobile;
  final double? customWaveOffset;

  const WaveClipper({
    this.isMobile = false,
    this.customWaveOffset,
  });

  @override
  Path getClip(Size size) {
    final path = Path();

    // Comenzar desde la esquina superior izquierda
    path.moveTo(0, 0);

    // Línea superior
    path.lineTo(size.width, 0);

    // Altura de la onda adaptativa según el dispositivo
    // Usar customWaveOffset si se proporciona, sino usar valores por defecto
    final waveOffset = customWaveOffset ?? (isMobile ? 40.0 : 60.0);
    final waveHeight = isMobile ? 20.0 : 40.0;

    // Línea derecha hasta antes de la onda
    path.lineTo(size.width, size.height - waveOffset);

    // Crear la onda usando curvas cuadráticas
    final waveLength = size.width / (isMobile ? 2 : 3); // Menos ondas en móvil

    if (isMobile) {
      // Versión simplificada para móvil (2 ondas)
      // Segunda onda
      path.quadraticBezierTo(
        size.width - (waveLength * 0.5),
        (size.height - waveOffset) + waveHeight * 0.8,
        size.width - waveLength,
        size.height - waveOffset,
      );

      // Primera onda
      path.quadraticBezierTo(
        size.width - (waveLength * 1.5),
        (size.height - waveOffset) - waveHeight * 0.6,
        0,
        size.height - waveOffset,
      );
    } else {
      // Versión completa para desktop (3 ondas)
      // Tercera onda (de derecha a izquierda)
      path.quadraticBezierTo(
        size.width - (waveLength * 0.5),
        (size.height - waveOffset) + waveHeight * 0.9,
        size.width - waveLength,
        size.height - waveOffset,
      );

      // Segunda onda
      path.quadraticBezierTo(
        size.width - (waveLength * 1.5),
        (size.height - waveOffset) - waveHeight * 0.8,
        size.width - (waveLength * 2),
        size.height - waveOffset,
      );

      // Primera onda
      path.quadraticBezierTo(
        size.width - (waveLength * 2.5),
        (size.height - waveOffset) + waveHeight,
        0,
        size.height - waveOffset,
      );
    }

    // Línea izquierda de vuelta al inicio
    path.lineTo(0, 0);

    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant WaveClipper oldClipper) =>
      isMobile != oldClipper.isMobile ||
      customWaveOffset != oldClipper.customWaveOffset;
}

/// Custom painter para crear forma de onda en la parte inferior del hero section
class WavePainter extends CustomPainter {
  final Color color;
  final Color backgroundColor;

  WavePainter({
    required this.color,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;

    final path = Path();

    // Comenzar desde la esquina superior izquierda
    path.moveTo(0, 0);

    // Crear la onda usando curvas cuadráticas
    final waveHeight = size.height * 0.6;
    final waveLength = size.width / 3;

    // Primera onda
    path.quadraticBezierTo(
      waveLength * 0.5,
      waveHeight,
      waveLength,
      0,
    );

    // Segunda onda
    path.quadraticBezierTo(
      waveLength * 1.5,
      -waveHeight * 0.8,
      waveLength * 2,
      0,
    );

    // Tercera onda
    path.quadraticBezierTo(
      waveLength * 2.5,
      waveHeight * 0.9,
      size.width,
      0,
    );

    // Completar el rectángulo hacia abajo
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    // Primero pintar el fondo
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      backgroundPaint,
    );

    // Luego pintar la onda
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

/// Widget que simula efecto de tipeo secuencial con cursor
class TypewriterText extends StatefulWidget {
  final List<String> texts;
  final TextStyle? style;
  final TextAlign textAlign;
  final Duration typingSpeed;
  final Duration pauseDuration;
  final Duration backspacingSpeed;

  const TypewriterText({
    super.key,
    required this.texts,
    this.style,
    this.textAlign = TextAlign.center,
    this.typingSpeed = const Duration(milliseconds: 100),
    this.pauseDuration = const Duration(milliseconds: 2000),
    this.backspacingSpeed = const Duration(milliseconds: 50),
  });

  @override
  State<TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<TypewriterText>
    with TickerProviderStateMixin {
  String _currentText = '';
  int _currentIndex = 0;
  int _charIndex = 0;
  bool _isTyping = true;
  bool _showCursor = true;

  Timer? _typingTimer;
  Timer? _cursorTimer;

  @override
  void initState() {
    super.initState();
    _startTypewriterEffect();
    _startCursorBlinking();
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _cursorTimer?.cancel();
    super.dispose();
  }

  void _startCursorBlinking() {
    _cursorTimer = Timer.periodic(const Duration(milliseconds: 600), (timer) {
      if (mounted) {
        setState(() {
          _showCursor = !_showCursor;
        });
      }
    });
  }

  void _startTypewriterEffect() {
    if (widget.texts.isEmpty) return;

    _typingTimer = Timer.periodic(
      _isTyping ? widget.typingSpeed : widget.backspacingSpeed,
      (timer) {
        if (!mounted) return;

        setState(() {
          if (_isTyping) {
            // Escribiendo
            if (_charIndex < widget.texts[_currentIndex].length) {
              _currentText =
                  widget.texts[_currentIndex].substring(0, _charIndex + 1);
              _charIndex++;
            } else {
              // Terminó de escribir, pausa antes de borrar
              timer.cancel();
              Timer(widget.pauseDuration, () {
                if (mounted) {
                  setState(() {
                    _isTyping = false;
                  });
                  _startTypewriterEffect();
                }
              });
            }
          } else {
            // Borrando
            if (_charIndex > 0) {
              _charIndex--;
              _currentText =
                  widget.texts[_currentIndex].substring(0, _charIndex);
            } else {
              // Terminó de borrar, cambiar al siguiente texto
              _currentIndex = (_currentIndex + 1) % widget.texts.length;
              _isTyping = true;
              timer.cancel();
              Timer(const Duration(milliseconds: 300), () {
                if (mounted) {
                  _startTypewriterEffect();
                }
              });
            }
          }
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Obtener el ancho disponible considerando el padding horizontal
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < ResponsiveBreakpoints.mobile;
    final availableWidth =
        screenWidth - (isMobile ? 32 : 48); // Considerando padding lateral

    // Encontrar el texto más largo de la lista para calcular altura máxima
    String longestText = widget.texts
        .fold('', (prev, text) => text.length > prev.length ? text : prev);

    // Calcular altura dinámica basada en el texto más largo y el ancho disponible
    final textPainter = TextPainter(
      text: TextSpan(
        text: longestText,
        style: widget.style,
      ),
      textDirection: TextDirection.ltr,
      textAlign: widget.textAlign,
    );
    textPainter.layout(maxWidth: availableWidth);
    final maxTextHeight = textPainter.height;

    // Calcular altura para el texto actual
    final currentTextPainter = TextPainter(
      text: TextSpan(
        text: _currentText.isEmpty
            ? ' '
            : _currentText, // Espacio para evitar altura cero
        style: widget.style,
      ),
      textDirection: TextDirection.ltr,
      textAlign: widget.textAlign,
    );
    currentTextPainter.layout(maxWidth: availableWidth);
    final currentTextHeight = currentTextPainter.height;

    // Usar la altura máxima para mantener consistencia visual
    final finalHeight = maxTextHeight + 16; // Padding adicional para el cursor

    return SizedBox(
      height: finalHeight,
      width: double.infinity,
      child: Align(
        alignment: Alignment.center,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: availableWidth,
            minHeight: currentTextHeight,
          ),
          child: RichText(
            textAlign: widget.textAlign,
            text: TextSpan(
              children: [
                TextSpan(
                  text: _currentText,
                  style: widget.style,
                ),
                TextSpan(
                  text: _showCursor ? '●' : '●',
                  style: widget.style?.copyWith(
                    color: _showCursor
                        ? (widget.style?.color ?? Colors.white)
                        : Colors.transparent,
                    fontWeight: FontWeight.w900,
                    fontSize: (widget.style?.fontSize ?? 24) *
                        0.6, // 60% del tamaño del texto
                    shadows: _showCursor
                        ? [
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 1,
                              offset: const Offset(0, 0.5),
                            ),
                          ]
                        : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
