import 'package:flutter/material.dart';
import 'package:sellweb/core/core.dart';
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
  final formKey = GlobalKey<FormState>();

  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      title: Text(isEditing ? 'Editar categoría' : 'Nueva categoría'),
      content: Form(
        key: formKey,
        child: TextFormField(
          controller: controller,
          decoration: InputDecoration(
            labelText: 'Nombre*',
            hintText: TextFormatter.capitalizeString('nombre de la categoría'),
          ),
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'El nombre es obligatorio';
            }
            return null;
          },
        ),
      ),
      actions: [
        // Botón de eliminar (solo visible al editar)
        if (isEditing)
          TextButton(
            onPressed: () async {
              final confirmed = await showConfirmationDialog(
                context: context,
                title: '¿Eliminar categoría?',
                message:
                    '¿Estás seguro de que deseas eliminar "${category.name}"? Esta acción no se puede deshacer.',
                confirmText: 'Eliminar',
                cancelText: 'Cancelar',
                isDestructive: true,
              );

              if (confirmed == true && context.mounted) {
                try {
                  await catalogueProvider.deleteCategory(
                    accountId: accountId,
                    categoryId: category.id,
                  );
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error al eliminar: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Eliminar'),
          ),
        const Spacer(),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () async {
            if (formKey.currentState?.validate() ?? false) {
              final name = controller.text.trim();
              final categoryToSave = Category(
                id: isEditing ? category.id : '',
                name: name,
                subcategories: isEditing ? category.subcategories : {},
              );

              // Cerrar inmediatamente el diálogo
              Navigator.pop(context);

              // Continuar guardado en segundo plano
              try {
                if (isEditing) {
                  await catalogueProvider.updateCategory(
                    accountId: accountId,
                    category: categoryToSave,
                  );
                } else {
                  await catalogueProvider.createCategory(
                    accountId: accountId,
                    category: categoryToSave,
                  );
                }
                
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 5),
                      action: SnackBarAction(
                        label: 'Reintentar',
                        textColor: Colors.white,
                        onPressed: () {
                          // Reabrir el diálogo con los mismos datos
                          showCategoryDialog(
                            context,
                            catalogueProvider: catalogueProvider,
                            accountId: accountId,
                            category: isEditing ? categoryToSave : null,
                          );
                        },
                      ),
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
