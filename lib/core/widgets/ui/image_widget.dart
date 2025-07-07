import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Imagen de producto cuadrada 1:1 con soporte para red y fallback local
class ProductImage extends StatelessWidget {
  final String? imageUrl;
  final double? size;
  final Color? backgroundColor;
  final BoxFit fit;
  final double borderRadius;
  final String defaultAsset;

  const ProductImage({
    super.key,
    this.imageUrl,
    this.size,
    this.backgroundColor,
    this.fit = BoxFit.cover,
    this.borderRadius = 8.0,
    this.defaultAsset = 'assets/product_default.png',
  });

  @override
  Widget build(BuildContext context) {
    final Color effectiveBackground = backgroundColor ?? 
        Theme.of(context).colorScheme.surface;

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Container(
        color: effectiveBackground,
        width: size,
        height: size,
        child: _buildImageContent(),
      ),
    );
  }

  Widget _buildImageContent() {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: imageUrl!,
        fit: fit,
        width: size,
        height: size,
        errorWidget: (context, url, error) => _buildDefaultImage(),
        placeholder: (context, url) => _buildLoadingPlaceholder(),
      );
    }

    return _buildDefaultImage();
  }

  Widget _buildDefaultImage() {
    return Image.asset(
      defaultAsset,
      fit: fit,
      width: size,
      height: size,
    );
  }

  Widget _buildLoadingPlaceholder() {
    return Center(
      child: SizedBox(
        width: size != null ? size! * 0.3 : 24,
        height: size != null ? size! * 0.3 : 24,
        child: const CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }
}
