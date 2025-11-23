import 'package:sellweb/core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sellweb/presentation/providers/sell_provider.dart';

/// Diálogo para agregar descuento al ticket de venta
class DiscountDialog extends StatefulWidget {
  const DiscountDialog({super.key});

  @override
  State<DiscountDialog> createState() => _DiscountDialogState();
}

class _DiscountDialogState extends State<DiscountDialog> {
  late final TextEditingController _discountController;
  late final AppMoneyTextEditingController _moneyController;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isPercentage = false;

  @override
  void initState() {
    super.initState();
    _discountController = TextEditingController();
    _moneyController = AppMoneyTextEditingController();

    // Inicializar con el descuento actual si existe
    final sellProvider = Provider.of<SellProvider>(context, listen: false);
    if (sellProvider.ticket.discount > 0) {
      // Restaurar el estado original del descuento
      _isPercentage = sellProvider.ticket.discountIsPercentage;
      if (_isPercentage) {
        // Para porcentaje, asegurar que sea entero
        _discountController.text =
            sellProvider.ticket.discount.round().toString();
      } else {
        // Para monto fijo, usar el controlador de dinero
        _moneyController.updateValue(sellProvider.ticket.discount);
      }
    }
  }

  @override
  void dispose() {
    _discountController.dispose();
    _moneyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SellProvider>(
      builder: (context, sellProvider, _) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        final totalTicket = sellProvider.ticket.getTotalPriceWithoutDiscount;

        return BaseDialog(
          title: 'Agregar descuento',
          icon: Icons.percent_rounded,
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // view : Vista previa del descuento (siempre visible arriba)
                _buildDiscountPreview(totalTicket, theme, colorScheme),

                const SizedBox(height: 20),

                // Tipo de descuento usando chips
                Text(
                  'Tipo de descuento',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: _buildDiscountTypeChip(
                        label: 'Monto fijo',
                        icon: Icons.attach_money_rounded,
                        isSelected: !_isPercentage,
                        onTap: () => _convertToFixedAmount(totalTicket),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildDiscountTypeChip(
                        label: 'Porcentaje',
                        icon: Icons.percent_rounded,
                        isSelected: _isPercentage,
                        onTap: () => _convertToPercentage(totalTicket),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Campo de entrada
                Text(
                  _isPercentage
                      ? 'Porcentaje de descuento (0-100%)'
                      : 'Monto del descuento',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 12),

                _isPercentage
                    ? InputTextField(
                        controller: _discountController,
                        labelText: 'Porcentaje (%)',
                        hintText: 'Ej: 10',
                        prefixIcon: const Icon(Icons.percent_rounded),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingrese un valor';
                          }

                          final numValue = int.tryParse(value);
                          if (numValue == null || numValue <= 0) {
                            return 'Ingrese un valor válido mayor a 0';
                          }

                          if (numValue > 100) {
                            return 'El porcentaje no puede ser mayor a 100%';
                          }

                          // Validar que el descuento calculado no exceda el total
                          final calculatedDiscount =
                              totalTicket * numValue / 100;
                          if (calculatedDiscount > totalTicket) {
                            return 'El descuento excede el total';
                          }

                          return null;
                        },
                        onChanged: (value) {
                          setState(() {}); // Para actualizar el preview
                        },
                      )
                    : MoneyInputTextField(
                        controller: _moneyController,
                        labelText: 'Monto del descuento',
                        errorText: _validateMoneyAmount(totalTicket),
                        onChanged: (value) {
                          setState(
                              () {}); // Para actualizar el preview y validación
                        },
                      ),
              ],
            ),
          ),
          actions: [
            ButtonApp.text(
              text: 'Cancelar',
              onPressed: () => Navigator.of(context).pop(),
            ),

            // Botón para limpiar descuento si ya existe uno
            if (sellProvider.ticket.discount > 0)
              ButtonApp.text(
                text: 'Quitar descuento',
                onPressed: () {
                  sellProvider.setDiscount(discount: 0.0, isPercentage: false);
                  Navigator.of(context).pop();
                },
                foregroundColor: colorScheme.error,
              ),

            Container(
              margin: EdgeInsets.zero,
              child: ButtonApp.primary(
                text: 'Aplicar descuento',
                onPressed: _canApplyDiscount(totalTicket)
                    ? () => _applyDiscount(context, sellProvider, totalTicket)
                    : null, // Deshabilitar si no es válido
                backgroundColor: colorScheme.primary,
                textColor: colorScheme.onPrimary,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDiscountTypeChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color:
              isSelected ? colorScheme.primaryContainer : colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.outline.withValues(alpha: 0.5),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? colorScheme.onPrimaryContainer
                  : colorScheme.onSurface.withValues(alpha: 0.7),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiscountPreview(
      double totalTicket, ThemeData theme, ColorScheme colorScheme) {
    // Obtener el valor de descuento según el tipo
    final discountValue = _isPercentage
        ? (double.tryParse(_discountController.text) ?? 0)
        : _moneyController.doubleValue;

    // Calcular valores para mostrar siempre el preview
    final discountAmount = discountValue > 0
        ? (_isPercentage ? (totalTicket * discountValue / 100) : discountValue)
        : 0.0;
    final finalTotal = totalTicket - discountAmount;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.secondary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.preview_rounded,
                color: colorScheme.secondary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Vista previa',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Subtotal:',
                style: theme.textTheme.bodyMedium,
              ),
              Text(
                CurrencyFormatter.formatPrice(value: totalTicket),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Descuento${discountValue > 0 && _isPercentage ? ' ($discountValue%)' : ''}:',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: discountAmount > 0
                      ? colorScheme.error
                      : colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              Text(
                discountAmount > 0
                    ? '- ${CurrencyFormatter.formatPrice(value: discountAmount)}'
                    : CurrencyFormatter.formatPrice(value: 0),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: discountAmount > 0
                      ? colorScheme.error
                      : colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
          const Divider(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total final:',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                CurrencyFormatter.formatPrice(value: finalTotal),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: discountAmount > 0
                      ? colorScheme.primary
                      : colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Valida el monto del descuento en tiempo real
  String? _validateMoneyAmount(double totalTicket) {
    final moneyValue = _moneyController.doubleValue;

    if (moneyValue <= 0) {
      return null; // No mostrar error si está vacío
    }

    if (moneyValue > totalTicket) {
      return 'El descuento no puede ser mayor al total';
    }

    return null; // Valor válido
  }

  /// Valida si se puede aplicar el descuento
  bool _canApplyDiscount(double totalTicket) {
    final discountValue = _isPercentage
        ? (double.tryParse(_discountController.text) ?? 0)
        : _moneyController.doubleValue;

    if (discountValue <= 0) return false;

    if (_isPercentage) {
      return discountValue <= 100;
    } else {
      return discountValue <= totalTicket;
    }
  }

  void _applyDiscount(
      BuildContext context, SellProvider sellProvider, double totalTicket) {
    // Solo validar el formulario si es necesario
    if (_isPercentage && !_formKey.currentState!.validate()) return;

    // Obtener el valor según el tipo de descuento
    final discountValue = _isPercentage
        ? (double.tryParse(_discountController.text) ?? 0)
        : _moneyController.doubleValue;

    if (discountValue <= 0) {
      _showErrorSnackBar(context, 'Por favor ingrese un valor válido');
      return;
    }

    // Validaciones finales antes de aplicar
    if (_isPercentage && discountValue > 100) {
      _showErrorSnackBar(context, 'El porcentaje no puede ser mayor a 100%');
      return;
    }

    if (!_isPercentage && discountValue > totalTicket) {
      _showErrorSnackBar(context, 'El descuento no puede ser mayor al total');
      return;
    }

    // Aplicar el descuento
    sellProvider.setDiscount(
        discount: discountValue, isPercentage: _isPercentage);

    // Calcular el monto para mostrar en la confirmación
    final discountAmount =
        _isPercentage ? (totalTicket * discountValue / 100) : discountValue;

    // Cerrar el diálogo primero
    Navigator.of(context).pop();

    // Mostrar confirmación exitosa después de que el diálogo se cierre
    // usando Future.microtask para asegurar que el diálogo ya se cerró
    Future.microtask(() {
      if (context.mounted) {
        _showSuccessSnackBar(context, discountAmount);
      }
    });
  }

  /// Muestra SnackBar de error
  void _showErrorSnackBar(BuildContext context, String message) {
    context.showErrorSnackBar(message);
  }

  /// Muestra SnackBar de éxito
  void _showSuccessSnackBar(BuildContext context, double discountAmount) {
    context.showSuccessSnackBar(
      'Descuento de ${CurrencyFormatter.formatPrice(value: discountAmount)} aplicado',
    );
  }

  /// Convierte el valor actual a monto fijo
  void _convertToFixedAmount(double totalTicket) {
    if (_isPercentage && _discountController.text.isNotEmpty) {
      final percentageValue = double.tryParse(_discountController.text) ?? 0;
      if (percentageValue > 0 && percentageValue <= 100) {
        // Convertir porcentaje a monto fijo solo si es válido
        final fixedAmount = totalTicket * percentageValue / 100;
        if (fixedAmount <= totalTicket) {
          _moneyController.updateValue(fixedAmount);
        }
        _discountController.clear(); // Limpiar el controller de porcentaje
      }
    }
    setState(() {
      _isPercentage = false;
    });
  }

  /// Convierte el valor actual a porcentaje
  void _convertToPercentage(double totalTicket) {
    if (!_isPercentage && _moneyController.text.isNotEmpty) {
      final fixedValue = _moneyController.doubleValue;
      if (fixedValue > 0 && fixedValue <= totalTicket && totalTicket > 0) {
        // Convertir monto fijo a porcentaje (redondeado a entero) solo si es válido
        final percentage = (fixedValue / totalTicket) * 100;
        final finalPercentage = percentage > 100 ? 100 : percentage.round();
        if (finalPercentage <= 100 && finalPercentage > 0) {
          _discountController.text = finalPercentage.toString();
        }
        _moneyController.clear(); // Limpiar el controller de dinero
      }
    }
    setState(() {
      _isPercentage = true;
    });
  }
}

/// Función helper para mostrar el diálogo de descuento
Future<void> showDiscountDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (context) => const DiscountDialog(),
  );
}
