import 'package:flutter/material.dart';
import 'package:sellweb/core/widgets/dialogs/base/base_dialog.dart';
import 'package:sellweb/core/widgets/dialogs/components/dialog_components.dart';
import 'package:sellweb/core/widgets/inputs/money_input_text_field.dart';
import 'package:sellweb/core/utils/fuctions.dart';

/// Diálogo para crear un nuevo producto con información básica
/// Requiere precio y descripción obligatorios antes de crear el producto
/// se guardará en la base de datos pública, se agregará al catálogo de la cuenta y al ticket actual
class CreateProductDialog extends StatefulWidget {
  final String code;
  final Function(String description, double price) onCreateProduct;

  const CreateProductDialog({
    super.key,
    required this.code,
    required this.onCreateProduct,
  });

  @override
  State<CreateProductDialog> createState() => _CreateProductDialogState();
}

class _CreateProductDialogState extends State<CreateProductDialog> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _priceController = AppMoneyTextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BaseDialog(
      title: 'Crear Producto Nuevo',
      icon: Icons.add_business_outlined,
      width: 400,
      headerColor: theme.colorScheme.primaryContainer,
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Código escaneado - versión compacta
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.qr_code_scanner,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Código: ',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        widget.code,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Campo de descripción
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  hintText: 'Descripción',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                validator: (value) { 
                  if (value == null || value.trim().length < 3) {
                    return 'La descripción debe tener al menos 3 caracteres';
                  }
                  return null;
                },
              ), 

              const SizedBox(height: 16),

              // Campo de precio
              MoneyInputTextField(
                controller: _priceController,
                autofocus: false,
                onChanged: (value) {
                  setState(() {});
                },
              ),

              // Error de precio - solo mostrar cuando hay valor ingresado
              if (_priceController.text.isNotEmpty && _priceController.doubleValue <= 0)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'El precio debe ser mayor a \$0',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ),

              DialogComponents.sectionSpacing,

              // Nota informativa profesional
              DialogComponents.infoSection(
                context: context,
                title: 'Información Importante',
                icon: Icons.cloud_upload_outlined,
                backgroundColor: theme.colorScheme.secondaryContainer.withValues(alpha: 0.3),
                content: RichText(
                  text: TextSpan(
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    children: [
                      const TextSpan(
                        text: 'El producto se ',
                      ),
                      TextSpan(
                        text: 'creará en la base de datos pública',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const TextSpan(
                        text: ', se agregará el ',
                      ),
                      TextSpan(
                        text: 'producto (referencia) en su catálogo',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const TextSpan(
                        text: ' y se incluirá automáticamente en el ticket actual',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        DialogComponents.secondaryActionButton(
          context: context,
          text: 'Cancelar',
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
        ),
        DialogComponents.primaryActionButton(
          context: context,
          text: 'Crear Producto',
          icon: Icons.add_rounded,
          isLoading: _isLoading,
          onPressed: _canCreate() ? _createProduct : null,
        ),
      ],
    );
  }

  bool _canCreate() {
    return _descriptionController.text.trim().length >= 3 &&
           _priceController.doubleValue > 0 &&
           !_isLoading;
  }

  Future<void> _createProduct() async {
    // --- Validación de formulario y creación del producto---
    if (!_formKey.currentState!.validate()) return;
    if (_priceController.doubleValue <= 0) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // --- creación del producto ---
      await widget.onCreateProduct(
        _descriptionController.text.trim(),
        _priceController.doubleValue,
      );
      
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Error al crear producto: $e',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }
}

/// Helper function para mostrar el diálogo de crear producto
Future<void> showCreateProductDialog(
  BuildContext context, {
  required String code,
  required Function(String description, double price) onCreateProduct,
}) {
  return showDialog(
    context: context,
    barrierDismissible: false, // No permitir cerrar tocando fuera
    builder: (context) => CreateProductDialog(
      code: code,
      onCreateProduct: onCreateProduct,
    ),
  );
}
