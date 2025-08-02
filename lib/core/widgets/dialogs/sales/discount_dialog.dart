import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sellweb/core/utils/fuctions.dart';
import 'package:sellweb/core/widgets/buttons/buttons.dart';
import 'package:sellweb/core/widgets/dialogs/base/base_dialog.dart';
import 'package:sellweb/core/widgets/inputs/inputs.dart';
import 'package:sellweb/presentation/providers/sell_provider.dart';

/// Diálogo para agregar descuento al ticket de venta
class DiscountDialog extends StatefulWidget {
  const DiscountDialog({super.key});

  @override
  State<DiscountDialog> createState() => _DiscountDialogState();
}

class _DiscountDialogState extends State<DiscountDialog> {
  final TextEditingController _discountController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isPercentage = false;

  @override
  void initState() {
    super.initState();
    // Inicializar con el descuento actual si existe
    final sellProvider = Provider.of<SellProvider>(context, listen: false);
    if (sellProvider.ticket.discount > 0) {
      // Restaurar el estado del descuento
      _isPercentage = sellProvider.ticket.discountIsPercentage;
      _discountController.text = sellProvider.ticket.discount.toString();
    }
  }

  @override
  void dispose() {
    _discountController.dispose();
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
                // Información del total
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colorScheme.outline.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total antes del descuento',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        Publications.getFormatoPrecio(value: totalTicket),
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Tipo de descuento (porcentaje o monto fijo)
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
                      child: _buildDiscountTypeOption(
                        title: 'Monto fijo',
                        icon: Icons.attach_money_rounded,
                        isSelected: !_isPercentage,
                        onTap: () => setState(() => _isPercentage = false),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildDiscountTypeOption(
                        title: 'Porcentaje',
                        icon: Icons.percent_rounded,
                        isSelected: _isPercentage,
                        onTap: () => setState(() => _isPercentage = true),
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

                InputTextField(
                  controller: _discountController,
                  labelText: _isPercentage ? 'Porcentaje (%)' : 'Monto (\$)',
                  hintText: _isPercentage ? 'Ej: 10' : 'Ej: 50.00',
                  prefixIcon: Icon(_isPercentage
                      ? Icons.percent_rounded
                      : Icons.attach_money_rounded),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingrese un valor';
                    }

                    final numValue = double.tryParse(value);
                    if (numValue == null || numValue < 0) {
                      return 'Ingrese un valor válido mayor a 0';
                    }

                    if (_isPercentage && numValue > 100) {
                      return 'El porcentaje no puede ser mayor a 100%';
                    }

                    if (!_isPercentage && numValue > totalTicket) {
                      return 'El descuento no puede ser mayor al total';
                    }

                    return null;
                  },
                  onChanged: (value) {
                    setState(() {}); // Para actualizar el preview
                  },
                ),

                const SizedBox(height: 20),

                // Preview del descuento
                if (_discountController.text.isNotEmpty)
                  _buildDiscountPreview(totalTicket, theme, colorScheme),
              ],
            ),
          ),
          actions: [
            AppTextButton(
              text: 'Cancelar',
              onPressed: () => Navigator.of(context).pop(),
            ),

            // Botón para limpiar descuento si ya existe uno
            if (sellProvider.ticket.discount > 0)
              AppTextButton(
                text: 'Quitar descuento',
                onPressed: () {
                  sellProvider.setDiscount(discount: 0.0, isPercentage: false);
                  Navigator.of(context).pop();
                },
                foregroundColor: colorScheme.error,
              ),

            AppButton(
              text: 'Aplicar descuento',
              onPressed: () =>
                  _applyDiscount(context, sellProvider, totalTicket),
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              margin: EdgeInsets.zero,
              width: null,
            ),
          ],
        );
      },
    );
  }

  Widget _buildDiscountTypeOption({
    required String title,
    String subtitle = '',
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
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primaryContainer.withValues(alpha: 0.3)
              : colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? colorScheme.primary.withValues(alpha: 0.5)
                : colorScheme.outline.withValues(alpha: 0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.onSurface.withValues(alpha: 0.6),
                size: 28,
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.onSurface,
                    ),
                  ),
                  if (subtitle.isNotEmpty) const SizedBox(width: 4),
                  if (subtitle.isNotEmpty)
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isSelected
                            ? colorScheme.primary.withValues(alpha: 0.8)
                            : colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDiscountPreview(
      double totalTicket, ThemeData theme, ColorScheme colorScheme) {
    final discountValue = double.tryParse(_discountController.text) ?? 0;
    if (discountValue <= 0) return const SizedBox.shrink();

    final discountAmount =
        _isPercentage ? (totalTicket * discountValue / 100) : discountValue;

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
                Publications.getFormatoPrecio(value: totalTicket),
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
                'Descuento${_isPercentage ? ' ($discountValue%)' : ''}:',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.error,
                ),
              ),
              Text(
                '- ${Publications.getFormatoPrecio(value: discountAmount)}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: colorScheme.error,
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
                Publications.getFormatoPrecio(value: finalTotal),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _applyDiscount(
      BuildContext context, SellProvider sellProvider, double totalTicket) {
    if (!_formKey.currentState!.validate()) return;

    final discountValue = double.tryParse(_discountController.text) ?? 0;
    if (discountValue <= 0) return;

    // Aplicar el descuento con la información completa
    sellProvider.setDiscount(
        discount: discountValue, isPercentage: _isPercentage);

    // Mostrar confirmación
    final discountAmount =
        _isPercentage ? (totalTicket * discountValue / 100) : discountValue;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Descuento de ${Publications.getFormatoPrecio(value: discountAmount)} aplicado',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );

    Navigator.of(context).pop();
  }
}

/// Función helper para mostrar el diálogo de descuento
Future<void> showDiscountDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (context) => const DiscountDialog(),
  );
}
