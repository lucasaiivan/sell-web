import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Imagen de producto cuadrada 1:1 con soporte para red y fallback local
/// Optimizada para carga rápida y mejor UX
class ProductImage extends StatelessWidget {
  final String? imageUrl;
  final double? size;
  final Color? backgroundColor;
  final BoxFit fit;
  final double borderRadius;
  final String defaultAsset;
  final bool enableFadeIn;
  final Duration fadeInDuration;
  final Duration placeholderFadeInDuration;

  const ProductImage({
    super.key,
    this.imageUrl,
    this.size,
    this.backgroundColor,
    this.fit = BoxFit.cover,
    this.borderRadius = 4.0,
    this.defaultAsset = 'assets/product_default.png',
    this.enableFadeIn = true,
    this.fadeInDuration = const Duration(milliseconds: 200),
    this.placeholderFadeInDuration = const Duration(milliseconds: 100),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Si se especifica un size, usar SizedBox con AspectRatio 1:1
    if (size != null) {
      return SizedBox(
        width: size,
        height: size,
        child: AspectRatio(
          aspectRatio: 1,
          child: Container(
            decoration: BoxDecoration(
              color: backgroundColor ?? Colors.white,
              borderRadius: BorderRadius.circular(borderRadius),
            ),
            child: _buildImageContent(),
          ),
        ),
      );
    }

    // Si no se especifica size, permitir que se expanda completamente
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: _buildImageContent(),
    );
  }

  Widget _buildImageContent() {
    // Si la URL de la imagen es válida, carga la imagen desde la red
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      // Utiliza CachedNetworkImage para optimizar la carga y caché
      return Builder(
        builder: (context) => Center(
          child: CachedNetworkImage(
            imageUrl: imageUrl!,
            fit: fit,
            width: size,
            height: size,
            // Configuraciones optimizadas para carga rápida
            fadeInDuration: enableFadeIn ? fadeInDuration : Duration.zero,
            placeholderFadeInDuration: placeholderFadeInDuration,
            // Configuración de caché para mejor rendimiento
            memCacheWidth: size != null ? (size! * 2).round() : null,
            memCacheHeight: size != null ? (size! * 2).round() : null,
            maxWidthDiskCache: size != null ? (size! * 3).round() : null,
            maxHeightDiskCache: size != null ? (size! * 3).round() : null,
            // Manejo de errores y placeholder optimizado
            errorWidget: (context, url, error) =>
                _buildDefaultImageWithAnimation(context),
            placeholder: (context, url) =>
                _buildDefaultImageWithAnimation(context),
            // Configuración adicional para mejor UX
            useOldImageOnUrlChange: true,
            filterQuality: FilterQuality.medium,
          ),
        ),
      );
    }

    // Si no hay URL, muestra la imagen por defecto con animación
    return Builder(
      builder: (context) => _buildDefaultImageWithAnimation(context),
    );
  }

  /// Construye la imagen por defecto con animación suave
  Widget _buildDefaultImageWithAnimation(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Colores adaptativos basados en el tema actual
    final Color iconColor = colorScheme.onSurfaceVariant.withValues(alpha: 0.4);
    final Color backgroundOverlay =
        colorScheme.surfaceContainerHighest.withValues(alpha: 0.2);

    return Container(
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
