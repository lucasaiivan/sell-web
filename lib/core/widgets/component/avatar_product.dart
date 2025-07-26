import 'package:flutter/material.dart';
import 'package:sellweb/core/widgets/component/image.dart';
import 'package:sellweb/domain/entities/catalogue.dart';

/// Avatar de producto con estilo Instagram Stories
/// Incluye gradiente animado, imagen del producto y texto descriptivo
class AvatarProduct extends StatelessWidget {
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

  const AvatarProduct({
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
                // decoration : dibuja un círculo con gradient solo si es favorito
                decoration: BoxDecoration( 
                  shape: BoxShape.circle,
                  gradient: product.favorite 
                    ? LinearGradient(
                        colors: [
                          Colors.amber.shade300,
                          Colors.orange.shade400,
                          Colors.deepOrange.shade400,
                          Colors.red.shade400,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null, // Sin gradiente si no es favorito
                  color: product.favorite 
                    ? null 
                    : theme.colorScheme.surface, // Color sólido si no es favorito
                  boxShadow: [
                    BoxShadow(
                      color: isSelected 
                        ? Colors.green.withValues(alpha: 0.3)
                        : product.favorite 
                          ? Colors.amber.withValues(alpha: 0.3)
                          : Colors.grey.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
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
              // posicioned : icon check si está seleccionado
              if (isSelected)
                Positioned(
                  top: 4,
                  right: 4,
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
                      size: size * 0.12,
                      color: theme.colorScheme.onPrimary,
                    ),
                  ),
                ),
              // posicioned : icon star si es favorito
              if (product.favorite && !isSelected)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    width: size * 0.25,
                    height: size * 0.25,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.amber.shade600,
                      border: Border.all(
                        color: Colors.white,
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      Icons.star,
                      size: size * 0.15,
                      color: Colors.white,
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

  /// Trunca el texto del producto si excede la longitud máxima
  String _getTruncatedText(String text) {
    if (text.length > maxTextLength) {
      return '${text.substring(0, maxTextLength)}..';
    }
    return text;
  }
}
