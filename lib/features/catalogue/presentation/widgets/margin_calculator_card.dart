import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sellweb/core/presentation/widgets/inputs/input_text_field.dart';
import 'package:sellweb/core/presentation/widgets/buttons/app_button.dart';
import 'package:sellweb/core/utils/formatters/currency_formatter.dart';
import 'package:sellweb/core/constants/ui_constants.dart';
import 'package:sellweb/core/presentation/widgets/ui/ui.dart';

class MarginCalculatorCard extends StatefulWidget {
  final double costPrice;
  final double salePrice;
  final int ivaPercentage;
  final Function(double) onApplyPrice;

  const MarginCalculatorCard({
    super.key,
    required this.costPrice,
    required this.salePrice,
    required this.ivaPercentage,
    required this.onApplyPrice,
  });

  @override
  State<MarginCalculatorCard> createState() => _MarginCalculatorCardState();
}

class _MarginCalculatorCardState extends State<MarginCalculatorCard> {
  final _marginController = TextEditingController();
  final _finalPriceController = TextEditingController();
  final _listTileController = ListTileController();
  bool _isValidCost = false;
  bool _isManualEdit = false;

  
  // Estado para la animación de highlight
  bool _isPriceHighlighted = false;

  @override
  void initState() {
    super.initState();
    _checkCostValidity();
    
    // Inicialización: Si ya existe un precio de venta y costo, calculamos el margen implícito.
    if (_isValidCost && widget.salePrice > 0) {
      _calculateMarginReverse();
    }
    
    _marginController.addListener(_calculatePrice);
  }

  @override
  void didUpdateWidget(MarginCalculatorCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    final bool costChanged = oldWidget.costPrice != widget.costPrice;
    final bool salePriceChanged = oldWidget.salePrice != widget.salePrice;
    final bool ivaChanged = oldWidget.ivaPercentage != widget.ivaPercentage;

    if (costChanged || salePriceChanged || ivaChanged) {
      _checkCostValidity();
      
      // Auto-expandir si hay datos relevantes
      if ((costChanged || ivaChanged) && widget.costPrice > 0) {
        _listTileController.expand();
      }

      if (!_isValidCost) {
        _finalPriceController.clear();
        return;
      }

      // LÓGICA DE ACTUALIZACIÓN
      
      if (salePriceChanged) {
        // Caso 1: El usuario cambió el Precio Final manualmente en el formulario padre.
        // Debemos recalcular el Margen para reflejar este cambio (Reverse).
        if (widget.costPrice > 0) {
           _calculateMarginReverse();
        }
      } 
      else if (costChanged || ivaChanged) {
        // Caso 2: El usuario cambió el Costo o el Impuesto.
        // Debemos mantener el Margen % constante y calcular el nuevo Precio Final (Forward).
        // EXCEPCIÓN: Si es la primera vez (no hay margen seteado) y tenemos precio de venta, hacemos reverse.
        if (_marginController.text.isNotEmpty) {
          _calculatePrice();
        } else if (widget.salePrice > 0) {
          _calculateMarginReverse();
        }
      }
    }
  }

  /// Calcula el margen de ganancia basado en el Costo y Precio de Venta actuales
  void _calculateMarginReverse() {
    // Evitar division por cero
    if (widget.costPrice <= 0) return;

    // PrecioVenta = Costo * (1 + Margen) * (1 + IVA)
    // PrecioVenta / (1 + IVA) = Costo * (1 + Margen)
    // (PrecioVenta / (1 + IVA) / Costo) - 1 = Margen

    final priceWithoutIva = widget.salePrice / (1 + (widget.ivaPercentage / 100));
    final marginRatio = (priceWithoutIva / widget.costPrice) - 1;
    final marginPercentage = marginRatio * 100;

    // Actualizar UI
    final formattedMargin = marginPercentage.toStringAsFixed(2)
        .replaceAll(RegExp(r'\.00$'), ''); // Quitar decimales cero

    // Solo actualizar si el valor es diferente para evitar loops o saltos de cursor
    if (_marginController.text != formattedMargin && !_isManualEdit) {
       _marginController.text = formattedMargin;
    }
    
    // Actualizar el display de precio final para que coincida
    _finalPriceController.text = CurrencyFormatter.formatPrice(
      value: widget.salePrice,
      moneda: '\$',
    );
  }

  @override
  void dispose() {
    _marginController.dispose();
    _finalPriceController.dispose();
    super.dispose();
  }

  void _checkCostValidity() {
    setState(() {
      _isValidCost = widget.costPrice > 0;
    });
  }
 
  void _calculatePrice() {
    if (!mounted) return;
    
    setState(() {
      if (!_isValidCost) return;

      final marginText = _marginController.text.replaceAll(',', '.');
      final margin = double.tryParse(marginText);

      if (margin != null && margin > 0) {
        // Precio = Costo * (1 + Margen/100) * (1 + IVA/100)
        final costWithMargin = widget.costPrice * (1 + (margin / 100));
        final finalPrice = costWithMargin * (1 + (widget.ivaPercentage / 100));

        _finalPriceController.text = CurrencyFormatter.formatPrice(
          value: finalPrice,
          moneda: '\$',
        );
        
        // Activar highlight visual
        _triggerPriceHighlight();
      } else {
        _finalPriceController.clear();
      }
    });
  }
  
  void _triggerPriceHighlight() {
    setState(() => _isPriceHighlighted = true);
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() => _isPriceHighlighted = false);
      }
    });
  }

  void _handleApply() {
    final priceText = _finalPriceController.text
        .replaceAll('\$', '')
        .replaceAll('.', '') // Remove thousands separator
        .replaceAll(',', '.'); // Replace decimal separator
        
    final price = double.tryParse(priceText.trim());
    if (price != null) {
      widget.onApplyPrice(price);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Precio aplicado correctamente'),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListTileAppExpanded(
      controller: _listTileController,
      title: 'Calculadora de Margen',
      subtitle: Text(
        'Calcula el precio final según el margen y impuestos',
        style: theme.textTheme.bodySmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      icon: Icons.calculate_outlined,
      iconColor: colorScheme.primary, 
      initiallyExpanded: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!_isValidCost)
             Container(
               margin: const EdgeInsets.only(bottom: 16),
               padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                 color: colorScheme.errorContainer.withValues(alpha: 0.5),
                 borderRadius: BorderRadius.circular(UIConstants.defaultRadius),
                 border: Border.all(color: colorScheme.error.withValues(alpha: 0.2)),
               ),
               child: Row(
                 children: [
                   Icon(Icons.info_outline, size: 16, color: colorScheme.error),
                   const SizedBox(width: 8),
                   Expanded(
                     child: Text(
                       'Ingresa un costo válido para usar la calculadora',
                       style: theme.textTheme.labelMedium?.copyWith(
                         color: colorScheme.error,
                         fontWeight: FontWeight.bold
                       ),
                     ),
                   )
                 ],
               ),
             ),

          // Inputs Row
          LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 600;

              if (isMobile) {
                return Column(
                  children: [
                    _buildMarginInput(),
                    const SizedBox(height: 12),
                    _buildPriceOutput(),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 52, // Match input height
                      child: _buildApplyButton(theme),
                    ),
                  ],
                );
              } else {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildMarginInput()),
                    const SizedBox(width: 12),
                    Expanded(child: _buildPriceOutput()),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 52, // Match input height roughly
                        child: _buildApplyButton(theme),
                      ),
                    ),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMarginInput() {
    return InputTextField(
      controller: _marginController,
      labelText: '% de Ganancia',
      hintText: '30', 
      keyboardType: const TextInputType.numberWithOptions(decimal: true), 
      enabled: _isValidCost,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
      ],
      borderRadius: UIConstants.defaultRadius,
    );
  }

  Widget _buildPriceOutput() {
    // Determinar el label dinámico según qué se esté calculando
    String getFinalPriceLabel() {
      final hasMargin = _marginController.text.isNotEmpty && 
                        double.tryParse(_marginController.text.replaceAll(',', '.')) != null &&
                        double.parse(_marginController.text.replaceAll(',', '.')) > 0;
      final hasIva = widget.ivaPercentage > 0;

      if (hasMargin && hasIva) {
        return 'Precio Final (Ganancia + IVA ${widget.ivaPercentage}%)';
      } else if (hasMargin) {
        return 'Precio Final (con Ganancia)';
      } else if (hasIva) {
        return 'Precio Final (IVA ${widget.ivaPercentage}%)';
      } else {
        return 'Precio Final';
      }
    }
    
    // Colores de acento para feedback visual
    final theme = Theme.of(context);
    final highlightColor = Colors.green.shade600;

    return InputTextField(
      controller: _finalPriceController,
      labelText: getFinalPriceLabel(),
      hintText: '\$ 0.00',
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      // Read-only para visualización del cálculo
      readOnly: true,
      enabled: _isValidCost, // Si no hay costo válido, deshabilitado visualmente
      
      // highlight visual
      fillColor: _isPriceHighlighted 
          ? highlightColor.withValues(alpha: 0.1) 
          : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      borderColor: _isPriceHighlighted ? highlightColor : null,
      
      borderRadius: UIConstants.defaultRadius, 
    );
  }

  Widget _buildApplyButton(ThemeData theme) {
    // Habilitar botón solo si hay margen Y precio final válidos
    final hasValidMargin = _marginController.text.isNotEmpty &&
        double.tryParse(_marginController.text.replaceAll(',', '.')) != null &&
        double.parse(_marginController.text.replaceAll(',', '.')) > 0;
    final hasValidPrice = _finalPriceController.text.isNotEmpty;
    
    return AppButton.filled(
      text: 'Aplicar Precio',
      onPressed: (_isValidCost && hasValidMargin && hasValidPrice)
          ? _handleApply
          : null,
      icon: const Icon(Icons.check_circle_outline, size: 20),
      borderRadius: UIConstants.defaultRadius,
      fontSize: 15,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

}
