import 'package:flutter/material.dart';
import 'package:sellweb/core/core.dart';
import 'package:sellweb/features/catalogue/domain/entities/provider.dart';
import 'package:sellweb/features/catalogue/presentation/providers/catalogue_provider.dart';

/// Muestra diálogo para crear o editar un proveedor
Future<void> showProviderDialog(
  BuildContext context, {
  required CatalogueProvider catalogueProvider,
  required String accountId,
  Provider? provider,
}) async {
  final nameController = TextEditingController(text: provider?.name ?? '');
  final phoneController = TextEditingController(text: provider?.phone ?? '');
  final emailController = TextEditingController(text: provider?.email ?? '');
  final isEditing = provider != null;
  final formKey = GlobalKey<FormState>();

  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      title: Text(isEditing ? 'Editar proveedor' : 'Nuevo proveedor'),
      content: SingleChildScrollView(
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Nombre*',
                  hintText:
                      TextFormatter.capitalizeString('nombre del proveedor'),
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
              const SizedBox(height: 16),
              TextFormField(
                controller: phoneController,
                decoration: InputDecoration(
                  labelText: 'Teléfono',
                  hintText:
                      TextFormatter.capitalizeString('teléfono del proveedor'),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  hintText:
                      TextFormatter.capitalizeString('email del proveedor'),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
            ],
          ),
        ),
      ),
      actions: [
        // Botón de eliminar (solo visible al editar)
        if (isEditing)
          TextButton(
            onPressed: () async {
              final confirmed = await showConfirmationDialog(
                context: context,
                title: '¿Eliminar proveedor?',
                message:
                    '¿Estás seguro de que deseas eliminar "${provider.name}"? Esta acción no se puede deshacer.',
                confirmText: 'Eliminar',
                cancelText: 'Cancelar',
                isDestructive: true,
              );

              if (confirmed == true && context.mounted) {
                try {
                  await catalogueProvider.deleteProvider(
                    accountId: accountId,
                    providerId: provider.id,
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
              final name = nameController.text.trim();
              final phone = phoneController.text.trim();
              final email = emailController.text.trim();

              final providerEntity = Provider(
                id: provider?.id ?? '',
                name: name,
                phone: phone.isEmpty ? null : phone,
                email: email.isEmpty ? null : email,
              );

              // Cerrar inmediatamente el diálogo
              Navigator.pop(context);

              // Continuar guardado en segundo plano
              try {
                if (isEditing) {
                  await catalogueProvider.updateProvider(
                    accountId: accountId,
                    provider: providerEntity,
                  );
                } else {
                  await catalogueProvider.createProvider(
                    accountId: accountId,
                    provider: providerEntity,
                  );
                }

                Navigator.pop(context);
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
                          showProviderDialog(
                            context,
                            catalogueProvider: catalogueProvider,
                            accountId: accountId,
                            provider: isEditing ? providerEntity : null,
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
