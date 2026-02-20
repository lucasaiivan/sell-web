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
    return BaseBottomSheet(
      title: _isEditing ? 'Editar proveedor' : 'Nuevo proveedor',
      icon: _isEditing ? Icons.edit_rounded : Icons.add_business_rounded,
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

    // Guardar referencia al Navigator ANTES de operaciones async
    final navigator = Navigator.of(context);

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
      Provider? savedProvider;
      if (_isEditing) {
        await widget.catalogueProvider.updateProvider(
          accountId: widget.accountId,
          provider: providerEntity,
        );
        savedProvider = providerEntity;
      } else {
        // Al crear, esperamos a que se guarde y obtenemos el ID generado
        await widget.catalogueProvider.createProvider(
          accountId: widget.accountId,
          provider: providerEntity,
        );
        // Esperamos un poco para que Firestore propague el cambio
        await Future.delayed(const Duration(milliseconds: 300));
        // Obtenemos el proveedor desde el stream para tener el ID correcto
        final providers = await widget.catalogueProvider
            .getProvidersStream(widget.accountId)
            .first;
        savedProvider = providers.firstWhere(
          (prov) => prov.name == name,
          orElse: () => providerEntity,
        );
      }

      navigator.pop(savedProvider);
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
Future<Provider?> showProviderDialog(
  BuildContext context, {
  required CatalogueProvider catalogueProvider,
  required String accountId,
  Provider? provider,
}) {
  return showModalBottomSheet<Provider>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: ProviderDialog(
        catalogueProvider: catalogueProvider,
        accountId: accountId,
        provider: provider,
      ),
    ),
  );
}
