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
  final int initialIva;
  final double initialRevenuePercentage;
  final Function(double price, double revenuePercentage, int iva) onApplyValues;

  const MarginCalculatorCard({
    super.key,
    required this.costPrice,
    required this.salePrice,
    required this.initialIva,
    required this.initialRevenuePercentage,
    required this.onApplyValues,
  });



  @override
  State<MarginCalculatorCard> createState() => _MarginCalculatorCardState();
}

class _MarginCalculatorCardState extends State<MarginCalculatorCard> {
  final _marginController = TextEditingController();
  final _finalPriceController = TextEditingController();
  final _listTileController = ListTileController();
  
  // Método auxiliar para notificar cambios incluso sin cálculo de precio
  void _notifyParentValues() {
    final priceText = _finalPriceController.text
        .replaceAll('\$', '')
        .replaceAll('.', '') 
        .replaceAll(',', '.');
        
    final price = double.tryParse(priceText.trim()) ?? 0.0;
    final marginText = _marginController.text.replaceAll(',', '.');
    final margin = double.tryParse(marginText) ?? 0.0;
    
    // Notificamos incluso si el precio es 0, para guardar ganancia e IVA
    widget.onApplyValues(price, margin, _currentIva);
  }
  bool _isValidCost = false;
  bool _isManualEdit = false;

  
  // Estado para la animación de highlight
  // Estado local para impuestos
  late int _currentIva;
  final List<int> _commonIvaOptions = [21, 27, 10, 0];
  
  // Estado para la animación de highlight
  bool _isPriceHighlighted = false;

  @override
  void initState() {
    super.initState();
    _currentIva = widget.initialIva;
    _marginController.text = widget.initialRevenuePercentage > 0 
        ? widget.initialRevenuePercentage.toString() 
        : '';
        
    _checkCostValidity();
    
    // Si tenemos datos iniciales, calculamos el precio
    if (_isValidCost) {
       _calculatePrice();
    }
    
    _marginController.addListener(_calculatePrice);
  }

  @override
  void didUpdateWidget(MarginCalculatorCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    final bool costChanged = oldWidget.costPrice != widget.costPrice;
    final bool salePriceChanged = oldWidget.salePrice != widget.salePrice;
    
    // Si cambio el widget padre (ej. otro producto seleccionado o reset), actualizamos iva
    if (oldWidget.initialIva != widget.initialIva) {
      _currentIva = widget.initialIva;
    }
    
    if (oldWidget.initialRevenuePercentage != widget.initialRevenuePercentage) {
       if (widget.initialRevenuePercentage > 0 && !_isManualEdit) {
         _marginController.text = widget.initialRevenuePercentage.toString();
       }
    }

    if (costChanged || salePriceChanged) {
      _checkCostValidity();
      
      if (!_isValidCost) {
        _finalPriceController.clear();
        return;
      }
      
      // Si cambia el precio de venta externo (ej. input manual de precio final), 
      // calculamos el margen inverso manteniendo el IVA actual
      if (salePriceChanged && widget.salePrice > 0) {
        _calculateMarginReverse();
      } 
      // Si cambia el costo, recalculamos precio final manteniendo margen y iva
      else if (costChanged) {
        _calculatePrice();
      }
    }
  }

  /// Calcula el margen de ganancia basado en el Costo y Precio de Venta actuales
  void _calculateMarginReverse() {
    // Evitar division por cero
    if (widget.costPrice <= 0) return;

    // Nueva fórmula aditiva:
    // PrecioVenta = Costo * (1 + Margen% + IVA%)
    // PrecioVenta / Costo = 1 + Margen% + IVA%
    // (PrecioVenta / Costo) - 1 - IVA% = Margen%
    
    final priceToCostRatio = widget.salePrice / widget.costPrice;
    final ivaRatio = _currentIva / 100.0;
    
    final marginRatio = priceToCostRatio - 1 - ivaRatio;
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
      // Si no hay costo, no podemos calcular un precio numérico basado en margen
      // Pero permitimos que la UI actualice los valores de estado
      if (!_isValidCost) return;

      final marginText = _marginController.text.replaceAll(',', '.');
      // Si está vacío o es inválido, asumimos 0 para mostrar el precio base (Costo + IVA)
      final margin = double.tryParse(marginText) ?? 0.0;

      // Nueva fórmula aditiva:
      // Precio = Costo * (1 + Margen/100 + IVA/100)
      // Es decir, tanto el Margen como el IVA se calculan sobre el Costo Base.
      
      final marginRatio = margin / 100.0;
      final ivaRatio = _currentIva / 100.0;
      
      final finalPrice = widget.costPrice * (1 + marginRatio + ivaRatio);

      _finalPriceController.text = CurrencyFormatter.formatPrice(
        value: finalPrice,
        moneda: '\$',
      );
        
      // Activar highlight visual
      _triggerPriceHighlight();
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
    final marginText = _marginController.text.replaceAll(',', '.');
    final margin = double.tryParse(marginText) ?? 0.0;
    
    if (price != null) {
      // Devolvemos: Precio Final, Margen decimal, IVA Entero
      widget.onApplyValues(price, margin, _currentIva);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Valores aplicados correctamente'),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListTileAppExpanded(
      controller: _listTileController,
      title: 'Ganancias e impuestos',
      subtitle: _buildSubtitle(theme, colorScheme),
      icon: Icons.calculate_outlined,
      iconColor: colorScheme.primary, 
      initiallyExpanded: false,
      onExpansionChanged: (expanded) {
        setState(() {
          _isExpanded = expanded;
        });
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Inputs Row
          LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 600;

              if (isMobile) {
                return Column(
                  children: [
                      _buildTaxSelector(colorScheme),
                      const SizedBox(height: 12),
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
                  return Column(
                    children: [
                      // Fila de inputs
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                           Expanded(child: _buildTaxSelector(colorScheme)),
                           const SizedBox(width: 12),
                           Expanded(child: _buildMarginInput()),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Fila de resultado
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(child: _buildPriceOutput()),
                          const SizedBox(width: 12),
                          Expanded(
                            child: SizedBox(
                              height: 52, // Match input height roughly
                              child: _buildApplyButton(theme),
                            ),
                          ),
                        ],
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

  Widget _buildSubtitle(ThemeData theme, ColorScheme colorScheme) {
    // Si esta expandido, mostrar el texto de ayuda genérico
    if (_isExpanded) {
      return Text(
        'Define el margen de ganancia y los impuestos aplicables',
        style: theme.textTheme.bodySmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      );
    }

    // Si esta colapsado, mostrar chips resumen
    final marginText = _marginController.text.replaceAll(',', '.');
    final margin = double.tryParse(marginText) ?? 0.0;
    
    final hasIva = _currentIva > 0;
    final hasMargin = margin > 0;

    if (!hasIva && !hasMargin) {
       // Si no hay nada configurado, mostrar texto ayuda también
       return Text(
        'Define el margen de ganancia y los impuestos aplicables',
        style: theme.textTheme.bodySmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        if (hasIva)
          _buildChip(theme, 'IVA $_currentIva%', Colors.blue.shade100, Colors.blue.shade900),
        if (hasMargin)
          _buildChip(theme, 'Ganancia ${margin.toStringAsFixed(0)}%', Colors.green.shade100, Colors.green.shade900),
      ],
    );
  }

  Widget _buildChip(ThemeData theme, String label, Color bg, Color text) {
      final isDark = theme.brightness == Brightness.dark;
      // Ajustar colores para modo oscuro si es necesario
      final finalBg = isDark ? bg.withOpacity(0.2) : bg;
      final finalText = isDark ? text.withOpacity(0.9) : text;

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: finalBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: finalText.withOpacity(0.2), width: 0.5),
        ),
        child: Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: finalText,
            fontWeight: FontWeight.w600,
            fontSize: 10,
          ),
        ),
      );
  }

  Widget _buildTaxSelector(ColorScheme colorScheme) {
    String getIvaLabel(int iva) {
      if (iva == 0) return 'Exento';
      if (iva == 10) return 'IVA 10%';
      return 'IVA $iva%';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<int>(
            initialValue: _commonIvaOptions.contains(_currentIva) ? _currentIva : null,
            decoration: InputDecoration(
              labelText: 'Impuestos aplicable',
              hintText: 'Seleccionar IVA',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(UIConstants.defaultRadius),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            items: [
              ..._commonIvaOptions.map((iva) {
                return DropdownMenuItem(
                  value: iva,
                  child: Text(getIvaLabel(iva)),
                );
              }),
              if (!_commonIvaOptions.contains(_currentIva))
                DropdownMenuItem(
                  value: _currentIva,
                  child: Text('Manual $_currentIva%'),
                )
            ],
      onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _currentIva = value;
                    
                    // Si hay costo, recalculamos precio.
                    // Si no, solo notificamos el cambio de IVA manteniendo el precio actual
                    if (_isValidCost) {
                      _calculatePrice();
                    } else {
                      _notifyParentValues(); 
                    }
                  });
                }
              },
          ),


      ],
    );
  }

  Widget _buildMarginInput() {
    return InputTextField(
      controller: _marginController,
      labelText: '% de Ganancia',
      hintText: '30', 
      keyboardType: const TextInputType.numberWithOptions(decimal: true), 
      // Habilitado siempre para permitir configurar el margen esperado
      enabled: true,
      // inputFormatters: [
      //   FilteringTextInputFormatter.digitsOnly, 
      // ],
      borderRadius: UIConstants.defaultRadius,
    );
  }

  Widget _buildPriceOutput() {
    // Determinar el label dinámico según qué se esté calculando
    String getFinalPriceLabel() {
      final marginText = _marginController.text;
      final hasMargin = marginText.isNotEmpty && (int.tryParse(marginText) ?? 0) > 0;
      final hasIva = _currentIva > 0;

      if (hasMargin && hasIva) {
        return 'Precio Final (Ganancia + IVA $_currentIva%)';
      } else if (hasMargin) {
        return 'Precio Final (con Ganancia)';
      } else if (hasIva) {
        return 'Precio Final (IVA $_currentIva%)';
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
    // Habilitar botón si hay precio final válido (incluso con margen 0)
    final hasValidPrice = _finalPriceController.text.isNotEmpty;
    
    return AppButton.filled(
      text: 'Aplicar Precio',
      onPressed: (_isValidCost && hasValidPrice)
          ? _handleApply
          : null,
      icon: const Icon(Icons.check_circle_outline, size: 20),
      borderRadius: UIConstants.defaultRadius,
      fontSize: 15,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

}
