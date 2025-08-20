import 'package:flutter/material.dart';
import 'package:sellweb/core/widgets/component/image.dart';
import 'package:sellweb/domain/entities/catalogue.dart';

/// Avatar de producto con estilo Instagram Stories
/// Incluye gradiente animado, imagen del producto y texto descriptivo
class AvatarCircleProduct extends StatelessWidget {
  /// Datos del producto a mostrar
  final ProductCatalogue product;

  /// Si el producto está seleccionado/agregado al ticket
  final bool isSelected;

  /// Callback cuando se hace tap en el avatar
  final VoidCallback? onTap;

  /// Tamaño del avatar (diámetro del círculo)
  final double size;

  /// Ancho máximo del texto descriptivo
  final double textWidth;

  /// Número máximo de caracteres antes de truncar el texto
  final int maxTextLength;

  const AvatarCircleProduct({
    super.key,
    required this.product,
    this.isSelected = false,
    this.onTap,
    this.size = 75,
    this.textWidth = 66,
    this.maxTextLength = 8,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            children: [
              // view : avatar
              Container(
                width: size,
                height: size,
                // decoration : dibuja un círculo con gradient según estado (favorito/bajo stock)
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: _getAvatarGradient(),
                  color: product.favorite || (product.stock && product.quantityStock < 5)
                      ? null
                      : theme.colorScheme.onSurface.withOpacity(0.12), // Color en contraste con opacidad
                ),
                child: Container(
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.colorScheme.surface,
                    border: Border.all(
                      color: theme.colorScheme.surface,
                      width: 2,
                    ),
                  ),
                  child: ClipOval(
                    child: ProductImage(
                      imageUrl: product.image,
                      size: size - 6, // Restar el margen y borde
                      borderRadius: size / 2,
                    ),
                  ),
                ),
              ),
              
              // Badge de favorito - círculo amarillo (rojo si hay bajo stock)
              if (product.favorite)
                Positioned(
                  bottom: 4,
                  right: 4,
                  child: Container(
                    width: size * 0.18,
                    height: size * 0.18,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: (product.stock && product.quantityStock < 5)
                          ? Colors.red.shade400
                          : Colors.amber.shade400,
                      border: Border.all(
                        color: theme.colorScheme.surface,
                        width: 2,
                      ),
                    ),
                  ),
                ),
                // posicioned : icon check si está seleccionado
              if (isSelected)
                Positioned(
                  bottom: 3,
                  right: 2,
                  child: Container(
                    width: size * 0.2,
                    height: size * 0.2,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.colorScheme.primary,
                      border: Border.all(
                        color: theme.colorScheme.onPrimary,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      Icons.check,
                      size: size * 0.10,
                      color: theme.colorScheme.onPrimary,
                    ),
                  ),
                ),
              // Badge alerta de stock bajo
              if (product.stock && product.quantityStock < 5)
                Positioned(
                  top: 4,
                  left: 0,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red.shade400,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: theme.colorScheme.surface,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      'Bajo Stock',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onError,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          // Texto descriptivo corto
          SizedBox(
            width: textWidth,
            child: Text(
              _getTruncatedText(product.description),
              textAlign: TextAlign.center,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w500,
                fontSize: 11,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  /// Obtiene el gradiente apropiado según el estado del producto
  LinearGradient? _getAvatarGradient() {
    // Prioridad: bajo stock > favorito > sin gradiente
    if (product.stock && product.quantityStock < 5) {
      return LinearGradient(
        colors: [
          Colors.red.shade300,
          Colors.red.shade400,
          Colors.red.shade500,
          Colors.red.shade600,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else if (product.favorite) {
      return LinearGradient(
        colors: [
          Colors.orange.shade500,
          Colors.amber.shade400,
          Colors.amber.shade400,
          Colors.amber.shade500,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
    return null; // Sin gradiente
  }

  /// Trunca el texto del producto si excede la longitud máxima
  String _getTruncatedText(String text) {
    if (text.length > maxTextLength) {
      return '${text.substring(0, maxTextLength)}..';
    }
    return text;
  }
}
