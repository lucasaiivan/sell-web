import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/scheduler.dart' show Ticker;
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
    // Trigger rebuild para actualizar el CustomPaint dinámico
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Fondo optimizado para UI/UX - no usar negro puro en modo oscuro
    backgroundContainerColor = isDark 
        ? const Color(0xFF0F0F0F)  // Gris muy oscuro en lugar de negro puro
        : Colors.white;
    
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
        appBar: _PresentationAppBar(
          isScrolled: _isScrolled,
          isDark: isDark,
          colorScheme: colorScheme,
          appbarColor: appbarColor,
          accentAppbarColor: accentAppbarColor,
          onLoginTap: () => _navigateToLogin(context, Provider.of<AuthProvider>(context, listen: false)),
        ),
        body: SingleChildScrollView(
          controller: _scrollController,
          child: Stack(
            children: [
              // Fondo con CustomPaint dinámico que se adapta al contenido
              Positioned.fill(
                child: CustomPaint(
                  painter: _DynamicBackgroundPainter(
                    scrollOffset: _scrollController.hasClients ? _scrollController.offset : 0.0,
                    primaryColor: Theme.of(context).colorScheme.primary,
                    isDark: Theme.of(context).brightness == Brightness.dark,
                    isMobile: MediaQuery.of(context).size.width < ResponsiveBreakpoints.mobile,
                    screenHeight: MediaQuery.of(context).size.height,
                  ),
                ),
              ),
              // Contenido principal
              _buildResponsiveContent(context, width),
            ],
          ),
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
    final waveClipperOffset = deviceImageTopPadding; // Mismo valor para perfecta alineación 
    double spaceAdictional = isMobile? 200 : 300; // Espacio adicional para evitar desbordamiento en pantallas grandes

    return SizedBox(
      width: double.infinity,
      height: screenHeight + spaceAdictional ,
      child: Stack(
        fit: StackFit.expand,
        children: [ 
          // view : fondo con clipper y gradiente
          Padding(
            padding: EdgeInsets.only(bottom:spaceAdictional),
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
                                    Colors.amber.shade300,
                                    Colors.amber.shade400.withValues(alpha: 0.9),
                                    Colors.amber.shade300,
                                    Colors.amber,
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
                                    Colors.amber.shade200.withValues(alpha: 0.8),
                                    Colors.amber.shade300.withValues(alpha: 0.4),
                                    Colors.amber.shade300,
                                    Colors.amber.shade300,
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
          // image : Imagen del dispositivo móvil posicionada en la parte más baja disponible
          Positioned(
            bottom: 0, // Posicionar exactamente en el fondo
            left: 0,
            right: 0, 
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: isMobile ? screenHeight * 0.40 : screenHeight * 0.60,
              alignment: Alignment.bottomCenter, // Alinear al fondo del contenedor
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: isMobile ? 20 : 30, // Solo padding inferior para separar del borde
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Imagen del dispositivo móvil
                    _deviceImageWithHover(
                      screenWidth: screenWidth,
                      assetPath: 'assets/screenshot00.png',
                      zoomFactor: 1.6, // Zoom más moderado para móvil
                      actionWidget: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.green.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          '📱 Móvil',
                          style: TextStyle(
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.w600,
                            fontSize: isMobile ? 10 : 12,
                          ),
                        ),
                      ),
                    ),
                    // Imagen de la captura web
                    _deviceImageWithHover(
                      screenWidth: screenWidth,
                      assetPath: 'assets/screenshot06.png',
                      zoomFactor: 2.0, // Zoom más pronunciado para desktop
                      actionWidget: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          '💻 Web',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: isMobile ? 10 : 12,
                          ),
                        ),
                      ),
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
      ),
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
          'Tu negocio necesita un cambio, agilizá tu proceso de ventas fácil, rápido y controla tu inventario desde cualquier lugar',
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < ResponsiveBreakpoints.mobile;

    final features = [
      _FeatureData(
        icon: Icons.point_of_sale_outlined,
        title: 'Sistema de Ventas',
        description:
            'Acelera tu proceso comercial con tecnología avanzada que optimiza cada transacción y reduce errores operativos',
        checkItems: [
          'Interfaz intuitiva con atajos de teclado',
          'Soporte para múltiples métodos de pago',
          'Reportes y analytics en tiempo real',
          'Sistema de descuentos y promociones automáticas',
          'Sincronización automática con inventario'
        ],
        benefit: 'Aumenta la velocidad de ventas en 78%', 
        color: const Color(0xFF4F46E5), // Indigo moderno
        imageAsset: 'assets/screenshot00.png',
        imageOnRight: false,
        category: 'Punto de Venta',
        ctaText: 'Probar Demo de Ventas',
        onTap: () => debugPrint('Navegar a demo de ventas'),
      ),
      _FeatureData(
        icon: Icons.inventory_2_outlined,
        title: 'Gestión de Inventario Automatizada',
        description: 'Controla tu stock con precisión usando alertas inteligentes, códigos de barras y predicciones de demanda',
        checkItems: [
          'Alertas automáticas de stock crítico',
          'Escáner de códigos de barras integrado',
          'Historial completo de movimientos',
          'Predicción de demanda con IA',
          'Control de lotes y fechas de vencimiento'
        ],
        benefit: 'Reduce pérdidas por stock en 68%', 
        color: const Color(0xFF059669), // Verde esmeralda
        imageAsset: 'assets/screenshot02.png',
        imageOnRight: true,
        category: 'Control de Stock',
        ctaText: 'Explorar Inventario',
        onTap: () => debugPrint('Navegar a demo de inventario'),
      ),
      _FeatureData(
        icon: Icons.analytics_outlined,
        title: 'Analytics y Business Intelligence',
        description:
            'Convierte datos en decisiones estratégicas con dashboards personalizables y métricas avanzadas de negocio',
        checkItems: [
          'Dashboard personalizable y dinámico',
          'Análisis predictivo de tendencias',
          'Reportes exportables por período',
          'Métricas de rentabilidad por producto',
          'Comparativas históricas y benchmarking'
        ],
        benefit: 'Mejora decisiones estratégicas en 83%', 
        color: const Color(0xFFDC2626), // Rojo moderno
        imageAsset: 'assets/screenshot04.png',
        imageOnRight: false,
        category: 'Business Intelligence',
        ctaText: 'Ver Reportes Avanzados',
        onTap: () => debugPrint('Navegar a demo de analytics'),
      ),
    ];

    return SizedBox(
      width: double.infinity, 
      child: Column(
        children: [
          // Header mejorado con mejor jerarquía visual
          Column(
            children: [
              // Badge de sección con mejor diseño
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF4F46E5).withValues(alpha: 0.1),
                      const Color(0xFF7C3AED).withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(
                    color: const Color(0xFF4F46E5).withValues(alpha: 0.2),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      size: 16,
                      color: const Color(0xFF4F46E5),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Características Principales',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF4F46E5),
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              )
                  .animate()
                  .fadeIn(duration: 600.ms)
                  .slideY(begin: 0.3, end: 0.0, curve: Curves.easeOut),
              
              SizedBox(height: isMobile ? 24 : 32),
              
              // Título principal con mejor tipografía
              Text(
                'Todo lo que necesitas para\nhacer crecer tu negocio',
                style: theme.textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.8,
                  height: 1.1,
                  fontSize: isMobile ? 28 : 48,
                  color: isDark ? colorScheme.onSurface : colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              )
                  .animate(delay: 200.ms)
                  .fadeIn(duration: 800.ms)
                  .slideY(begin: 0.3, end: 0.0, curve: Curves.easeOut),
              
              SizedBox(height: isMobile ? 16 : 20),
              
              // Subtítulo mejorado
              Container(
                constraints: BoxConstraints(
                  maxWidth: isMobile ? double.infinity : 600,
                ),
                child: Text(
                  'Herramientas profesionales diseñadas para optimizar cada aspecto de tu operación comercial',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                    height: 1.5,
                    fontSize: isMobile ? 16 : 20,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              )
                  .animate(delay: 400.ms)
                  .fadeIn(duration: 800.ms)
                  .slideY(begin: 0.3, end: 0.0, curve: Curves.easeOut),
            ],
          ),
          
          SizedBox(height: isMobile ? 48 : 80),
          
          // Grid de características con animaciones escalonadas
          _buildFeaturesGrid(features, theme, colorScheme, isDark, isMobile, axis),
           
        ],
      ),
    );
  }

  Widget _buildFeaturesGrid(
    List<_FeatureData> features,
    ThemeData theme,
    ColorScheme colorScheme,
    bool isDark,
    bool isMobile,
    Axis axis,
  ) {
    // Determinar si usar layout horizontal basado en el eje y tamaño de pantalla
    final bool useHorizontalLayout = axis == Axis.horizontal && !isMobile;
    
    return Column(
      children: features
          .asMap()
          .entries
          .expand((entry) => [
                _ModernFeatureCard(
                  feature: entry.value,
                  delay: Duration(milliseconds: entry.key * (useHorizontalLayout ? 300 : 200)),
                  isFullWidth: useHorizontalLayout,
                  featureIndex: entry.key,
                ),
                const SizedBox(height: 50),
              ])
          .toList(),
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
    required String assetPath,
    required Widget actionWidget,
    double zoomFactor = 1.8,
  }) {
    return _DeviceScrollWidget(
      screenWidth: screenWidth,
      scrollController: _scrollController,
      assetPath: assetPath,
      actionWidget: actionWidget,
      zoomFactor: zoomFactor,
    );
  }
}

/// Widget simple de máquina de escribir para mostrar textos alternados
class TypewriterText extends StatefulWidget {
  final List<String> texts;
  final TextStyle? style;
  final TextAlign? textAlign;
  final Duration typingSpeed;
  final Duration pauseDuration;
  final Duration backspacingSpeed;

  const TypewriterText({
    super.key,
    required this.texts,
    this.style,
    this.textAlign,
    this.typingSpeed = const Duration(milliseconds: 80),
    this.pauseDuration = const Duration(milliseconds: 2000),
    this.backspacingSpeed = const Duration(milliseconds: 40),
  });

  @override
  State<TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<TypewriterText> {
  int _textIndex = 0;
  int _charCount = 0;
  bool _backspacing = false;
  late final Ticker _ticker;
  Duration _accum = Duration.zero;

  @override
  void initState() {
    super.initState();
    _ticker = Ticker(_onTick)..start();
  }

  void _onTick(Duration elapsed) {
    final delta = elapsed - _accum;
    final step = _backspacing ? widget.backspacingSpeed : widget.typingSpeed;
    if (delta >= step) {
      _accum = elapsed;
      setState(() {
        final current = widget.texts[_textIndex];
        if (_backspacing) {
          if (_charCount > 0) {
            _charCount--;
          } else {
            _backspacing = false;
            _textIndex = (_textIndex + 1) % widget.texts.length;
          }
        } else {
          if (_charCount < current.length) {
            _charCount++;
          } else {
            _backspacing = true;
            // pequeña pausa al final de la palabra
            _accum = elapsed - widget.pauseDuration;
          }
        }
      });
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final current = widget.texts[_textIndex];
    final visible = current.substring(0, _charCount);
    return Text(visible, style: widget.style, textAlign: widget.textAlign);
  }
}

class _DeviceScrollWidget extends StatefulWidget {
  final double screenWidth;
  final ScrollController scrollController;
  final String assetPath;
  final Widget actionWidget;
  final double zoomFactor;

  const _DeviceScrollWidget({
    required this.screenWidth,
    required this.scrollController,
    required this.assetPath,
    required this.actionWidget,
    this.zoomFactor = 1.8, // Factor de zoom por defecto
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
    if (!mounted) return;

    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    try {
      final position = renderBox.localToGlobal(Offset.zero);
      final size = renderBox.size;
      final screenHeight = MediaQuery.of(context).size.height;
      
      // Verificar si el widget está visible en el viewport
      final visibilityMargin = screenHeight * 0.1;
      final isCurrentlyVisible = position.dy < (screenHeight + visibilityMargin) && 
          (position.dy + size.height) > -visibilityMargin;

      // Zona de zoom simplificada
      // Zona de zoom más simple y efectiva
      final centerY = screenHeight / 2;
      final widgetCenterY = position.dy + (size.height / 2);
      
      // Zona de zoom centrada en el viewport
      final zoomZoneHeight = screenHeight * 0.6; // 60% de la pantalla
      final zoomZoneTop = centerY - (zoomZoneHeight / 2);
      final zoomZoneBottom = centerY + (zoomZoneHeight / 2);
      
      // Verificar si el centro del widget está en la zona de zoom
      final isInZoomZone = widgetCenterY >= zoomZoneTop && widgetCenterY <= zoomZoneBottom;

      if (isCurrentlyVisible != isVisible || isInZoomZone != isZoomed) {
        setState(() {
          isVisible = isCurrentlyVisible;
          isZoomed = isInZoomZone;
        });
      }
    } catch (e) {
      debugPrint('Error en _onScroll: $e');
    }
  }
 
  @override
  Widget build(BuildContext context) {
    final isMobile = widget.screenWidth < ResponsiveBreakpoints.mobile;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Calcular dimensiones basadas solo en screenWidth
    final widgetWidth = _calculateWidth(widget.screenWidth, isMobile);
    final widgetHeight = _calculateHeight(widget.screenWidth, isMobile);
    
    // Altura para el actionWidget
    final actionWidgetHeight = isMobile ? 32.0 : 40.0;
    final imageContainerHeight = widgetHeight - actionWidgetHeight - 8;
    
    // Aplicar zoom cuando está en la zona de zoom
    final scale = isZoomed ? widget.zoomFactor : 1.0;

    return Container(
      height: widgetHeight,
      width: widgetWidth,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Contenedor de imagen con zoom y sombra adaptativa
          Expanded(
            child: Center(
              child: AnimatedScale(
                scale: scale,
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOut,
                child: Container(
                  margin: EdgeInsets.only(bottom: isMobile ? 24 : 50),
                  width: widgetWidth,
                  height: imageContainerHeight,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(isMobile ? 8 : 12),
                    boxShadow: _buildAdaptiveShadow(isMobile, isDark, scale),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(isMobile ? 8 : 12),
                    child: Image.asset(
                      widget.assetPath,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                      errorBuilder: (context, error, stackTrace) => _buildErrorContainer(isMobile),
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 8),
          
          // ActionWidget
          Container(
            height: actionWidgetHeight,
            width: widgetWidth,
            alignment: Alignment.center,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: widget.actionWidget,
            ),
          ),
        ],
      ),
    );
  }

  /// Calcula el ancho del widget basado en screenWidth
  double _calculateWidth(double screenWidth, bool isMobile) {
    if (isMobile) {
      // Móvil: tamaño más grande para mejor visibilidad del zoom
      return (screenWidth * 0.35).clamp(90.0, 160.0);
    } else if (screenWidth < ResponsiveBreakpoints.tablet) {
      // Tablet: tamaño moderado
      return (screenWidth * 0.28).clamp(140.0, 220.0);
    } else if (screenWidth < ResponsiveBreakpoints.desktop) {
      // Desktop pequeño: tamaño estándar
      return (screenWidth * 0.24).clamp(180.0, 280.0);
    } else if (screenWidth < ResponsiveBreakpoints.largeDesktop) {
      // Desktop estándar: tamaño optimizado para zoom
      return (screenWidth * 0.22).clamp(220.0, 320.0);
    } else {
      // Desktop muy grande: tamaño escalado
      return (screenWidth * 0.20).clamp(260.0, 360.0);
    }
  }

  /// Calcula la altura del widget basado en screenWidth
  double _calculateHeight(double screenWidth, bool isMobile) {
    if (isMobile) {
      // Móvil: altura proporcionalmente mayor para el zoom
      return (screenWidth * 0.55).clamp(160.0, 240.0);
    } else if (screenWidth < ResponsiveBreakpoints.tablet) {
      // Tablet: altura moderada
      return (screenWidth * 0.40).clamp(200.0, 300.0);
    } else if (screenWidth < ResponsiveBreakpoints.desktop) {
      // Desktop pequeño: altura estándar
      return (screenWidth * 0.32).clamp(240.0, 350.0);
    } else if (screenWidth < ResponsiveBreakpoints.largeDesktop) {
      // Desktop estándar: altura optimizada para zoom
      return (screenWidth * 0.28).clamp(280.0, 400.0);
    } else {
      // Desktop muy grande: altura escalada
      return (screenWidth * 0.25).clamp(320.0, 450.0);
    }
  }

  /// Construye sombras adaptativas respetando dimensiones de imagen
  List<BoxShadow> _buildAdaptiveShadow(bool isMobile, bool isDark, double scale) {
    // Sin sombras para las imágenes de dispositivos
    return [];
  }

  /// Construye contenedor de error
  Widget _buildErrorContainer(bool isMobile) {
    final containerSize = isMobile ? 100.0 : 150.0;
    final iconSize = isMobile ? 40.0 : 60.0;

    return Container(
      height: containerSize,
      width: containerSize,
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_not_supported_outlined,
            color: Colors.grey.withValues(alpha: 0.6),
            size: iconSize,
          ),
          if (!isMobile) ...[
            const SizedBox(height: 8),
            Text(
              'Imagen no disponible',
              style: TextStyle(
                color: Colors.grey.withValues(alpha: 0.7),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
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
  final Color? color;
  final String? imageAsset;
  final bool imageOnRight;
  final String? category; // Nueva: categoría para agrupación
  final String? ctaText; // Nueva: texto de call to action
  final VoidCallback? onTap; // Nueva: acción opcional

  _FeatureData({
    required this.icon,
    required this.title,
    required this.description,
    this.checkItems,
    this.benefit, 
    this.color,
    this.imageAsset,
    this.imageOnRight = true,
    this.category,
    this.ctaText,
    this.onTap,
  });
}

class _ModernFeatureCard extends StatefulWidget {
  final _FeatureData feature;
  final Duration delay;
  final bool isFullWidth;
  final int featureIndex; // Nuevo: índice para diferenciación visual

  const _ModernFeatureCard({
    required this.feature,
    required this.delay,
    this.isFullWidth = false,
    this.featureIndex = 0, // Valor por defecto
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < ResponsiveBreakpoints.mobile;

    // En móvil o cuando se especifica, siempre mostrar en columna
    if (isMobile || !widget.isFullWidth) {
      return _buildMobileLayout(theme, colorScheme, isDark);
    }

    // En tablet/desktop con full width, mostrar lado a lado
    return _buildDesktopLayout(theme, colorScheme, isDark);
  }

  Widget _buildMobileLayout(ThemeData theme, ColorScheme colorScheme, bool isDark) {
    // Colores de fondo diferenciados para cada feature
    final backgroundColors = [
      widget.feature.color?.withValues(alpha: isDark ? 0.08 : 0.05) ?? 
          colorScheme.primary.withValues(alpha: isDark ? 0.08 : 0.05),
      widget.feature.color?.withValues(alpha: isDark ? 0.06 : 0.04) ?? 
          colorScheme.secondary.withValues(alpha: isDark ? 0.06 : 0.04),
      widget.feature.color?.withValues(alpha: isDark ? 0.07 : 0.045) ?? 
          colorScheme.tertiary.withValues(alpha: isDark ? 0.07 : 0.045),
    ];

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        transform: Matrix4.identity()
          ..translate(0.0, _isHovered ? -4.0 : 0.0),
        decoration: BoxDecoration(
          color: backgroundColors[widget.featureIndex % backgroundColors.length], 
        ), 
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Contenido de características
            _buildFeatureContent(theme, colorScheme, isDark),
            
            // Imagen abajo en móvil
            if (widget.feature.imageAsset != null) ...[
              const SizedBox(height: 32),
              Center(child: _buildFeatureImage(isMobile: true)),
            ],
          ],
        ),
      ),
    ).animate(delay: widget.delay).fadeIn(duration: 600.ms).slideY(begin: 0.3);
  }

  Widget _buildDesktopLayout(ThemeData theme, ColorScheme colorScheme, bool isDark) {
    // Colores de fondo diferenciados para cada feature
    final backgroundColors = [
      widget.feature.color?.withValues(alpha: isDark ? 0.08 : 0.05) ?? 
          colorScheme.primary.withValues(alpha: isDark ? 0.08 : 0.05),
      widget.feature.color?.withValues(alpha: isDark ? 0.06 : 0.04) ?? 
          colorScheme.secondary.withValues(alpha: isDark ? 0.06 : 0.04),
      widget.feature.color?.withValues(alpha: isDark ? 0.07 : 0.045) ?? 
          colorScheme.tertiary.withValues(alpha: isDark ? 0.07 : 0.045),
    ];

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        transform: Matrix4.identity()
          ..translate(0.0, _isHovered ? -6.0 : 0.0),
        decoration: BoxDecoration(
          color: backgroundColors[widget.featureIndex % backgroundColors.length], 
        ),
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 30),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: widget.feature.imageOnRight
              ? [
                  // Contenido a la izquierda
                  Expanded(
                    flex: 3,
                    child: _buildFeatureContent(theme, colorScheme, isDark),
                  ),
                  const SizedBox(width: 48),
                  // Imagen a la derecha
                  if (widget.feature.imageAsset != null)
                    Expanded(
                      flex: 2,
                      child: _buildFeatureImage(),
                    ),
                ]
              : [
                  // Imagen a la izquierda
                  if (widget.feature.imageAsset != null)
                    Expanded(
                      flex: 2,
                      child: _buildFeatureImage(),
                    ),
                  const SizedBox(width: 48),
                  // Contenido a la derecha
                  Expanded(
                    flex: 3,
                    child: _buildFeatureContent(theme, colorScheme, isDark),
                  ),
                ],
        ),
      ),
    ).animate(delay: widget.delay).fadeIn(duration: 600.ms).slideY(begin: 0.3);
  }

  Widget _buildFeatureContent(ThemeData theme, ColorScheme colorScheme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Ícono mejorado con accesibilidad
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                widget.feature.color ?? const Color(0xFF4F46E5),
                (widget.feature.color ?? const Color(0xFF4F46E5))
                    .withValues(alpha: 0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: (widget.feature.color ?? const Color(0xFF4F46E5))
                    .withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Icon(
            widget.feature.icon,
            size: 32,
            color: Colors.white,
            semanticLabel: '${widget.feature.title} ícono',
          ),
        ),
        const SizedBox(height: 20),

        // Título
        Text(
          widget.feature.title,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
            height: 1.2,
            color: isDark ? colorScheme.onSurface : colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),

        // Descripción
        Text(
          widget.feature.description,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: colorScheme.onSurface.withValues(alpha: 0.7),
            height: 1.6,
            fontSize: 16,
          ),
        ),

        // Check items
        if (widget.feature.checkItems != null &&
            widget.feature.checkItems!.isNotEmpty) ...[
          const SizedBox(height: 24),
          ...widget.feature.checkItems!
              .map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          margin: const EdgeInsets.only(top: 2),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                (widget.feature.color ?? const Color(0xFF4F46E5))
                                    .withValues(alpha: 0.2),
                                (widget.feature.color ?? const Color(0xFF4F46E5))
                                    .withValues(alpha: 0.1),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: (widget.feature.color ?? const Color(0xFF4F46E5))
                                  .withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            Icons.check_rounded,
                            size: 16,
                            color: widget.feature.color ?? const Color(0xFF4F46E5),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            item,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurface
                                  .withValues(alpha: 0.8),
                              fontWeight: FontWeight.w500,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ))
              ,
        ],

        // Estadísticas y beneficios
        if ( widget.feature.benefit != null) ...[
          const SizedBox(height: 32),
          Wrap(
            spacing: 16,
            runSpacing: 12,
            children: [
              if (widget.feature.benefit != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        (widget.feature.color ?? const Color(0xFF4F46E5))
                            .withValues(alpha: 0.15),
                        (widget.feature.color ?? const Color(0xFF4F46E5))
                            .withValues(alpha: 0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: (widget.feature.color ?? const Color(0xFF4F46E5))
                          .withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.feature.benefit!,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: widget.feature.color ?? const Color(0xFF4F46E5),
                          fontWeight: FontWeight.w900, 
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.trending_up_rounded,
                        size: 20,
                        color: widget.feature.color ?? const Color(0xFF4F46E5),
                      ),
                    ],
                  ),
                ), 
            ],
          ),
          
        ],
      ],
    );
  }

  Widget _buildFeatureImage({bool isMobile = false}) {
    // Dimensiones optimizadas para mostrar dispositivos móviles completos
    // Móvil: 280x160 - Desktop: 380x220 para mantener proporciones de dispositivo
    final containerHeight = isMobile ? 350.0 : 450.0; 
    
    return Container(
      height: containerHeight, 
      padding: const EdgeInsets.all(8), 
      child: Image.asset(
        widget.feature.imageAsset!,
        // BoxFit.contain asegura que todo el dispositivo se muestre sin recortes
        // Perfecto para screenshots de móviles PNG con fondo transparente
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        // Centrar la imagen para mejor presentación visual
        alignment: Alignment.center,
        errorBuilder: (context, error, stackTrace) => Container(
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.smartphone_outlined,
                  size: isMobile ? 48 : 64,
                  color: Colors.grey.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 12),
                Text(
                  'Vista previa del dispositivo\nno disponible',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey.withValues(alpha: 0.7),
                    fontSize: isMobile ? 12 : 14,
                    fontWeight: FontWeight.w500,
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
  )).animate(delay: widget.delay).fadeIn(duration: 600.ms).slideY(begin: 0.3);
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

/// Widget del AppBar de presentación con efectos de scroll y animaciones
class _PresentationAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool isScrolled;
  final bool isDark;
  final ColorScheme colorScheme;
  final Color appbarColor;
  final Color accentAppbarColor;
  final VoidCallback onLoginTap;

  const _PresentationAppBar({
    required this.isScrolled,
    required this.isDark,
    required this.colorScheme,
    required this.appbarColor,
    required this.accentAppbarColor,
    required this.onLoginTap,
  });

  @override
  Widget build(BuildContext context) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight),
      child: ClipRect(
        child: BackdropFilter(
          filter: isScrolled
              ? ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0)
              : ImageFilter.blur(sigmaX: 0.0, sigmaY: 0.0),
          child: Container(
            decoration: BoxDecoration(
              color: appbarColor,
              border: isScrolled 
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
                    transform: isScrolled 
                        ? (Matrix4.identity()..scale(1.05))
                        : Matrix4.identity(),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: isScrolled
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
                      fontSize: isScrolled ? 20 : 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                    child: Text(
                      'Sell',
                      style: TextStyle(
                        color: isScrolled
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
                  child: isScrolled
                      ? AppBarButton(
                          text: const Text('Iniciar Sesión'),
                          onTap: onLoginTap,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        )
                      : const SizedBox(key: ValueKey('placeholder')),
                ),

                // Botón para cambiar tema con diseño mejorado
                Consumer<ThemeDataAppProvider>(
                  builder: (context, themeProvider, _) {
                    return AppBarButton(
                      text: themeProvider.darkTheme.brightness == Brightness.dark? const Icon(Icons.dark_mode): const Icon(Icons.light_mode), 
                      onTap: themeProvider.toggleTheme, 
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    );
                  },
                ),
                const SizedBox(width: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

// Pintor de fondo dinámico con efecto parallax basado en el scroll
class _DynamicBackgroundPainter extends CustomPainter {
  final double scrollOffset;
  final Color primaryColor; // Reservado por si se desea tematizar colores en el futuro
  final bool isDark;        // Reservado para variantes de tema
  final bool isMobile;      // Reservado para ajustar curvas/escala si se necesita
  final double screenHeight; // Reservado para cálculos dependientes de altura visible

  _DynamicBackgroundPainter({
    required this.scrollOffset,
    required this.primaryColor,
    required this.isDark,
    required this.isMobile,
    required this.screenHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Colores adaptativos según el tema con transparencia optimizada para legibilidad
    final baseColors = isDark 
        ? [
            const Color(0xFF2A3D5C).withValues(alpha: 0.15), // Azul oscuro - reducido para legibilidad
            const Color(0xFF3A5F4C).withValues(alpha: 0.12), // Verde oscuro - reducido para legibilidad
            const Color(0xFF5C4A3A).withValues(alpha: 0.10), // Marrón oscuro - reducido para legibilidad
            const Color(0xFF4C3A5C).withValues(alpha: 0.13), // Púrpura oscuro - reducido para legibilidad
            const Color(0xFF5C3A3A).withValues(alpha: 0.11), // Rojo oscuro - reducido para legibilidad
            const Color(0xFF3A5C5C).withValues(alpha: 0.08), // Teal oscuro - reducido para legibilidad
          ]
        : [
            const Color(0xFFA3D8D1).withValues(alpha: 0.12), // Verde agua - reducido para legibilidad
            const Color(0xFFFAD86A).withValues(alpha: 0.10), // Amarillo - reducido para legibilidad
            const Color(0xFFA7C6ED).withValues(alpha: 0.13), // Azul - reducido para legibilidad
            const Color(0xFFFFB3D1).withValues(alpha: 0.11), // Rosa suave - reducido para legibilidad
            const Color(0xFFD1A3FF).withValues(alpha: 0.09), // Púrpura suave - reducido para legibilidad
            const Color(0xFFFFA3B3).withValues(alpha: 0.08), // Coral suave - reducido para legibilidad
          ];

    // --- CÍRCULOS GIGANTES CON DIFUMINADO (fondo) ---
    
    // Círculo gigante izquierdo (solo se ve la mitad derecha)
    final leftGiantRadius = size.width * (isMobile ? 0.6 : 0.5);
    final leftGiantPaint = Paint()..style = PaintingStyle.fill;
    
    // Gradiente radial para el círculo izquierdo con difuminado - transparencia optimizada
    leftGiantPaint.shader = RadialGradient(
      center: Alignment.centerLeft,
      radius: 1.2,
      colors: [
        baseColors[0].withValues(alpha: isDark ? 0.06 : 0.03), // Reducido para mejor legibilidad
        baseColors[1].withValues(alpha: isDark ? 0.03 : 0.015), // Reducido para mejor legibilidad
        Colors.transparent,
      ],
      stops: const [0.0, 0.6, 1.0],
    ).createShader(Rect.fromCircle(
      center: Offset(-leftGiantRadius * 0.5 + scrollOffset * 0.01, size.height * 0.5),
      radius: leftGiantRadius,
    ));

    canvas.drawCircle(
      Offset(-leftGiantRadius * 0.5 + scrollOffset * 0.01, size.height * 0.5),
      leftGiantRadius,
      leftGiantPaint,
    );

    // Círculo gigante derecho (solo se ve la mitad izquierda)
    final rightGiantRadius = size.width * (isMobile ? 0.55 : 0.45);
    final rightGiantPaint = Paint()..style = PaintingStyle.fill;
    
    // Gradiente radial para el círculo derecho con difuminado - transparencia optimizada
    rightGiantPaint.shader = RadialGradient(
      center: Alignment.centerRight,
      radius: 1.1,
      colors: [
        baseColors[2].withValues(alpha: isDark ? 0.05 : 0.025), // Reducido para mejor legibilidad
        baseColors[3].withValues(alpha: isDark ? 0.025 : 0.012), // Reducido para mejor legibilidad
        Colors.transparent,
      ],
      stops: const [0.0, 0.7, 1.0],
    ).createShader(Rect.fromCircle(
      center: Offset(size.width + rightGiantRadius * 0.5 + scrollOffset * 0.008, size.height * 0.3),
      radius: rightGiantRadius,
    ));

    canvas.drawCircle(
      Offset(size.width + rightGiantRadius * 0.5 + scrollOffset * 0.008, size.height * 0.3),
      rightGiantRadius,
      rightGiantPaint,
    );

    // --- CÍRCULOS PRINCIPALES (por encima de los gigantes) ---

    // Círculo principal 1: Grande en la esquina superior derecha
    paint.color = baseColors[0];
    canvas.drawCircle(
      Offset(
        size.width * 0.85 + scrollOffset * 0.02,
        size.height * 0.15 + scrollOffset * 0.03,
      ),
      size.width * (isMobile ? 0.15 : 0.12),
      paint,
    );

    // Círculo principal 2: Grande en la esquina inferior izquierda
    paint.color = baseColors[1];
    canvas.drawCircle(
      Offset(
        size.width * 0.15 + scrollOffset * 0.04,
        size.height * 0.8 + scrollOffset * 0.02,
      ),
      size.width * (isMobile ? 0.18 : 0.14),
      paint,
    );

    // Círculo principal 3: Mediano en el centro-derecha
    paint.color = baseColors[2];
    canvas.drawCircle(
      Offset(
        size.width * 0.88 + scrollOffset * 0.03,
        size.height * 0.6 + scrollOffset * 0.05,
      ),
      size.width * (isMobile ? 0.12 : 0.09),
      paint,
    );

    // Círculo principal 4: Mediano en el centro-izquierda
    paint.color = baseColors[3];
    canvas.drawCircle(
      Offset(
        size.width * 0.12 + scrollOffset * 0.06,
        size.height * 0.35 + scrollOffset * 0.04,
      ),
      size.width * (isMobile ? 0.14 : 0.1),
      paint,
    );

    // Círculo principal 5: Mediano en el centro superior
    paint.color = baseColors[4];
    canvas.drawCircle(
      Offset(
        size.width * 0.6 + scrollOffset * 0.01,
        size.height * 0.2 + scrollOffset * 0.03,
      ),
      size.width * (isMobile ? 0.1 : 0.08),
      paint,
    );

    // --- CÍRCULOS ADICIONALES PARA DESKTOP ---
    if (!isMobile) {
      // Círculo 6: Pequeño flotante centro
      paint.color = baseColors[5];
      canvas.drawCircle(
        Offset(
          size.width * 0.45 + scrollOffset * 0.07,
          size.height * 0.45 + scrollOffset * 0.02,
        ),
        size.width * 0.06,
        paint,
      );

      // Círculo 7: Pequeño superior centro-izquierda - transparencia optimizada
      paint.color = baseColors[0].withValues(alpha: isDark ? 0.12 : 0.08); // Reducido para legibilidad
      canvas.drawCircle(
        Offset(
          size.width * 0.3 + scrollOffset * 0.05,
          size.height * 0.1 + scrollOffset * 0.04,
        ),
        size.width * 0.05,
        paint,
      );

      // Círculo 8: Pequeño inferior centro-derecha - transparencia optimizada
      paint.color = baseColors[1].withValues(alpha: isDark ? 0.10 : 0.06); // Reducido para legibilidad
      canvas.drawCircle(
        Offset(
          size.width * 0.75 + scrollOffset * 0.03,
          size.height * 0.85 + scrollOffset * 0.06,
        ),
        size.width * 0.07,
        paint,
      );

      // Círculo 9: Muy pequeño decorativo superior - transparencia optimizada
      paint.color = baseColors[2].withValues(alpha: isDark ? 0.08 : 0.05); // Reducido para legibilidad
      canvas.drawCircle(
        Offset(
          size.width * 0.2 + scrollOffset * 0.08,
          size.height * 0.05 + scrollOffset * 0.02,
        ),
        size.width * 0.03,
        paint,
      );

      // Círculo 10: Muy pequeño decorativo inferior - transparencia optimizada
      paint.color = baseColors[3].withValues(alpha: isDark ? 0.06 : 0.04); // Reducido para legibilidad
      canvas.drawCircle(
        Offset(
          size.width * 0.9 + scrollOffset * 0.04,
          size.height * 0.9 + scrollOffset * 0.05,
        ),
        size.width * 0.04,
        paint,
      );
    }

    // --- CÍRCULO CON GRADIENTE CENTRAL (con efecto de profundidad) ---
    final gradientPaint = Paint()..style = PaintingStyle.fill;
    
    // Gradiente radial para círculo principal - transparencia optimizada
    gradientPaint.shader = RadialGradient(
      colors: [
        primaryColor.withValues(alpha: isDark ? 0.08 : 0.12), // Reducido para mejor legibilidad
        primaryColor.withValues(alpha: isDark ? 0.04 : 0.06), // Reducido para mejor legibilidad
        Colors.transparent,
      ],
      stops: const [0.0, 0.7, 1.0],
    ).createShader(Rect.fromCircle(
      center: Offset(
        size.width * 0.5 + scrollOffset * 0.01,
        size.height * 0.7 + scrollOffset * 0.03,
      ),
      radius: size.width * (isMobile ? 0.2 : 0.15),
    ));

    canvas.drawCircle(
      Offset(
        size.width * 0.5 + scrollOffset * 0.01,
        size.height * 0.7 + scrollOffset * 0.03,
      ),
      size.width * (isMobile ? 0.2 : 0.15),
      gradientPaint,
    );

    // --- CÍRCULOS FLOTANTES PEQUEÑOS CON DIFERENTES VELOCIDADES ---
    final smallCircles = [
      {'x': 0.25, 'y': 0.25, 'radius': 0.02, 'speed': 0.08, 'color': 0},
      {'x': 0.65, 'y': 0.35, 'radius': 0.025, 'speed': 0.05, 'color': 1},
      {'x': 0.8, 'y': 0.45, 'radius': 0.015, 'speed': 0.12, 'color': 2},
      {'x': 0.35, 'y': 0.65, 'radius': 0.03, 'speed': 0.06, 'color': 3},
      {'x': 0.15, 'y': 0.55, 'radius': 0.018, 'speed': 0.1, 'color': 4},
      {'x': 0.95, 'y': 0.3, 'radius': 0.022, 'speed': 0.07, 'color': 5},
      {'x': 0.05, 'y': 0.15, 'radius': 0.012, 'speed': 0.15, 'color': 0},
      {'x': 0.55, 'y': 0.05, 'radius': 0.016, 'speed': 0.09, 'color': 1},
    ];

    paint.style = PaintingStyle.fill;
    for (final circle in smallCircles) {
      final colorIndex = circle['color'] as int;
      paint.color = baseColors[colorIndex % baseColors.length]
          .withValues(alpha: isDark ? 0.08 : 0.12); // Transparencia uniforme optimizada para legibilidad
      
      canvas.drawCircle(
        Offset(
          size.width * (circle['x'] as double) + scrollOffset * (circle['speed'] as double),
          size.height * (circle['y'] as double) + scrollOffset * (circle['speed'] as double) * 0.3,
        ),
        size.width * (circle['radius'] as double),
        paint,
      );
    }

    // --- ANILLOS DECORATIVOS (círculos con solo borde) - transparencia optimizada ---
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = isDark ? 1.0 : 1.5 // Líneas más sutiles para mejor legibilidad
      ..strokeCap = StrokeCap.round;

    final rings = [
      {'x': 0.4, 'y': 0.3, 'radius': 0.08, 'speed': 0.04},
      {'x': 0.7, 'y': 0.7, 'radius': 0.06, 'speed': 0.06},
      {'x': 0.25, 'y': 0.75, 'radius': 0.05, 'speed': 0.03},
    ];

    if (!isMobile) {
      for (int i = 0; i < rings.length; i++) {
        final ring = rings[i];
        ringPaint.color = baseColors[i % baseColors.length]
            .withValues(alpha: isDark ? 0.06 : 0.10); // Reducido para mejor legibilidad
        
        canvas.drawCircle(
          Offset(
            size.width * (ring['x'] as double) + scrollOffset * (ring['speed'] as double),
            size.height * (ring['y'] as double) + scrollOffset * (ring['speed'] as double) * 0.2,
          ),
          size.width * (ring['radius'] as double),
          ringPaint,
        );
      }
    }

    // --- PUNTOS MICRO DECORATIVOS - transparencia optimizada ---
    final microDotPaint = Paint()..style = PaintingStyle.fill;
    final microDots = List.generate(15, (index) => {
      'x': 0.1 + (index * 0.06) % 0.8,
      'y': 0.1 + (index * 0.07) % 0.8,
      'size': 1.0 + (index % 3),
      'speed': 0.02 + (index % 5) * 0.01,
    });

    for (final dot in microDots) {
      microDotPaint.color = primaryColor.withValues(alpha: isDark ? 0.04 : 0.08); // Reducido para mejor legibilidad
      canvas.drawCircle(
        Offset(
          size.width * (dot['x'] as double) + scrollOffset * (dot['speed'] as double),
          size.height * (dot['y'] as double) + scrollOffset * (dot['speed'] as double) * 0.1,
        ),
        dot['size'] as double,
        microDotPaint,
      );
    }

    // --- EFECTOS DE DIFUMINADO ADICIONALES - transparencia optimizada ---
    
    // Círculo de difuminado superior izquierdo
    if (!isMobile) {
      final topLeftBlurPaint = Paint()..style = PaintingStyle.fill;
      topLeftBlurPaint.shader = RadialGradient(
        colors: [
          baseColors[4].withValues(alpha: isDark ? 0.02 : 0.015), // Reducido para mejor legibilidad
          Colors.transparent,
        ],
        stops: const [0.0, 1.0],
      ).createShader(Rect.fromCircle(
        center: Offset(
          size.width * 0.1 + scrollOffset * 0.015,
          size.height * 0.1 + scrollOffset * 0.02,
        ),
        radius: size.width * 0.25,
      ));

      canvas.drawCircle(
        Offset(
          size.width * 0.1 + scrollOffset * 0.015,
          size.height * 0.1 + scrollOffset * 0.02,
        ),
        size.width * 0.25,
        topLeftBlurPaint,
      );

      // Círculo de difuminado inferior derecho
      final bottomRightBlurPaint = Paint()..style = PaintingStyle.fill;
      bottomRightBlurPaint.shader = RadialGradient(
        colors: [
          baseColors[5].withValues(alpha: isDark ? 0.018 : 0.012), // Reducido para mejor legibilidad
          Colors.transparent,
        ],
        stops: const [0.0, 1.0],
      ).createShader(Rect.fromCircle(
        center: Offset(
          size.width * 0.9 + scrollOffset * 0.012,
          size.height * 0.85 + scrollOffset * 0.018,
        ),
        radius: size.width * 0.2,
      ));

      canvas.drawCircle(
        Offset(
          size.width * 0.9 + scrollOffset * 0.012,
          size.height * 0.85 + scrollOffset * 0.018,
        ),
        size.width * 0.2,
        bottomRightBlurPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DynamicBackgroundPainter oldDelegate) {
    return oldDelegate.scrollOffset != scrollOffset ||
        oldDelegate.primaryColor != primaryColor ||
        oldDelegate.isDark != isDark ||
        oldDelegate.isMobile != isMobile ||
        oldDelegate.screenHeight != screenHeight;
  }
}
