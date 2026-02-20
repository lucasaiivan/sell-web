import 'package:flutter/material.dart';

/// Widget que muestra un tag de combo 
class ComboTag extends StatelessWidget {
  final bool isCompact;
  const ComboTag({super.key, this.isCompact = false});

  @override
  Widget build(BuildContext context) {
    // Elegant purple gradient
    final theme = Theme.of(context);
    final color = theme.colorScheme.secondary;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 6 : 8,
        vertical: isCompact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color,
            color.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        'COMBO',
        style: TextStyle(
          color: Colors.white,
          fontSize: isCompact ? 8 : 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
