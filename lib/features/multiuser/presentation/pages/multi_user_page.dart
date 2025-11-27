import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/di/injection_container.dart';
import '../provider/multi_user_provider.dart';
import '../widgets/user_dialog.dart';
import '../widgets/user_list_tile.dart';

class MultiUserPage extends StatelessWidget {
  const MultiUserPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => getIt<MultiUserProvider>()..loadUsers(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Gestión de Usuarios'),
        ),
        floatingActionButton: Consumer<MultiUserProvider>(
          builder: (context, provider, child) {
            // Only show FAB if current user has permission to create users
            if (!provider.canCreateUsers) {
              return const SizedBox.shrink();
            }
            
            return FloatingActionButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => ChangeNotifierProvider.value(
                    value: provider,
                    child: const UserDialog(),
                  ),
                );
              },
              child: const Icon(Icons.add),
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
              return const Center(child: Text('No hay usuarios registrados.'));
            }

            return ListView.builder(
              itemCount: provider.users.length,
              itemBuilder: (context, index) {
                return UserListTile(user: provider.users[index]);
              },
            );
          },
        ),
      ),
    );
  }
}
