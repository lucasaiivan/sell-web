import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dialogs/category_dialog.dart';
import '../../domain/entities/category.dart';
import '../providers/catalogue_provider.dart';

/// Vista de listado de categorías
class CategoriesListView extends StatefulWidget {
  final String accountId;
  final Function(String categoryId, String categoryName)? onCategoryTap;

  const CategoriesListView({
    super.key,
    required this.accountId,
    this.onCategoryTap,
  });

  @override
  State<CategoriesListView> createState() => _CategoriesListViewState();
}

class _CategoriesListViewState extends State<CategoriesListView> {
  @override
  Widget build(BuildContext context) {
    return Consumer<CatalogueProvider>(
      builder: (context, catalogueProvider, _) {
        final categories = catalogueProvider.categories;

        if (catalogueProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (categories.isEmpty) {
          return _buildEmptyState(context);
        }

        return Stack(
          children: [
            ListView.separated(
              padding: const EdgeInsets.only(bottom: 80),
              itemCount: categories.length,
              separatorBuilder: (context, index) =>
                  const Divider(height: 0, thickness: 0.4),
              itemBuilder: (context, index) {
                final category = categories[index];
                return _CategoryListTile(
                  category: category,
                  onTap: () {
                    if (widget.onCategoryTap != null) {
                      widget.onCategoryTap!(category.id, category.name);
                    }
                  },
                  onEdit: () => _showEditDialog(context, category),
                );
              },
            ),
            Positioned(
              bottom: 16,
              right: 16,
              child: FloatingActionButton(
                heroTag: 'categories_add_fab',
                onPressed: () => _showAddDialog(context),
                child: const Icon(Icons.add),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showAddDialog(BuildContext context) {
    final catalogueProvider =
        Provider.of<CatalogueProvider>(context, listen: false);

    showCategoryDialog(
      context,
      catalogueProvider: catalogueProvider,
      accountId: widget.accountId,
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.category_outlined,
            size: 80,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'No hay categorías',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Agrega tu primera categoría',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, Category category) {
    final catalogueProvider =
        Provider.of<CatalogueProvider>(context, listen: false);

    showCategoryDialog(
      context,
      catalogueProvider: catalogueProvider,
      accountId: widget.accountId,
      category: category,
    );
  }
}

/// Tile individual para una categoría
class _CategoryListTile extends StatelessWidget {
  final Category category;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;

  const _CategoryListTile({
    required this.category,
    this.onTap,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Generar avatar con 2 primeros caracteres
    final avatarText = category.name.length >= 2
        ? category.name.substring(0, 2).toUpperCase()
        : category.name.toUpperCase();

    return InkWell(
      onTap: onTap,
      onLongPress: onEdit,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Avatar con iniciales
            CircleAvatar(
              radius: 20,
              backgroundColor: colorScheme.primaryContainer,
              child: Text(
                avatarText,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Nombre
            Expanded(
              child: Text(
                category.name,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
