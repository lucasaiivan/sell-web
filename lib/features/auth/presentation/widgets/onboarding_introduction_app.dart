import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sellweb/core/core.dart';

class OnboardingIntroductionApp extends StatefulWidget {
  const OnboardingIntroductionApp({
    this.colorAccent = Colors.deepPurple,
    this.colorText = Colors.white,
    super.key,
  });

  final Color colorAccent;
  final Color colorText;

  @override
  State<OnboardingIntroductionApp> createState() =>
      _OnboardingIntroductionAppState();
}

class _OnboardingIntroductionAppState extends State<OnboardingIntroductionApp> {
  // Datos de las páginas
  final List<_OnboardingPageModel> _pages = [
    _OnboardingPageModel(
      imagePath: "assets/sell02.jpeg",
      title: "VENTAS",
      subtitle: "Registra tus ventas de una forma simple 😊",
      icon: Icons.monetization_on,
      colorIcon: Colors.orange.shade300,
    ),
    _OnboardingPageModel(
      imagePath: "assets/sell05.jpeg",
      title: "TRANSACCIONES",
      subtitle: "Observa las transacciones que has realizado 💰",
      icon: Icons.analytics_outlined,
      colorIcon: Colors.teal.shade300,
    ),
    _OnboardingPageModel(
      imagePath: "assets/catalogue02.png",
      title: "CATÁLOGO",
      subtitle:
          "Arma tu catálogo y controla el stock de tus productos \n 🍫🍬🥫🍾",
      icon: Icons.category,
      colorIcon: Colors.deepPurple.shade300,
    ),
  ];

  // Estado
  late List<double> _progressValues;
  int _currentIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _progressValues = List.filled(_pages.length, 0.0);
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!mounted) return;
      setState(() {
        _updateProgress();
      });
    });
  }

  void _updateProgress() {
    // Si ya completamos todas, reiniciamos
    if (_currentIndex >= _pages.length) {
      _resetAll();
      return;
    }

    // Incrementamos el progreso actual
    double currentProgress = _progressValues[_currentIndex];

    // Lógica de velocidad variable: más rápido en el medio (0.1-0.8) para efecto visual
    double increment =
        (currentProgress >= 0.1 && currentProgress <= 0.8) ? 0.02 : 0.01;
    _progressValues[_currentIndex] += increment;

    if (_progressValues[_currentIndex] >= 1.0) {
      _progressValues[_currentIndex] = 1.0;
      _currentIndex++;
      if (_currentIndex >= _pages.length) {
        _resetAll();
      }
    }
  }

  void _resetAll() {
    for (int i = 0; i < _progressValues.length; i++) {
      _progressValues[i] = 0.0;
    }
    _currentIndex = 0;
  }

  void _onLeftTap() {
    setState(() {
      if (_currentIndex > 0) {
        // Si estamos al inicio de la actual (< 20%), volvemos a la anterior
        if (_progressValues[_currentIndex] < 0.2) {
          _progressValues[_currentIndex] = 0.0;
          _currentIndex--;
          _progressValues[_currentIndex] =
              0.0; // Reiniciar la anterior para verla desde el inicio
        } else {
          // Si ya avanzó algo, solo reiniciamos la actual
          _progressValues[_currentIndex] = 0.0;
        }
      } else {
        // Estamos en la primera, reiniciamos
        _progressValues[0] = 0.0;
      }
    });
  }

  void _onRightTap() {
    setState(() {
      if (_currentIndex < _pages.length - 1) {
        // Completamos la actual y pasamos a la siguiente
        _progressValues[_currentIndex] = 1.0;
        _currentIndex++;
      } else {
        // Estamos en la última, reiniciamos todo (loop)
        _resetAll();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Aseguramos que el índice sea válido para la vista
    final int viewIndex = _currentIndex >= _pages.length ? 0 : _currentIndex;
    final _OnboardingPageModel currentPage = _pages[viewIndex];

    return Stack(
      children: [
        // Fondo con Imagen
        Positioned.fill(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10.0),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Imagen de fondo
                Image.asset(
                  currentPage.imagePath,
                  fit: BoxFit.cover,
                  key: ValueKey(currentPage.imagePath),
                ),
              ],
            ),
          ),
        ),

        // Contenido
        Column(
          children: [
            // Indicadores de Progreso
            SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  children: List.generate(_pages.length, (index) {
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10.0),
                          child: LinearProgressIndicator(
                            minHeight: 4,
                            value: _progressValues[index],
                            backgroundColor:
                                Colors.white.withValues(alpha: 0.3),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                Colors.white),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),

            // Vista de la página (Texto e Icono)
            Expanded(
              child: _OnboardingPageView(
                page: currentPage,
                textColor: widget.colorText,
              ),
            ),
          ],
        ),

        // Detectores de Gestos (Invisibles)
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: _onLeftTap,
                behavior: HitTestBehavior.translucent,
                child: Container(),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: _onRightTap,
                behavior: HitTestBehavior.translucent,
                child: Container(),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Modelo de datos para cada página del onboarding
class _OnboardingPageModel {
  final String imagePath;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color colorIcon;

  _OnboardingPageModel({
    required this.imagePath,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.colorIcon,
  });
}

/// Widget para mostrar el contenido de una página
class _OnboardingPageView extends StatelessWidget {
  final _OnboardingPageModel page;
  final Color textColor;

  const _OnboardingPageView({
    required this.page,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    // Estilos de texto con sombra para mejor legibilidad sobre imágenes
    final shadow = Shadow(
      offset: const Offset(0, 2),
      blurRadius: 6.0,
      color: Colors.black.withValues(alpha: 0.8),
    );

    final titleStyle = TextStyle(
      fontSize: getResponsiveValue(
        context,
        mobile: 40.0,
        tablet: 50.0,
        desktop: 60.0,
      ),
      fontWeight: FontWeight.bold,
      color: textColor,
      shadows: [shadow],
    );

    final subtitleStyle = TextStyle(
      fontSize: getResponsiveValue(
        context,
        mobile: 24.0,
        tablet: 30.0,
        desktop: 40.0,
      ),
      fontWeight: FontWeight.w500,
      color: textColor.withValues(alpha: 0.95),
      shadows: [shadow],
      height: 1.2,
    );

    return Padding(
      padding: getResponsivePadding(
        context,
        mobile: const EdgeInsets.all(20.0),
        tablet: const EdgeInsets.all(30.0),
        desktop: const EdgeInsets.all(40.0),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),

          // Icono animado con fondo
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withValues(alpha: 0.3),
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2), width: 1),
            ),
            child: Icon(
              page.icon,
              size: screenSize.height * 0.06,
              color: page.colorIcon,
            ),
          )
              .animate(key: ValueKey(page.title))
              .fadeIn(duration: 500.ms)
              .scale(duration: 500.ms, curve: Curves.easeOutBack),

          const SizedBox(height: 24),

          // Título animado
          Text(
            page.title,
            style: titleStyle,
            textAlign: TextAlign.center,
          )
              .animate(key: ValueKey("${page.title}_t"))
              .fadeIn(duration: 600.ms)
              .slideY(
                  begin: 0.2, end: 0, duration: 600.ms, curve: Curves.easeOut),

          const SizedBox(height: 16),

          // Subtítulo animado
          Text(
            page.subtitle,
            style: subtitleStyle,
            textAlign: TextAlign.center,
          )
              .animate(key: ValueKey("${page.title}_s"))
              .fadeIn(delay: 200.ms, duration: 600.ms)
              .slideY(
                  begin: 0.2, end: 0, duration: 600.ms, curve: Curves.easeOut),

          const Spacer(),
          const SizedBox(height: 40), // Espacio inferior visual
        ],
      ),
    );
  }
}
