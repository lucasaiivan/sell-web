import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Avatar circular para usuarios con soporte para imagen, texto o icono
class UserAvatar extends StatelessWidget {
  final String? imageUrl;
  final String? text;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double radius;
  final bool isEmpty;

  const UserAvatar({
    super.key,
    this.imageUrl,
    this.text,
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
    this.radius = 20.0,
    this.isEmpty = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // Colores efectivos
    final Color effectiveBackground = backgroundColor ?? colorScheme.primaryContainer;
    final Color effectiveForeground = foregroundColor ?? colorScheme.onPrimaryContainer;

    if (isEmpty) {
      return Container(
        width: radius * 2,
        height: radius * 2,
      );
    }

    // Determinar el contenido del avatar
    Widget avatarContent = _buildAvatarContent(effectiveForeground);

    // Si hay URL de imagen, usar CachedNetworkImage
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: imageUrl!,
        placeholder: (context, url) => CircleAvatar(
          backgroundColor: effectiveBackground,
          radius: radius,
          child: Center(child: avatarContent),
        ),
        imageBuilder: (context, image) => CircleAvatar(
          backgroundImage: image,
          radius: radius,
        ),
        errorWidget: (context, url, error) {
          return CircleAvatar(
            backgroundColor: effectiveBackground,
            radius: radius,
            child: Center(child: avatarContent),
          );
        },
      );
    }

    // Avatar sin imagen
    return CircleAvatar(
      backgroundColor: effectiveBackground,
      radius: radius,
      child: Center(child: avatarContent),
    );
  }

  Widget _buildAvatarContent(Color foregroundColor) {
    if (text != null && text!.isNotEmpty) {
      return Text(
        text!.substring(0, 1).toUpperCase(),
        style: TextStyle(
          color: foregroundColor,
          fontSize: radius * 0.8,
          fontWeight: FontWeight.w600,
        ),
      );
    }

    return Icon(
      icon ?? Icons.person_outline_rounded,
      color: foregroundColor,
      size: radius * 1.1,
    );
  }
}
