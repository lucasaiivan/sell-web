import 'package:flutter/material.dart';
import 'package:sellweb/core/utils/fuctions.dart';
import 'package:sellweb/domain/entities/catalogue.dart' hide Provider;

/// Widget personalizado que muestra la lista de productos en el ticket 
/// con un indicador de "items ocultos" si es necesario
class TicketProductListWidget extends StatefulWidget {
  final dynamic ticket;
  final TextStyle textValuesStyle;

  const TicketProductListWidget({
    super.key,
    required this.ticket,
    required this.textValuesStyle,
  });

  @override
  State<TicketProductListWidget> createState() => _TicketProductListWidgetState();
}

class _TicketProductListWidgetState extends State<TicketProductListWidget> {
  final ScrollController _scrollController = ScrollController();
  bool _showIndicator = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_updateIndicator);
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateIndicator());
  }

  void _updateIndicator() {
    if (!_scrollController.hasClients) return;
    final max = _scrollController.position.maxScrollExtent;
    final offset = _scrollController.offset;
    final show = max > 0 && offset < max - 8;
    if (_showIndicator != show) {
      setState(() => _showIndicator = show);
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_updateIndicator);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> items = widget.ticket.listPoduct.map<Widget>((item) {
      final product = item is ProductCatalogue 
          ? item 
          : ProductCatalogue.fromMap(item);
      
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        child: Row(
          children: [
            Expanded(
              child: Text(
                '${product.quantity}',
                style: widget.textValuesStyle,
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                product.description,
                style: widget.textValuesStyle,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              child: Text(
                Publications.getFormatoPrecio(
                  value: product.salePrice * product.quantity,
                ),
                style: widget.textValuesStyle,
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
      );
    }).toList(growable: false);

    return Stack(
      children: [
        ListView(
          key: const Key('ticket'),
          controller: _scrollController,
          shrinkWrap: false,
          children: items,
        ),
        if (_showIndicator)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .surface
                      .withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  border: Border.all(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.18),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 22,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Hay más ítems',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
