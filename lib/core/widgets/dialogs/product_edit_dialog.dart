import 'package:flutter/material.dart';
import 'package:sellweb/core/utils/fuctions.dart';
import 'package:sellweb/core/widgets/inputs/input_text_field.dart';
import 'package:sellweb/core/widgets/inputs/money_input_text_field.dart';
import 'package:sellweb/core/widgets/ui/image_widget.dart';
import 'package:sellweb/core/widgets/ui/user_avatar.dart';
import 'package:sellweb/domain/entities/catalogue.dart';
import 'package:sellweb/presentation/providers/sell_provider.dart';
import 'package:provider/provider.dart' as provider_package;

/// Muestra un diálogo para editar la cantidad de un producto en el ticket de venta
Future<void> showProductEditDialog(
  BuildContext context, {
  required ProductCatalogue producto,
  VoidCallback? onProductUpdated,
}) async {
  final originalContext = context;
  
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
                    : UserAvatar(
                        imageUrl: producto.imageMark,
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
                  _buildProductInfo(dialogContext, producto, productDescription, productCode),
                  
                  const SizedBox(height: 20),
                  
                  // Sección de cantidad y total
                  _buildQuantityControls(
                    dialogContext, 
                    originalContext, 
                    producto, 
                    cantidad, 
                    setState,
                  ),
                ],
              ),
            ),
            actions: [
              // Botón eliminar
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
              // Botón cerrar
              TextButton(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onPressed: () => Navigator.of(originalContext).pop(),
                child: const Text('Cerrar'),
              ),
            ],
          );
        },
      );
    },
  );
}

Widget _buildProductInfo(
  BuildContext context,
  ProductCatalogue producto,
  String productDescription,
  String productCode,
) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
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
            color: Theme.of(context).colorScheme.surface,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: ProductImage(
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
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  productCode,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget _buildQuantityControls(
  BuildContext dialogContext,
  BuildContext originalContext,
  ProductCatalogue producto,
  int cantidad,
  StateSetter setState,
) {
  return Column(
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
              _buildQuantityButton(
                dialogContext,
                originalContext,
                producto,
                cantidad,
                setState,
                isIncrement: false,
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
              _buildQuantityButton(
                dialogContext,
                originalContext,
                producto,
                cantidad,
                setState,
                isIncrement: true,
              ),
            ],
          ),
        ],
      ),
      
      const SizedBox(height: 12),
      
      // Total calculado
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
  );
}

Widget _buildQuantityButton(
  BuildContext dialogContext,
  BuildContext originalContext,
  ProductCatalogue producto,
  int cantidad,
  StateSetter setState, {
  required bool isIncrement,
}) {
  final bool isEnabled = isIncrement || cantidad > 1;
  
  return Container(
    width: 36,
    height: 36,
    decoration: BoxDecoration(
      color: isEnabled 
          ? Theme.of(dialogContext).colorScheme.primary.withValues(alpha: 0.12)
          : Theme.of(dialogContext).colorScheme.outline.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(8),
    ),
    child: IconButton(
      padding: EdgeInsets.zero,
      icon: Icon(
        isIncrement ? Icons.add_rounded : Icons.remove_rounded,
        size: 18,
      ),
      onPressed: isEnabled
          ? () {
              final newQuantity = isIncrement ? cantidad + 1 : cantidad - 1;
              provider_package.Provider.of<SellProvider>(originalContext, listen: false)
                  .addProductsticket(
                producto.copyWith(quantity: newQuantity),
                replaceQuantity: true,
              );
              setState(() {});
            }
          : null,
      color: isEnabled 
          ? Theme.of(dialogContext).colorScheme.primary
          : Theme.of(dialogContext).colorScheme.outline,
    ),
  );
}
