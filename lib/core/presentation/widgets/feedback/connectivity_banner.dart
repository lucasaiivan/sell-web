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
      elevation: 0,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              Icon(
                Icons.cloud_off_rounded,
                color: colorScheme.onErrorContainer,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Sin conexión - Trabajando en modo offline',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colorScheme.onErrorContainer,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: colorScheme.onErrorContainer,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () {
                  setState(() {
                    _isDismissed = true;
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
