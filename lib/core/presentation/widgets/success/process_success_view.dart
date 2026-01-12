import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:audioplayers/audioplayers.dart';

/// Widget reutilizable para mostrar confirmación visual de procesos
///
/// **Características:**
/// - Pantalla completa con animación de check
/// - Textos personalizables para loading y éxito
/// - Sonido de éxito (opcional)
/// - Duraciones configurables
/// - Callback al completar
///
/// **Casos de uso:**
/// - Creación de cuentas de negocio
/// - Eliminación de cuentas de negocio
/// - Eliminación de cuentas de usuario
/// - Cualquier proceso que requiera feedback visual
///
/// **Ejemplo de uso:**
/// ```dart
/// Navigator.of(context).push(
///   MaterialPageRoute(
///     builder: (context) => ProcessSuccessView(
///       loadingText: 'Eliminando cuenta...',
///       successTitle: '¡Cuenta eliminada!',
///       successSubtitle: 'Nombre de la cuenta',
///       onComplete: () => Navigator.of(context).pop(),
///     ),
///   ),
/// );
/// ```
class ProcessSuccessView extends StatefulWidget {
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
  
  /// Callback ejecutado al completar la animación (después de los pops automáticos)
  final VoidCallback? onComplete;

  /// Acción asíncrona a ejecutar. Si se proporciona, el tiempo de carga dependerá de esta acción
  final Future<dynamic> Function()? action;

  /// Callback para manejar errores si la acción falla
  final Function(Object error)? onError;
  
  /// Número de navegaciones pop a ejecutar automáticamente al completar.
  /// 
  /// Si es > 0, el widget ejecutará `Navigator.pop()` esa cantidad de veces
  /// usando su propio contexto válido. El último pop puede incluir [popResult].
  /// 
  /// Esto evita problemas cuando el callback [onComplete] captura un contexto
  /// de un widget padre que ya fue dispuesto.
  final int popCount;
  
  /// Resultado a pasar en el último Navigator.pop() si [popCount] > 0
  final dynamic popResult;

  const ProcessSuccessView({
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
    this.action,
    this.onError,
    this.popCount = 0,
    this.popResult,
  });

  @override
  State<ProcessSuccessView> createState() => _ProcessSuccessViewState();
}

class _ProcessSuccessViewState extends State<ProcessSuccessView>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _showSuccess = false;
  
  /// Resultado devuelto por el action (si aplica)
  dynamic _actionResult;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Demorar la ejecución hasta después del frame actual
    // para evitar conflictos con notifyListeners durante el build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _startProcess();
      }
    });
  }

  Future<void> _startProcess() async {
    // Si hay una acción definida, ejecutarla
    if (widget.action != null) {
      try {
        // Capturar el resultado del action para usarlo en la navegación
        _actionResult = await widget.action!();
        if (mounted) {
          _triggerSuccess();
        }
      } catch (e) {
        if (mounted) {
          if (widget.onError != null) {
            widget.onError!(e);
          } else {
            // Comportamiento por defecto ante error: cerrar la vista
            Navigator.of(context).pop();
          }
        }
      }
    } else {
      // Modo temporizado (legacy)
      Future.delayed(Duration(milliseconds: widget.loadingDuration), () {
        if (mounted) {
          _triggerSuccess();
        }
      });
    }
  }

  void _triggerSuccess() {
    setState(() => _showSuccess = true);

    if (widget.playSound) {
      _playSuccessSound();
    }

    _controller.forward();

    // Esperar duración de éxito antes de completar
    Future.delayed(Duration(milliseconds: widget.successDuration), () {
      if (mounted) {
        _handleCompletion();
      }
    });
  }
  
  /// Maneja la finalización ejecutando pops automáticos y el callback
  void _handleCompletion() {
    // Ejecutar pops automáticos con el contexto válido de este widget
    if (widget.popCount > 0) {
      // Determinar el resultado a usar: explícito > resultado del action
      final resultToPass = widget.popResult ?? _actionResult;
      
      for (int i = 0; i < widget.popCount; i++) {
        if (!mounted) break;
        
        // En el último pop, pasar el resultado si existe
        if (i == widget.popCount - 1 && resultToPass != null) {
          Navigator.of(context).pop(resultToPass);
        } else {
          Navigator.of(context).pop();
        }
      }
    }
    
    // Llamar callback adicional si existe
    widget.onComplete?.call();
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
