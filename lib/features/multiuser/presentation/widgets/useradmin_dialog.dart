import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:sellweb/core/core.dart';
import 'package:sellweb/core/utils/formatters/date_formatter.dart';
import '../../../auth/domain/entities/admin_profile.dart';
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

    _arqueo = user?.arqueo ?? false;
    _historyArqueo = user?.historyArqueo ?? false;
    _transactions = user?.transactions ?? false;
    _catalogue = user?.catalogue ?? false;
    _multiuser = user?.multiuser ?? false;
    _editAccount = user?.editAccount ?? false;

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
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Información Básica',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 12),
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
        const SizedBox(height: 12),
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
                            'Nota de Bloqueo',
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
                        labelText: 'Motivo del bloqueo (opcional)',
                        hintText: 'Ej: Usuario suspendido temporalmente por...',
                        maxLines: 3,
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
          Text(
            'Tipo de Permiso',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.purple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.purple.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.shield_rounded,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Control de Acceso',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Text(
              'Días de la Semana',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: _showValidationErrors && _daysOfWeekError
                    ? theme.colorScheme.error
                    : null,
              ),
            ),
            if (_showValidationErrors && _daysOfWeekError) ...[
              const SizedBox(width: 8),
              Icon(
                Icons.error_outline_rounded,
                size: 18,
                color: theme.colorScheme.error,
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: _showValidationErrors && _daysOfWeekError
              ? BoxDecoration(
                  color: theme.colorScheme.errorContainer.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.error,
                    width: 2,
                  ),
                )
              : null,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: DayOfWeek.values.map((day) {
              return FilterChip(
                label: Text(_translateDay(day)),
                selected: _selectedDays.contains(day),
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedDays.add(day);
                    } else {
                      _selectedDays.remove(day);
                    }
                    // Limpiar error si hay al menos un día seleccionado
                    if (_selectedDays.isNotEmpty) {
                      _daysOfWeekError = false;
                    }
                  });
                },
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),
        TimeRangeSelector(
          startTime: _startTime,
          endTime: _endTime,
          hasError: _showValidationErrors && _accessTimeError,
          errorMessage: 'Debes configurar el horario de acceso',
          onTap: _selectAccessTime,
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

  /// Muestra diálogo para seleccionar rango de horario de acceso
  Future<void> _selectAccessTime() async {
    final result = await showDialog<Map<String, TimeOfDay>>(
      context: context,
      builder: (context) => TimeRangePickerDialog(
        initialStartTime: _startTime,
        initialEndTime: _endTime,
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _startTime = result['start'];
        _endTime = result['end'];
        // Limpiar error de validación
        _accessTimeError = false;
      });
    }
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
      setState(() {
        _permissionTypeError = true;
      });
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
      final hasAnyPermission = _arqueo ||
          _historyArqueo ||
          _transactions ||
          _catalogue ||
          _multiuser ||
          _editAccount;
      if (!hasAnyPermission) {
        setState(() {
          _personalizedPermissionsError = true;
        });
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
      setState(() {
        _daysOfWeekError = true;
      });
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
      setState(() {
        _accessTimeError = true;
      });
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
    setState(() {
      _permissionTypeError = false;
      _personalizedPermissionsError = false;
      _daysOfWeekError = false;
      _accessTimeError = false;
    });

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
      arqueo: _isPersonalized ? _arqueo : _isAdmin || _isSuperAdmin,
      historyArqueo:
          _isPersonalized ? _historyArqueo : _isAdmin || _isSuperAdmin,
      transactions: _isPersonalized ? _transactions : _isAdmin || _isSuperAdmin,
      catalogue: _isPersonalized ? _catalogue : _isAdmin || _isSuperAdmin,
      multiuser: _isPersonalized ? _multiuser : _isAdmin || _isSuperAdmin,
      editAccount: _isPersonalized ? _editAccount : _isAdmin || _isSuperAdmin,
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
      Navigator.of(context).pop();
    } else if (mounted && provider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.errorMessage!)),
      );
    }
  }
}
