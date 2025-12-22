import 'package:flutter/material.dart';
import 'package:sellweb/core/core.dart';
import 'package:sellweb/features/catalogue/domain/entities/provider.dart';
import 'package:sellweb/features/catalogue/presentation/providers/catalogue_provider.dart';

/// Diálogo para crear o editar un proveedor
class ProviderDialog extends StatefulWidget {
  final CatalogueProvider catalogueProvider;
  final String accountId;
  final Provider? provider;

  const ProviderDialog({
    super.key,
    required this.catalogueProvider,
    required this.accountId,
    this.provider,
  });

  @override
  State<ProviderDialog> createState() => _ProviderDialogState();
}

class _ProviderDialogState extends State<ProviderDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  final _formKey = GlobalKey<FormState>();
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.provider?.name ?? '');
    _phoneController =
        TextEditingController(text: widget.provider?.phone ?? '');
    _emailController =
        TextEditingController(text: widget.provider?.email ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  bool get _isEditing => widget.provider != null;

  @override
  Widget build(BuildContext context) {
    return BaseDialog(
      title: _isEditing ? 'Editar proveedor' : 'Nuevo proveedor',
      icon: _isEditing ? Icons.edit_rounded : Icons.add_business_rounded,
      width: 500,
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DialogComponents.sectionSpacing,
            DialogComponents.textField(
              context: context,
              controller: _nameController,
              label: 'Nombre*',
              hint: 'Ej: Distribuidora XYZ',
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'El nombre es obligatorio';
                }
                return null;
              },
            ),
            DialogComponents.itemSpacing,
            DialogComponents.textField(
              context: context,
              controller: _phoneController,
              label: 'Teléfono',
              hint: 'Ej: +52 55 1234 5678',
              keyboardType: TextInputType.phone,
            ),
            DialogComponents.itemSpacing,
            DialogComponents.textField(
              context: context,
              controller: _emailController,
              label: 'Email',
              hint: 'Ej: contacto@proveedor.com',
              keyboardType: TextInputType.emailAddress,
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
      title: '¿Eliminar proveedor?',
      message:
          '¿Estás seguro de que deseas eliminar "${widget.provider!.name}"? Esta acción no se puede deshacer.',
      confirmText: 'Eliminar',
      cancelText: 'Cancelar',
      isDestructive: true,
    );

    if (confirmed == true && mounted) {
      setState(() => _isProcessing = true);
      try {
        await widget.catalogueProvider.deleteProvider(
          accountId: widget.accountId,
          providerId: widget.provider!.id,
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
            message: 'No se pudo eliminar el proveedor.',
            details: e.toString(),
          );
        }
      }
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isProcessing = true);

    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim();

    final providerEntity = Provider(
      id: widget.provider?.id ?? '',
      name: name,
      phone: phone.isEmpty ? null : phone,
      email: email.isEmpty ? null : email,
    );

    try {
      if (_isEditing) {
        await widget.catalogueProvider.updateProvider(
          accountId: widget.accountId,
          provider: providerEntity,
        );
      } else {
        await widget.catalogueProvider.createProvider(
          accountId: widget.accountId,
          provider: providerEntity,
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
          message: 'No se pudo guardar el proveedor.',
          details: e.toString(),
        );
      }
    }
  }
}

/// Muestra diálogo para crear o editar un proveedor
Future<void> showProviderDialog(
  BuildContext context, {
  required CatalogueProvider catalogueProvider,
  required String accountId,
  Provider? provider,
}) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => ProviderDialog(
      catalogueProvider: catalogueProvider,
      accountId: accountId,
      provider: provider,
    ),
  );
}
