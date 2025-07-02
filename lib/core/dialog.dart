import 'package:flutter/material.dart';
import 'package:sellweb/core/utils/fuctions.dart';
import 'package:sellweb/core/widgets/money_input_text_field.dart';
import 'package:sellweb/domain/entities/catalogue.dart';
import 'package:sellweb/presentation/providers/sell_provider.dart';
import 'package:sellweb/presentation/providers/catalogue_provider.dart';
import 'package:sellweb/presentation/providers/auth_provider.dart';
import 'package:provider/provider.dart' as provider_package;

/// Muestra un diálogo para agregar un producto al catálogo o crear uno nuevo en la base pública
Future<void> showDialogAgregarProductoPublico(
  BuildContext context, {
  required ProductCatalogue product, 
  String? errorMessage,
  bool isNew = false, // true: crear producto nuevo en base pública, false: agregar existente al catálogo
}) async {
  // Variables
  bool checkAddCatalogue = true; // Checkbox para agregar al catálogo 
  final priceController = AppMoneyTextEditingController(); 
  final descriptionController = TextEditingController(text: product.description); 
  String? errorText = errorMessage;
  var checkActiveColor = Theme.of(context).colorScheme.primary.withAlpha(128);
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
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: theme.colorScheme.surface,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: isNew ? Colors.blue.withAlpha(38) : Colors.green.withAlpha(38),
                child: Icon(
                  isNew ? Icons.add_circle : Icons.cloud_download, 
                  color: isNew ? Colors.blue : Colors.green, 
                  size: 26
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  isNew ? 'Crear nuevo producto' : 'Producto encontrado',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [ 
                Padding(
                  padding: const EdgeInsets.all(30.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Avatar circular con la inicial del producto o imagen si existe
                      CircleAvatar(
                        radius: 25,
                        backgroundImage: product.image.isNotEmpty ? NetworkImage(product.image) : null,
                        child: product.image.isEmpty ? Text(product.description.isNotEmpty ? product.description[0] : '?') : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Campo de descripción editable si isNew
                              if (isNew)
                                TextField(
                                  controller: descriptionController,
                                  decoration: const InputDecoration(
                                    labelText: 'Descripción del producto',
                                    border: OutlineInputBorder(),
                                  ),
                                  maxLines: 2,
                                  onChanged: (_) {
                                    setState(() {
                                      errorText = null;
                                    });
                                  },
                                )
                              else
                                Text(
                                  product.description,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              const SizedBox(height: 8),
                              // Información de marca y código
                              Row(
                                children: [
                                  // text : marca del producto
                                  if (product.nameMark.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: Text(
                                        product.nameMark,
                                        style: TextStyle(
                                          color: Colors.grey.shade700,
                                          fontSize: 14,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  // icon divisor punto 
                                  if (product.nameMark.isNotEmpty)
                                    const Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 4.0),
                                      child: Icon(Icons.circle, size: 4, color: Colors.grey),
                                    ), 
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                MoneyInputTextField(
                  controller: priceController,
                  labelText: 'Precio de venta',
                  autofocus: true,
                  style: theme.textTheme.titleLarge,
                  onChanged: (_) {
                    setState(() {
                      errorText = null;
                    });
                  },
                ),
                const SizedBox(height: 12),
                // Checkbox para agregar al catálogo
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: checkActiveColor, width: 0.5),
                    color: checkAddCatalogue ? checkActiveColor.withAlpha(51) : null,
                    borderRadius: BorderRadius.circular(5)
                  ), 
                  child: CheckboxListTile(
                    title: const Text('Agregar al catálogo'),
                    value: checkAddCatalogue,
                    onChanged: (bool? value) { 
                      setState(() {
                        checkAddCatalogue = value ?? false;
                        checkActiveColor = value == true
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurface.withAlpha(128);
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ), 
                if (errorText != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(errorText!, style: TextStyle(color: theme.colorScheme.error)),
                  ),
                const SizedBox(height: 24),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            FilledButton.icon(
              icon: Icon(isNew ? Icons.add_circle : Icons.add),
              label: Text(isNew ? 'Crear' : 'Agregar'),
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                textStyle: theme.textTheme.labelLarge,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                final price = priceController.doubleValue;
                if (price <= 0) {
                  setState(() {
                    errorText = 'Ingrese un precio válido';
                  });
                  return;
                }

                // Validaciones para producto nuevo
                if (isNew) {
                  if (descriptionController.text.trim().isEmpty) {
                    setState(() {
                      errorText = 'Ingrese una descripción válida';
                    });
                    return;
                  } 
                }

                try {
                  // Crear producto actualizado con datos del formulario
                  final updatedProduct = product.copyWith(
                    description: isNew ? descriptionController.text.trim() : product.description,
                    code: product.code,
                    salePrice: price,
                  );

                  // Agregar siempre a la lista de productos seleccionados del ticket
                  sellProvider.addProductsticket(updatedProduct);
                  Navigator.of(context).pop(); // Cierra el diálogo de inmediato

                  // Procesar en segundo plano
                  if (isNew) {
                    // 1. Crear producto en base de datos pública
                    try {
                      final publicProduct = Product(
                        id: updatedProduct.id.isEmpty ?'prod_${DateTime.now().millisecondsSinceEpoch}' : 
                            updatedProduct.id,
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
                      
                      // Actualizar el producto con el ID generado
                      final finalProduct = updatedProduct.copyWith(id: publicProduct.id);
                      
                      // 2. Agregar al catálogo si está marcado
                      if (checkAddCatalogue) {
                        await catalogueProvider.addProductToCatalogue(finalProduct);
                      }
                    } catch (e) {
                      // Si falla, reabrir el diálogo con mensaje de error
                      // ignore: use_build_context_synchronously
                      showDialogAgregarProductoPublico(
                        // ignore: use_build_context_synchronously
                        context, 
                        product: product, 
                        errorMessage: 'Error al crear producto público: ${e.toString()}',
                        isNew: isNew,
                      );
                    }
                  } else if (!isNew && checkAddCatalogue && updatedProduct.id.isNotEmpty) {
                    // Producto existente: solo agregar al catálogo
                    try {
                      await catalogueProvider.addProductToCatalogue(updatedProduct);
                    } catch (e) {
                      // Si falla, reabrir el diálogo con mensaje de error
                      // ignore: use_build_context_synchronously
                      showDialogAgregarProductoPublico(
                        context, 
                        product: product, 
                        errorMessage: 'Error al guardar en el catálogo: ${e.toString()}',
                        isNew: isNew,
                      );
                    }
                  } else if (isNew  && checkAddCatalogue) {
                    // Producto nuevo solo para catálogo local
                    try {
                      final localProduct = updatedProduct.copyWith(
                        id: updatedProduct.id.isEmpty ? 
                            'local_${DateTime.now().millisecondsSinceEpoch}' : 
                            updatedProduct.id,
                      );
                      await catalogueProvider.addProductToCatalogue(localProduct);
                    } catch (e) {
                      // Si falla, reabrir el diálogo con mensaje de error
                      // ignore: use_build_context_synchronously
                      showDialogAgregarProductoPublico(
                        context, 
                        product: product, 
                        errorMessage: 'Error al guardar en el catálogo: ${e.toString()}',
                        isNew: isNew,
                      );
                    }
                  }
                } catch (e) {
                  setState(() {
                    errorText = 'Error inesperado: ${e.toString()}';
                  });
                }
              },
            ),
          ],
        );
      },
    ),
  );
}
