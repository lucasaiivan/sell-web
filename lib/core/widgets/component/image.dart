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
    final Color effectiveBackground =
        backgroundColor ?? Theme.of(context).colorScheme.surfaceContainer;

    return SizedBox(
      width: size,
      height: size,
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          color: effectiveBackground.withAlpha(51), // alpha: 0.2*255 ≈ 51
          child: _buildImageContent(),
        ),
      ),
    );
  }

  Widget _buildImageContent() {
    // Si la URL de la imagen es válida, carga la imagen desde la red
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      // Utiliza CachedNetworkImage para optimizar la carga y caché
      return Builder(
        builder: (context) => CachedNetworkImage(
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
      );
    }

    // Si no hay URL, muestra la imagen por defecto con animación
    return Builder(
      builder: (context) => _buildDefaultImageWithAnimation(context),
    );
  }

  /// Construye la imagen por defecto con animación suave
  Widget _buildDefaultImageWithAnimation(BuildContext context) {
    // Determinar si el tema es claro u oscuro
    final bool isDarkTheme = Theme.of(context).brightness == Brightness.dark;

    // Colores discretos basados en el brillo del tema
    final Color iconColor = isDarkTheme
        ? Colors.grey.shade400 // Gris claro discreto para tema oscuro
        : Colors.grey.shade200; // Gris medio discreto para tema claro

    final Color backgroundOverlay = isDarkTheme
        ? Colors.grey.shade500 // Overlay sutil para tema oscuro
        : Colors.grey.shade100; // Overlay sutil para tema claro

    return Container(
      decoration: BoxDecoration(
        color: backgroundOverlay,
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
