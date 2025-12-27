import 'package:flutter/material.dart';

class ComboTag extends StatelessWidget {
  final bool isCompact;
  const ComboTag({super.key, this.isCompact = false});

  @override
  Widget build(BuildContext context) {
    // Purple color for "llamativo" but somewhat minimalist
    const color = Colors.deepPurple;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 4 : 6,
        vertical: isCompact ? 1 : 2,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 2,
            offset: Offset(0, 1),
          )
        ],
      ),
      child: Text(
        'COMBO',
        style: TextStyle(
          color: Colors.white,
          fontSize: isCompact ? 8 : 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
