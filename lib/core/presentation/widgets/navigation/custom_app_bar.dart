import 'package:flutter/material.dart';

/// Un AppBar reutilizable que mantiene el estilo base de la aplicación
/// y permite personalizar el contenido para las pantallas principales.
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// El texto del título a mostrar.
  final String? title;

  /// Widget personalizado para el título (tiene prioridad sobre [title]).
  final Widget? titleWidget;

  /// Lista de widgets de acción para mostrar a la derecha.
  final List<Widget>? actions;

  /// Widget para mostrar antes del título.
  final Widget? leading;

  /// Si el título debe estar centrado.
  final bool? centerTitle;

  /// Widget que aparece en la parte inferior de la barra de aplicaciones.
  /// Típicamente un [TabBar].
  final PreferredSizeWidget? bottom;

  /// Color de fondo personalizado.
  final Color? backgroundColor;

  /// Altura personalizada del toolbar.
  final double? toolbarHeight;

  /// Espaciado del título.
  final double? titleSpacing;

  /// Si se debe implicar automáticamente el widget leading.
  final bool automaticallyImplyLeading;

  const CustomAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.actions,
    this.leading,
    this.centerTitle = false,
    this.bottom,
    this.backgroundColor,
    this.toolbarHeight = 80.0,
    this.titleSpacing = 0.0,
    this.automaticallyImplyLeading = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AppBar(
      toolbarHeight: toolbarHeight,
      titleSpacing: titleSpacing,
      actionsPadding: const EdgeInsets.only(right: 8.0, top: 8.0),
      automaticallyImplyLeading: automaticallyImplyLeading,
      title: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 8.0),
        child: titleWidget ??
            (title != null
                ? Text(
                    title!,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  )
                : const SizedBox.shrink()),
      ),
      centerTitle: centerTitle,
      leading: leading,
      // Si leading es null y no queremos el botón de back automático, podemos controlarlo
      // pero por defecto AppBar lo maneja bien.
      actions: actions,
      backgroundColor: backgroundColor ?? theme.scaffoldBackgroundColor,
      surfaceTintColor: colorScheme.surfaceTint,
      elevation: 0,
      scrolledUnderElevation: 1,
      bottom: bottom,
      iconTheme: IconThemeData(color: colorScheme.onSurface),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(
        kToolbarHeight + (bottom?.preferredSize.height ?? 0.0),
      );
}
