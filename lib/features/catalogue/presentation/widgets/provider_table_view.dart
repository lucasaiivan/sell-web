import 'package:flutter/material.dart';
import 'package:sellweb/features/catalogue/domain/entities/provider.dart';
import '../providers/catalogue_provider.dart';
import '../views/dialogs/provider_dialog.dart';
import 'package:sellweb/core/presentation/widgets/ui/avatar.dart';

class ProviderTableView extends StatelessWidget {
  final List<Provider> providers;
  final CatalogueProvider catalogueProvider;
  final Function(String id, String name) onProviderTap;
  final String accountId;

  const ProviderTableView({
    super.key,
    required this.providers,
    required this.catalogueProvider,
    required this.onProviderTap,
    required this.accountId,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(context),
        Expanded(
          child: ListView.builder(
            itemCount: providers.length,
            padding: const EdgeInsets.only(bottom: 80),
            itemBuilder: (context, index) {
              final provider = providers[index];
              return _ProviderTableRow(
                provider: provider,
                productCount:
                    catalogueProvider.getProductCountByProvider(provider.id),
                onTap: () => onProviderTap(provider.id, provider.name),
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
            flex: 2,
            child: Text('Proveedor', style: textStyle),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 3,
            child: Text('Contacto', style: textStyle),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 1,
            child: Text('Cantidad de productos',
                style: textStyle, textAlign: TextAlign.end),
          ),
          const SizedBox(width: 48), // Espacio para el menú
        ],
      ),
    );
  }
}

class _ProviderTableRow extends StatelessWidget {
  final Provider provider;
  final int productCount;
  final VoidCallback onTap;
  final CatalogueProvider catalogueProvider;
  final String accountId;

  const _ProviderTableRow({
    required this.provider,
    required this.productCount,
    required this.onTap,
    required this.catalogueProvider,
    required this.accountId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Preparar info de contacto para mostrar
    final hasPhone = provider.phone != null && provider.phone!.isNotEmpty;
    final hasEmail = provider.email != null && provider.email!.isNotEmpty;

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
            // NOMBRE PROVEEDOR
            Expanded(
              flex: 2,
              child: Row(
                children: [
                   AvatarItem(
                    name: provider.name,
                    radius: 18,
                    backgroundColor: colorScheme.secondaryContainer.withValues(alpha: 0.5),
                    textStyle: theme.textTheme.titleSmall?.copyWith(
                      color: colorScheme.secondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      provider.name,
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),

            // CONTACTO
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (hasPhone)
                    Row(
                      children: [
                        Icon(Icons.phone_outlined,
                            size: 14, color: colorScheme.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text(
                          provider.phone!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  if (hasPhone && hasEmail) const SizedBox(height: 4),
                  if (hasEmail)
                    Row(
                      children: [
                        Icon(Icons.email_outlined,
                            size: 14, color: colorScheme.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            provider.email!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontSize: 13,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  if (!hasPhone && !hasEmail)
                    Text(
                      'Sin contacto',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color:
                            colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 16),

            // CANTIDAD PRODUCTOS
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
                    showProviderDialog(
                      context,
                      catalogueProvider: catalogueProvider,
                      accountId: accountId,
                      provider: provider,
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
        title: const Text('Eliminar proveedor'),
        content: Text(
            '¿Estás seguro de que deseas eliminar el proveedor "${provider.name}"? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              catalogueProvider.deleteProvider(
                accountId: accountId,
                providerId: provider.id,
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
