import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sellweb/core/presentation/providers/connectivity_provider.dart';

/// Banner de conectividad que muestra el estado offline/online
///
/// **Características:**
/// - Se integra con [ConnectivityProvider]
/// - Aparece automáticamente cuando se pierde conexión
/// - Se oculta automáticamente al recuperar conexión
/// - Deslizable para ocultar temporalmente
/// - Diseño Material 3
///
/// **Uso:**
/// ```dart
/// // En el árbol de widgets principal (ya incluido en MaterialApp)
/// ConnectivityBanner()
/// ```
class ConnectivityBanner extends StatefulWidget {
  const ConnectivityBanner({super.key});

  @override
  State<ConnectivityBanner> createState() => _ConnectivityBannerState();
}

class _ConnectivityBannerState extends State<ConnectivityBanner>
    with SingleTickerProviderStateMixin {
  bool _isDismissed = false;
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectivityProvider>(
      builder: (context, connectivity, _) {
        final isOffline = connectivity.isOffline;

        // Reset dismissed state cuando vuelve online
        if (!isOffline && _isDismissed) {
          _isDismissed = false;
        }

        // Mostrar/ocultar banner con animación
        if (isOffline && !_isDismissed) {
          _controller.forward();
        } else {
          _controller.reverse();
        }

        return SizeTransition(
          sizeFactor: _animation,
          child: _buildBannerContent(context),
        );
      },
    );
  }

  Widget _buildBannerContent(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: colorScheme.errorContainer,
      elevation: 4,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Icono de offline
              Icon(
                Icons.cloud_off_rounded,
                color: colorScheme.onErrorContainer,
                size: 20,
              ),
              const SizedBox(width: 12),

              // Texto informativo
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sin conexión a internet',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: colorScheme.onErrorContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Trabajando en modo offline con datos guardados',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color:
                            colorScheme.onErrorContainer.withValues(alpha: 0.8),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),

              // Botón cerrar
              IconButton(
                icon: Icon(
                  Icons.close_rounded,
                  size: 20,
                  color: colorScheme.onErrorContainer,
                ),
                onPressed: () {
                  setState(() {
                    _isDismissed = true;
                  });
                },
                tooltip: 'Cerrar',
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
