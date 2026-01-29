import 'package:sellweb/core/constants/payment_methods.dart';
import 'package:sellweb/core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';
import 'package:sellweb/features/catalogue/domain/entities/product_catalogue.dart';
import 'package:sellweb/features/sales/presentation/providers/sales_provider.dart';
import 'package:sellweb/core/presentation/widgets/combo_tag.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:sellweb/features/sales/presentation/dialogs/ticket_options_dialog.dart';

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
            width: isMobile(context) ? MediaQuery.of(context).size.width : 400,
            onAnimationComplete: onCloseTicket, // Usar el callback del padre
          ).animate().scale(
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
    final provider = Provider.of<SalesProvider>(context);
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
    final provider = Provider.of<SalesProvider>(context, listen: false);

    return Stack(
      children: [
        // view : contenido principal del ticket con máscara de gradiente superior e inferior
        ShaderMask(
          shaderCallback: (Rect rect) {
            return LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.white,
                Colors.white,
                Colors.transparent,
              ],
              stops: [
                0.0,
                0.1,
                0.8,
                1.0
              ], // fade-in arriba, contenido opaco, fade-out abajo
            ).createShader(rect);
          },
          blendMode: BlendMode.dstIn,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
                12, 12, 12, 120), // Espacio inferior para botones y gradiente
            child: Column(
              children: [
                const SizedBox(height: 20),
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
                const SizedBox(height: 5),
                // Total del ticket
                // Total del ticket
                _buildTotalSection(ticket, colorScheme.primary, textTotalStyle,
                    textDescriptionStyle),

                const SizedBox(height: 12),

                // Métodos de pago
                _buildPaymentMethods(onEditCashAmount),

                // Sección unificada de vuelto y descuento con chips editables
                _buildEditableChipsSection(
                    ticket, onEditCashAmount, colorScheme),
              ],
            ),
          ),
        ),
        // buttons : botones posicionados en la parte inferior
        Positioned(
            left: 0,
            right: 12,
            bottom: 12,
            child: _buildActionButtons(
                onConfirmSale, onCloseTicket, isMobile(context))),
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
    return Consumer<SalesProvider>(
      builder: (context, provider, _) {
        final hasDiscount = provider.ticket.discount > 0;
        final hasChange = ticket.valueReceived > 0 &&
            ticket.valueReceived >= ticket.getTotalPrice;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
    final hasChange =
        ticket.valueReceived > 0 && ticket.valueReceived > ticket.getTotalPrice;

    return Builder(
      builder: (context) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;

        // Colores adaptativos para tema claro/oscuro
        final primaryColor = colorScheme.primary;
        final onPrimaryColor = colorScheme.onPrimary;

        // Estilos de texto adaptativos
        final adaptiveTotalStyle = textTotalStyle.copyWith(
          color: onPrimaryColor,
          fontSize: 28,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        );

        final adaptiveSubtitleStyle = textDescriptionStyle.copyWith(
          color: onPrimaryColor.withValues(alpha: 0.95),
          fontSize: 15,
          fontWeight: FontWeight.w500,
        );

        final adaptiveDiscountStyle = textDescriptionStyle.copyWith(
          color: onPrimaryColor.withValues(alpha: 0.85),
          fontSize: 13,
          fontWeight: FontWeight.w400,
        );

        final adaptiveChangeStyle = textDescriptionStyle.copyWith(
          color: onPrimaryColor.withValues(alpha: 0.9),
          fontSize: 16,
          fontWeight: FontWeight.w500,
        );

        return Padding(
          padding:
              const EdgeInsets.only(left: 12, right: 12, top: 8, bottom: 6),
          child: Container(
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: onPrimaryColor.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
              child: hasDiscount
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Subtotal
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Subtotal',
                              style: adaptiveSubtitleStyle,
                            ),
                            Text(
                              CurrencyFormatter.formatPrice(
                                  value: ticket.getTotalPriceWithoutDiscount),
                              style: adaptiveSubtitleStyle.copyWith(
                                fontFamily: 'RobotoMono',
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 6),

                        // Descuento
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.local_offer_outlined,
                                  size: 16,
                                  color: onPrimaryColor.withValues(alpha: 0.8),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  ticket.discountIsPercentage
                                      ? 'Descuento (${ticket.discount.toStringAsFixed(0)}%)'
                                      : 'Descuento',
                                  style: adaptiveDiscountStyle,
                                ),
                              ],
                            ),
                            Text(
                              '- ${CurrencyFormatter.formatPrice(value: ticket.getDiscountAmount)}',
                              style: adaptiveDiscountStyle.copyWith(
                                fontFamily: 'RobotoMono',
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // Separador elegante
                        Container(
                          height: 1,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                onPrimaryColor.withValues(alpha: 0.0),
                                onPrimaryColor.withValues(alpha: 0.3),
                                onPrimaryColor.withValues(alpha: 0.0),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Total final destacado
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  'TOTAL',
                                  style:
                                      adaptiveTotalStyle.copyWith(fontSize: 18),
                                ),
                                Text(
                                  CurrencyFormatter.formatPrice(
                                      value: ticket.getTotalPrice),
                                  style: adaptiveTotalStyle.copyWith(
                                    fontFamily: 'RobotoMono',
                                  ),
                                ),
                              ],
                            ),

                            // Vuelto (si aplica)
                            if (hasChange) ...[
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Vuelto',
                                    style: adaptiveChangeStyle,
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: onPrimaryColor.withValues(
                                            alpha: 0.3),
                                        width: 1,
                                      ),
                                      borderRadius: BorderRadius.circular(6),
                                      color:
                                          onPrimaryColor.withValues(alpha: 0.1),
                                    ),
                                    child: Text(
                                      CurrencyFormatter.formatPrice(
                                          value: ticket.valueReceived -
                                              ticket.getTotalPrice),
                                      style: adaptiveChangeStyle.copyWith(
                                        fontFamily: 'RobotoMono',
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              'TOTAL',
                              style: adaptiveTotalStyle.copyWith(fontSize: 20),
                            ),
                            Text(
                              CurrencyFormatter.formatPrice(
                                  value: ticket.getTotalPrice),
                              style: adaptiveTotalStyle.copyWith(
                                fontFamily: 'RobotoMono',
                                fontSize: 32,
                              ),
                            ),
                          ],
                        ),

                        // Vuelto (si aplica)
                        if (hasChange) ...[
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Vuelto',
                                style: adaptiveChangeStyle,
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color:
                                        onPrimaryColor.withValues(alpha: 0.3),
                                    width: 1,
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                  color: onPrimaryColor.withValues(alpha: 0.1),
                                ),
                                child: Text(
                                  CurrencyFormatter.formatPrice(
                                      value: ticket.valueReceived -
                                          ticket.getTotalPrice),
                                  style: adaptiveChangeStyle.copyWith(
                                    fontFamily: 'RobotoMono',
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }

  /// Construye los métodos de pago
  Widget _buildPaymentMethods(VoidCallback? onCashPaymentSelected) {
    return Builder(
      builder: (context) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Consumer<SalesProvider>(
            builder: (context, provider, _) {
              return Wrap(
                spacing: 8,
                alignment: WrapAlignment.center,
                runSpacing: 8,
                children: PaymentMethod.getValidMethods().map((method) {
                  final isSelected = provider.ticket.payMode == method.code;
                  
                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        if (method == PaymentMethod.cash &&
                            onCashPaymentSelected != null) {
                          onCashPaymentSelected();
                        }
                        provider.setPayMode(payMode: method.code);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? colorScheme.primary
                              : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? colorScheme.primary
                                : colorScheme.outline.withValues(alpha: 0.2),
                            width: 1,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: colorScheme.primary.withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  )
                                ]
                              : [],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              method.icon,
                              size: 18,
                              color: isSelected
                                  ? colorScheme.onPrimary
                                  : colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              method.displayName,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: isSelected
                                    ? colorScheme.onPrimary
                                    : colorScheme.onSurface,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        );
      }
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
          AppButton.fab(
            heroTag: "close_ticket_nav_fab", // Hero tag único para navigation
            onPressed: onCloseTicket,
            icon: Icons.close_rounded,
            backgroundColor: Colors.grey.withValues(alpha: 0.8),
          ).animate(delay: const Duration(milliseconds: 0)).fade(),
          const SizedBox(width: 8),
        ],
        AppButton.fab(
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
                product.formattedQuantityWithUnit,
                style: widget.textValuesStyle,
              ),
            ),
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  if (product.isQuickSale) ...[
                    Icon(
                      Icons.bolt_rounded,
                      size: 16,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                  ],
                  Flexible(
                    child: Text(
                      product.description,
                      style: widget.textValuesStyle,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (product.isCombo) ...[
                    const SizedBox(width: 4),
                    const ComboTag(isCompact: true),
                  ],
                ],
              ),
            ),
            Expanded(
              child: Text(
                CurrencyFormatter.formatPrice(
                  value: product.totalPrice,
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
class _TicketConfirmedPurchase extends StatefulWidget {
  final double width;
  final VoidCallback?
      onAnimationComplete; // Callback para notificar cuando termina la animación

  const _TicketConfirmedPurchase({
    this.width = 400,
    this.onAnimationComplete,
  });

  @override
  State<_TicketConfirmedPurchase> createState() =>
      _TicketConfirmedPurchaseState();
}

class _TicketConfirmedPurchaseState extends State<_TicketConfirmedPurchase>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  bool _animationCompleted = false;

  // AudioPlayer para el sonido de éxito
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();

    // Reproducir sonido de éxito
    _playSuccessSound();

    // Controlador para fade-in del contenido
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    // Controlador para scale de entrada
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Iniciar animaciones
    _scaleController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _fadeController.forward();
      }
    });

    // Simular la duración típica de la animación Lottie (aproximadamente 2 segundos)
    /*
    // y agregar 1 segundo adicional como solicita el usuario
    Future.delayed(const Duration(milliseconds: 3000), () {
      if (mounted && !_animationCompleted) {
        _animationCompleted = true;
        widget.onAnimationComplete?.call();
      }
    });
    */
  }

  Future<void> _playSuccessSound() async {
    try {
      // Configurar modo de baja latencia para efectos de sonido cortos (crucial en Web)
      // Ajustar volumen al máximo explícitamente antes de reproducir
      await _audioPlayer.setVolume(1.0);
      
      await _audioPlayer.play(
        AssetSource('sounds/sale_success.mp3'), 
        volume: 1.0,
        mode: PlayerMode.lowLatency, // Ayuda en web para eliminar delay y problemas de carga
      );
    } catch (e) {
      debugPrint('Error reproduciendo sonido (Sales Success): $e');
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SalesProvider>(context, listen: false);
    final theme = Theme.of(context);
    final ticket = provider.ticket;
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    // Colores para el diseño minimalista
    final backgroundColor = isDark ? colorScheme.surface : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF2D3E4F); // Color oscuro tipo "Hecho"
    final secondaryTextColor = isDark ? Colors.white70 : Colors.grey.shade600;
    final primaryColor = colorScheme.primary;

    return ScaleTransition(
      scale: CurvedAnimation(
        parent: _scaleController,
        curve: Curves.elasticOut,
      ),
      child: Container(
        margin: const EdgeInsets.all(0), // Sin márgenes externos en móvil
        width: widget.width,
        decoration: BoxDecoration(
          color: backgroundColor,
          // En modo escritorio/tablet queremos bordes redondeados si es un modal/drawer
          borderRadius: BorderRadius.circular(isMobile(context) ? 0 : 16),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),
              
              // 1. Animación Lottie (Check)
              // Usamos un tamaño adecuado y repetitivo como se solicitó
              SizedBox(
                width: 180,
                height: 180,
                child: Lottie.asset(
                  'assets/anim/success_check.json',
                  fit: BoxFit.contain,
                  repeat: true,
                  animate: true,
                  frameRate: FrameRate.max,
                ),
              ),

              const SizedBox(height: 12),

              // 2. Título "Hecho" o "Venta exitosa"
              FadeTransition(
                opacity: _fadeController,
                child: Text(
                  'Venta exitosa',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 16),

              // 3. Monto Total (Grande)
              FadeTransition(
                opacity: _fadeController,
                child: Text(
                  CurrencyFormatter.formatPrice(value: ticket.getTotalPrice),
                  style: theme.textTheme.displayMedium?.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w400, // Fuente más fina y elegante
                    letterSpacing: -1.0,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              // 4. Vuelto (Sutil)
              if (ticket.valueReceived > ticket.getTotalPrice) ...[
                const SizedBox(height: 8),
                FadeTransition(
                  opacity: _fadeController,
                  child: Text(
                    'Vuelto: ${CurrencyFormatter.formatPrice(value: ticket.valueReceived - ticket.getTotalPrice)}',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: secondaryTextColor,
                      fontSize: 18,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],

              const Spacer(flex: 2),

              // 5. Botones de Acción 
              FadeTransition(
                opacity: _fadeController,
                child: Column(
                  children: [
                    // Botón Recibo (Outlined)
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          // Abrir diálogo de opciones de ticket
                          showTicketOptionsDialog(
                            context: context,
                            ticket: ticket,
                            businessName: provider.profileAccountSelected.name.isNotEmpty
                                ? provider.profileAccountSelected.name
                                : 'PUNTO DE VENTA',
                            onComplete: () {
                              // Callback cuando se completa el proceso
                            },
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: textColor,
                          side: BorderSide(color: Colors.grey.withValues(alpha: 0.4), width: 1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                          backgroundColor: Colors.transparent,
                        ),
                        icon: Icon(Icons.receipt_long_rounded, color: secondaryTextColor),
                        label: Text(
                          'Recibo',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Botón Realizar nueva venta (Filled Primary)
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: FilledButton(
                        onPressed: () {
                          if (mounted && !_animationCompleted) {
                            _animationCompleted = true;
                            widget.onAnimationComplete?.call();
                          }
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: colorScheme.onPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Continuar',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
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
