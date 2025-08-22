import 'package:flutter/material.dart';
import 'package:sellweb/presentation/widgets/dialogs/base/base_dialog.dart';
import 'package:sellweb/presentation/widgets/dialogs/base/standard_dialogs.dart';
import 'package:sellweb/presentation/widgets/dialogs/components/dialog_components.dart';
import '../../../../core/utils/fuctions.dart';

/// Ejemplo de diálogo modernizado usando los nuevos componentes estándar
///
/// Este ejemplo muestra cómo crear un diálogo complejo siguiendo
/// la guía de Material Design 3 implementada
class ExampleModernDialog extends StatefulWidget {
  const ExampleModernDialog({
    super.key,
    required this.productName,
    required this.currentPrice,
  });

  final String productName;
  final double currentPrice;

  @override
  State<ExampleModernDialog> createState() => _ExampleModernDialogState();
}

class _ExampleModernDialogState extends State<ExampleModernDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.productName;
    _priceController.text = widget.currentPrice.toString();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BaseDialog(
      title: 'Editar Producto',
      icon: Icons.edit_rounded,
      width: 500,
      content: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sección de información actual
            DialogComponents.infoSection(
              context: context,
              title: 'Información Actual',
              icon: Icons.info_outline_rounded,
              content: Column(
                children: [
                  DialogComponents.infoRow(
                    context: context,
                    label: 'Producto',
                    value: widget.productName,
                    icon: Icons.label_outline,
                  ),
                  DialogComponents.minSpacing,
                  DialogComponents.infoRow(
                    context: context,
                    label: 'Precio Actual',
                    value: Publications.getFormatoPrecio(
                        value: widget.currentPrice),
                    icon: Icons.monetization_on_outlined,
                  ),
                ],
              ),
            ),

            DialogComponents.sectionSpacing,

            // Formulario de edición
            Text(
              'Nuevos Datos',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            DialogComponents.itemSpacing,

            DialogComponents.textField(
              context: context,
              controller: _nameController,
              label: 'Nombre del Producto',
              prefixIcon: Icons.label_outline,
              validator: (value) {
                if (value?.isEmpty == true) return 'El nombre es requerido';
                return null;
              },
            ),

            DialogComponents.itemSpacing,

            DialogComponents.textField(
              context: context,
              controller: _priceController,
              label: 'Precio',
              prefixIcon: Icons.monetization_on_outlined,
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value?.isEmpty == true) return 'El precio es requerido';
                final price = double.tryParse(value!);
                if (price == null || price <= 0) return 'Precio inválido';
                return null;
              },
            ),

            DialogComponents.sectionSpacing,

            // Resumen de cambios si hay diferencias
            if (_hasChanges())
              DialogComponents.summaryContainer(
                context: context,
                label: 'Nuevo Precio',
                value:
                    Publications.getFormatoPrecio(value: _getNewPrice() ?? 0.0),
                icon: Icons.trending_up_rounded,
              ),
          ],
        ),
      ),
      actions: [
        DialogComponents.secondaryActionButton(
          context: context,
          text: 'Cancelar',
          icon: Icons.cancel_outlined,
          onPressed: () => Navigator.of(context).pop(),
        ),
        DialogComponents.primaryActionButton(
          context: context,
          text: 'Guardar Cambios',
          icon: Icons.save_rounded,
          onPressed: _hasChanges() ? _saveChanges : null,
          isLoading: _isLoading,
        ),
      ],
    );
  }

  bool _hasChanges() {
    return _nameController.text != widget.productName ||
        _getNewPrice() != widget.currentPrice;
  }

  double? _getNewPrice() {
    return double.tryParse(_priceController.text);
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    // Confirmar cambios importantes
    if (_getNewPrice()! > widget.currentPrice * 1.5) {
      final confirmed = await showConfirmationDialog(
        context: context,
        title: 'Aumento Significativo',
        message: 'El precio aumentará más del 50%. ¿Continuar?',
        icon: Icons.warning_amber_rounded,
        confirmText: 'Sí, continuar',
        isDestructive: false,
      );

      if (confirmed != true) return;
    }

    setState(() => _isLoading = true);

    try {
      // Simular guardado
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        Navigator.of(context).pop({
          'name': _nameController.text,
          'price': _getNewPrice(),
        });

        // Mostrar confirmación
        showInfoDialog(
          context: context,
          title: 'Guardado Exitoso',
          message: 'Los cambios se han guardado correctamente.',
          icon: Icons.check_circle_outline_rounded,
        );
      }
    } catch (e) {
      if (mounted) {
        showErrorDialog(
          context: context,
          title: 'Error al Guardar',
          message: 'No se pudieron guardar los cambios.',
          details: e.toString(),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}

/// Helper function para mostrar el diálogo de ejemplo
Future<Map<String, dynamic>?> showExampleModernDialog({
  required BuildContext context,
  required String productName,
  required double currentPrice,
}) {
  return showDialog<Map<String, dynamic>>(
    context: context,
    builder: (context) => ExampleModernDialog(
      productName: productName,
      currentPrice: currentPrice,
    ),
  );
}

/// Ejemplo de migración: Diálogo simple antes vs después
class MigrationExample {
  /// ❌ ANTES - Diálogo sin estándares
  static Widget oldDialog(BuildContext context) {
    return AlertDialog(
      title: const Text('Confirmar'),
      content: const Text('¿Estás seguro?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Confirmar'),
        ),
      ],
    );
  }

  /// ✅ DESPUÉS - Usando componentes estándar
  static Future<bool?> newDialog(BuildContext context) {
    return showConfirmationDialog(
      context: context,
      title: 'Confirmar Acción',
      message: '¿Estás seguro de que deseas continuar?',
      icon: Icons.help_outline_rounded,
      confirmText: 'Confirmar',
      cancelText: 'Cancelar',
    );
  }

  /// Ejemplo de diálogo complejo con componentes estándar
  static Future<void> complexDialog(BuildContext context) {
    return showBaseDialog(
      context: context,
      title: 'Detalles de Venta',
      icon: Icons.point_of_sale_rounded,
      width: 450,
      content: Column(
        children: [
          DialogComponents.infoSection(
            context: context,
            title: 'Información del Cliente',
            icon: Icons.person_outline,
            content: Column(
              children: [
                DialogComponents.infoRow(
                  context: context,
                  label: 'Nombre',
                  value: 'Juan Pérez',
                ),
                DialogComponents.itemSpacing,
                DialogComponents.infoRow(
                  context: context,
                  label: 'Teléfono',
                  value: '+52 555 123 4567',
                ),
              ],
            ),
          ),
          DialogComponents.sectionSpacing,
          DialogComponents.itemList(
            context: context,
            items: [
              DialogComponents.infoRow(
                context: context,
                label: 'Producto A',
                value: '\$25.00',
              ),
              DialogComponents.infoRow(
                context: context,
                label: 'Producto B',
                value: '\$30.00',
              ),
            ],
          ),
          DialogComponents.sectionSpacing,
          DialogComponents.summaryContainer(
            context: context,
            label: 'Total',
            value: '\$55.00',
            icon: Icons.monetization_on_outlined,
          ),
        ],
      ),
      actions: [
        DialogComponents.secondaryActionButton(
          context: context,
          text: 'Cancelar',
          onPressed: () => Navigator.of(context).pop(),
        ),
        DialogComponents.primaryActionButton(
          context: context,
          text: 'Procesar Venta',
          icon: Icons.shopping_cart_checkout_rounded,
          onPressed: () {
            // Lógica de procesamiento
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}
