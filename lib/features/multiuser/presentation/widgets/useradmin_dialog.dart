import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';

import 'package:sellweb/core/core.dart';
import 'package:sellweb/core/utils/formatters/date_formatter.dart';
import '../../../auth/domain/entities/admin_profile.dart';
import '../../../sales/presentation/providers/sales_provider.dart';
import '../provider/multi_user_provider.dart';
import 'time_range_selector.dart';

// ============================================================================
// ENUMS
// ============================================================================

/// Días de la semana disponibles para configuración de acceso
enum DayOfWeek {
  monday,
  tuesday,
  wednesday,
  thursday,
  friday,
  saturday,
  sunday,
}

// ============================================================================
// DIALOG WIDGET
// ============================================================================

/// Widget: Diálogo de gestión de usuarios administradores
///
/// **Responsabilidad:**
/// - Crear y editar perfiles de usuarios administradores
/// - Configurar tipos de permisos (Admin, SuperAdmin, Personalizado)
/// - Gestionar permisos granulares para usuarios personalizados
/// - Configurar control de acceso (días y horarios)
/// - Validar datos del formulario antes de guardar
///
/// **Modos de operación:**
/// - Creación: cuando [user] es null
/// - Edición: cuando [user] contiene un perfil existente
///
/// **Features:**
/// - Tipos de permisos: Administrador, Super Administrador, Personalizado
/// - Permisos granulares: arqueo, historial, transacciones, catálogo, multiusuario, editar cuenta
/// - Control de acceso: días de la semana y rango horario
/// - Validación en tiempo real con feedback visual
/// - Pantalla completa en dispositivos pequeños cuando fullView=true
class UserAdminDialog extends StatefulWidget {
  /// Perfil de usuario a editar (null para crear nuevo)
  final AdminProfile? user;

  /// Si es true, se muestra en pantalla completa en dispositivos pequeños
  final bool fullView;

  const UserAdminDialog({super.key, this.user, this.fullView = false});

  @override
  State<UserAdminDialog> createState() => _UserAdminDialogState();
}

// ============================================================================
// DIALOG STATE
// ============================================================================

class _UserAdminDialogState extends State<UserAdminDialog> {
  // Form & Controllers
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _emailController;
  late TextEditingController _nameController;
  late TextEditingController _inactivateNoteController;

  // ==================== Permission Type ====================
  /// Indica si el usuario tiene permisos de administrador completo
  bool _isAdmin = false;

  /// Indica si el usuario es el super administrador (propietario)
  bool _isSuperAdmin = false;

  /// Indica si el usuario tiene permisos personalizados
  bool _isPersonalized = false;

  // ==================== User Status ====================
  /// Indica si el usuario está inactivado (bloqueado)
  bool _inactivate = false;

  // ==================== Granular Permissions ====================
  /// Permiso para registrar ventas
  bool _sales = false;

  /// Permiso para realizar arqueo (cierre de caja)
  bool _arqueo = false;

  /// Permiso para ver y eliminar historial de arqueos
  bool _historyArqueo = false;

  /// Permiso para ver y eliminar transacciones
  bool _transactions = false;

  /// Permiso para gestionar catálogo de productos
  bool _catalogue = false;

  /// Permiso para gestionar usuarios
  bool _multiuser = false;

  /// Permiso para editar configuración de la cuenta
  bool _editAccount = false;

  // ==================== Access Control ====================
  /// Días de la semana en los que el usuario tiene acceso
  Set<DayOfWeek> _selectedDays = {};

  /// Hora de inicio del rango de acceso permitido
  TimeOfDay? _startTime;

  /// Hora de fin del rango de acceso permitido
  TimeOfDay? _endTime;

  // ==================== Validation Flags ====================
  /// Activa la visualización de errores de validación en el formulario
  bool _showValidationErrors = false;

  /// Indica error al no seleccionar tipo de permiso
  bool _permissionTypeError = false;

  /// Indica error al no seleccionar permisos específicos en modo personalizado
  bool _personalizedPermissionsError = false;

  /// Indica error al no seleccionar días de la semana
  bool _daysOfWeekError = false;

  /// Indica error al no configurar horario de acceso
  bool _accessTimeError = false;

  // ==========================================================================
  // LIFECYCLE METHODS
  // ==========================================================================

  @override
  void initState() {
    super.initState();
    final user = widget.user;

    _emailController = TextEditingController(text: user?.email ?? '');
    _nameController = TextEditingController(text: user?.name ?? '');
    _inactivateNoteController =
        TextEditingController(text: user?.inactivateNote ?? '');

    _inactivate = user?.inactivate ?? false;
    _isAdmin = user?.admin ?? false;
    _isSuperAdmin = user?.superAdmin ?? false;
    _isPersonalized = user?.personalized ?? false;

    // Load granular permissions usando hasPermission()
    _sales = user?.hasPermission(AdminPermission.registerSales) ?? false;
    _arqueo = user?.hasPermission(AdminPermission.createCashCount) ?? false;
    _historyArqueo = user?.hasPermission(AdminPermission.viewCashCountHistory) ?? false;
    _transactions = user?.hasPermission(AdminPermission.manageTransactions) ?? false;
    _catalogue = user?.hasPermission(AdminPermission.manageCatalogue) ?? false;
    _multiuser = user?.hasPermission(AdminPermission.manageUsers) ?? false;
    _editAccount = user?.hasPermission(AdminPermission.manageAccount) ?? false;

    // Load days of week
    if (user != null && user.daysOfWeek.isNotEmpty) {
      _selectedDays = user.daysOfWeek
          .map((day) => _dayStringToEnum(day))
          .whereType<DayOfWeek>()
          .toSet();
    }

    // Load access times
    if (user != null && user.startTime.isNotEmpty) {
      _startTime = TimeOfDay(
        hour: user.startTime['hour'] as int? ?? 0,
        minute: user.startTime['minute'] as int? ?? 0,
      );
    }
    if (user != null && user.endTime.isNotEmpty) {
      _endTime = TimeOfDay(
        hour: user.endTime['hour'] as int? ?? 0,
        minute: user.endTime['minute'] as int? ?? 0,
      );
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    _inactivateNoteController.dispose();
    super.dispose();
  }

  // ==========================================================================
  // HELPER METHODS
  // ==========================================================================

  /// Convierte string de día a enum DayOfWeek
  ///
  /// Retorna Monday por defecto si no encuentra coincidencia
  DayOfWeek? _dayStringToEnum(String day) {
    final dayLower = day.toLowerCase().trim();
    return DayOfWeek.values.firstWhere(
      (d) => d.toString().split('.').last == dayLower,
      orElse: () => DayOfWeek.monday,
    );
  }

  /// Limpia el error de permisos personalizados si al menos uno está activo
  void _clearPersonalizedPermissionsError() {
    if (_arqueo ||
        _historyArqueo ||
        _transactions ||
        _catalogue ||
        _multiuser ||
        _editAccount) {
      _personalizedPermissionsError = false;
    }
  }

  /// Traduce enum DayOfWeek a abreviatura en español
  String _translateDay(DayOfWeek day) {
    const translations = {
      DayOfWeek.monday: 'Lun',
      DayOfWeek.tuesday: 'Mar',
      DayOfWeek.wednesday: 'Mié',
      DayOfWeek.thursday: 'Jue',
      DayOfWeek.friday: 'Vie',
      DayOfWeek.saturday: 'Sáb',
      DayOfWeek.sunday: 'Dom',
    };
    return translations[day] ?? '';
  }

  // ==========================================================================
  // BUILD METHOD
  // ==========================================================================

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.user != null;
    final theme = Theme.of(context);

    return BaseDialog(
      title: isEditing ? 'Editar Usuario' : 'Nuevo Usuario',
      subtitle: isEditing && widget.user != null
          ? 'Creado: ${DateFormatter.formatPublicationDate(dateTime: widget.user!.creation)}'
          : null,
      icon: isEditing ? Icons.edit_rounded : Icons.person_add_rounded,
      width: 550,
      maxHeight: 700,
      fullView: widget.fullView,
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildBasicInfoSection(),
            const SizedBox(height: 20),
            if (isEditing && !widget.user!.superAdmin) ...[
              _buildUserStatusSection(theme),
              const SizedBox(height: 20),
            ],
            _buildPermissionTypeSection(),
            if (_isPersonalized) ...[
              const SizedBox(height: 20),
              _buildGranularPermissionsSection(),
            ],
            if (!_isSuperAdmin) ...[
              const SizedBox(height: 20),
              _buildAccessControlSection(theme),
            ],
          ],
        ),
      ),
      actions: [
        if (isEditing && !widget.user!.superAdmin)
          AppButton.text(
            text: 'Eliminar',
            onPressed: () => _confirmDelete(context),
            foregroundColor: theme.colorScheme.error,
          ),
        if (isEditing && !widget.user!.superAdmin)
          AppButton.text(
            text: 'Cancelar',
            onPressed: () => Navigator.of(context).pop(),
          ),
        AppButton.primary(
          text: isEditing ? 'Actualizar' : 'Crear',
          onPressed: _saveUser,
        ),
      ],
    );
  }

  // ==========================================================================
  // UI SECTIONS
  // ==========================================================================

  /// Construye sección de información básica del usuario
  ///
  /// Contiene campos de email (no editable en modo edición) y nombre opcional
  Widget _buildBasicInfoSection() {
    final isEditing = widget.user != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FormInputTextField(
          controller: _emailController,
          labelText: 'Email',
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor ingrese un email';
            }
            if (!ValidatorsHelper.isValidEmail(value)) {
              return 'Ingrese un email válido';
            }
            return null;
          },
          enabled: !isEditing,
        ),
        const SizedBox(height: 20),
        FormInputTextField(
          controller: _nameController,
          labelText: 'Nombre (opcional)',
        ),
      ],
    );
  }

  /// Construye sección de estado del usuario
  ///
  /// Permite activar/inactivar (bloquear) al usuario
  Widget _buildUserStatusSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Estado del Usuario',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: _inactivate
                ? theme.colorScheme.errorContainer.withOpacity(0.3)
                : theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _inactivate
                  ? theme.colorScheme.error.withOpacity(0.5)
                  : theme.colorScheme.outlineVariant.withOpacity(0.5),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              SwitchListTile(
                secondary: Icon(
                  _inactivate
                      ? Icons.block_rounded
                      : Icons.check_circle_rounded,
                  color: _inactivate ? theme.colorScheme.error : Colors.green,
                  size: 28,
                ),
                title: Text(
                  _inactivate ? 'Usuario Inactivo' : 'Usuario Activo',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: _inactivate ? theme.colorScheme.error : Colors.green,
                  ),
                ),
                subtitle: Text(
                  _inactivate
                      ? 'El usuario está bloqueado y no puede acceder'
                      : 'El usuario puede acceder normalmente',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                value: _inactivate,
                onChanged: (value) {
                  setState(() {
                    _inactivate = value;
                  });
                },
              ),
              // Campo de nota cuando está bloqueado
              if (_inactivate) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.note_alt_rounded,
                            size: 16,
                            color: theme.colorScheme.error,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Nota de Bloqueo (opcional)',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.error,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      FormInputTextField(
                        controller: _inactivateNoteController,
                        hintText: 'Ej: Usuario suspendido temporalmente por...',
                        minLines: 1,
                        maxLines: null,
                        keyboardType: TextInputType.multiline,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Esta nota será visible para el usuario cuando intente acceder',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  /// Construye sección de tipo de permiso
  ///
  /// Muestra información estática para Super Admin o permite seleccionar
  /// entre Admin y Personalizado para usuarios normales
  Widget _buildPermissionTypeSection() {
    final theme = Theme.of(context);

    // Si es superusuario, mostrar info estática sin permitir edición
    if (_isSuperAdmin) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.purple.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.purple.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.security_rounded,
                  color: Colors.purple,
                  size: 32,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Super Administrador',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.purple,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Propietario de la cuenta con acceso completo sin restricciones',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    // Para usuarios normales, mostrar opciones de Admin y Personalizado
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Tipo de Permiso',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: _showValidationErrors && _permissionTypeError
                    ? theme.colorScheme.error
                    : theme.colorScheme.primary,
              ),
            ),
            if (_showValidationErrors && _permissionTypeError) ...[
              const SizedBox(width: 8),
              Icon(
                Icons.error_outline_rounded,
                size: 20,
                color: theme.colorScheme.error,
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: _showValidationErrors && _permissionTypeError
                ? theme.colorScheme.errorContainer.withOpacity(0.2)
                : theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _showValidationErrors && _permissionTypeError
                  ? theme.colorScheme.error
                  : theme.colorScheme.outlineVariant.withOpacity(0.5),
              width: _showValidationErrors && _permissionTypeError ? 2 : 1,
            ),
          ),
          child: RadioGroup<String>(
            groupValue: _isAdmin
                ? 'admin'
                : _isPersonalized
                    ? 'personalized'
                    : '',
            onChanged: (value) {
              setState(() {
                if (value == 'admin') {
                  _isAdmin = true;
                  _isPersonalized = false;
                  // Admin gets all permissions
                  _sales = true;
                  _arqueo = true;
                  _historyArqueo = true;
                  _transactions = true;
                  _catalogue = true;
                  _multiuser = true;
                  _editAccount = true;
                } else if (value == 'personalized') {
                  _isAdmin = false;
                  _isPersonalized = true;
                  // Reset personalized permissions
                  _sales = false;
                  _arqueo = false;
                  _historyArqueo = false;
                  _transactions = false;
                  _catalogue = false;
                  _multiuser = false;
                  _editAccount = false;
                }
                // Limpiar error de validación
                _permissionTypeError = false;
                _personalizedPermissionsError = false;
              });
            },
            child: Column(
              children: [
                RadioListTile<String>(
                  secondary: Icon(
                    Icons.admin_panel_settings_rounded,
                    color: _isAdmin
                        ? Colors.blue
                        : theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                    size: 28,
                  ),
                  title: Text(
                    'Administrador',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    'Permisos administrativos completos',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  value: 'admin',
                ),
                Divider(
                    height: 1,
                    color: theme.colorScheme.outlineVariant.withOpacity(0.3)),
                RadioListTile<String>(
                  secondary: Icon(
                    Icons.tune_rounded,
                    color: _isPersonalized
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                    size: 28,
                  ),
                  title: Text(
                    'Personalizado',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    'Configurar permisos específicos',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  value: 'personalized',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Construye sección de permisos granulares para usuarios personalizados
  ///
  /// Permite seleccionar permisos específicos: arqueo, historial, transacciones,
  /// catálogo, multiusuario y edición de cuenta
  Widget _buildGranularPermissionsSection() {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Permisos Específicos',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: _showValidationErrors && _personalizedPermissionsError
                    ? theme.colorScheme.error
                    : theme.colorScheme.primary,
              ),
            ),
            if (_showValidationErrors && _personalizedPermissionsError) ...[
              const SizedBox(width: 8),
              Icon(
                Icons.error_outline_rounded,
                size: 20,
                color: theme.colorScheme.error,
              ),
            ],
          ],
        ),
        if (_showValidationErrors && _personalizedPermissionsError) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.errorContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: theme.colorScheme.error.withOpacity(0.5),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Selecciona al menos un permiso',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 8),
        Container(
          decoration: _showValidationErrors && _personalizedPermissionsError
              ? BoxDecoration(
                  color: theme.colorScheme.errorContainer.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.error,
                    width: 2,
                  ),
                )
              : null,
          child: Column(
            children: [
              CheckboxListTile(
                title: const Text('Ventas'),
                subtitle: const Text('Registrar ventas y gestionar tickets'),
                value: _sales,
                onChanged: (value) {
                  setState(() {
                    _sales = value ?? false;
                    _clearPersonalizedPermissionsError();
                  });
                },
              ),
              CheckboxListTile(
                title: const Text('Arqueo'),
                subtitle: const Text('Crear cierre de caja'),
                value: _arqueo,
                onChanged: (value) {
                  setState(() {
                    _arqueo = value ?? false;
                    _clearPersonalizedPermissionsError();
                  });
                },
              ),
              CheckboxListTile(
                title: const Text('Historial de Arqueo'),
                subtitle: const Text('Ver y eliminar registros de caja'),
                value: _historyArqueo,
                onChanged: (value) {
                  setState(() {
                    _historyArqueo = value ?? false;
                    _clearPersonalizedPermissionsError();
                  });
                },
              ),
              CheckboxListTile(
                title: const Text('Transacciones'),
                subtitle: const Text('Ver y eliminar transacciones'),
                value: _transactions,
                onChanged: (value) {
                  setState(() {
                    _transactions = value ?? false;
                    _clearPersonalizedPermissionsError();
                  });
                },
              ),
              CheckboxListTile(
                title: const Text('Catálogo'),
                subtitle: const Text('Gestionar productos'),
                value: _catalogue,
                onChanged: (value) {
                  setState(() {
                    _catalogue = value ?? false;
                    _clearPersonalizedPermissionsError();
                  });
                },
              ),
              CheckboxListTile(
                title: const Text('Multiusuario'),
                subtitle: const Text('Gestionar usuarios'),
                value: _multiuser,
                onChanged: (value) {
                  setState(() {
                    _multiuser = value ?? false;
                    _clearPersonalizedPermissionsError();
                  });
                },
              ),
              CheckboxListTile(
                title: const Text('Editar Cuenta'),
                subtitle: const Text('Modificar configuración de la cuenta'),
                value: _editAccount,
                onChanged: (value) {
                  setState(() {
                    _editAccount = value ?? false;
                    _clearPersonalizedPermissionsError();
                  });
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Construye sección de control de acceso
  ///
  /// Permite configurar días de la semana y rango horario de acceso
  Widget _buildAccessControlSection(ThemeData theme) {
    final allDaysSelected = _selectedDays.length == DayOfWeek.values.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header con acción de seleccionar todos
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Control de Acceso',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  if (allDaysSelected) {
                    _selectedDays.clear();
                  } else {
                    _selectedDays.addAll(DayOfWeek.values);
                    _daysOfWeekError = false;
                  }
                });
              },
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              child: Text(
                allDaysSelected ? 'Deseleccionar todo' : 'Seleccionar todo',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Días de la semana
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _showValidationErrors && _daysOfWeekError
                ? theme.colorScheme.errorContainer.withOpacity(0.1)
                : theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _showValidationErrors && _daysOfWeekError
                  ? theme.colorScheme.error
                  : theme.colorScheme.outlineVariant.withOpacity(0.5),
              width: _showValidationErrors && _daysOfWeekError ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_rounded,
                    size: 16,
                    color: _showValidationErrors && _daysOfWeekError
                        ? theme.colorScheme.error
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Días permitidos',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: _showValidationErrors && _daysOfWeekError
                          ? theme.colorScheme.error
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: DayOfWeek.values.map((day) {
                  final isSelected = _selectedDays.contains(day);
                  return FilterChip(
                    label: Text(_translateDay(day)),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedDays.add(day);
                        } else {
                          _selectedDays.remove(day);
                        }
                        if (_selectedDays.isNotEmpty) {
                          _daysOfWeekError = false;
                        }
                      });
                    },
                    showCheckmark: false,
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected
                          ? theme.colorScheme.onPrimaryContainer
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                    visualDensity: VisualDensity.compact,
                    backgroundColor: Colors.transparent,
                    selectedColor: theme.colorScheme.primaryContainer,
                    side: BorderSide(
                      color: isSelected
                          ? theme.colorScheme.primaryContainer
                          : theme.colorScheme.outlineVariant.withOpacity(0.5),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  );
                }).toList(),
              ),
              if (_showValidationErrors && _daysOfWeekError) ...[
                const SizedBox(height: 8),
                Text(
                  'Selecciona al menos un día',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                    fontSize: 11,
                  ),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Selector de rango horario
        TimeRangeSelector(
          startTime: _startTime,
          endTime: _endTime,
          hasError: _showValidationErrors && _accessTimeError,
          errorMessage: 'Debes configurar el horario de acceso',
          onTimeSelected: (start, end) {
            setState(() {
              _startTime = start;
              _endTime = end;
              _accessTimeError = false;
            });
          },
        ),
      ],
    );
  }

  // ==========================================================================
  // ACTIONS
  // ==========================================================================

  /// Muestra diálogo de confirmación para eliminar usuario
  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(Icons.warning_rounded,
            color: Theme.of(context).colorScheme.error, size: 32),
        title: const Text('Eliminar Usuario'),
        content: Text(
            '¿Estás seguro de que deseas eliminar a ${widget.user!.email}?\n\nEsta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop(); // Close user dialog
              Provider.of<MultiUserProvider>(context, listen: false)
                  .deleteUser(widget.user!);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  /// Valida y guarda el usuario (crear o actualizar)
  ///
  /// **Validaciones:**
  /// - Campos básicos del formulario (email válido)
  /// - Tipo de permiso seleccionado
  /// - Al menos un permiso específico si es personalizado
  /// - Días de la semana seleccionados (excepto super admin)
  /// - Horario de acceso configurado (excepto super admin)
  ///
  /// Muestra errores visuales y snackbars si las validaciones fallan
  Future<void> _saveUser() async {
    // Activar mostrar errores de validación
    if (!mounted) return;
    setState(() {
      _showValidationErrors = true;
    });

    // Validar formulario
    if (!_formKey.currentState!.validate()) {
      // Scroll al principio para ver el error
      return;
    }

    // Validation: at least one permission type selected
    final permissionTypeValid = _isAdmin || _isSuperAdmin || _isPersonalized;
    if (!permissionTypeValid) {
      if (!mounted) return;
      setState(() {
        _permissionTypeError = true;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Debes seleccionar un tipo de permiso'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Validation: at least one permission selected for personalized users
    if (_isPersonalized) {
      final hasAnyPermission = _sales ||
          _arqueo ||
          _historyArqueo ||
          _transactions ||
          _catalogue ||
          _multiuser ||
          _editAccount;
      if (!hasAnyPermission) {
        if (!mounted) return;
        setState(() {
          _personalizedPermissionsError = true;
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                const Text('Debes seleccionar al menos un permiso específico'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
    }

    // Validation: days of week selected (if not super admin)
    final daysValid = _isSuperAdmin || _selectedDays.isNotEmpty;
    if (!daysValid) {
      if (!mounted) return;
      setState(() {
        _daysOfWeekError = true;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Debes seleccionar al menos un día de la semana'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Validation: access time configured (if not super admin)
    final timeValid = _isSuperAdmin || (_startTime != null && _endTime != null);
    if (!timeValid) {
      if (!mounted) return;
      setState(() {
        _accessTimeError = true;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Debes configurar el horario de acceso'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Reiniciar flags de error
    if (!mounted) return;
    setState(() {
      _permissionTypeError = false;
      _personalizedPermissionsError = false;
      _daysOfWeekError = false;
      _accessTimeError = false;
    });

    if (!mounted) return;
    final provider = Provider.of<MultiUserProvider>(context, listen: false);
    final now = DateTime.now();

    // Build days of week list
    final daysOfWeek =
        _selectedDays.map((day) => day.toString().split('.').last).toList();

    // Build time maps
    final startTime = _startTime != null
        ? {'hour': _startTime!.hour, 'minute': _startTime!.minute}
        : <String, dynamic>{};
    final endTime = _endTime != null
        ? {'hour': _endTime!.hour, 'minute': _endTime!.minute}
        : <String, dynamic>{};

    // Build permissions list
    List<String> permissions = [];
    if (_isPersonalized) {
      if (_sales) permissions.add(AdminPermission.registerSales.name);
      if (_arqueo) permissions.add(AdminPermission.createCashCount.name);
      if (_historyArqueo) permissions.add(AdminPermission.viewCashCountHistory.name);
      if (_transactions) permissions.add(AdminPermission.manageTransactions.name);
      if (_catalogue) permissions.add(AdminPermission.manageCatalogue.name);
      if (_multiuser) permissions.add(AdminPermission.manageUsers.name);
      if (_editAccount) permissions.add(AdminPermission.manageAccount.name);
    } else if (_isAdmin || _isSuperAdmin) {
       // Opcional: Podríamos agregar todos, pero la lógica de AdminProfile
       // ya maneja (admin || superAdmin) => true para cualquier permiso.
       // Dejamos la lista vacía o limpia para evitar redundancia.
    }

    final newUser = AdminProfile(
      id: widget.user?.id ?? '',
      inactivate: _inactivate,
      inactivateNote: _inactivateNoteController.text.trim(),
      email: _emailController.text.trim(),
      name: _nameController.text.trim(),
      admin: _isAdmin,
      superAdmin: _isSuperAdmin,
      personalized: _isPersonalized,
      creation: widget.user?.creation ?? now,
      lastUpdate: now,
      account: widget.user?.account ?? '',
      permissions: permissions,
      daysOfWeek: daysOfWeek,
      startTime: startTime,
      endTime: endTime,
    );

    bool success;
    if (widget.user != null) {
      success = await provider.updateUser(newUser);
    } else {
      success = await provider.createUser(newUser);
    }

    if (success && mounted) {
      // Si el usuario editado es el usuario actualmente logueado,
      // refrescar su AdminProfile en SalesProvider para que los cambios
      // de permisos se reflejen inmediatamente
      final salesProvider = Provider.of<SalesProvider>(context, listen: false);
      final currentAdminEmail = salesProvider.currentAdminProfile?.email;
      
      if (currentAdminEmail != null && 
          currentAdminEmail == newUser.email) {
        if (kDebugMode) {
          print('🔄 UserAdminDialog: Refrescando AdminProfile del usuario actual');
        }
        
        // Refrescar el perfil desde Firebase para obtener los cambios
        await salesProvider.refreshCurrentAdminProfile();
        
        if (kDebugMode) {
          print('✅ UserAdminDialog: AdminProfile actualizado');
        }
      }
      
      Navigator.of(context).pop();
    } else if (mounted && provider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.errorMessage!)),
      );
    }
  }
}
