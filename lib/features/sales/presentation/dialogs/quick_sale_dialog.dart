import 'package:flutter/material.dart';
import '../../../../../core/core.dart';
import 'package:sellweb/features/sales/presentation/providers/sales_provider.dart';

/// Diálogo modernizado para venta rápida siguiendo Material Design 3
///
/// En pantallas pequeñas (< 600px) con fullView=true, se muestra en pantalla completa.
/// En pantallas grandes, siempre se muestra como diálogo modal.
class QuickSaleDialog extends StatefulWidget {
  const QuickSaleDialog({
    super.key,
    required this.provider,
    this.fullView = false,
  });

  final SalesProvider provider;
  final bool fullView;

  @override
  State<QuickSaleDialog> createState() => _QuickSaleDialogState();
}

class _QuickSaleDialogState extends State<QuickSaleDialog> {
  final _formKey = GlobalKey<FormState>();
  final _priceController = AppMoneyTextEditingController();
  final _descriptionController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');

  // FocusNodes para navegación por teclado
  final _priceFocusNode = FocusNode();
  final _descriptionFocusNode = FocusNode();
  final _quantityFocusNode = FocusNode();

  // Unidades disponibles
  final List<String> _units = ['unidad', 'kilogramo', 'litro'];
  String _selectedUnit = 'unidad';

  bool _isProcessing = false;
  bool _showPriceError = false;

  /// Devuelve la etiqueta dinámica del monto según la unidad seleccionada
  String _getMountLabel() {
    switch (_selectedUnit) {
      case 'kilogramo':
        return 'Monto por kg';
      case 'litro':
        return 'Monto por litro';
      case 'unidad':
      default:
        return 'Monto por unidad';
    }
  }

  /// Devuelve el símbolo de la unidad
  String _getUnitSymbol() {
    switch (_selectedUnit) {
      case 'kilogramo':
        return 'kg';
      case 'litro':
        return 'L';
      case 'unidad':
      default:
        return 'u';
    }
  }


  @override
  void dispose() {
    _priceController.dispose();
    _descriptionController.dispose();
    _quantityController.dispose();
    _priceFocusNode.dispose();
    _descriptionFocusNode.dispose();
    _quantityFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BaseDialog(
      title: 'Venta Rápida',
      icon: Icons.flash_on_rounded,
      fullView: widget.fullView,
      content: _buildContent(context),
      actions: [], // Botón movido dentro del content para mejor UX con teclado
    );
  }

  Widget _buildContent(BuildContext context) {
    final hasValidAmount =
        _priceController.text.isNotEmpty && _priceController.doubleValue > 0;

    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DialogComponents.sectionSpacing,
            // Campo de monto con etiqueta dinámica
            DialogComponents.moneyField(
              autofocus: true,
              context: context,
              controller: _priceController,
              focusNode: _priceFocusNode,
              nextFocusNode: _quantityFocusNode,
              textInputAction: TextInputAction.next,
              fontSize: 30,
              label: _getMountLabel(), // Etiqueta dinámica según unidad
              hint: '\$0.0',
              errorText: _showPriceError &&
                      (_priceController.text.isEmpty ||
                          _priceController.doubleValue <= 0)
                  ? 'El precio es obligatorio y debe ser mayor a 0'
                  : null,
              onChanged: (value) {
                setState(() {
                  if (_showPriceError && value > 0) {
                    _showPriceError = false;
                  }
                });
              },
            ),
            DialogComponents.itemSpacing,
            // Selección de Unidad
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Unidad de medida',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8.0,
                  runSpacing: 4.0,
                  children: _units.map((unit) {
                    final isSelected = _selectedUnit == unit;
                    return ChoiceChip(
                      label: Text(
                        unit[0].toUpperCase() + unit.substring(1),
                        style: TextStyle(
                          fontSize: 12,
                          color: isSelected ? Colors.white : null,
                        ),
                      ),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedUnit = unit;
                            // Resetear cantidad a 1 al cambiar unidad
                            _quantityController.text = '1';
                          });
                        }
                      },
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      selectedColor: Theme.of(context).colorScheme.primary,
                      backgroundColor: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest
                          .withValues(alpha: 0.5),
                    );
                  }).toList(),
                ),
              ],
            ),
            DialogComponents.itemSpacing,
            // Campo de cantidad con controles (+/-)
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Botón Decrementar
                _buildQuantityControlBtn(
                  context,
                  icon: Icons.remove,
                  onTap: _decreaseQuantity,
                ),
                const SizedBox(width: 8),
                // Input Cantidad
                Expanded(
                  child: DialogComponents.textField(
                    context: context,
                    controller: _quantityController,
                    focusNode: _quantityFocusNode,
                    nextFocusNode: _descriptionFocusNode,
                    textInputAction: TextInputAction.next,
                    label: 'Cantidad (${_getUnitSymbol()})',
                    hint: '1',
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      // Cantidad opcional, se asume 1 si está vacío
                      if (value == null || value.isEmpty) return null;
                      final quantity =
                          double.tryParse(value.replaceAll(',', '.'));
                      if (quantity == null || quantity <= 0) {
                        return 'Inválido';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                // Botón Incrementar
                _buildQuantityControlBtn(
                  context,
                  icon: Icons.add,
                  onTap: _increaseQuantity,
                ),
              ],
            ),
            DialogComponents.itemSpacing,
            // Campo de descripción
            DialogComponents.textField(
              context: context,
              controller: _descriptionController,
              focusNode: _descriptionFocusNode,
              textInputAction: TextInputAction.done,
              label: 'Descripción (Opcional)',
              hint: 'Ej: bebida, snack, etc.',
              onEditingComplete: () {
                _processQuickSale();
              },
              onSuffixPressed: () => _showPriceError = false,
            ),
            DialogComponents.sectionSpacing,
            // Vista previa del total calculado
            _buildTotalPreview(context),
            DialogComponents.sectionSpacing,
            // Botón al final dentro del scroll (mejor UX con teclado)
            DialogComponents.primaryActionButton(
              context: context,
              text: 'Agregar',
              onPressed: hasValidAmount ? _processQuickSale : null,
              isLoading: _isProcessing,
            ),
            DialogComponents.itemSpacing,
          ],
        ),
      ),
    );
  }

  /// Muestra una vista previa del cálculo total en tiempo real
  Widget _buildTotalPreview(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_priceController, _quantityController]),
      builder: (context, _) {
        final price = _priceController.doubleValue;
        final quantityText = _quantityController.text.replaceAll(',', '.');
        final quantity = double.tryParse(quantityText) ?? 0.0;
        final total = price * quantity;


        if (price <= 0 || quantity <= 0) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context)
                .colorScheme
                .primaryContainer
                .withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context)
                  .colorScheme
                  .primary
                  .withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Estimado',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    '${CurrencyFormatter.formatPrice(value: price)} x ${UnitHelper.formatQuantityAdaptive(quantity, _selectedUnit)}',
                    style: TextStyle(
                      fontSize: 10,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
              Text(
                CurrencyFormatter.formatPrice(value: total),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _processQuickSale() async {
    // Validar que el precio no esté vacío y sea mayor a 0
    if (_priceController.text.isEmpty || _priceController.doubleValue <= 0) {
      setState(() {
        _showPriceError = true;
      });
      return;
    }

    // Validar formulario antes de proceder
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final price = _priceController.doubleValue;
      var description = _descriptionController.text.trim();
      
      // Si la descripción está vacía, usar un valor por defecto descriptivo
      if (description.isEmpty) {
        description = 'Venta Rápida';
      }
      
      final quantity =
          double.tryParse(_quantityController.text.replaceAll(',', '.')) ??
              1.0;

      // Agregar el producto de venta rápida con cantidad
      await widget.provider.addQuickProduct(
        description: description,
        salePrice: price,
        unit: _selectedUnit,
        quantity: quantity,
      );

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        showErrorDialog(
          context: context,
          title: 'Error',
          message: 'No se pudo agregar el producto de venta rápida.',
          details: e.toString(),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  // MÉTODOS DE UI Y LÓGICA DE CANTIDAD

  Widget _buildQuantityControlBtn(
    BuildContext context, {
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Icon(
              icon,
              size: 24,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      ),
    );
  }

  void _increaseQuantity() {
    final step = UnitHelper.isFractionalUnit(_selectedUnit) ? 0.1 : 1.0;
    final currentText = _quantityController.text.replaceAll(',', '.');
    final current = double.tryParse(currentText) ?? 0;
    _updateQuantity(current + step);
  }

  void _decreaseQuantity() {
    final step = UnitHelper.isFractionalUnit(_selectedUnit) ? 0.1 : 1.0;
    final minVal = UnitHelper.isFractionalUnit(_selectedUnit) ? 0.1 : 1.0;
    final currentText = _quantityController.text.replaceAll(',', '.');
    final current = double.tryParse(currentText) ?? 0;
    if (current > minVal) {
      _updateQuantity(current - step);
    }
  }

  void _updateQuantity(double newValue) {
    if (newValue <= 0) return;

    // Evitar errores de precisión flotante (ej: 0.300000004)
    final roundedValue = double.parse(newValue.toStringAsFixed(2));

    // Si es entero, mostrar sin decimales
    if (roundedValue % 1 == 0) {
      _quantityController.text = roundedValue.toInt().toString();
    } else {
      // Si tiene decimales, mostrar con hasta 2 decimales limpios
      String text = roundedValue.toStringAsFixed(2);
      if (text.endsWith('0')) text = text.substring(0, text.length - 1);
      if (text.endsWith('0')) text = text.substring(0, text.length - 1);
      if (text.endsWith('.')) text = text.substring(0, text.length - 1);
      _quantityController.text = text;
    }
  }
}

/// Helper function para mostrar el diálogo de venta rápida
///
/// **Parámetros:**
/// - `context`: BuildContext necesario para mostrar el diálogo
/// - `provider`: SalesProvider para agregar el producto de venta rápida
/// - `fullView`: Si es true, se muestra en pantalla completa en dispositivos pequeños (default: true)
///
/// **Ejemplo:**
/// ```dart
/// await showQuickSaleDialog(
///   context,
///   provider: salesProvider,
///   fullView: true,
/// );
/// ```
Future<void> showQuickSaleDialog(
  BuildContext context, {
  required SalesProvider provider,
  bool fullView = true,
}) {
  final isSmallScreen = MediaQuery.of(context).size.width < 600;

  // Si es vista completa Y pantalla pequeña, usar Navigator.push
  if (fullView && isSmallScreen) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => QuickSaleDialog(
          provider: provider,
          fullView: fullView,
        ),
      ),
    );
  }

  // Vista normal como diálogo
  return showDialog(
    barrierDismissible: false,
    context: context,
    builder: (context) => QuickSaleDialog(
      provider: provider,
      fullView: fullView,
    ),
  );
}
