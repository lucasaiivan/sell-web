import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/connectivity_provider.dart';

/// Widget que muestra un indicador visual del estado de conectividad
///
/// Muestra un chip pequeño con un icono y texto que indica si la app
/// está en modo online u offline. Solo se muestra cuando está offline
/// para no molestar al usuario en operación normal.
class ConnectivityIndicator extends StatelessWidget {
  const ConnectivityIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    final connectivityProvider = context.watch<ConnectivityProvider>();
    final theme = Theme.of(context);

    // Solo mostrar cuando está offline
    if (connectivityProvider.isOnline) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.orange.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.orange.shade300,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.cloud_off_rounded,
            size: 14,
            color: Colors.orange.shade800,
          ),
          const SizedBox(width: 4),
          Text(
            'Sin conexión',
            style: theme.textTheme.labelSmall?.copyWith(
              color: Colors.orange.shade900,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
