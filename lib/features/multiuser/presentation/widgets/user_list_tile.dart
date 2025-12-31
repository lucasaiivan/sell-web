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
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth >= 600;

    // Verificar si este usuario es la cuenta actual
    final isCurrentAccount = authProvider.user?.email == user.email ||
        authProvider.user?.uid == user.id;

    final roleText = user.superAdmin
        ? 'Super Admin'
        : user.admin
            ? 'Administrador'
            : 'Personalizado';

    // Determinar color base según rol
    final Color roleColor = user.inactivate
        ? colorScheme.error
        : user.superAdmin
            ? Colors.purple
            : user.admin
                ? Colors.blue
                : colorScheme.tertiary;

    // Icono o iniciales
    Widget buildAvatar() {
      final name = user.name.isNotEmpty ? user.name : user.email;
      final initials = name.isNotEmpty ? name[0].toUpperCase() : '?';

      return Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: roleColor.withValues(alpha: 0.1),
          shape: BoxShape.circle,
          border: Border.all(
            color: roleColor.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        alignment: Alignment.center,
        child: user.superAdmin
            ? Icon(Icons.verified_user_rounded, color: roleColor, size: 22)
            : Text(
                initials,
                style: TextStyle(
                  color: roleColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
      );
    }

    return Card(
      elevation: 0,
      color: theme.colorScheme.surface,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withOpacity(0.4),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          final multiUserProvider =
              Provider.of<MultiUserProvider>(context, listen: false);
          showDialog(
            context: context,
            builder: (_) => ChangeNotifierProvider.value(
              value: multiUserProvider,
              child: UserAdminDialog(user: user, fullView: true),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Avatar Section
              buildAvatar(),
              const SizedBox(width: 16),

              // Info Section
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            user.name.isNotEmpty ? user.name : user.email,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              decoration: user.inactivate
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: user.inactivate
                                  ? theme.colorScheme.onSurface.withOpacity(0.5)
                                  : theme.colorScheme.onSurface,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isCurrentAccount) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'TÚ',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                        if (user.inactivate) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: colorScheme.errorContainer,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'BLOQUEADO',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colorScheme.error,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.email,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (user.hasAccessTimeConfiguration &&
                        !user.superAdmin &&
                        !user.inactivate) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 12,
                            color: theme.colorScheme.tertiary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            user.accessTimeFormat,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.tertiary,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              if (isLargeScreen) ...[
                const SizedBox(width: 16),
                _buildRoleBadge(
                    context, roleText, roleColor, theme, isLargeScreen),
                const SizedBox(width: 16),
                Icon(
                  Icons.chevron_right_rounded,
                  color: theme.colorScheme.outline,
                ),
              ] else ...[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _buildRoleBadge(
                        context, roleText, roleColor, theme, isLargeScreen),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleBadge(BuildContext context, String text, Color color,
      ThemeData theme, bool isLarge) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        text,
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // Legacy layout methods removed in favor of responsive Card layout above
}
