import 'package:flutter/material.dart';
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

  return showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(isEditing ? 'Editar proveedor' : 'Nuevo proveedor'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Nombre*',
                hintText: 'Ingrese el nombre del proveedor',
              ),
              autofocus: true,
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(
                labelText: 'Teléfono',
                hintText: 'Ingrese el teléfono',
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                hintText: 'Ingrese el email',
              ),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () async {
            final name = nameController.text.trim();
            if (name.isNotEmpty) {
              try {
                final providerEntity = Provider(
                  id: provider?.id ?? '',
                  name: name,
                  phone: phoneController.text.trim().isEmpty
                      ? null
                      : phoneController.text.trim(),
                  email: emailController.text.trim().isEmpty
                      ? null
                      : emailController.text.trim(),
                );

                if (isEditing) {
                  await catalogueProvider.updateProvider(
                    provider: providerEntity,
                  );
                } else {
                  await catalogueProvider.createProvider(
                    accountId: accountId,
                    provider: providerEntity,
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
