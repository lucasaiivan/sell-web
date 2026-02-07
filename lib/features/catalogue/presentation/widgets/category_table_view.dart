import 'package:flutter/material.dart';
import 'package:sellweb/features/catalogue/domain/entities/category.dart';
import '../providers/catalogue_provider.dart';
import 'package:sellweb/features/catalogue/presentation/views/dialogs/category_dialog.dart';
import 'package:sellweb/core/presentation/widgets/ui/avatar.dart';

class CategoryTableView extends StatelessWidget {
  final List<Category> categories;
  final CatalogueProvider catalogueProvider;
  final Function(String id, String name) onCategoryTap;
  final String accountId;

  const CategoryTableView({
    super.key,
    required this.categories,
    required this.catalogueProvider,
    required this.onCategoryTap,
    required this.accountId,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(context),
        Expanded(
          child: ListView.builder(
            itemCount: categories.length,
            padding: const EdgeInsets.only(bottom: 80),
            itemBuilder: (context, index) {
              final category = categories[index];
              return _CategoryTableRow(
                category: category,
                productCount:
                    catalogueProvider.getProductCountByCategory(category.id),
                onTap: () => onCategoryTap(category.id, category.name),
                catalogueProvider: catalogueProvider,
                accountId: accountId,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textStyle = theme.textTheme.labelMedium?.copyWith(
      color: colorScheme.onSurfaceVariant,
      fontWeight: FontWeight.bold,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        border: Border(
          bottom: BorderSide(color: colorScheme.outlineVariant, width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text('Categoría', style: textStyle),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 1,
            child: Text('Cantidad de productos',
                style: textStyle, textAlign: TextAlign.end),
          ),
          const SizedBox(width: 48), // Espacio para el menú de ações
        ],
      ),
    );
  }
}

class _CategoryTableRow extends StatelessWidget {
  final Category category;
  final int productCount;
  final VoidCallback onTap;
  final CatalogueProvider catalogueProvider;
  final String accountId;

  const _CategoryTableRow({
    required this.category,
    required this.productCount,
    required this.onTap,
    required this.catalogueProvider,
    required this.accountId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      hoverColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: colorScheme.outlineVariant.withValues(alpha: 0.4),
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Row(
                children: [
                   AvatarItem(
                    name: category.name,
                    radius: 18, // Slightly smaller for table density
                    backgroundColor: colorScheme.primaryContainer.withValues(alpha: 0.5),
                    textStyle: theme.textTheme.titleSmall?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    category.name,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 1,
              child: Text(
                '$productCount productos',
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.end,
              ),
            ),
            const SizedBox(width: 16),
            // Menu de acciones
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: colorScheme.onSurfaceVariant),
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    showCategoryDialog(
                      context,
                      catalogueProvider: catalogueProvider,
                      accountId: accountId,
                      category: category,
                    );
                    break;
                  case 'delete':
                    _showDeleteConfirmation(context);
                    break;
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                  value: 'edit',
                  child: ListTile(
                    leading: Icon(Icons.edit_outlined),
                    title: Text('Editar'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'delete',
                  child: ListTile(
                    leading: Icon(Icons.delete_outlined, color: Colors.red),
                    title: Text('Eliminar', style: TextStyle(color: Colors.red)),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar categoría'),
        content: Text(
            '¿Estás seguro de que deseas eliminar la categoría "${category.name}"? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              catalogueProvider.deleteCategory(
                accountId: accountId,
                categoryId: category.id,
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}
