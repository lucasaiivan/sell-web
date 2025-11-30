import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../auth/domain/entities/admin_profile.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../provider/multi_user_provider.dart';
import 'useradmin_dialog.dart';

class UserListTile extends StatelessWidget {
  final AdminProfile user;

  const UserListTile({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final authProvider = Provider.of<AuthProvider>(context);
    
    // Verificar si este usuario es la cuenta actual (comparar por email o id de Firebase Auth)
    final isCurrentAccount = authProvider.user?.email == user.email || 
                            authProvider.user?.uid == user.id;
    
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
        final multiUserProvider = Provider.of<MultiUserProvider>(context, listen: false);
        showDialog(
          context: context,
          builder: (_) => ChangeNotifierProvider.value(
            value: multiUserProvider,
            child: UserAdminDialog(user: user),
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
                  if (user.name.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    // Email (solo si el nombre no está vacío)
                    Text(
                      user.email,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.75),
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ],
              ),
            ),
            
            const SizedBox(width: 12),
            
            // Indicador de cuenta actual
            if (isCurrentAccount) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 14,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Actual',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
            ],
            
            // Badge de rol en el extremo derecho
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: roleColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                roleText,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: roleColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
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
