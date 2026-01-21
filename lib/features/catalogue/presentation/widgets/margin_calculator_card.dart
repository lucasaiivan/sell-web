import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sellweb/core/presentation/widgets/inputs/input_text_field.dart';
import 'package:sellweb/core/presentation/widgets/buttons/app_button.dart';
import 'package:sellweb/core/utils/formatters/currency_formatter.dart';
import 'package:sellweb/core/constants/ui_constants.dart';

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
  bool _isValidCost = false;

  @override
  void initState() {
    super.initState();
    _checkCostValidity();
    _marginController.addListener(_calculatePrice);
  }

  @override
  void didUpdateWidget(MarginCalculatorCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.costPrice != widget.costPrice ||
        oldWidget.salePrice != widget.salePrice ||
        oldWidget.ivaPercentage != widget.ivaPercentage) {
      _checkCostValidity();
      if (_isValidCost && _marginController.text.isNotEmpty) {
        _calculatePrice();
      } else if (!_isValidCost) {
        _finalPriceController.clear();
      }
    }
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
    if (!_isValidCost) return;

    final marginText = _marginController.text.replaceAll(',', '.');
    final margin = double.tryParse(marginText);

    if (margin != null) {
      // Precio = Costo * (1 + Margen/100) * (1 + IVA/100)
      final costWithMargin = widget.costPrice * (1 + (margin / 100));
      final finalPrice = costWithMargin * (1 + (widget.ivaPercentage / 100));

      _finalPriceController.text = CurrencyFormatter.formatPrice(
        value: finalPrice,
        moneda: '\$',
      );
    } else {
      _finalPriceController.clear();
    }
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

  /// Calcula el beneficio y porcentaje de ganancia
  ({double profit, double percentage, bool isProfitable})? _calculateProfit() {
    if (widget.salePrice <= 0 || widget.costPrice <= 0) return null;

    final profit = widget.salePrice - widget.costPrice;
    final percentage = (profit / widget.costPrice) * 100;

    return (
      profit: profit,
      percentage: percentage,
      isProfitable: profit > 0,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
       color: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(UIConstants.defaultRadius),
        side: BorderSide(
          color: colorScheme.outlineVariant,
        ),
      ),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.calculate_outlined,
                  color: colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Calculadora de Margen',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Calcula el precio de venta final basándote en el costo y el margen de utilidad deseado.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            
            if (!_isValidCost)
               Container(
                 margin: const EdgeInsets.only(bottom: 16),
                 padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                   color: colorScheme.errorContainer.withOpacity(0.5),
                   borderRadius: BorderRadius.circular(UIConstants.defaultRadius),
                   border: Border.all(color: colorScheme.error.withOpacity(0.2)),
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
            
            // Profit Indicator
            _buildProfitIndicator(colorScheme, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildMarginInput() {
    return InputTextField(
      controller: _marginController,
      labelText: '% de Ganancia',
      hintText: '30', 
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      suffixIcon: const Padding(
        padding: EdgeInsets.all(12.0),
        child: Text('%', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
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
        return 'Precio Final (Ganancias + IVA)';
      } else if (hasMargin) {
        return 'Precio Final (con Ganancias)';
      } else if (hasIva) {
        return 'Precio Final (con IVA)';
      } else {
        return 'Precio Final';
      }
    }

    return InputTextField(
      controller: _finalPriceController,
      labelText: getFinalPriceLabel(),
      readOnly: true,
      enabled: _isValidCost,
      fillColor: Theme.of(context).colorScheme.surface,
      borderRadius: UIConstants.defaultRadius,
    );
  }

  Widget _buildApplyButton(ThemeData theme) {
    return AppButton.filled(
      text: 'Aplicar Precio',
      onPressed: (_isValidCost && _finalPriceController.text.isNotEmpty)
          ? _handleApply
          : null,
      icon: const Icon(Icons.check_circle_outline, size: 20),
      borderRadius: UIConstants.defaultRadius,
      fontSize: 15,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget _buildProfitIndicator(ColorScheme colorScheme, ThemeData theme) {
    final calculation = _calculateProfit();
    if (calculation == null) return const SizedBox.shrink();

    final profit = calculation.profit;
    final isProfitable = calculation.isProfitable;

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isProfitable
            ? Colors.green.withValues(alpha: 0.08)
            : Colors.red.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(UIConstants.defaultRadius),
        border: Border.all(
          color: isProfitable
              ? Colors.green.withValues(alpha: 0.3)
              : Colors.red.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isProfitable ? Icons.trending_up : Icons.trending_down,
            color: isProfitable ? Colors.green.shade700 : Colors.red.shade700,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isProfitable ? 'Beneficio estimado' : 'Pérdida estimada',
              style: theme.textTheme.labelMedium?.copyWith(
                color: isProfitable
                    ? Colors.green.shade700
                    : Colors.red.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            CurrencyFormatter.formatPrice(value: profit.abs()),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: isProfitable
                  ? Colors.green.shade700
                  : Colors.red.shade700,
            ),
          ),
        ],
      ),
    );
  }
}
