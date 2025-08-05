
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
    final double width = MediaQuery.of(context).size.width;
    final colorScheme = Theme.of(context).colorScheme;

    return Title(
      title: 'Bienvenido - Sell Web',
      color: colorScheme.primary,
      child: Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset('assets/launcher.png', height: 32),
            const SizedBox(width: 8),
            Text(
              'Sell',
              overflow: TextOverflow.ellipsis,
              style: TextStyle( 
                color: _isScrolled ? colorScheme.onSurface : Colors.white,
              ),
            ),
          ],
        ),
        backgroundColor: _isScrolled ? colorScheme.surface.withValues(alpha: 0.95): Colors.transparent,
        elevation: _isScrolled ? 1 : 0, 
        scrolledUnderElevation: 2,
        surfaceTintColor: colorScheme.surfaceTint, 
        actions: [
          // Botón de login
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(
                opacity: animation,
                child: ScaleTransition(
                  scale: animation,
                  child: child,
                ),
              );
            },
            child: _isScrolled
                ? AppOutlinedButton(
                    key: const ValueKey('login_button'),
                    onPressed: () => _navigateToLogin(
                        context, Provider.of<AuthProvider>(context, listen: false)),
                    text: 'Iniciar Sesión',
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  )
                : const SizedBox(key: ValueKey('placeholder')),
          ),

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
          const SizedBox(width: 16),
        ],
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
        const SizedBox(height: 48),
        _buildProblemSolutionSection(context),
        const SizedBox(height: 48),
        _buildFeaturesSection(context, axis: Axis.vertical),
        const SizedBox(height: 48),
        _buildTestimonialsSection(context),
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
        _buildProblemSolutionSection(context),
        const SizedBox(height: 64),
        _buildFeaturesSection(context, axis: Axis.horizontal),
        const SizedBox(height: 64),
        _buildTestimonialsSection(context),
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
        const SizedBox(height: 80),
        _buildProblemSolutionSection(context),
        const SizedBox(height: 80),
        _buildFeaturesSection(context, axis: Axis.horizontal),
        const SizedBox(height: 80),
        _buildTestimonialsSection(context),
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

    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 64 + MediaQuery.of(context).padding.top,
        bottom: 64,
      ),
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 1.5,
          colors: Theme.of(context).brightness == Brightness.light
              ? [
                  colorScheme.surface,
                  Colors.amberAccent.shade100,
                ]
              : [
                  colorScheme.surface,
                  colorScheme.primaryContainer,
                ],
        ),
      ),
      child: _buildHeroMobileLayout(context, theme, colorScheme),
    );
  }

  Widget _buildHeroMobileLayout(
      BuildContext context, ThemeData theme, ColorScheme colorScheme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildHeroContent(context, theme, colorScheme, isMobile: true),
        const SizedBox(height: 32),
        _buildHeroImage(colorScheme, height: 400),
      ],
    );
  }
 

  Widget _buildHeroContent(BuildContext context, ThemeData theme, ColorScheme colorScheme, {bool isMobile = false}) {
    return Column(
      crossAxisAlignment: isMobile ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Sistema de Ventas e Inventario Simple',
          textAlign: isMobile ? TextAlign.center : TextAlign.left,
          style: theme.textTheme.displayLarge,
        ).animate().fadeIn(duration: 800.ms).slideX(begin: -0.3),
        const SizedBox(height: 16),
        Text(
          'El punto de venta más fácil de usar',
          textAlign: isMobile ? TextAlign.center : TextAlign.left,
          style: theme.textTheme.headlineSmall?.copyWith(
        color: colorScheme.onPrimaryContainer.withOpacity(0.9),
        fontWeight: FontWeight.w600,
          ),
        ).animate(delay: 200.ms).fadeIn(duration: 800.ms).slideX(begin: -0.3),
        const SizedBox(height: 8),
        Text(
          'Tu negocio necesita un cambio. Controla inventario, procesa ventas y genera reportes desde cualquier dispositivo.',
          textAlign: isMobile ? TextAlign.center : TextAlign.left,
          style: theme.textTheme.bodyLarge?.copyWith(
        color: colorScheme.onPrimaryContainer.withOpacity(0.8),
        height: 1.6,
          ),
        ).animate(delay: 400.ms).fadeIn(duration: 800.ms).slideX(begin: -0.3),
        const SizedBox(height: 24),
        // Beneficios rápidos
        Row(
          mainAxisAlignment: isMobile ? MainAxisAlignment.center : MainAxisAlignment.start,
          children: [
        _buildBenefitChip(context, '✓ Cualquier negocio', colorScheme),
        const SizedBox(width: 8),
        _buildBenefitChip(context, '✓ Celular o computadora', colorScheme),
        if (!isMobile) const SizedBox(width: 8),
        if (!isMobile) _buildBenefitChip(context, '✓ Acompañamiento', colorScheme),
          ],
        ).animate(delay: 500.ms).fadeIn(duration: 800.ms),
        const SizedBox(height: 32),
        Wrap(
          alignment: isMobile ? WrapAlignment.center : WrapAlignment.start,
          spacing: 16,
          runSpacing: 16,
          children: [
            
            AppFilledButton(
              onPressed: () => _showDemoDialog(context),
              text: 'Descargar de Play Store',
              icon: const Icon(Icons.shop, size: 20),
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              borderRadius: 24,
            ).animate(delay: 800.ms).fadeIn(duration: 800.ms).scale(),
            AppFilledButton(
              onPressed: () => _navigateToLogin( context, Provider.of<AuthProvider>(context, listen: false)),
              text: 'Comenzar ahora',
              icon: const Icon(Icons.rocket_launch, size: 20),
              backgroundColor: Colors.white,
              foregroundColor: Colors.black87,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              borderRadius: 24,
            ).animate(delay: 600.ms).fadeIn(duration: 800.ms).scale(),
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

  void _showDemoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.play_circle_outline, color: Colors.blue),
            SizedBox(width: 8),
            Text('Demo Interactiva'),
          ],
        ),
        content: const Text(
            'Próximamente tendremos una demo interactiva disponible. Por ahora, puedes crear una cuenta gratuita para explorar todas las funcionalidades.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _navigateToLogin(context, Provider.of<AuthProvider>(context, listen: false));
            },
            child: const Text('Crear Cuenta'),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitChip(BuildContext context, String text, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration( 
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.onPrimaryContainer.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: colorScheme.onPrimaryContainer.withValues(alpha: 0.9),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildProblemSolutionSection(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 64),
      color: colorScheme.surfaceContainerLowest,
      child: Column(
        children: [
          Text(
            '¿Tus semanas se ven así?',
            style: theme.textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(duration: 600.ms),
          const SizedBox(height: 48),
          Wrap(
            spacing: 24,
            runSpacing: 24,
            alignment: WrapAlignment.center,
            children: [
              _buildProblemCard(context, '5 hrs', 'controlando inventario manual', colorScheme),
              _buildProblemCard(context, '+4 hrs', 'registrando ventas en papel', colorScheme),
              _buildProblemCard(context, '+3 hrs', 'anotando gastos en Excel', colorScheme),
              _buildProblemCard(context, '+4 hrs', 'elaborando informes manuales', colorScheme),
              _buildProblemCard(context, '+\$\$\$', 'tomando pedidos erróneos', colorScheme),
              _buildProblemCard(context, '+ ∞ hrs', 'pensando como mejorar...', colorScheme),
            ],
          ).animate(delay: 200.ms).fadeIn(duration: 800.ms),
          const SizedBox(height: 48),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text(
                  '20+ horas',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onErrorContainer,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'con dolor de cabeza 💥',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onErrorContainer,
                  ),
                ),
              ],
            ),
          ).animate(delay: 400.ms).fadeIn(duration: 800.ms).scale(),
          const SizedBox(height: 32),
          Icon(
            Icons.arrow_downward,
            size: 48,
            color: colorScheme.primary,
          ).animate(delay: 600.ms).fadeIn(duration: 800.ms),
          const SizedBox(height: 32),
          Text(
            'Hay una forma más sencilla',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
            textAlign: TextAlign.center,
          ).animate(delay: 800.ms).fadeIn(duration: 800.ms), 
        ],
      ),
    );
  }

  Widget _buildProblemCard(BuildContext context, String time, String problem, ColorScheme colorScheme) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(
            time,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            problem,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTestimonialsSection(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 64),
      child: Column(
        children: [
          Text(
            'Clientes satisfechos alrededor del mundo',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(duration: 600.ms),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) => 
              Icon(Icons.star, color: Colors.amber, size: 32)
            ),
          ).animate(delay: 200.ms).fadeIn(duration: 600.ms),
          const SizedBox(height: 48),
          Wrap(
            spacing: 24,
            runSpacing: 24,
            alignment: WrapAlignment.center,
            children: [
              _buildTestimonialCard(
                context,
                '"En 5 min empecé"',
                'App Store',
                colorScheme,
              ),
              _buildTestimonialCard(
                context,
                '"Lo recomiendo al 100%"',
                'Google Play',
                colorScheme,
              ),
              _buildTestimonialCard(
                context,
                '"Soporte Increíble"',
                'Cliente Verificado',
                colorScheme,
              ),
            ],
          ).animate(delay: 400.ms).fadeIn(duration: 800.ms),
        ],
      ),
    );
  }

  Widget _buildTestimonialCard(BuildContext context, String quote, String source, ColorScheme colorScheme) {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) => 
              Icon(Icons.star, color: Colors.amber, size: 20)
            ),
          ),
          const SizedBox(height: 16),
          Text(
            quote,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontStyle: FontStyle.italic,
              color: colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            source,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesSection(BuildContext context, {required Axis axis}) {
    final features = [
      _FeatureData(
        icon: Icons.inventory_2_outlined,
        title: 'Inventario Controlado',
        description: 'Verifica existencias, alertas de stock mínimo y olvida el Excel para siempre.',
        image: 'assets/catalogue02.png',
        benefit: 'Reduce 68% robo hormiga',
      ),
      _FeatureData(
        icon: Icons.point_of_sale_outlined,
        title: 'Punto de Venta Fácil',
        description: 'Toma control de tu negocio con tickets impresos, ventas a crédito y descuentos.',
        image: 'assets/sell02.jpeg',
        benefit: 'Reduce 78% errores',
      ),
      _FeatureData(
        icon: Icons.analytics_outlined,
        title: 'Reportes Instantáneos',
        description: 'Accede desde cualquier lugar a tus análisis y reportes guardados en la nube.',
        image: 'assets/sell05.jpeg',
        benefit: 'Reduce 83% tiempo',
      ),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Text(
            'Potencia tu negocio y aumenta tus ingresos',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
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
      padding: const EdgeInsets.all(64),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primary.withOpacity(0.1),
            colorScheme.secondary.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colorScheme.primary.withOpacity(0.2),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Text(
            'Deja el papel y las tareas repetitivas',
            style: theme.textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(duration: 600.ms),
          const SizedBox(height: 16),
          Text(
            'Únete a miles de negocios satisfechos que ya transformaron su forma de trabajar.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.8),
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ).animate(delay: 200.ms).fadeIn(duration: 600.ms),
          const SizedBox(height: 40),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.center,
            children: [
              AppButton(
                onPressed: () => _navigateToLogin(context, Provider.of<AuthProvider>(context, listen: false)),
                text: 'Empezar Gratis Ahora',
                icon: const Icon(Icons.rocket_launch, size: 20),
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              ).animate(delay: 400.ms).fadeIn(duration: 600.ms).scale(),
              AppOutlinedButton(
                onPressed: () => _showDemoDialog(context),
                text: 'Ver Demo',
                icon: const Icon(Icons.play_circle_outline, size: 20),
                foregroundColor: colorScheme.primary,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              ).animate(delay: 600.ms).fadeIn(duration: 600.ms).scale(),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Sin tarjeta de crédito • Configuración en 5 minutos',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.6),
            ),
            textAlign: TextAlign.center,
          ).animate(delay: 800.ms).fadeIn(duration: 600.ms),
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
  final String? benefit;

  _FeatureData({
    required this.icon,
    required this.title,
    required this.description,
    required this.image,
    this.benefit,
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
                if (widget.feature.benefit != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.1),
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
