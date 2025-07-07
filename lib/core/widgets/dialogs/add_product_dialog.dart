import 'package:flutter/material.dart';
import 'package:sellweb/core/utils/fuctions.dart';
import 'package:sellweb/core/widgets/inputs/input_text_field.dart';
import 'package:sellweb/core/widgets/inputs/money_input_text_field.dart';
import 'package:sellweb/core/widgets/ui/image_widget.dart';
import 'package:sellweb/core/widgets/ui/dividers.dart';
import 'package:sellweb/domain/entities/catalogue.dart';
import 'package:sellweb/presentation/providers/sell_provider.dart';
import 'package:sellweb/presentation/providers/catalogue_provider.dart';
import 'package:sellweb/presentation/providers/auth_provider.dart';
import 'package:provider/provider.dart' as provider_package;

/// Muestra un diálogo para agregar un producto al catálogo o crear uno nuevo
Future<void> showAddProductDialog(
  BuildContext context, {
  required ProductCatalogue product, 
  String? errorMessage,
  bool isNew = false,
}) async {
  // Variables
  bool checkAddCatalogue = true;
  final priceController = AppMoneyTextEditingController(); 
  final descriptionController = TextEditingController(text: product.description); 
  String? errorText = errorMessage;
  
  // Proveedores
  final sellProvider = provider_package.Provider.of<SellProvider>(context, listen: false);
  final catalogueProvider = provider_package.Provider.of<CatalogueProvider>(context, listen: false);
  final authProvider = provider_package.Provider.of<AuthProvider>(context, listen: false);

  await showDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        
        // Colores para el checkbox
        Color checkActiveColor = checkAddCatalogue 
            ? colorScheme.primary
            : colorScheme.onSurface.withValues(alpha: 0.5);
        
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: colorScheme.surface,
          title: Row(
            children: [
              Expanded(
                child: Text(
                  isNew ? 'Crear producto' : 'Nuevo producto',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: isNew ? Colors.orange : null,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          content: SingleChildScrollView(  
            child: Column(  
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [ 
                // Código del producto
                _buildProductCodeSection(product),
                
                // Información del producto (solo si no es nuevo)
                if (!isNew) _buildProductInfoSection(product),
                
                // Campo de descripción para productos nuevos
                if (isNew) ...[
                  InputTextField(
                    controller: descriptionController,
                    labelText: 'Descripción del producto',
                    hintText: 'Ingrese una descripción',
                    errorText: errorText,
                  ),
                  const SizedBox(height: 20),
                ],
                
                // Campo de precio
                MoneyInputTextField(
                  controller: priceController,
                  labelText: 'Precio de venta',
                  autofocus: true,
                  onChanged: (_) {
                    setState(() {
                      errorText = null;
                    });
                  },
                ),
                
                const SizedBox(height: 12),
                
                // Checkbox para agregar al catálogo
                _buildCatalogueCheckbox(
                  checkAddCatalogue, 
                  checkActiveColor, 
                  colorScheme,
                  (value) {
                    setState(() {
                      checkAddCatalogue = value ?? false;
                    });
                  },
                ),
                
                // Mostrar error si existe
                if (errorText != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      errorText!, 
                      style: TextStyle(color: colorScheme.error),
                    ),
                  ), 
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton.icon(
              icon: const Icon(Icons.add_circle_outline_sharp),
              label: Text(isNew ? 'Crear' : 'Agregar'),
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                textStyle: theme.textTheme.labelLarge,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => _processAddProduct(
                context,
                setState,
                product,
                priceController,
                descriptionController,
                checkAddCatalogue,
                isNew,
                sellProvider,
                catalogueProvider,
                authProvider,
              ),
            ),
          ],
        );
      },
    ),
  );
}

Widget _buildProductCodeSection(ProductCatalogue product) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 16.0),
    child: Row(
      children: [
        const Icon(Icons.qr_code, size: 22, color: Colors.grey),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            product.code.isNotEmpty ? product.code : 'Sin código',
            style: const TextStyle(fontSize: 16),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ),
  );
}

Widget _buildProductInfoSection(ProductCatalogue product) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 30, top: 20),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Imagen del producto
        ProductImage(
          imageUrl: product.image,
          size: 50,
        ),
        const SizedBox(width: 16),
        Flexible(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Descripción del producto
                if (product.description.isNotEmpty)
                  Text(
                    product.description,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 8),
                // Información de marca
                if (product.nameMark.isNotEmpty) ...[
                  Row(
                    children: [
                      Text(
                        product.nameMark,
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (product.nameMark.isNotEmpty) ...[
                        const SizedBox(width: 4),
                        const DotDivider(size: 4),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _buildCatalogueCheckbox(
  bool checkAddCatalogue,
  Color checkActiveColor,
  ColorScheme colorScheme,
  ValueChanged<bool?> onChanged,
) {
  return Container(
    decoration: BoxDecoration(
      border: Border.all(color: checkActiveColor, width: 0.5),
      color: checkAddCatalogue ? checkActiveColor.withValues(alpha: 0.2) : null,
      borderRadius: BorderRadius.circular(5),
    ), 
    child: CheckboxListTile(
      title: const Text('Agregar al catálogo'),
      value: checkAddCatalogue,
      onChanged: onChanged,
      controlAffinity: ListTileControlAffinity.leading,
    ),
  );
}

Future<void> _processAddProduct(
  BuildContext context,
  StateSetter setState,
  ProductCatalogue product,
  AppMoneyTextEditingController priceController,
  TextEditingController descriptionController,
  bool checkAddCatalogue,
  bool isNew,
  SellProvider sellProvider,
  CatalogueProvider catalogueProvider,
  AuthProvider authProvider,
) async {
  final price = priceController.doubleValue;
  
  // Validar precio
  if (price <= 0) {
    setState(() {
      // errorText = 'Ingrese un precio válido';
    });
    return;
  }

  // Validar descripción para producto nuevo
  if (isNew && descriptionController.text.trim().isEmpty) {
    setState(() {
      // errorText = 'Ingrese una descripción válida';
    });
    return;
  }

  try {
    // Crear producto actualizado
    final updatedProduct = product.copyWith(
      description: isNew ? descriptionController.text.trim() : product.description,
      code: product.code,
      salePrice: price,
    );

    // Agregar al ticket
    sellProvider.addProductsticket(updatedProduct);
    Navigator.of(context).pop();

    // Procesar en segundo plano
    if (isNew) {
      await _createNewProduct(
        context,
        product,
        updatedProduct,
        checkAddCatalogue,
        catalogueProvider,
        authProvider,
      );
    } else if (checkAddCatalogue && updatedProduct.id.isNotEmpty) {
      await _addExistingProduct(
        context,
        product,
        updatedProduct,
        catalogueProvider,
      );
    }
  } catch (e) {
    setState(() {
      // errorText = 'Error inesperado: ${e.toString()}';
    });
  }
}

Future<void> _createNewProduct(
  BuildContext context,
  ProductCatalogue originalProduct,
  ProductCatalogue updatedProduct,
  bool addToCatalogue,
  CatalogueProvider catalogueProvider,
  AuthProvider authProvider,
) async {
  try {
    final publicProduct = Product(
      id: updatedProduct.id.isEmpty 
          ? 'prod_${DateTime.now().millisecondsSinceEpoch}' 
          : updatedProduct.id,
      code: updatedProduct.code,
      description: updatedProduct.description,
      image: updatedProduct.image,
      idMark: updatedProduct.idMark,
      nameMark: updatedProduct.nameMark,
      imageMark: updatedProduct.imageMark,
      creation: Utils().getTimestampNow(),
      upgrade: Utils().getTimestampNow(),
      idUserCreation: authProvider.user?.email ?? '',
      idUserUpgrade: authProvider.user?.email ?? '',
      verified: false,
      reviewed: false,
      favorite: false,
      followers: 0,
    );
    
    await catalogueProvider.createPublicProduct(publicProduct);
    
    if (addToCatalogue) {
      final finalProduct = updatedProduct.copyWith(id: publicProduct.id);
      await catalogueProvider.addProductToCatalogue(finalProduct);
    }
  } catch (e) {
    // Reabrir diálogo con error si falla
    if (context.mounted) {
      showAddProductDialog(
        context, 
        product: originalProduct, 
        errorMessage: 'Error al crear producto público: ${e.toString()}',
        isNew: true,
      );
    }
  }
}

Future<void> _addExistingProduct(
  BuildContext context,
  ProductCatalogue originalProduct,
  ProductCatalogue updatedProduct,
  CatalogueProvider catalogueProvider,
) async {
  try {
    await catalogueProvider.addProductToCatalogue(updatedProduct);
  } catch (e) {
    // Reabrir diálogo con error si falla
    if (context.mounted) {
      showAddProductDialog(
        context, 
        product: originalProduct, 
        errorMessage: 'Error al guardar en el catálogo: ${e.toString()}',
        isNew: false,
      );
    }
  }
}
