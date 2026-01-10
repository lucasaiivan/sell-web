import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:audioplayers/audioplayers.dart';

/// Widget reutilizable para mostrar confirmación visual de procesos de creación
///
/// **Características:**
/// - Pantalla completa con animación de check
/// - Textos personalizables para loading y éxito
/// - Sonido de éxito (opcional)
/// - Duraciones configurables
/// - Callback al completar
///
/// **Ejemplo de uso:**
/// ```dart
/// Navigator.of(context).push(
///   MaterialPageRoute(
///     builder: (context) => CreationSuccessView(
///       loadingText: 'Creando producto...',
///       successTitle: '¡Producto creado!',
///       successSubtitle: 'Nombre del Producto',
///       onComplete: () => Navigator.of(context).pop(),
///     ),
///   ),
/// );
/// ```
class CreationSuccessView extends StatefulWidget {
  /// Texto mostrado durante el estado de carga
  final String loadingText;
  
  /// Título mostrado en el estado de éxito
  final String successTitle;
  
  /// Subtítulo opcional mostrado en el estado de éxito (ej: nombre del elemento creado)
  final String? successSubtitle;
  
  /// Texto final mostrado debajo del subtítulo
  final String? finalText;
  
  /// Duración del estado de carga en milisegundos
  final int loadingDuration;
  
  /// Duración del estado de éxito antes de ejecutar onComplete (en milisegundos)
  final int successDuration;
  
  /// Si debe reproducir sonido de éxito
  final bool playSound;
  
  /// Ruta del archivo de sonido (por defecto usa el de ventas)
  final String soundAssetPath;
  
  /// Callback ejecutado al completar la animación
  final VoidCallback? onComplete;

  const CreationSuccessView({
    super.key,
    this.loadingText = 'Procesando...',
    this.successTitle = '¡Completado!',
    this.successSubtitle,
    this.finalText = 'Redirigiendo...',
    this.loadingDuration = 1500,
    this.successDuration = 2000,
    this.playSound = true,
    this.soundAssetPath = 'sounds/sale_success.mp3',
    this.onComplete,
  });

  @override
  State<CreationSuccessView> createState() => _CreationSuccessViewState();
}

class _CreationSuccessViewState extends State<CreationSuccessView>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _showSuccess = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Mostrar estado de carga por la duración especificada
    Future.delayed(Duration(milliseconds: widget.loadingDuration), () {
      if (mounted) {
        setState(() => _showSuccess = true);
        
        if (widget.playSound) {
          _playSuccessSound();
        }
        
        _controller.forward();

        // Esperar duración de éxito antes de completar
        Future.delayed(Duration(milliseconds: widget.successDuration), () {
          if (mounted) {
            widget.onComplete?.call();
          }
        });
      }
    });
  }

  Future<void> _playSuccessSound() async {
    try {
      await _audioPlayer.setVolume(1.0);
      await _audioPlayer.play(
        AssetSource(widget.soundAssetPath),
        volume: 1.0,
        mode: PlayerMode.lowLatency,
      );
    } catch (e) {
      debugPrint('Error reproduciendo sonido: $e');
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final backgroundColor = isDark ? colorScheme.surface : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF2D3E4F);
    final secondaryTextColor = isDark ? Colors.white70 : Colors.grey.shade600;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (!_showSuccess) ...[
                // Estado: Cargando
                SizedBox(
                  width: 80,
                  height: 80,
                  child: CircularProgressIndicator(
                    strokeWidth: 4,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  widget.loadingText,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ] else ...[
                // Estado: Éxito
                ScaleTransition(
                  scale: CurvedAnimation(
                    parent: _controller,
                    curve: Curves.elasticOut,
                  ),
                  child: Column(
                    children: [
                      // Animación de check
                      SizedBox(
                        width: 180,
                        height: 180,
                        child: Lottie.asset(
                          'assets/anim/success_check.json',
                          fit: BoxFit.contain,
                          repeat: true,
                          animate: true,
                          frameRate: FrameRate.max,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Título de éxito
                      Text(
                        widget.successTitle,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      // Subtítulo (si existe)
                      if (widget.successSubtitle != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: colorScheme.primary.withValues(alpha: 0.2),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            widget.successSubtitle!,
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],

                      // Texto final (si existe)
                      if (widget.finalText != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          widget.finalText!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: secondaryTextColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
