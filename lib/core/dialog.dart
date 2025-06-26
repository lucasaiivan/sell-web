import 'package:flutter/material.dart';
import 'package:sellweb/core/utils/fuctions.dart';
import 'package:sellweb/core/widgets/money_input_text_field.dart';
import 'package:sellweb/domain/entities/catalogue.dart';
import 'package:sellweb/presentation/providers/sell_provider.dart';
import 'package:sellweb/presentation/providers/catalogue_provider.dart';
import 'package:provider/provider.dart' as provider_package;

/// Muestra un diálogo cuando se encuentra un producto en la base pública y permite agregarlo a la lista seleccionada.
Future<void> showDialogAgregarProductoPublico(BuildContext context, {required ProductCatalogue product, String? errorMessage }) async {
  // Variables
  bool checkAddCatalogue = true; // Checkbox para agregar al catálogo
  final priceController = AppMoneyTextEditingController(); 
  String? errorText = errorMessage;
  var checkActiveColor = Theme.of(context).colorScheme.primary.withAlpha(128);
  // Proveedores
  final sellProvider = provider_package.Provider.of<SellProvider>(context, listen: false);
  final catalogueProvider = provider_package.Provider.of<CatalogueProvider>(context, listen: false);

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
                backgroundColor: Colors.green.withAlpha(38),
                child: const Icon(Icons.cloud_download, color: Colors.green, size: 26),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.0),
                child: Text('Nuevo producto en el catálogo', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold )),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          content: Column(
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
                            Text(
                              product.description,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ), 
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
                                  // text : codigo del producto
                                  Text(
                                    product.code,
                                    style: TextStyle(
                                      color: Colors.grey.shade700,
                                      fontSize: 12,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
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
              const SizedBox(height:12),
              Container(
                decoration: BoxDecoration(border: Border.all(color:  checkActiveColor,width: 0.5),color: checkAddCatalogue? checkActiveColor.withAlpha(51):null,borderRadius: BorderRadius.circular(5)), 
                child: CheckboxListTile(
                  title: const Text('Agregar al catálogo'),
                  value:  checkAddCatalogue,
                    onChanged: (bool? value) { 
                    setState(() {
                      checkAddCatalogue = value ?? false;
                      checkActiveColor = value == true
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurface.withAlpha(128);
                    });
                    },
                  controlAffinity: ListTileControlAffinity.leading, // Alinea el checkbox a la izquierda
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
          actions: [
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            FilledButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Agregar'),
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
                final productToAdd = product.copyWith(salePrice: price);
                // Agregar siempre a la lista de productos seleccionados del ticket
                sellProvider.addProductsticket(productToAdd);
                Navigator.of(context).pop(); // Cierra el diálogo de inmediato
                // Procesar en segundo plano la adición al catálogo
                if (checkAddCatalogue && productToAdd.id.isNotEmpty) {
                  try {
                    await catalogueProvider.addProductToCatalogue(productToAdd);
                  } catch (e) {
                    // Si falla, reabrir el diálogo con mensaje de error
                    // ignore: use_build_context_synchronously
                    showDialogAgregarProductoPublico(context, product: product, errorMessage: 'Error al guardar en el catálogo. Intente nuevamente.');
                  }
                }
              },
            ),
          ],
        );
      },
    ),
  );
}
