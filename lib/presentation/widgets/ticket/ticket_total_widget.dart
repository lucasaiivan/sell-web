import 'package:flutter/material.dart';
import 'package:sellweb/core/utils/fuctions.dart';

/// Widget animado que muestra el total con un leve rebote al cambiar el valor
class TicketTotalWidget extends StatefulWidget {
  final double total;
  final Color color;

  const TicketTotalWidget({
    super.key,
    required this.total,
    required this.color,
  });

  @override
  State<TicketTotalWidget> createState() => _TicketTotalWidgetState();
}

class _TicketTotalWidgetState extends State<TicketTotalWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;
  double? _oldTotal;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 260),
      vsync: this,
    );
    _scale = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);
    _oldTotal = widget.total;
    // Inicia la animación al mostrar el widget por primera vez
    _controller.forward(from: 0);
  }

  @override
  void didUpdateWidget(covariant TicketTotalWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.total != _oldTotal) {
      _controller.forward(from: 0);
      _oldTotal = widget.total;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final TextStyle textTotalStyle = TextStyle(
      fontFamily: 'RobotoMono',
      fontWeight: FontWeight.bold,
      fontSize: 24,
      color: Theme.of(context).colorScheme.onPrimary,
    );

    return Padding(
      padding: const EdgeInsets.only(left: 12, right: 12, top: 5, bottom: 4),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          decoration: BoxDecoration(
            color: widget.color,
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Text('TOTAL', style: textTotalStyle),
              const Spacer(),
              Text(
                Publications.getFormatoPrecio(value: widget.total),
                style: textTotalStyle,
                textAlign: TextAlign.right,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
