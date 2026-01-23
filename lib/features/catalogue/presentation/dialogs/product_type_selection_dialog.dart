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

              // Layout responsivo: Row o Column según el ancho
              LayoutBuilder(
                builder: (context, constraints) {
                  // Breakpoint: si el ancho es menor a 400px, usar columna
                  final isCompact = constraints.maxWidth < 400;

                  if (isCompact) {
                    // Layout compacto: ListTiles en columna
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _ProductTypeListTile(
                          icon: Icons.inventory_2_outlined,
                          title: 'Producto',
                          description: 'Artículo individual con stock y precio único',
                          onTap: () => Navigator.of(context).pop(ProductType.product),
                          colorScheme: colorScheme,
                        ),
                        const SizedBox(height: 12),
                        _ProductTypeListTile(
                          icon: Icons.layers_outlined,
                          title: 'Combo',
                          description: 'Agrupa varios productos con precio especial',
                          onTap: () => Navigator.of(context).pop(ProductType.combo),
                          colorScheme: colorScheme,
                        ),
                      ],
                    );
                  } else {
                    // Layout expandido: Cards en fila
                    return Row(
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
                          ),
                        ),
                      ],
                    );
                  }
                },
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

  const _ProductTypeCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
    required this.colorScheme,
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
              color: widget.colorScheme.primaryContainer.withValues(alpha: 0.3),
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
                    color: widget.colorScheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    widget.icon,
                    size: 40,
                    color: widget.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 16),
                // Título
                Text(
                  widget.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: widget.colorScheme.primary,
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

/// Widget ListTile para pantallas compactas
class _ProductTypeListTile extends StatefulWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;
  final ColorScheme colorScheme;

  const _ProductTypeListTile({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
    required this.colorScheme,
  });

  @override
  State<_ProductTypeListTile> createState() => _ProductTypeListTileState();
}

class _ProductTypeListTileState extends State<_ProductTypeListTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: widget.colorScheme.primaryContainer.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isHovered
                ? widget.colorScheme.primary
                : widget.colorScheme.outline.withValues(alpha: 0.2),
            width: _isHovered ? 2 : 1,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(16),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              // Ícono leading circular
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: widget.colorScheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  widget.icon,
                  size: 28,
                  color: widget.colorScheme.primary,
                ),
              ),
              // Título y descripción
              title: Text(
                widget.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: widget.colorScheme.primary,
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  widget.description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: widget.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Flecha trailing
              trailing: Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: widget.colorScheme.primary.withValues(alpha: 0.6),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
