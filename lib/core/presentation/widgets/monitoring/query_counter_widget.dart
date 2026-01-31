import 'package:flutter/material.dart';
import 'package:sellweb/core/di/injection_container.dart';
import 'package:sellweb/core/services/monitoring/query_counter_service.dart';

/// Widget que muestra un contador de consultas (tests UI)
class QueryCounterWidget extends StatefulWidget {
  const QueryCounterWidget({super.key});

  @override
  State<QueryCounterWidget> createState() => _QueryCounterWidgetState();
}

class _QueryCounterWidgetState extends State<QueryCounterWidget> {
  late final QueryCounterService _service;

  @override
  void initState() {
    super.initState();
    _service = getIt<QueryCounterService>();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;


    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.monitor_heart_outlined, 
                size: 14, 
                color: colorScheme.primary
              ),
              const SizedBox(width: 8),
              Text(
                'Monitor de Consultas',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Reads
              _CounterItem(
                label: 'Lecturas',
                valueListenable: _service.reads,
                color: Colors.blue.shade700,
                icon: Icons.download_rounded,
              ),
              const SizedBox(width: 16),
              // Writes
              _CounterItem(
                label: 'Escrituras',
                valueListenable: _service.writes,
                color: Colors.orange.shade700,
                icon: Icons.upload_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CounterItem extends StatelessWidget {
  final String label;
  final ValueNotifier<int> valueListenable;
  final Color color;
  final IconData icon;

  const _CounterItem({
    required this.label,
    required this.valueListenable,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ValueListenableBuilder<int>(
          valueListenable: valueListenable,
          builder: (context, value, _) {
            return Text(
              '$value',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                fontFamily: 'Monospace',
                color: color,
              ),
            );
          },
        ),
        const SizedBox(height: 2),
         Row(
          children: [
            Icon(icon, size: 10, color: Colors.grey),
            const SizedBox(width: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Colors.grey,
                fontSize: 9,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
