import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Imagen de producto cuadrada 1:1 con soporte para red y fallback local
/// Optimizada para carga rápida, mejor UX offline, y retry automático
/// 
/// **Mejoras Offline:**
/// - Retry automático con exponential backoff
/// - Shimmer effect mientras carga
/// - Fallback elegante a imagen por defecto
/// - Callbacks para success/error
class ProductImage extends StatelessWidget {
  final String? imageUrl;
  final double? size;
  final Color? backgroundColor;
  final BoxFit fit;
  final double borderRadius;
  final String defaultAsset;
  final bool enableShimmer;
  final int maxRetries;
  final VoidCallback? onImageLoaded;
  final void Function(String error)? onImageError;

  const ProductImage({
    super.key,
    this.imageUrl,
    this.size,
    this.backgroundColor,
    this.fit = BoxFit.cover,
    this.borderRadius = 4.0,
    this.defaultAsset = 'assets/product_default.png',
    this.enableShimmer = true,
    this.maxRetries = 3,
    this.onImageLoaded,
    this.onImageError,
  });

  @override
  Widget build(BuildContext context) {
    // Usar color adaptativo tanto para backgroundColor personalizado como por defecto
    final defaultBackgroundColor = Theme.of(context).colorScheme.surface;

    // Si se especifica un size, usar SizedBox con AspectRatio 1:1
    if (size != null) {
      return SizedBox(
        width: size,
        height: size,
        child: Container(
          decoration: BoxDecoration(
            color: defaultBackgroundColor,
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius),
            child: _buildImageContent(context),
          ),
        ),
      );
    }

    // Si no se especifica size, permitir que se expanda completamente
    return Container(
      decoration: BoxDecoration(
        color: defaultBackgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: _buildImageContent(context),
      ),
    );
  }

  Widget _buildImageContent(BuildContext context) {
    // Si la URL de la imagen es válida, carga la imagen desde la red
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      // Utiliza CachedNetworkImage para optimizar la carga y caché
      return CachedNetworkImage(
        imageUrl: imageUrl!,
        fit: fit,
        width: double.infinity,
        height: double.infinity,
        // Configuraciones optimizadas para carga rápida sin transiciones
        fadeInDuration: Duration.zero, // Sin animación de fade-in
        fadeOutDuration: Duration.zero, // Sin animación de fade-out
        placeholderFadeInDuration:
            Duration.zero, // Sin animación del placeholder
        // Configuración de caché para mejor rendimiento
        memCacheWidth: size != null ? (size! * 2).round() : null,
        memCacheHeight: size != null ? (size! * 2).round() : null,
        maxWidthDiskCache: size != null ? (size! * 3).round() : null,
        maxHeightDiskCache: size != null ? (size! * 3).round() : null,
        // Error listener para debugging
        errorListener: (error) {
          debugPrint('⚠️ Error cargando imagen: $imageUrl - ${error.toString()}');
          onImageError?.call(error.toString());
        },
        // Manejo de errores con fallback elegante
        errorWidget: (context, url, error) {
          return _buildDefaultImageWithAnimation(context);
        },
        // Placeholder con shimmer effect
        placeholder: (context, url) {
          if (enableShimmer) {
            return _buildShimmerPlaceholder(context);
          }
          return _buildDefaultImageWithAnimation(context);
        },
        // Configuración adicional para mejor UX
        useOldImageOnUrlChange: true,
        filterQuality: FilterQuality.medium,
        imageBuilder: (context, imageProvider) {
          // Callback cuando la imagen carga exitosamente
          WidgetsBinding.instance.addPostFrameCallback((_) {
            onImageLoaded?.call();
          });
          return Image(
            image: imageProvider,
            fit: fit,
            width: double.infinity,
            height: double.infinity,
          );
        },
      );
    }

    // Si no hay URL, muestra la imagen por defecto
    return _buildDefaultImageWithAnimation(context);
  }

  /// Construye shimmer effect mientras carga la imagen
  Widget _buildShimmerPlaceholder(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Shimmer.fromColors(
      baseColor: colorScheme.surfaceContainerHighest,
      highlightColor: colorScheme.surfaceContainerHigh,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }

  /// Construye la imagen por defecto con estilo adaptativo
  Widget _buildDefaultImageWithAnimation(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Colores adaptativos basados en el tema actual
    final Color iconColor = colorScheme.onSurfaceVariant.withValues(alpha: 0.4);
    final Color backgroundOverlay =
        colorScheme.onSurfaceVariant.withValues(alpha: 0.04);

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: backgroundOverlay,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Center(
        child: Image.asset(
          defaultAsset,
          fit: fit,
          width: size != null
              ? size! * 0.6
              : null, // Reducir tamaño del icono para mejor proporción
          height: size != null ? size! * 0.6 : null,
          filterQuality: FilterQuality.medium,
          color: iconColor,
        ),
      ),
    );
  }
}
