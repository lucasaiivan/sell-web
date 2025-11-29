import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sellweb/core/core.dart';
import '../../../auth/domain/entities/admin_profile.dart';
import '../provider/multi_user_provider.dart';

/// Days of the week enum for selection
enum DayOfWeek {
  monday,
  tuesday,
  wednesday,
  thursday,
  friday,
  saturday,
  sunday,
}

class UserAdminDialog extends StatefulWidget {
  final AdminProfile? user;

  const UserAdminDialog({super.key, this.user});

  @override
  State<UserAdminDialog> createState() => _UserAdminDialogState();
}

class _UserAdminDialogState extends State<UserAdminDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _emailController;
  late TextEditingController _nameController;
  
  // Permission Type
  bool _isAdmin = false;
  bool _isSuperAdmin = false;
  bool _isPersonalized = false;
  
  // Granular Permissions (for personalized users)
  bool _arqueo = false;
  bool _historyArqueo = false;
  bool _transactions = false;
  bool _catalogue = false;
  bool _multiuser = false;
  bool _editAccount = false;
  
  // Access Control
  Set<DayOfWeek> _selectedDays = {};
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  @override
  void initState() {
    super.initState();
    final user = widget.user;
    
    _emailController = TextEditingController(text: user?.email ?? '');
    _nameController = TextEditingController(text: user?.name ?? '');
    
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

  DayOfWeek? _dayStringToEnum(String day) {
    final dayLower = day.toLowerCase().trim();
    return DayOfWeek.values.firstWhere(
      (d) => d.toString().split('.').last == dayLower,
      orElse: () => DayOfWeek.monday,
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.user != null;
    final theme = Theme.of(context);

    return BaseDialog(
      title: isEditing ? 'Editar Usuario' : 'Nuevo Usuario',
      icon: isEditing ? Icons.edit_rounded : Icons.person_add_rounded,
      width: 550,
      maxHeight: 700,
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildBasicInfoSection(),
            const SizedBox(height: 20),
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
            if (!value.contains('@')) {
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
            color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withOpacity(0.5),
              width: 1,
            ),
          ),
          child: RadioGroup<String>(
            groupValue: _isAdmin ? 'admin' : _isPersonalized ? 'personalized' : '',
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
              });
            },
            child: Column(
              children: [
                RadioListTile<String>(
                  secondary: Icon(
                    Icons.admin_panel_settings_rounded,
                    color: _isAdmin ? Colors.blue : theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
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
                Divider(height: 1, color: theme.colorScheme.outlineVariant.withOpacity(0.3)),
                RadioListTile<String>(
                  secondary: Icon(
                    Icons.tune_rounded,
                    color: _isPersonalized ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
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

  Widget _buildGranularPermissionsSection() {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Permisos Específicos',
          style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
        ),
        const SizedBox(height: 8),
        CheckboxListTile(
          title: const Text('Arqueo'),
          subtitle: const Text('Crear cierre de caja'),
          value: _arqueo,
          onChanged: (value) => setState(() => _arqueo = value ?? false),
        ),
        CheckboxListTile(
          title: const Text('Historial de Arqueo'),
          subtitle: const Text('Ver y eliminar registros de caja'),
          value: _historyArqueo,
          onChanged: (value) => setState(() => _historyArqueo = value ?? false),
        ),
        CheckboxListTile(
          title: const Text('Transacciones'),
          subtitle: const Text('Ver y eliminar transacciones'),
          value: _transactions,
          onChanged: (value) => setState(() => _transactions = value ?? false),
        ),
        CheckboxListTile(
          title: const Text('Catálogo'),
          subtitle: const Text('Gestionar productos'),
          value: _catalogue,
          onChanged: (value) => setState(() => _catalogue = value ?? false),
        ),
        CheckboxListTile(
          title: const Text('Multiusuario'),
          subtitle: const Text('Gestionar usuarios'),
          value: _multiuser,
          onChanged: (value) => setState(() => _multiuser = value ?? false),
        ),
        CheckboxListTile(
          title: const Text('Editar Cuenta'),
          subtitle: const Text('Modificar configuración de la cuenta'),
          value: _editAccount,
          onChanged: (value) => setState(() => _editAccount = value ?? false),
        ),
      ],
    );
  }

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
        Text(
          'Días de la Semana',
          style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
        ),
        const SizedBox(height: 8),
        Wrap(
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
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        ListTile(
          leading: const Icon(Icons.access_time),
          title: const Text('Horario de Acceso'),
          subtitle: Text(
            _startTime != null && _endTime != null
                ? '${_formatTime(_startTime!)} - ${_formatTime(_endTime!)}'
                : 'Toca para configurar',
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: _selectAccessTime,
        ),
      ],
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(Icons.warning_rounded, color: Theme.of(context).colorScheme.error, size: 32),
        title: const Text('Eliminar Usuario'),
        content: Text('¿Estás seguro de que deseas eliminar a ${widget.user!.email}?\n\nEsta acción no se puede deshacer.'),
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

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _selectAccessTime() async {
    final startTime = await showTimePicker(
      context: context,
      initialTime: _startTime ?? const TimeOfDay(hour: 9, minute: 0),
      helpText: 'Selecciona la hora de inicio',
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );

    if (startTime == null) return;

    if (!mounted) return;

    final endTime = await showTimePicker(
      context: context,
      initialTime: _endTime ?? const TimeOfDay(hour: 18, minute: 0),
      helpText: 'Selecciona la hora de finalización',
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );

    if (endTime == null) return;

    // Validate time range
    final startMinutes = startTime.hour * 60 + startTime.minute;
    final endMinutes = endTime.hour * 60 + endTime.minute;

    if (startMinutes >= endMinutes) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La hora de inicio debe ser menor que la hora de fin'),
        ),
      );
      return;
    }

    setState(() {
      _startTime = startTime;
      _endTime = endTime;
    });
  }

  Future<void> _saveUser() async {
    if (!_formKey.currentState!.validate()) return;

    // Validation: at least one permission type selected
    if (!_isAdmin && !_isSuperAdmin && !_isPersonalized) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes seleccionar un tipo de permiso'),
        ),
      );
      return;
    }

    // Validation: days of week selected (if not super admin)
    if (!_isSuperAdmin && _selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes seleccionar al menos un día de la semana'),
        ),
      );
      return;
    }

    // Validation: access time configured (if not super admin)
    if (!_isSuperAdmin && (_startTime == null || _endTime == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes configurar el horario de acceso'),
        ),
      );
      return;
    }

    final provider = Provider.of<MultiUserProvider>(context, listen: false);
    final now = DateTime.now();

    // Build days of week list
    final daysOfWeek = _selectedDays
        .map((day) => day.toString().split('.').last)
        .toList();

    // Build time maps
    final startTime = _startTime != null
        ? {'hour': _startTime!.hour, 'minute': _startTime!.minute}
        : <String, dynamic>{};
    final endTime = _endTime != null
        ? {'hour': _endTime!.hour, 'minute': _endTime!.minute}
        : <String, dynamic>{};

    final newUser = AdminProfile(
      id: widget.user?.id ?? '',
      email: _emailController.text.trim(),
      name: _nameController.text.trim(),
      admin: _isAdmin,
      superAdmin: _isSuperAdmin,
      personalized: _isPersonalized,
      creation: widget.user?.creation ?? now,
      lastUpdate: now,
      account: widget.user?.account ?? '',
      arqueo: _isPersonalized ? _arqueo : _isAdmin || _isSuperAdmin,
      historyArqueo: _isPersonalized ? _historyArqueo : _isAdmin || _isSuperAdmin,
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
