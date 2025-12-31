import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sellweb/core/core.dart';
import 'package:sellweb/core/presentation/widgets/navigation/drawer.dart';
import '../provider/multi_user_provider.dart';
import '../widgets/useradmin_dialog.dart';
import '../widgets/user_list_tile.dart';

class MultiUserPage extends StatefulWidget {
  const MultiUserPage({super.key});

  @override
  State<MultiUserPage> createState() => _MultiUserPageState();
}

class _MultiUserPageState extends State<MultiUserPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      drawer: const AppDrawer(),
      floatingActionButton: Consumer<MultiUserProvider>(
        builder: (context, provider, child) {
          // Only show FAB if current user has permission to create users
          if (!provider.canCreateUsers) {
            return const SizedBox.shrink();
          }

          return FloatingActionButton.extended(
            heroTag: 'multiuser_add_fab',
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => ChangeNotifierProvider.value(
                  value: provider,
                  child: const UserAdminDialog(fullView: true),
                ),
              );
            },
            icon: const Icon(Icons.person_add_rounded),
            label: const Text('Agregar'),
          );
        },
      ),
      body: Consumer<MultiUserProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.users.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.errorMessage != null) {
            return Center(child: Text('Error: ${provider.errorMessage}'));
          }

          if (provider.users.isEmpty) {
            return _buildEmptyState(context);
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
            itemCount: provider.users.length,
            separatorBuilder: (context, index) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Divider(
                height: 0.5,
                thickness: 0.5,
                color: Theme.of(context)
                    .colorScheme
                    .outlineVariant
                    .withValues(alpha: 0.3),
              ),
            ),
            itemBuilder: (context, index) {
              return UserListTile(user: provider.users[index]);
            },
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final theme = Theme.of(context);

    return CustomAppBar(
      automaticallyImplyLeading: false,
      titleWidget: Row(
        children: [
          // Botón de menú drawer
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu_rounded),
              onPressed: () => Scaffold.of(context).openDrawer(),
              tooltip: 'Menú',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Usuarios',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline_rounded,
            size: 64,
            color: theme.colorScheme.outline.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No hay usuarios registrados',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Agrega tu primer usuario',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}
