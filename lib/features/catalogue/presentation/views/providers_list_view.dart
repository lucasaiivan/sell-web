import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dialogs/provider_dialog.dart';
import '../../domain/entities/provider.dart' as catalogue_provider_entity;
import '../providers/catalogue_provider.dart';

/// Vista de listado de proveedores
class ProvidersListView extends StatefulWidget {
  final String accountId;
  final Function(String providerId, String providerName)? onProviderTap;

  const ProvidersListView({
    super.key,
    required this.accountId,
    this.onProviderTap,
  });

  @override
  State<ProvidersListView> createState() => _ProvidersListViewState();
}

class _ProvidersListViewState extends State<ProvidersListView> {
  @override
  Widget build(BuildContext context) {
    return Consumer<CatalogueProvider>(
      builder: (context, catalogueProvider, _) {
        final providers = catalogueProvider.providers;

        if (catalogueProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (providers.isEmpty) {
          return _buildEmptyState(context);
        }

        return Stack(
          children: [
            ListView.separated(
              padding: const EdgeInsets.only(bottom: 80),
              itemCount: providers.length,
              separatorBuilder: (context, index) =>
                  const Divider(height: 0, thickness: 0.4),
              itemBuilder: (context, index) {
                final provider = providers[index];
                return _ProviderListTile(
                  provider: provider,
                  onTap: () {
                    if (widget.onProviderTap != null) {
                      widget.onProviderTap!(provider.id, provider.name);
                    }
                  },
                  onEdit: () => _showEditDialog(context, provider),
                );
              },
            ),
            Positioned(
              bottom: 16,
              right: 16,
              child: FloatingActionButton(
                heroTag: 'providers_add_fab',
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

    showProviderDialog(
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
            Icons.local_shipping_outlined,
            size: 80,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'No hay proveedores',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Agrega tu primer proveedor',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(
      BuildContext context, catalogue_provider_entity.Provider provider) {
    final catalogueProvider =
        Provider.of<CatalogueProvider>(context, listen: false);

    showProviderDialog(
      context,
      catalogueProvider: catalogueProvider,
      accountId: widget.accountId,
      provider: provider,
    );
  }
}

/// Tile individual para un proveedor
class _ProviderListTile extends StatelessWidget {
  final catalogue_provider_entity.Provider provider;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;

  const _ProviderListTile({
    required this.provider,
    this.onTap,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Generar avatar con 2 primeros caracteres
    final avatarText = provider.name.length >= 2
        ? provider.name.substring(0, 2).toUpperCase()
        : provider.name.toUpperCase();

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
              backgroundColor: colorScheme.secondaryContainer,
              child: Text(
                avatarText,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: colorScheme.onSecondaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Información del proveedor
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    provider.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (provider.phone != null || provider.email != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      [provider.phone, provider.email]
                          .where((e) => e != null && e.isNotEmpty)
                          .join(' • '),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
