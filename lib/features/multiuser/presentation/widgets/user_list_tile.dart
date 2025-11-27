import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../auth/domain/entities/admin_profile.dart';
import '../provider/multi_user_provider.dart';
import 'user_dialog.dart';

class UserListTile extends StatelessWidget {
  final AdminProfile user;

  const UserListTile({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          child: Icon(
            user.superAdmin
                ? Icons.security
                : user.admin
                    ? Icons.admin_panel_settings
                    : Icons.person,
          ),
        ),
        title: Text(user.name.isNotEmpty ? user.name : user.email),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (user.name.isNotEmpty) Text(user.email),
            Text(
              user.superAdmin
                  ? 'Super Administrador'
                  : user.admin
                      ? 'Administrador'
                      : 'Personalizado',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                final provider = Provider.of<MultiUserProvider>(context, listen: false);
                showDialog(
                  context: context,
                  builder: (_) => ChangeNotifierProvider.value(
                    value: provider,
                    child: UserDialog(user: user),
                  ),
                );
              },
            ),
            if (!user.superAdmin) // Prevent deleting super admin if needed, or just allow it.
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _confirmDelete(context),
              ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Usuario'),
        content: Text('¿Estás seguro de que deseas eliminar a ${user.email}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Provider.of<MultiUserProvider>(context, listen: false)
                  .deleteUser(user);
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
