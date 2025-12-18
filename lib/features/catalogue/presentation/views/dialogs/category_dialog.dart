import 'package:flutter/material.dart';
import 'package:sellweb/features/catalogue/domain/entities/category.dart';
import 'package:sellweb/features/catalogue/presentation/providers/catalogue_provider.dart';

/// Muestra diálogo para crear o editar una categoría
Future<void> showCategoryDialog(
  BuildContext context, {
  required CatalogueProvider catalogueProvider,
  required String accountId,
  Category? category,
}) async {
  final controller = TextEditingController(text: category?.name ?? '');
  final isEditing = category != null;

  return showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(isEditing ? 'Editar categoría' : 'Nueva categoría'),
      content: TextField(
        controller: controller,
        decoration: const InputDecoration(
          labelText: 'Nombre',
          hintText: 'Ingrese el nombre de la categoría',
        ),
        autofocus: true,
        textCapitalization: TextCapitalization.words,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () async {
            final name = controller.text.trim();
            if (name.isNotEmpty) {
              try {
                if (isEditing) {
                  await catalogueProvider.updateCategory(
                    category: Category(
                      id: category.id,
                      name: name,
                      subcategories: category.subcategories,
                    ),
                  );
                } else {
                  await catalogueProvider.createCategory(
                    accountId: accountId,
                    category: Category(name: name),
                  );
                }
                if (context.mounted) {
                  Navigator.pop(context);
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            }
          },
          child: Text(isEditing ? 'Guardar' : 'Crear'),
        ),
      ],
    ),
  );
}
