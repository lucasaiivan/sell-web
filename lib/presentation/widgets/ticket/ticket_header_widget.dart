import 'package:flutter/material.dart';

/// Widget del encabezado del ticket con información del negocio y fecha
class TicketHeaderWidget extends StatelessWidget {
  final String businessName;
  final TextStyle textDescriptionStyle;
  final TextStyle textSmallStyle;

  const TicketHeaderWidget({
    super.key,
    required this.businessName,
    required this.textDescriptionStyle,
    required this.textSmallStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          businessName.toUpperCase(),
          style: textDescriptionStyle.copyWith(
            fontSize: 22,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 1),
        Text('compra', style: textSmallStyle),
        const SizedBox(height: 1),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
          child: Row(
            children: [
              Text('fecha:', style: textSmallStyle),
              const Spacer(),
              Text(DateTime.now().toString().substring(0, 11)),
            ],
          ),
        ),
      ],
    );
  }
}
