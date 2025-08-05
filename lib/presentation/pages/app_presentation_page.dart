import 'dart:html' as html;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:sellweb/core/utils/responsive.dart';
import 'package:sellweb/core/widgets/buttons/buttons.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_data_app_provider.dart';
import 'login_page.dart';

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
    html.document.title = 'Bienvenido - Sell Web';
    final double width = MediaQuery.of(context).size.width;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: _isScrolled 
            ? colorScheme.surface.withOpacity(0.95)
            : Colors.transparent,
        elevation: _isScrolled ? 1 : 0,
        scrolledUnderElevation: 2,
        surfaceTintColor: colorScheme.surfaceTint,
        actions: [
          // Botón para cambiar tema
          Consumer<ThemeDataAppProvider>(
            builder: (context, themeProvider, _) {
              return IconButton(
                onPressed: themeProvider.toggleTheme,
                icon: Icon(
                  themeProvider.themeMode == ThemeMode.dark 
                    ? Icons.light_mode_outlined
                    : Icons.dark_mode_outlined,
                ),
                tooltip: themeProvider.themeMode == ThemeMode.dark 
                  ? 'Cambiar a tema claro'
                  : 'Cambiar a tema oscuro',
              );
            },
          ),
          const SizedBox(width: 8),
          // Botón de login
          Consumer<AuthProvider>(
            builder: (context, authProvider, _) {
              return IconButton(
                onPressed: () => _navigateToLogin(context, authProvider),
                icon: const Icon(Icons.login),
                tooltip: 'Iniciar Sesión',
              );
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        child: _buildResponsiveContent(context, width),
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
        const SizedBox(height: 32),
        _buildFeaturesSection(context, axis: Axis.vertical),
        const SizedBox(height: 32),
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
        const SizedBox(height: 48),
        _buildFeaturesSection(context, axis: Axis.horizontal),
        const SizedBox(height: 48),
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
        const SizedBox(height: 64),
        _buildFeaturesSection(context, axis: Axis.horizontal),
        const SizedBox(height: 64),
        _buildCallToActionSection(context),
        const SizedBox(height: 48),
        _buildFooterSection(context),
      ],
    );
  }

  Widget _buildHeroSection(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final width = MediaQuery.of(context).size.width;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 64 + MediaQuery.of(context).padding.top,
        bottom: 64,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primaryContainer,
            colorScheme.secondaryContainer,
          ],
        ),
      ),
      child: width < ResponsiveBreakpoints.tablet
          ? _buildHeroMobileLayout(context, theme, colorScheme)
          : _buildHeroDesktopLayout(context, theme, colorScheme),
    );
  }

  Widget _buildHeroMobileLayout(
      BuildContext context, ThemeData theme, ColorScheme colorScheme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildHeroImage(colorScheme, height: 200),
        const SizedBox(height: 32),
        _buildHeroContent(context, theme, colorScheme, isMobile: true),
      ],
    );
  }

  Widget _buildHeroDesktopLayout(
      BuildContext context, ThemeData theme, ColorScheme colorScheme) {
    return Row(
      children: [
        Expanded(
          flex: 1,
          child: Padding(
            padding: const EdgeInsets.only(right: 32),
            child: _buildHeroContent(context, theme, colorScheme),
          ),
        ),
        Expanded(
          flex: 1,
          child: _buildHeroImage(colorScheme, height: 400),
        ),
      ],
    );
  }

  Widget _buildHeroContent(BuildContext context, ThemeData theme, ColorScheme colorScheme, {bool isMobile = false}) {
    return Column(
      crossAxisAlignment: isMobile ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'PUNTO DE VENTA',
          textAlign: isMobile ? TextAlign.center : TextAlign.left,
          style: theme.textTheme.displayMedium?.copyWith(
            color: colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ).animate().fadeIn(duration: 800.ms).slideX(begin: -0.3),
        const SizedBox(height: 16),
        Text(
          'EL PUNTO DE VENTA MÁS FÁCIL DE USAR',
          textAlign: isMobile ? TextAlign.center : TextAlign.left,
          style: theme.textTheme.headlineSmall?.copyWith(
            color: colorScheme.onPrimaryContainer.withOpacity(0.9),
            fontWeight: FontWeight.w600,
          ),
        ).animate(delay: 200.ms).fadeIn(duration: 800.ms).slideX(begin: -0.3),
        const SizedBox(height: 24),
        Text(
          'Sencillo y poderoso. Tenemos todas las herramientas que necesitas para controlar tu negocio desde el móvil, tablet o computadora.',
          textAlign: isMobile ? TextAlign.center : TextAlign.left,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: colorScheme.onPrimaryContainer.withOpacity(0.8),
            height: 1.6,
          ),
        ).animate(delay: 400.ms).fadeIn(duration: 800.ms).slideX(begin: -0.3),
        const SizedBox(height: 32),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          alignment: isMobile ? WrapAlignment.center : WrapAlignment.start,
          children: [
            AppButton(
              onPressed: () => _downloadAndroidApp(context),
              text: 'Descargar de Play Store',
              icon:  const Icon(Icons.shop_two_rounded, size: 20),
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            ).animate(delay: 600.ms).fadeIn(duration: 800.ms).scale(),
            Consumer<AuthProvider>(
              builder: (context, authProvider, _) {
                return AppOutlinedButton(
                  onPressed: () => _navigateToLogin(context, authProvider),
                  text: 'Iniciar Sesión',
                  icon: const Icon(Icons.login, size: 20),
                  foregroundColor: colorScheme.onPrimaryContainer,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                ).animate(delay: 800.ms).fadeIn(duration: 800.ms).scale();
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHeroImage(ColorScheme colorScheme, {required double height}) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.3),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Image.asset(
          'assets/sell06.jpeg',
          height: height,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            height: height,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.image_not_supported_outlined,
              color: colorScheme.onSurface.withOpacity(0.5), 
              size: 50
            ),
          ),
        ).animate().fadeIn(duration: 1000.ms).slideX(begin: 0.3),
      ),
    );
  }

  void _downloadAndroidApp(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.android, color: Colors.green),
            SizedBox(width: 8),
            Text('Descargar para Android'),
          ],
        ),
        content: const Text(
            'La aplicación para Android estará disponible próximamente en Google Play Store.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesSection(BuildContext context, {required Axis axis}) {
    final features = [
      _FeatureData(
        icon: Icons.inventory_2_outlined,
        title: 'Gestión de Inventario',
        description: 'Controla tu catálogo de productos con facilidad y precisión.',
        image: 'assets/catalogue02.png',
      ),
      _FeatureData(
        icon: Icons.point_of_sale_outlined,
        title: 'Ventas Rápidas',
        description: 'Procesa ventas de forma eficiente y segura en cualquier dispositivo.',
        image: 'assets/sell02.jpeg',
      ),
      _FeatureData(
        icon: Icons.analytics_outlined,
        title: 'Reportes y Analytics',
        description: 'Obtén insights detallados de tu negocio en tiempo real.',
        image: 'assets/sell05.jpeg',
      ),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Text(
            'Características Principales',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ).animate().fadeIn(duration: 600.ms),
          const SizedBox(height: 48),
          if (axis == Axis.horizontal) 
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: features
                  .asMap()
                  .entries
                  .map((entry) => Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: _FeatureCard(
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
                        padding: const EdgeInsets.only(bottom: 24),
                        child: _FeatureCard(
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
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.surfaceContainerHighest,
            colorScheme.surfaceContainer,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            '¿Listo para empezar?',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(duration: 600.ms),
          const SizedBox(height: 16),
          Text(
            'Inicia sesión ahora y comienza a gestionar tu negocio de manera profesional.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ).animate(delay: 200.ms).fadeIn(duration: 600.ms),
          const SizedBox(height: 32),
          Consumer<AuthProvider>(
            builder: (context, authProvider, _) {
              return AppButton(
                onPressed: () => _navigateToLogin(context, authProvider),
                text: 'Iniciar Sesión',
                icon: const Icon(Icons.arrow_forward),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ).animate(delay: 400.ms).fadeIn(duration: 600.ms).scale();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFooterSection(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      color: theme.colorScheme.surfaceContainerLow,
      child: Column(
        children: [
          Text(
            '© 2025 Sell Web. Todos los derechos reservados.',
            style: theme.textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Sistema de punto de venta moderno para tu negocio.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
            textAlign: TextAlign.center,
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
}

class _FeatureData {
  final IconData icon;
  final String title;
  final String description;
  final String image;

  _FeatureData({
    required this.icon,
    required this.title,
    required this.description,
    required this.image,
  });
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
          shadowColor: colorScheme.shadow.withOpacity(0.3),
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
                    color: colorScheme.primaryContainer.withOpacity(0.3),
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
                    color: colorScheme.onSurface.withOpacity(0.7),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate(delay: widget.delay).fadeIn(duration: 600.ms).slideY(begin: 0.3);
  }
}
