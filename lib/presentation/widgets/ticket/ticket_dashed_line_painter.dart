import 'package:flutter/material.dart';

/// Dibuja una línea punteada horizontal para simular el corte de un ticket impreso
class TicketDashedLinePainter extends CustomPainter {
  final Color color;

  TicketDashedLinePainter({this.color = Colors.black38});

  @override
  void paint(Canvas canvas, Size size) {
    const dashWidth = 5.0;
    const dashSpace = 4.0;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    double startX = 0;
    while (startX < size.width) {
      canvas.drawLine(Offset(startX, 0), Offset(startX + dashWidth, 0), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
