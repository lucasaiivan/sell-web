import 'package:flutter/material.dart';
import 'package:sellweb/core/utils/fuctions.dart';
import 'package:sellweb/core/widgets/input_text_field.dart';
import 'package:sellweb/core/widgets/money_input_text_field.dart';
import 'package:sellweb/core/widgets/widgets.dart';
import 'package:sellweb/domain/entities/catalogue.dart';
import 'package:sellweb/presentation/providers/sell_provider.dart';
import 'package:sellweb/presentation/providers/catalogue_provider.dart';
import 'package:sellweb/presentation/providers/auth_provider.dart';
import 'package:provider/provider.dart' as provider_package;

/// Muestra un diálogo para editar la cantidad de un producto en el ticket de venta
Future<void> showProductEditDialog(
  BuildContext context, {
  required ProductCatalogue producto,
  VoidCallback? onProductUpdated,
}) async {
  final originalContext = context; // Guardar el contexto original para el Provider
  
  await showDialog(
    context: context,
    builder: (dialogContext) {
      int cantidad = producto.quantity;
      
      // Validaciones de datos para evitar errores con productos vacíos
      final String productName = producto.nameMark.isNotEmpty 
          ? producto.nameMark 
          : (producto.description.isNotEmpty 
              ? producto.description.split(' ').take(2).join(' ')
              : 'Producto');
      
      final String productDescription = producto.description.isNotEmpty 
          ? producto.description 
          : 'Producto de venta rápida';
      
      final String productCode = producto.code.isNotEmpty 
          ? producto.code 
          : 'Sin código';
      
      final bool isQuickSaleProduct = producto.id.isEmpty || producto.id.startsWith('quick_');
      
      // Definir ancho uniforme según plataforma
      double dialogWidth = MediaQuery.of(dialogContext).size.width;
      if (dialogWidth > 400) {
        dialogWidth = 400;
      } else if (dialogWidth < 320) {
        dialogWidth = 320;
      }
      
      return StatefulBuilder(
        builder: (statefulContext, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            backgroundColor: Theme.of(dialogContext).colorScheme.surface,
            contentPadding: const EdgeInsets.all(24),
            title: Row(
              children: [
                // Avatar de la marca o indicador de venta rápida
                isQuickSaleProduct
                    ? Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Theme.of(dialogContext).colorScheme.secondary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          Icons.flash_on_rounded,
                          color: Theme.of(dialogContext).colorScheme.secondary,
                          size: 24,
                        ),
                      )
                    : ComponentApp().userAvatarCircle(
                        urlImage: producto.imageMark,
                        text: producto.nameMark.isNotEmpty ? producto.nameMark : productName,
                      ),
                const SizedBox(width: 12),
                // Título del producto
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        productName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(dialogContext).textTheme.titleLarge,
                      ),
                      if (isQuickSaleProduct)
                        Text(
                          'Venta rápida',
                          style: Theme.of(dialogContext).textTheme.bodySmall?.copyWith(
                            color: Theme.of(dialogContext).colorScheme.secondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(originalContext).pop(),
                  splashRadius: 20,
                  color: Theme.of(dialogContext).colorScheme.onSurface,
                ),
              ],
            ),
            content: SizedBox(
              width: dialogWidth,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Información principal del producto
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(dialogContext).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        // Imagen del producto
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: Theme.of(dialogContext).colorScheme.surface,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: ComponentApp().imageProduct(
                              imageUrl: producto.image,
                              size: 80,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Información del producto
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Descripción del producto
                              Text(
                                productDescription,
                                style: Theme.of(dialogContext).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                              ),
                              const SizedBox(height: 8),
                              // Código del producto
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Theme.of(dialogContext).colorScheme.outline.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  productCode,
                                  style: Theme.of(dialogContext).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(dialogContext).colorScheme.onSurfaceVariant,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              // Precio unitario
                              Text(
                                Publications.getFormatoPrecio(value: producto.salePrice),
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(dialogContext).colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // view : Sección de cantidad y total minimalista
                  Column(
                    children: [
                      // Controles de cantidad compactos
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Etiqueta de cantidad
                          Text(
                            'Cantidad',
                            style: Theme.of(dialogContext).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(dialogContext).colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          // Controles de cantidad
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Botón disminuir
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: cantidad > 1 
                                      ? Theme.of(dialogContext).colorScheme.primary.withValues(alpha: 0.12)
                                      : Theme.of(dialogContext).colorScheme.outline.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: IconButton(
                                  padding: EdgeInsets.zero,
                                  icon: const Icon(Icons.remove_rounded, size: 18),
                                  onPressed: cantidad > 1
                                      ? () {
                                          cantidad--;
                                          provider_package.Provider.of<SellProvider>(originalContext, listen: false)
                                              .addProductsticket(
                                            producto.copyWith(quantity: cantidad),
                                            replaceQuantity: true,
                                          );
                                          setState(() {});
                                        }
                                      : null,
                                  color: cantidad > 1 
                                      ? Theme.of(dialogContext).colorScheme.primary
                                      : Theme.of(dialogContext).colorScheme.outline,
                                ),
                              ),
                              
                              // Cantidad actual
                              Container(
                                margin: const EdgeInsets.symmetric(horizontal: 12),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Theme.of(dialogContext).colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '$cantidad',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(dialogContext).colorScheme.onPrimaryContainer,
                                  ),
                                ),
                              ),
                              
                              // Botón aumentar
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: Theme.of(dialogContext).colorScheme.primary.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: IconButton(
                                  padding: EdgeInsets.zero,
                                  icon: const Icon(Icons.add_rounded, size: 18),
                                  onPressed: () {
                                    cantidad++;
                                    provider_package.Provider.of<SellProvider>(originalContext, listen: false)
                                        .addProductsticket(
                                      producto.copyWith(quantity: cantidad),
                                      replaceQuantity: true,
                                    );
                                    setState(() {});
                                  },
                                  color: Theme.of(dialogContext).colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Total calculado compacto
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Theme.of(dialogContext).colorScheme.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total',
                              style: Theme.of(dialogContext).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(dialogContext).colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              Publications.getFormatoPrecio(value: producto.salePrice * cantidad),
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(dialogContext).colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              // Botón eliminar con confirmación visual
              TextButton.icon(
                icon: const Icon(Icons.delete_outline_rounded),
                label: const Text('Eliminar'),
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(dialogContext).colorScheme.error,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onPressed: () {
                  provider_package.Provider.of<SellProvider>(originalContext, listen: false)
                      .removeProduct(producto);
                  Navigator.of(originalContext).pop();
                  onProductUpdated?.call();
                },
              ),
              // Botón cancelar
              TextButton(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                child: const Text('Cerrar'),
                onPressed: () => Navigator.of(originalContext).pop(),
              ),
            ],
          );
        },
      );
    },
  );
}

/// Muestra un diálogo para agregar un producto al catálogo o crear uno nuevo en la base pública
Future<void> showDialogAgregarProductoPublico(
  BuildContext context, {
  required ProductCatalogue product, 
  String? errorMessage,
  bool isNew = false, // true: crear producto nuevo en base pública, false: agregar existente al catálogo
}) async {

  // style 
  Color infoContainerColor = isNew ? Colors.orange:Colors.red;
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
            children: [
              Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row( 
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(
                        isNew ? Icons.add_circle : Icons.add,
                        color: infoContainerColor,
                        size: 28,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isNew ? 'Crear producto' : 'Agregar al catálogo',
                        style: theme.textTheme.titleLarge?.copyWith(color: infoContainerColor),
                      ),
                    ],
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
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [ 

                // text : codigo del producto
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Row(
                    children: [
                      const Icon(Icons.qr_code, size: 22, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          product.code.isNotEmpty ? product.code : 'Sin código',
                          style: const TextStyle(fontSize: 16, color: Colors.black87),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // view :Información del producto
                isNew?Container()
                  :Padding(
                    padding: const EdgeInsets.only(bottom:30, top: 20),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        // Avatar circular con la inicial del producto o imagen si existe
                        ComponentApp().imageProduct(imageUrl:product.image,size:50),
                        const SizedBox(width: 16),
                        Flexible(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // text : nombre del producto
                                product.description.isEmpty?Container()
                                  :Text(
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
                // input : Descripción del producto
                if (isNew)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: InputTextField(
                      controller: descriptionController,
                      labelText: 'Descripción del producto',
                      hintText: 'Ingrese una descripción',
                      errorText: errorText,
                    ),
                  ),
                // input : Precio de venta
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
              icon: Icon( Icons.add_circle_outline_sharp),
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
