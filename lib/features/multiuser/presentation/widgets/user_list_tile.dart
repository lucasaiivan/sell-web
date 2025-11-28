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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final roleText = user.superAdmin
        ? 'Super Administrador'
        : user.admin
            ? 'Administrador'
            : 'Personalizado';
    
    final roleIcon = user.superAdmin
        ? Icons.security_rounded
        : user.admin
            ? Icons.admin_panel_settings_rounded
            : Icons.person_rounded;
    
    final roleColor = user.superAdmin
        ? Colors.purple
        : user.admin
            ? Colors.blue
            : colorScheme.onSurfaceVariant;

    return InkWell(
      onTap: () {
        final provider = Provider.of<MultiUserProvider>(context, listen: false);
        showDialog(
          context: context,
          builder: (_) => ChangeNotifierProvider.value(
            value: provider,
            child: UserDialog(user: user),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // Icono de rol
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: roleColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                roleIcon,
                color: roleColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            
            // Info Principal
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Nombre o email principal
                  Text(
                    user.name.isNotEmpty ? user.name : user.email,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  const SizedBox(height: 3),
                  // Email (si el nombre no está vacío) y badge de rol
                  Row(
                    children: [
                      if (user.name.isNotEmpty) ...[
                        Flexible(
                          child: Text(
                            user.email,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.75),
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Container(
                            width: 3,
                            height: 3,
                            decoration: BoxDecoration(
                              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                      Text(
                        roleText,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: roleColor.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(width: 8),
            
            // Icono de acción
            Icon(
              Icons.chevron_right_rounded,
              size: 22,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
            ),
          ],
        ),
      ),
    );
  }
}
