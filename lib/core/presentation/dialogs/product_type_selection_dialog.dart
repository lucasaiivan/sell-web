import 'package:flutter/material.dart';

/// Enum para representar el tipo de producto a crear
enum ProductType {
  product,
  combo,
}

/// Muestra un diálogo para seleccionar el tipo de producto a crear
///
/// Retorna:
/// - `ProductType.product` si el usuario selecciona crear un producto
/// - `ProductType.combo` si el usuario selecciona crear un combo
/// - `null` si el usuario cancela
Future<ProductType?> showProductTypeSelectionDialog(BuildContext context) {
  return showDialog<ProductType>(
    context: context,
    builder: (context) => const _ProductTypeSelectionDialog(),
  );
}

class _ProductTypeSelectionDialog extends StatelessWidget {
  const _ProductTypeSelectionDialog();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icono y título
              Icon(
                Icons.add_shopping_cart_rounded,
                size: 48,
                color: colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                '¿Qué deseas crear?',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Selecciona el tipo de producto',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Opciones
              Row(
                children: [
                  // Opción Producto
                  Expanded(
                    child: _ProductTypeCard(
                      icon: Icons.inventory_2_outlined,
                      title: 'Producto',
                      description: 'Artículo individual con stock y precio único',
                      onTap: () => Navigator.of(context).pop(ProductType.product),
                      colorScheme: colorScheme,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Opción Combo
                  Expanded(
                    child: _ProductTypeCard(
                      icon: Icons.layers_outlined,
                      title: 'Combo',
                      description: 'Agrupa varios productos con precio especial',
                      onTap: () => Navigator.of(context).pop(ProductType.combo),
                      colorScheme: colorScheme,
                      isPrimary: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Botón cancelar
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancelar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductTypeCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;
  final ColorScheme colorScheme;
  final bool isPrimary;

  const _ProductTypeCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
    required this.colorScheme,
    this.isPrimary = false,
  });

  @override
  State<_ProductTypeCard> createState() => _ProductTypeCardState();
}

class _ProductTypeCardState extends State<_ProductTypeCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedScale(
        scale: _isHovered ? 1.05 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: widget.isPrimary
                  ? widget.colorScheme.primaryContainer.withValues(alpha: 0.3)
                  : widget.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isHovered
                    ? widget.colorScheme.primary
                    : widget.colorScheme.outline.withValues(alpha: 0.2),
                width: _isHovered ? 2 : 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Ícono
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: widget.isPrimary
                        ? widget.colorScheme.primary.withValues(alpha: 0.1)
                        : widget.colorScheme.surfaceContainerHighest,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    widget.icon,
                    size: 40,
                    color: widget.isPrimary
                        ? widget.colorScheme.primary
                        : widget.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                // Título
                Text(
                  widget.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: widget.isPrimary
                        ? widget.colorScheme.primary
                        : widget.colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                // Descripción
                Text(
                  widget.description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: widget.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
