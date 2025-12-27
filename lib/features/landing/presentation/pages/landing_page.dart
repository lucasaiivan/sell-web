import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sellweb/core/presentation/helpers/responsive_helper.dart';

import 'package:url_launcher/url_launcher.dart';
import 'package:sellweb/features/auth/presentation/pages/login_page.dart';
import 'package:sellweb/features/auth/presentation/providers/auth_provider.dart';
import 'dart:ui';
import 'dart:math' as math;

import 'package:sellweb/core/presentation/providers/theme_provider.dart';

/// Clase helper para colores del AppBar optimizada
class _AppBarColors {
  final Color background;
  final Color accent;
  final Color iconColor;

  const _AppBarColors({
    required this.background,
    required this.accent,
    required this.iconColor,
  });
}

/// Página de presentación optimizada con diseño Premium
class AppPresentationPage extends StatefulWidget {
  const AppPresentationPage({super.key});

  @override
  State<AppPresentationPage> createState() => _AppPresentationPageState();
}

class _AppPresentationPageState extends State<AppPresentationPage>
    with TickerProviderStateMixin {
  late final ScrollController _scrollController;
  bool _isScrolled = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_handleScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _handleScroll() {
    final bool isScrolled = _scrollController.offset > 50;
    if (_isScrolled != isScrolled && mounted) {
      setState(() => _isScrolled = isScrolled);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final mediaQuery = MediaQuery.of(context);
    final screenSize = mediaQuery.size;

    final appBarColors = _calculateAppBarColors(colorScheme, isDark);

    return Title(
      title: 'Bienvenido - Sell Web',
      color: colorScheme.primary,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        appBar: _PresentationAppBar(
          isScrolled: _isScrolled,
          isDark: isDark,
          colorScheme: colorScheme,
          appbarColor: appBarColors.background,
          accentAppbarColor: appBarColors.accent,
          iconColor: appBarColors.iconColor,
          onLoginTap: () => _navigateToLogin(
              context, Provider.of<AuthProvider>(context, listen: false)),
        ),
        body: _buildBody(context, screenSize, theme),
      ),
    );
  }

  _AppBarColors _calculateAppBarColors(ColorScheme colorScheme, bool isDark) {
    final isScrolled = _isScrolled;

    return _AppBarColors(
      background: isScrolled
          ? (isDark
              ? const Color(0xFF0F172A).withOpacity(0.9)
              : Colors.white.withOpacity(0.9))
          : Colors.transparent,
      accent: isScrolled
          ? colorScheme.primary
          : (isDark ? Colors.white : Colors.white), // Always white on hero
      iconColor:
          isScrolled ? (isDark ? Colors.white : Colors.black) : Colors.white,
    );
  }

  Widget _buildBody(BuildContext context, Size screenSize, ThemeData theme) {
    return SingleChildScrollView(
      controller: _scrollController,
      child: Column(
        children: [
          //  Hero Section
          _buildHeroSection(context),
          // Responsive Content Sections
          _buildResponsiveContent(context, screenSize.width),
          // Footer Section
          _buildFooterSection(context),
        ],
      ),
    );
  }

  Widget _buildResponsiveContent(BuildContext context, double width) {
    final isMobile = width < ResponsiveHelper.mobile;

    return Container(
      color: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF0F172A)
          : const Color(0xFFF8FAFC),
      child: Column(
        children: [
          const SizedBox(height: 100),
          _buildFeaturesSection(context,
              axis: isMobile ? Axis.vertical : Axis.horizontal),
          const SizedBox(height: 100),
          _buildCallToActionSection(context),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < ResponsiveHelper.mobile;

    return Container(
      constraints: BoxConstraints(minHeight: size.height),
      width: double.infinity,
      child: Stack(
        children: [
          // Dynamic Background
          Positioned.fill(
            child: CustomPaint(
              painter: _PremiumBackgroundPainter(
                scrollOffset:
                    _scrollController.hasClients ? _scrollController.offset : 0,
                isDark: isDark,
                primaryColor: theme.colorScheme.primary,
              ),
            ),
          ),

          // Content - contenido centrado de la página de presentación
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1400),
              child: SafeArea(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 20 : 40, vertical: 40),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      _buildHeroText(context, isMobile),
                      const SizedBox(height: 40),
                      _buildHeroButtons(context),
                      _buildHeroDevices(context, isMobile),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroText(BuildContext context, bool isMobile) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
              const SizedBox(width: 8),
              Text(
                'La solución #1 para tu negocio',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ).animate().fadeIn().slideY(begin: -0.5),
        const SizedBox(height: 24),
        Text(
          'GESTIONA TUS VENTAS\nE INVENTARIO',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: GoogleFonts.inter().fontFamily,
            fontWeight: FontWeight.w900,
            fontSize: isMobile ? 36 : 64,
            height: 1.1,
            color: Colors.white,
            letterSpacing: -1.5,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.3),
                offset: const Offset(0, 4),
                blurRadius: 12,
              ),
            ],
          ),
        ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.2),
        const SizedBox(height: 24),
        SizedBox(
          height: 40,
          child: TypewriterText(
            texts: const [
              'Punto de venta fácil de usar',
              'Control de stock en tiempo real',
              'Reportes inteligentes',
              'Todo en la nube',
            ],
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: isMobile ? 18 : 24,
              fontWeight: FontWeight.w500,
            ),
            cursorColor: Colors.white,
          ),
        ).animate(delay: 400.ms).fadeIn(),
      ],
    );
  }

  Widget _buildHeroButtons(BuildContext context) {
    return Wrap(
      spacing: 20,
      runSpacing: 16,
      alignment: WrapAlignment.center,
      children: [
        _GlassButton(
          text: 'Comenzar Ahora',
          icon: Icons.rocket_launch_rounded,
          isPrimary: true,
          onPressed: () => _navigateToLogin(
              context, Provider.of<AuthProvider>(context, listen: false)),
        ),
        _GlassButton(
          text: 'Play Store',
          icon: Icons.android_rounded,
          isPrimary: false,
          onPressed: _launchPlayStore,
        ),
      ],
    ).animate(delay: 600.ms).fadeIn().slideY(begin: 0.2);
  }

  Widget _buildHeroDevices(BuildContext context, bool isMobile) {
    return _AnimatedDeviceShowcase(
      scrollController: _scrollController,
      isMobile: isMobile,
    );
  }

  Widget _buildFeaturesSection(BuildContext context, {required Axis axis}) {
    final theme = Theme.of(context);
    final isMobile =
        MediaQuery.of(context).size.width < ResponsiveHelper.mobile;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1400),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              Text(
                'CARACTERÍSTICAS',
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Todo lo que necesitas para crecer',
                textAlign: TextAlign.center,
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),
              const SizedBox(height: 60),
              _buildFeaturesGrid(theme, isMobile),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturesGrid(ThemeData theme, bool isMobile) {
    final features = _getFeatureData();

    if (isMobile) {
      return Column(
        children: features
            .map((f) => Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: _GlassFeatureCard(feature: f),
                ))
            .toList(),
      );
    }

    return Wrap(
      spacing: 30,
      runSpacing: 30,
      alignment: WrapAlignment.center,
      children: features
          .map((f) => SizedBox(
                width: 350,
                child: _GlassFeatureCard(feature: f),
              ))
          .toList(),
    );
  }

  Widget _buildCallToActionSection(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.all(48),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primary,
                theme.colorScheme.tertiary,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(40),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withOpacity(0.4),
                blurRadius: 30,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: Column(
            children: [
              const Icon(Icons.rocket_launch_outlined,
                  size: 64, color: Colors.white),
              const SizedBox(height: 24),
              Text(
                '¿Listo para transformar tu negocio?',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Únete a los emprendedores que ya están usando Sell Web',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () => _navigateToLogin(
                    context, Provider.of<AuthProvider>(context, listen: false)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: theme.colorScheme.primary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 48, vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Comenzar Gratis',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
                  begin: const Offset(1, 1),
                  end: const Offset(1.05, 1.05),
                  duration: 1.seconds),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooterSection(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      color: isDark ? const Color(0xFF0F172A) : Colors.white,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/launcher.png', height: 32),
              const SizedBox(width: 12),
              Text(
                'Sell Web',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            '© 2025 Sell Web. Hecho con ❤️ en Argentina.',
            style: TextStyle(
              color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  List<_FeatureData> _getFeatureData() => [
        _FeatureData(
          icon: Icons.point_of_sale_rounded,
          title: 'Punto de Venta y Control de Arqueo',
          description:
              'Sistema completo de ventas con gestión profesional de caja',
          features: [
            'Escaneo eficiente de códigos de barras',
            'Múltiples métodos de pago (efectivo, tarjeta, transferencia y qr)',
            'Arqueo de caja con auditoría completa',
            'Impresión de tickets por diferentes medios',
          ],
          color: Colors.blue,
        ),
        _FeatureData(
          icon: Icons.inventory_2_rounded,
          title: 'Gestión de Productos e Inventario',
          description: 'Control total de tu catálogo y stock en tiempo real.',
          features: [
            'Disponibilidad de una gran base de datos de productos precargados',
            'Control y alerta de stock',
            'Categorías y proveedores organizados',
            'Búsqueda rápida y productos favoritos',
          ],
          color: Colors.green,
        ),
        _FeatureData(
          icon: Icons.analytics_rounded,
          title: 'Analíticas',
          description:
              'Métricas y reportes detallados para tomar mejores decisiones.',
          features: [
            'Dashboard con ganancias en tiempo real',
            'Reportes de ventas por período',
            'Historial completo de transacciones',
            'Análisis de productos más vendidos',
          ],
          color: Colors.purple,
        ),
        _FeatureData(
          icon: Icons.people_alt_rounded,
          title: 'Multiusuario',
          description: 'Colabora con tu equipo de forma segura y organizada.',
          features: [
            'Sistema de roles y permisos',
            'Múltiples usuarios simultáneos',
            'Registro de actividad por usuario',
            'Gestión centralizada en la nube',
          ],
          color: Colors.orange,
        ),
      ];

  void _navigateToLogin(BuildContext context, AuthProvider authProvider) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  Future<void> _launchPlayStore() async {
    const url =
        'https://play.google.com/store/apps/details?id=com.logicabooleana.sell&pcampaignid=web_share';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }
}

class _GlassButton extends StatefulWidget {
  final String text;
  final IconData icon;
  final bool isPrimary;
  final VoidCallback onPressed;

  const _GlassButton({
    required this.text,
    required this.icon,
    required this.isPrimary,
    required this.onPressed,
  });

  @override
  State<_GlassButton> createState() => _GlassButtonState();
}

class _GlassButtonState extends State<_GlassButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          decoration: BoxDecoration(
            color:
                widget.isPrimary ? Colors.white : Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(50),
            border: Border.all(
              color: Colors.white.withOpacity(widget.isPrimary ? 1 : 0.3),
              width: 1.5,
            ),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.2),
                      blurRadius: 20,
                      spreadRadius: 2,
                    )
                  ]
                : [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                color:
                    widget.isPrimary ? const Color(0xFF4F46E5) : Colors.white,
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                widget.text,
                style: TextStyle(
                  color:
                      widget.isPrimary ? const Color(0xFF4F46E5) : Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Animated Device Showcase with scroll-based parallax
class _AnimatedDeviceShowcase extends StatefulWidget {
  final ScrollController scrollController;
  final bool isMobile;

  const _AnimatedDeviceShowcase({
    required this.scrollController,
    required this.isMobile,
  });

  @override
  State<_AnimatedDeviceShowcase> createState() =>
      _AnimatedDeviceShowcaseState();
}

class _AnimatedDeviceShowcaseState extends State<_AnimatedDeviceShowcase> {
  bool _webHovered = false;
  bool _mobileHovered = false;

  double get _scrollOffset => widget.scrollController.hasClients
      ? widget.scrollController.offset.clamp(0, 500)
      : 0;

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
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final parallaxWeb = _scrollOffset * 0.1;
    final parallaxMobile = _scrollOffset * 0.15;

    return SizedBox(
      height: widget.isMobile ? 300 : 400,
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          // Web Screenshot (Back) with parallax
          Transform.translate(
            offset: Offset(0, 40 - parallaxWeb),
            child: MouseRegion(
              onEnter: (_) => setState(() => _webHovered = true),
              onExit: (_) => setState(() => _webHovered = false),
              child: AnimatedScale(
                scale: _webHovered ? 1.1 : 1.0,
                duration: const Duration(milliseconds: 300),
                child: Transform(
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.001)
                    ..rotateX(0.1),
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    width: widget.isMobile ? 350 : 700,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color:
                              Colors.black.withOpacity(_webHovered ? 0.4 : 0.3),
                          blurRadius: _webHovered ? 40 : 30,
                          spreadRadius: _webHovered ? 8 : 5,
                          offset: Offset(0, _webHovered ? 25 : 20),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        'assets/screenshot06.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ).animate(delay: 800.ms).fadeIn().slideY(begin: 0.5),

          // Mobile Screenshot (Front) with parallax
          Positioned(
            right: widget.isMobile ? 20 : 100,
            bottom: -20 - parallaxMobile,
            child: MouseRegion(
              onEnter: (_) => setState(() => _mobileHovered = true),
              onExit: (_) => setState(() => _mobileHovered = false),
              child: AnimatedScale(
                scale: _mobileHovered ? 1.15 : 1.0,
                duration: const Duration(milliseconds: 300),
                child: Transform(
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.001)
                    ..rotateY(_mobileHovered ? -0.15 : -0.1)
                    ..rotateZ(_mobileHovered ? 0.08 : 0.05),
                  alignment: Alignment.center,
                  child: Container(
                    width: widget.isMobile ? 140 : 240,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black
                              .withOpacity(_mobileHovered ? 0.5 : 0.4),
                          blurRadius: _mobileHovered ? 25 : 20,
                          spreadRadius: _mobileHovered ? 4 : 2,
                          offset: Offset(0, _mobileHovered ? 15 : 10),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.asset(
                        'assets/screenshot00.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ).animate(delay: 1000.ms).fadeIn().slideX(begin: 0.5),
        ],
      ),
    );
  }
}

class _GlassFeatureCard extends StatefulWidget {
  final _FeatureData feature;

  const _GlassFeatureCard({required this.feature});

  @override
  State<_GlassFeatureCard> createState() => _GlassFeatureCardState();
}

class _GlassFeatureCardState extends State<_GlassFeatureCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        transform: Matrix4.identity()..translate(0.0, _isHovered ? -10.0 : 0.0),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.1)
                : Colors.grey.withOpacity(0.1),
          ),
          boxShadow: [
            BoxShadow(
              color: widget.feature.color!.withOpacity(_isHovered ? 0.2 : 0.05),
              blurRadius: _isHovered ? 30 : 10,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ícono destacado
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    widget.feature.color!.withOpacity(0.2),
                    widget.feature.color!.withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: widget.feature.color!.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Icon(
                widget.feature.icon,
                color: widget.feature.color,
                size: 36,
              ),
            ),
            const SizedBox(height: 24),

            // Título con badge
            Text(
              widget.feature.title,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 16),

            // Descripción principal
            Text(
              widget.feature.description,
              style: TextStyle(
                fontSize: 15,
                color: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.color
                    ?.withOpacity(0.7),
                height: 1.6,
              ),
            ),

            const SizedBox(height: 20),

            // Lista de características
            ...widget.feature.features.map((feat) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: widget.feature.color!.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.check,
                          size: 14,
                          color: widget.feature.color,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          feat,
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.color
                                ?.withOpacity(0.8),
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

class _FeatureData {
  final IconData icon;
  final String title;
  final String description;
  final List<String> features;
  final Color? color;

  _FeatureData({
    required this.icon,
    required this.title,
    required this.description,
    required this.features,
    this.color,
  });
}

class _PremiumBackgroundPainter extends CustomPainter {
  final double scrollOffset;
  final bool isDark;
  final Color primaryColor;

  _PremiumBackgroundPainter({
    required this.scrollOffset,
    required this.isDark,
    required this.primaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // 1. Background Gradient
    final bgPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark
            ? [
                const Color(0xFF0F172A),
                const Color(0xFF1E1B4B),
                const Color(0xFF312E81),
              ]
            : [
                const Color(0xFF4F46E5),
                const Color(0xFF7C3AED),
                const Color(0xFF2563EB),
              ],
      ).createShader(rect);

    canvas.drawRect(rect, bgPaint);

    // 2. Animated Orbs

    _drawOrb(
        canvas,
        size,
        Offset(size.width * 0.8, size.height * 0.2 - scrollOffset * 0.5),
        200,
        Colors.purpleAccent.withOpacity(0.3));

    _drawOrb(
        canvas,
        size,
        Offset(size.width * 0.2, size.height * 0.5 - scrollOffset * 0.3),
        300,
        Colors.blueAccent.withOpacity(0.3));

    _drawOrb(
        canvas,
        size,
        Offset(size.width * 0.9, size.height * 0.8 - scrollOffset * 0.8),
        150,
        Colors.pinkAccent.withOpacity(0.2));
  }

  void _drawOrb(
      Canvas canvas, Size size, Offset center, double radius, Color color) {
    final paint = Paint()
      ..color = color
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 80);
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant _PremiumBackgroundPainter oldDelegate) {
    return scrollOffset != oldDelegate.scrollOffset ||
        isDark != oldDelegate.isDark;
  }
}

// Reusing TypewriterText from previous implementation as it was good
class TypewriterText extends StatefulWidget {
  final List<String> texts;
  final TextStyle? style;
  final Color? cursorColor;

  const TypewriterText({
    super.key,
    required this.texts,
    this.style,
    this.cursorColor,
  });

  @override
  State<TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<TypewriterText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final text = widget.texts[_currentIndex];
        final len =
            (text.length * _controller.value * 2).clamp(0, text.length).toInt();

        if (_controller.value > 0.9 && len == text.length) {
          SchedulerBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _currentIndex = (_currentIndex + 1) % widget.texts.length;
                _controller.reset();
                _controller.forward();
              });
            }
          });
        }

        return RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            children: [
              TextSpan(
                text: text.substring(0, len),
                style: widget.style,
              ),
              TextSpan(
                text: '|',
                style: widget.style?.copyWith(
                  color: (widget.cursorColor ?? Colors.black)
                      .withOpacity((math.sin(_controller.value * 20) + 1) / 2),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PresentationAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final bool isScrolled;
  final bool isDark;
  final ColorScheme colorScheme;
  final Color appbarColor;
  final Color accentAppbarColor;
  final Color iconColor;
  final VoidCallback onLoginTap;

  const _PresentationAppBar({
    required this.isScrolled,
    required this.isDark,
    required this.colorScheme,
    required this.appbarColor,
    required this.accentAppbarColor,
    required this.iconColor,
    required this.onLoginTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      color: appbarColor,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(
            children: [
              Image.asset('assets/launcher.png', height: 32),
              const SizedBox(width: 12),
              Text(
                'Sell Web',
                style: TextStyle(
                  color: iconColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              const Spacer(),
              if (!isMobile(context))
                Row(
                  children: [
                    TextButton(
                      onPressed: onLoginTap,
                      child: Text(
                        'Iniciar Sesión',
                        style: TextStyle(
                          color: iconColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                  ],
                ),
              Consumer<ThemeDataAppProvider>(
                builder: (context, themeProvider, _) {
                  return IconButton(
                    icon: Icon(
                      themeProvider.darkTheme.brightness == Brightness.dark
                          ? Icons.light_mode_rounded
                          : Icons.dark_mode_rounded,
                      color: iconColor,
                    ),
                    onPressed: () => themeProvider.toggleTheme(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(80);
}
