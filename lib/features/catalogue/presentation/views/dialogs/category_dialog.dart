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
    return BaseBottomSheet(
      title: _isEditing ? 'Editar categoría' : 'Nueva categoría',
      icon: _isEditing ? Icons.edit_rounded : Icons.add_rounded,
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 24),
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
              const SizedBox(height: 48), // Espacio extra para el teclado
            ],
          ),
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

    // Guardar referencia al Navigator ANTES de operaciones async
    final navigator = Navigator.of(context);

    setState(() => _isProcessing = true);

    final name = _controller.text.trim();
    final categoryToSave = Category(
      id: _isEditing ? widget.category!.id : '',
      name: name,
      subcategories: _isEditing ? widget.category!.subcategories : {},
    );

    try {
      Category? savedCategory;
      if (_isEditing) {
        await widget.catalogueProvider.updateCategory(
          accountId: widget.accountId,
          category: categoryToSave,
        );
        savedCategory = categoryToSave;
      } else {
        // Al crear, esperamos a que se guarde y obtenemos el ID generado
        await widget.catalogueProvider.createCategory(
          accountId: widget.accountId,
          category: categoryToSave,
        );
        // Esperamos un poco para que Firestore propague el cambio
        await Future.delayed(const Duration(milliseconds: 300));
        // Obtenemos la categoría desde el stream para tener el ID correcto
        final categories = await widget.catalogueProvider
            .getCategoriesStream(widget.accountId)
            .first;
        savedCategory = categories.firstWhere(
          (cat) => cat.name == name,
          orElse: () => categoryToSave,
        );
      }

      navigator.pop(savedCategory);
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
Future<Category?> showCategoryDialog(
  BuildContext context, {
  required CatalogueProvider catalogueProvider,
  required String accountId,
  Category? category,
}) {
  return showModalBottomSheet<Category>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: CategoryDialog(
        catalogueProvider: catalogueProvider,
        accountId: accountId,
        category: category,
      ),
    ),
  );
}
