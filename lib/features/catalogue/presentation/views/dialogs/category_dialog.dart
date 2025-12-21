import 'package:flutter/material.dart';
import 'package:sellweb/core/core.dart';
import 'package:sellweb/features/catalogue/domain/entities/category.dart';
import 'package:sellweb/features/catalogue/presentation/providers/catalogue_provider.dart';

/// Diálogo para crear o editar una categoría
class CategoryDialog extends StatefulWidget {
  final CatalogueProvider catalogueProvider;
  final String accountId;
  final Category? category;

  const CategoryDialog({
    super.key,
    required this.catalogueProvider,
    required this.accountId,
    this.category,
  });

  @override
  State<CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends State<CategoryDialog> {
  late final TextEditingController _controller;
  final _formKey = GlobalKey<FormState>();
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.category?.name ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _isEditing => widget.category != null;

  @override
  Widget build(BuildContext context) {
    return BaseDialog(
      title: _isEditing ? 'Editar categoría' : 'Nueva categoría',
      icon: _isEditing ? Icons.edit_rounded : Icons.add_rounded,
      width: 450,
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DialogComponents.sectionSpacing,
            DialogComponents.textField(
              context: context,
              controller: _controller,
              label: 'Nombre*',
              hint: 'Ej: Bebidas, Snacks',
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'El nombre es obligatorio';
                }
                return null;
              },
            ),
            DialogComponents.sectionSpacing,
          ],
        ),
      ),
      actions: [
        // Botón eliminar si está editando
        if (_isEditing)
          DialogComponents.secondaryActionButton(
            context: context,
            text: 'Eliminar',
            icon: Icons.delete_outline_rounded,
            onPressed: _isProcessing ? null : _handleDelete,
          ),
        // Botón guardar/crear
        DialogComponents.primaryActionButton(
          context: context,
          text: _isEditing ? 'Guardar' : 'Crear',
          icon: _isEditing ? Icons.save_rounded : Icons.add_rounded,
          onPressed: _isProcessing ? null : _handleSave,
          isLoading: _isProcessing,
        ),
      ],
    );
  }

  Future<void> _handleDelete() async {
    final confirmed = await showConfirmationDialog(
      context: context,
      title: '¿Eliminar categoría?',
      message:
          '¿Estás seguro de que deseas eliminar "${widget.category!.name}"? Esta acción no se puede deshacer.',
      confirmText: 'Eliminar',
      cancelText: 'Cancelar',
      isDestructive: true,
    );

    if (confirmed == true && mounted) {
      setState(() => _isProcessing = true);
      try {
        await widget.catalogueProvider.deleteCategory(
          accountId: widget.accountId,
          categoryId: widget.category!.id,
        );
        if (mounted) {
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isProcessing = false);
          showErrorDialog(
            context: context,
            title: 'Error al eliminar',
            message: 'No se pudo eliminar la categoría.',
            details: e.toString(),
          );
        }
      }
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isProcessing = true);

    final name = _controller.text.trim();
    final categoryToSave = Category(
      id: _isEditing ? widget.category!.id : '',
      name: name,
      subcategories: _isEditing ? widget.category!.subcategories : {},
    );

    try {
      if (_isEditing) {
        await widget.catalogueProvider.updateCategory(
          accountId: widget.accountId,
          category: categoryToSave,
        );
      } else {
        await widget.catalogueProvider.createCategory(
          accountId: widget.accountId,
          category: categoryToSave,
        );
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        showErrorDialog(
          context: context,
          title: 'Error al guardar',
          message: 'No se pudo guardar la categoría.',
          details: e.toString(),
        );
      }
    }
  }
}

/// Muestra diálogo para crear o editar una categoría
Future<void> showCategoryDialog(
  BuildContext context, {
  required CatalogueProvider catalogueProvider,
  required String accountId,
  Category? category,
}) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => CategoryDialog(
      catalogueProvider: catalogueProvider,
      accountId: accountId,
      category: category,
    ),
  );
}
