import '../../../../core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:sellweb/presentation/widgets/dialogs/sales/discount_dialog.dart';
import 'package:sellweb/domain/entities/catalogue.dart' hide Provider;
import 'package:sellweb/presentation/providers/sell_provider.dart';

/// Widget principal que muestra el drawer/vista del ticket de venta
/// Consolidado para priorizar simplicidad y reducir fragmentación
class TicketDrawerWidget extends StatelessWidget {
  final bool showConfirmedPurchase;
  final VoidCallback? onEditCashAmount;
  final VoidCallback? onConfirmSale;
  final VoidCallback? onCloseTicket;

  const TicketDrawerWidget({
    super.key,
    required this.showConfirmedPurchase,
    this.onEditCashAmount,
    this.onConfirmSale,
    this.onCloseTicket,
  });

  @override
  Widget build(BuildContext context) {
    return showConfirmedPurchase
        ? _TicketConfirmedPurchase(
                width:
                    isMobile(context) ? MediaQuery.of(context).size.width : 400)
            .animate()
            .scale(
              duration: 600.ms,
              curve: Curves.elasticOut,
              begin: const Offset(0.8, 0.8),
              end: const Offset(1, 1),
            )
        : AnimatedContainer(
            width: isMobile(context) ? MediaQuery.of(context).size.width : 400,
            height: double.infinity,
            curve: Curves.fastOutSlowIn,
            duration: const Duration(milliseconds: 300),
            child: _TicketContent(
              onEditCashAmount: onEditCashAmount,
              onConfirmSale: onConfirmSale,
              onCloseTicket: onCloseTicket,
            ),
          );
  }
}

/// Widget que contiene todo el contenido principal del ticket
class _TicketContent extends StatelessWidget {
  final VoidCallback? onEditCashAmount;
  final VoidCallback? onConfirmSale;
  final VoidCallback? onCloseTicket;

  const _TicketContent({
    this.onEditCashAmount,
    this.onConfirmSale,
    this.onCloseTicket,
  });

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SellProvider>(context);
    final ticket = provider.ticket;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Estilos del ticket
    final borderColor = colorScheme.onSurface;
    final backgroundColor = colorScheme.primaryContainer.withValues(alpha: 0.3);

    final textValuesStyle = TextStyle(
      fontFamily: 'RobotoMono',
      fontWeight: FontWeight.bold,
      fontSize: 16,
      color: colorScheme.onSurface,
    );

    final textDescriptionStyle = TextStyle(
      fontFamily: 'RobotoMono',
      fontSize: 18,
      color: colorScheme.onSurface,
    );

    final textSmallStyle = TextStyle(
      fontFamily: 'RobotoMono',
      fontSize: 13,
      color: colorScheme.onSurface.withValues(alpha: 0.87),
    );

    final textTotalStyle = TextStyle(
      fontFamily: 'RobotoMono',
      fontWeight: FontWeight.bold,
      fontSize: 24,
      color: colorScheme.onPrimary,
    );

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      elevation: 0,
      color: backgroundColor,
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: borderColor.withValues(alpha: 0.2),
          width: 0.5,
        ),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: _buildScrollableContentWithGradient(
        context: context,
        ticket: ticket,
        textValuesStyle: textValuesStyle,
        textDescriptionStyle: textDescriptionStyle,
        textSmallStyle: textSmallStyle,
        textTotalStyle: textTotalStyle,
        colorScheme: colorScheme,
        backgroundColor: backgroundColor,
      ),
    );
  }

  /// Construye el contenido scrollable con efecto de gradiente difuminado
  Widget _buildScrollableContentWithGradient({
    required BuildContext context,
    required dynamic ticket,
    required TextStyle textValuesStyle,
    required TextStyle textDescriptionStyle,
    required TextStyle textSmallStyle,
    required TextStyle textTotalStyle,
    required ColorScheme colorScheme,
    required Color backgroundColor,
  }) {
    final provider = Provider.of<SellProvider>(context, listen: false);

    return Stack(
      children: [
        // view : contenido principal del ticket con máscara de gradiente
        ShaderMask(
          shaderCallback: (Rect rect) {
            return LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white,
                Colors.white,
                Colors.transparent,
              ],
              stops: [0.0, 0.8, 1.0], // 90% opaco, 10% de fade-out
            ).createShader(rect);
          },
          blendMode: BlendMode.dstIn,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 120), // Espacio inferior para botones y gradiente
            child: Column(
              children: [
                // Encabezado del ticket
                _buildTicketHeader(
                    provider.profileAccountSelected.name.isNotEmpty
                        ? provider.profileAccountSelected.name
                        : 'TICKET',
                    textDescriptionStyle,
                    textSmallStyle),
                _buildDividerLine(colorScheme),
                // Encabezados de columnas
                _buildColumnHeaders(textSmallStyle),
                _buildDividerLine(colorScheme),
                // Lista de productos que se contrae al contenido
                _TicketProductList(
                    ticket: ticket, textValuesStyle: textValuesStyle),
                _buildDividerLine(colorScheme),
                // Cantidad total de artículos
                _buildTotalItems(ticket, textSmallStyle, textDescriptionStyle),
                _buildDividerLine(colorScheme),
                const SizedBox(height: 5),
                // Total del ticket
                _buildTotalSection(ticket, colorScheme.secondary, textTotalStyle,
                    textDescriptionStyle),
                // view : Sección unificada de vuelto y descuento con chips editables
                _buildEditableChipsSection(
                    ticket, onEditCashAmount, colorScheme),
                // Métodos de pago
                _buildPaymentMethods(onEditCashAmount),

                const SizedBox(height: 12),

                // Checkbox para imprimir ticket
                _buildPrintCheckbox(),
              ],
            ),
          ),
        ),
        // buttons : botones posicionados en la parte inferior
        Positioned(left: 0,right: 12,bottom: 12,child: _buildActionButtons(onConfirmSale, onCloseTicket, isMobile(context))),
      ],
    );
  }

  /// Construye el encabezado del ticket
  Widget _buildTicketHeader(
    String businessName,
    TextStyle textDescriptionStyle,
    TextStyle textSmallStyle,
  ) {
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
        Text('ticket de compra', style: textSmallStyle),
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

  /// Construye la línea divisoria punteada
  Widget _buildDividerLine(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 1),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return CustomPaint(
            size: Size(constraints.maxWidth, 1),
            painter: _TicketDashedLinePainter(
              color: colorScheme.onSurface.withValues(alpha: 0.2),
            ),
          );
        },
      ),
    );
  }

  /// Construye los encabezados de las columnas
  Widget _buildColumnHeaders(TextStyle textSmallStyle) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
      child: Row(
        children: [
          Expanded(child: Text('Cant.', style: textSmallStyle)),
          Expanded(
            flex: 3,
            child: Text('Producto', style: textSmallStyle),
          ),
          Expanded(
            child: Text(
              'Precio',
              style: textSmallStyle,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  /// Construye la sección unificada de chips editables para vuelto y descuento
  Widget _buildEditableChipsSection(
    dynamic ticket,
    VoidCallback? onEditCashAmount,
    ColorScheme colorScheme,
  ) {
    return Consumer<SellProvider>(
      builder: (context, provider, _) {
        final hasDiscount = provider.ticket.discount > 0;
        final hasChange = ticket.valueReceived > 0 &&
            ticket.valueReceived >= ticket.getTotalPrice;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              // Chip de vuelto (solo si aplica)
              if (hasChange)
                _buildEditableChip(
                  context: context,
                  text:
                      'Vuelto ${CurrencyFormatter.formatPrice(value: ticket.valueReceived - ticket.getTotalPrice)}',
                  onTap: onEditCashAmount,
                  backgroundColor: Colors.blue.withValues(alpha: 0.15),
                  borderColor: Colors.blue.withValues(alpha: 0.3),
                  textColor: Colors.blue.shade700,
                  iconColor: Colors.blue.shade600,
                ),

              // Chip de descuento
              _buildEditableChip(
                context: context,
                text: hasDiscount
                    ? _getDiscountDisplayText(provider.ticket)
                    : 'Agregar descuento',
                onTap: () => showDiscountDialog(context),
                backgroundColor: hasDiscount
                    ? colorScheme.errorContainer.withValues(alpha: 0.2)
                    : colorScheme.primaryContainer.withValues(alpha: 0.2),
                borderColor: hasDiscount
                    ? colorScheme.error.withValues(alpha: 0.3)
                    : colorScheme.primary.withValues(alpha: 0.3),
                textColor:
                    hasDiscount ? colorScheme.error : colorScheme.primary,
                iconColor:
                    hasDiscount ? colorScheme.error : colorScheme.primary,
                showRemoveButton: hasDiscount,
                onRemove: hasDiscount
                    ? () =>
                        provider.setDiscount(discount: 0.0, isPercentage: false)
                    : null,
              ),
            ],
          ),
        );
      },
    );
  }

  /// Construye un chip editable reutilizable
  Widget _buildEditableChip({
    required BuildContext context,
    required String text,
    IconData? icon,
    required VoidCallback? onTap,
    required Color backgroundColor,
    required Color borderColor,
    required Color textColor,
    required Color iconColor,
    bool showRemoveButton = false,
    VoidCallback? onRemove,
  }) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: borderColor,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              icon == null
                  ? const SizedBox()
                  : Icon(
                      icon,
                      size: 18,
                      color: iconColor,
                    ),
              const SizedBox(width: 8),
              Text(
                text,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (showRemoveButton && onRemove != null) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onRemove,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: textColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      size: 14,
                      color: textColor,
                    ),
                  ),
                ),
              ] else ...[
                const SizedBox(width: 4),
                Icon(
                  Icons.edit_outlined,
                  size: 14,
                  color: iconColor.withValues(alpha: 0.7),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Construye la fila de total de artículos
  Widget _buildTotalItems(
    dynamic ticket,
    TextStyle textSmallStyle,
    TextStyle textDescriptionStyle,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
      child: Row(
        children: [
          Text('Artículos:', style: textSmallStyle),
          const Spacer(),
          Text(
            '${ticket.getProductsQuantity()}',
            style: textDescriptionStyle,
          ),
        ],
      ),
    );
  }

  /// Construye la sección de total (con o sin descuento)
  Widget _buildTotalSection(
    dynamic ticket,
    Color color,
    TextStyle textTotalStyle,
    TextStyle textDescriptionStyle,
  ) {
    final hasDiscount = ticket.discount > 0;

    return Padding(
      padding: const EdgeInsets.only(left: 12, right: 12, top: 5, bottom: 4),
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: hasDiscount
            ? Column(
                children: [
                  // Subtotal
                  Row(
                    children: [
                      Text(
                        'SUBTOTAL',
                        style: textDescriptionStyle.copyWith(
                          fontSize: 16,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        CurrencyFormatter.formatPrice(
                            value: ticket.getTotalPriceWithoutDiscount),
                        style: textDescriptionStyle.copyWith(
                          fontSize: 16,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  // Descuento
                  Row(
                    children: [
                      Text(
                        ticket.discountIsPercentage
                            ? 'DESCUENTO (${ticket.discount.toStringAsFixed(0)}%)'
                            : 'DESCUENTO',
                        style: textDescriptionStyle.copyWith(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '- ${CurrencyFormatter.formatPrice(value: ticket.getDiscountAmount)}',
                        style: textDescriptionStyle.copyWith(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  Container(
                    height: 1,
                    color: Colors.white.withValues(alpha: 0.3),
                  ),

                  const SizedBox(height: 8),

                  // Total final
                  Row(
                    children: [
                      Text('TOTAL', style: textTotalStyle),
                      const Spacer(),
                      Text(
                        CurrencyFormatter.formatPrice(
                            value: ticket.getTotalPrice),
                        style: textTotalStyle,
                        textAlign: TextAlign.right,
                      ),
                    ],
                  ),
                ],
              )
            : Row(
                children: [
                  Text('TOTAL', style: textTotalStyle),
                  const Spacer(),
                  Text(
                    CurrencyFormatter.formatPrice(value: ticket.getTotalPrice),
                    style: textTotalStyle,
                    textAlign: TextAlign.right,
                  ),
                ],
              ),
      ),
    );
  }

  /// Construye los métodos de pago
  Widget _buildPaymentMethods(VoidCallback? onCashPaymentSelected) {
    return Builder(
      builder: (context) => Padding(
        padding: const EdgeInsets.only(left: 12, right: 12, top: 6, bottom: 0),
        child: Column(
          children: [
            Text(
              'Forma de pago:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.87),
                  ),
            ),
            const SizedBox(height: 6),
            Consumer<SellProvider>(
              builder: (context, provider, _) {
                return Wrap(
                  spacing: 5,
                  alignment: WrapAlignment.center,
                  runSpacing: 5,
                  children: [
                    ChoiceChip(
                      label: const Text('Efectivo'),
                      selected: provider.ticket.payMode == 'effective',
                      onSelected: (bool selected) {
                        if (selected && onCashPaymentSelected != null) {
                          onCashPaymentSelected();
                        }
                        provider.setPayMode(
                            payMode: selected ? 'effective' : '');
                      },
                    ),
                    ChoiceChip(
                      label: const Text('Mercado Pago'),
                      selected: provider.ticket.payMode == 'mercadopago',
                      onSelected: (bool selected) {
                        provider.setPayMode(
                            payMode: selected ? 'mercadopago' : '');
                      },
                    ),
                    ChoiceChip(
                      label: const Text('Tarjeta Deb/Cred'),
                      selected: provider.ticket.payMode == 'card',
                      onSelected: (bool selected) {
                        provider.setPayMode(payMode: selected ? 'card' : '');
                      },
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Construye el checkbox para imprimir ticket
  Widget _buildPrintCheckbox() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Consumer<SellProvider>(
        builder: (context, sellProvider, __) {
          final colorScheme = Theme.of(context).colorScheme;

          return Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: sellProvider.shouldPrintTicket
                    ? colorScheme.primary.withValues(alpha: 0.3)
                    : colorScheme.outline.withValues(alpha: 0.2),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(6),
              color: !sellProvider.shouldPrintTicket
                  ? null
                  : colorScheme.primaryContainer.withValues(alpha: 0.1),
            ),
            child: CheckboxListTile(
              dense: true,
              value: sellProvider.shouldPrintTicket,
              onChanged: (bool? value) {
                sellProvider.setShouldPrintTicket(value ?? false);
              },
              title: Text(
                'Ticket',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: sellProvider.shouldPrintTicket
                          ? colorScheme.primary
                          : colorScheme.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
              ),
              secondary: Icon(
                sellProvider.shouldPrintTicket
                    ? Icons.receipt_long
                    : Icons.receipt_long_outlined,
                color: sellProvider.shouldPrintTicket
                    ? colorScheme.primary
                    : colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 2,
              ),
            ),
          );
        },
      ),
    );
  }

  /// Construye los botones de acción
  Widget _buildActionButtons(
    VoidCallback? onConfirmSale,
    VoidCallback? onCloseTicket,
    bool showCloseButton,
  ) {
    const String confirmarText = 'Confirmar venta';

    return Row(
      children: [
        const Spacer(),
        if (showCloseButton && onCloseTicket != null) ...[
          ButtonApp.fab(
            heroTag: "close_ticket_nav_fab", // Hero tag único para navigation
            onPressed: onCloseTicket,
            icon: Icons.close_rounded,
            backgroundColor: Colors.grey.withValues(alpha: 0.8),
          ).animate(delay: const Duration(milliseconds: 0)).fade(),
          const SizedBox(width: 8),
        ],
        ButtonApp.fab(
          heroTag: "confirm_sale_nav_fab", // Hero tag único para navigation
          onPressed: onConfirmSale,
          icon: Icons.check_circle_outline_rounded,
          text: confirmarText,
          extended: true,
        ).animate(delay: const Duration(milliseconds: 0)).fade(),
      ],
    );
  }

  /// Genera el texto a mostrar en el chip de descuento
  String _getDiscountDisplayText(dynamic ticket) {
    if (ticket.discount <= 0) return 'Agregar descuento';

    if (ticket.discountIsPercentage) {
      // Mostrar el porcentaje y el monto calculado dinámicamente
      final discountAmount = ticket.getDiscountAmount;
      return 'Descuento ${ticket.discount.toStringAsFixed(0)}% (${CurrencyFormatter.formatPrice(value: discountAmount)})';
    } else {
      // Solo mostrar el monto fijo
      return 'Descuento ${CurrencyFormatter.formatPrice(value: ticket.discount)}';
    }
  }
}

/// Widget personalizado que muestra la lista de productos en el ticket
class _TicketProductList extends StatefulWidget {
  final dynamic ticket;
  final TextStyle textValuesStyle;

  const _TicketProductList({
    required this.ticket,
    required this.textValuesStyle,
  });

  @override
  State<_TicketProductList> createState() => _TicketProductListState();
}

class _TicketProductListState extends State<_TicketProductList> {
  bool _isExpanded = false;
  static const int _maxItemsToShow = 4;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final List<Widget> allItems = widget.ticket.products.map<Widget>((item) {
      final product = item as ProductCatalogue;

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
                CurrencyFormatter.formatPrice(
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

    final totalItems = allItems.length;
    final shouldShowExpander = totalItems > _maxItemsToShow;
    final itemsToShow =
        _isExpanded ? allItems : allItems.take(_maxItemsToShow).toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Lista de productos (limitada o completa según el estado)
        ...itemsToShow,

        // Indicador para expandir/contraer si hay más de 7 items
        if (shouldShowExpander)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  setState(() {
                    _isExpanded = !_isExpanded;
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _isExpanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        _isExpanded
                            ? 'Ver menos'
                            : 'Ver ${totalItems - _maxItemsToShow} más productos',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Widget que muestra la confirmación de venta exitosa
class _TicketConfirmedPurchase extends StatelessWidget {
  final double width;

  const _TicketConfirmedPurchase({
    this.width = 400,
  });

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SellProvider>(context, listen: false);
    final theme = Theme.of(context);
    final ticket = provider.ticket;

    // Obtener información del método de pago
    final paymentMethodText = _getPaymentMethodDisplayText(ticket.payMode);
    final paymentIcon = _getPaymentMethodIcon(ticket.payMode);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      width: width - 24,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.green.shade400,
            Colors.green.shade600,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icono principal
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: Colors.white,
                size: 60,
              ),
            ),

            const SizedBox(height: 24),

            // Título principal
            Text(
              '¡Venta exitosa!',
              style: theme.textTheme.headlineMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            // Subtítulo
            Text(
              'Transacción completada correctamente',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: Colors.white.withValues(alpha: 0.9),
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 32),

            // Card con detalles
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  // Información del total con descuento si aplica
                  if (ticket.discount > 0) ...[
                    // Subtotal
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Subtotal:',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                        Text(
                          CurrencyFormatter.formatPrice(
                              value: ticket.getTotalPriceWithoutDiscount),
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontFamily: 'RobotoMono',
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Descuento
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          ticket.discountIsPercentage
                              ? 'Descuento (${ticket.discount.toStringAsFixed(0)}%):'
                              : 'Descuento:',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                        Text(
                          '- ${CurrencyFormatter.formatPrice(value: ticket.getDiscountAmount)}',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontFamily: 'RobotoMono',
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    Container(
                      height: 1,
                      color: Colors.white.withValues(alpha: 0.2),
                    ),

                    const SizedBox(height: 12),
                  ],

                  // Total de la venta
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total vendido:',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        CurrencyFormatter.formatPrice(
                            value: ticket.getTotalPrice),
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'RobotoMono',
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  Container(
                    height: 1,
                    color: Colors.white.withValues(alpha: 0.3),
                  ),

                  const SizedBox(height: 16),

                  // Información adicional
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Cantidad de artículos
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Artículos',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${ticket.getProductsQuantity()}',
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),

                      // Método de pago
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Método de pago',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                paymentIcon,
                                color: Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                paymentMethodText,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Mostrar vuelto si aplica
                  if (ticket.valueReceived > 0 &&
                      ticket.valueReceived > ticket.getTotalPrice) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Vuelto a entregar',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            CurrencyFormatter.formatPrice(
                              value:
                                  ticket.valueReceived - ticket.getTotalPrice,
                            ),
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'RobotoMono',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Información de fecha y hora
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.access_time_rounded,
                    color: Colors.white.withValues(alpha: 0.8),
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _getFormattedDateTime(),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontFamily: 'RobotoMono',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Obtiene el texto a mostrar para el método de pago
  String _getPaymentMethodDisplayText(String payMode) {
    switch (payMode) {
      case 'effective':
        return 'Efectivo';
      case 'mercadopago':
        return 'Mercado Pago';
      case 'card':
        return 'Tarjeta';
      default:
        return 'Sin especificar';
    }
  }

  /// Obtiene el icono correspondiente al método de pago
  IconData _getPaymentMethodIcon(String payMode) {
    switch (payMode) {
      case 'effective':
        return Icons.payments_rounded;
      case 'mercadopago':
        return Icons.account_balance_wallet_rounded;
      case 'card':
        return Icons.credit_card_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  /// Obtiene la fecha y hora formateada
  String _getFormattedDateTime() {
    final now = DateTime.now();
    return '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }
}

/// Dibuja una línea punteada horizontal para simular el corte de un ticket impreso
class _TicketDashedLinePainter extends CustomPainter {
  final Color color;

  _TicketDashedLinePainter({this.color = Colors.black38});

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
