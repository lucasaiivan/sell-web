import 'package:flutter/material.dart';

/// Widget: Selector de rango de horario
///
/// **Responsabilidad:**
/// - Proveer UI amigable para seleccionar rango de horarios
/// - Mostrar visualmente el horario seleccionado
/// - Validar que la hora de inicio sea menor que la de fin
class TimeRangeSelector extends StatelessWidget {
  final TimeOfDay? startTime;
  final TimeOfDay? endTime;
  final VoidCallback onTap;
  final bool hasError;
  final String? errorMessage;

  const TimeRangeSelector({
    super.key,
    required this.startTime,
    required this.endTime,
    required this.onTap,
    this.hasError = false,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasSelection = startTime != null && endTime != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.schedule_rounded,
              size: 20,
              color: hasError
                  ? theme.colorScheme.error
                  : theme.colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              'Horario de Acceso',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: hasError
                    ? theme.colorScheme.error
                    : theme.colorScheme.primary,
              ),
            ),
            if (hasError) ...[
              const SizedBox(width: 8),
              Icon(
                Icons.error_outline_rounded,
                size: 18,
                color: theme.colorScheme.error,
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: hasError
                  ? theme.colorScheme.errorContainer.withOpacity(0.2)
                  : theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: hasError
                    ? theme.colorScheme.error
                    : theme.colorScheme.outlineVariant.withOpacity(0.5),
                width: hasError ? 2 : 1,
              ),
            ),
            child: hasSelection
                ? _buildSelectedTime(context, theme)
                : _buildEmptyState(context, theme),
          ),
        ),
        if (hasError && errorMessage != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 14,
                color: theme.colorScheme.error,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  errorMessage!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildSelectedTime(BuildContext context, ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: _TimeCard(
            label: 'Inicio',
            time: startTime!,
            icon: Icons.wb_sunny_rounded,
            theme: theme,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Icon(
            Icons.arrow_forward_rounded,
            color: theme.colorScheme.primary,
            size: 24,
          ),
        ),
        Expanded(
          child: _TimeCard(
            label: 'Fin',
            time: endTime!,
            icon: Icons.nightlight_rounded,
            theme: theme,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, ThemeData theme) {
    return Column(
      children: [
        Icon(
          Icons.access_time_rounded,
          size: 40,
          color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
        ),
        const SizedBox(height: 12),
        Text(
          'Toca para seleccionar horario',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Define el rango de acceso permitido',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
          ),
        ),
      ],
    );
  }
}

class _TimeCard extends StatelessWidget {
  final String label;
  final TimeOfDay time;
  final IconData icon;
  final ThemeData theme;

  const _TimeCard({
    required this.label,
    required this.time,
    required this.icon,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: theme.colorScheme.primary,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _formatTime(time),
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

/// Dialog: Selector de rango de horario con preset options
///
/// **Responsabilidad:**
/// - Mostrar diálogo amigable para seleccionar horarios
/// - Ofrecer opciones preset comunes (horario comercial, completo, etc.)
/// - Permitir selección manual personalizada
class TimeRangePickerDialog extends StatefulWidget {
  final TimeOfDay? initialStartTime;
  final TimeOfDay? initialEndTime;

  const TimeRangePickerDialog({
    super.key,
    this.initialStartTime,
    this.initialEndTime,
  });

  @override
  State<TimeRangePickerDialog> createState() => _TimeRangePickerDialogState();
}

class _TimeRangePickerDialogState extends State<TimeRangePickerDialog> {
  late TimeOfDay? _startTime;
  late TimeOfDay? _endTime;

  @override
  void initState() {
    super.initState();
    _startTime = widget.initialStartTime;
    _endTime = widget.initialEndTime;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.schedule_rounded,
                    color: theme.colorScheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Seleccionar Horario',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Define el rango de acceso',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Horarios Predefinidos',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            _buildPresetOptions(),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 24),
            Text(
              'Personalizado',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            _buildCustomTimePickers(),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: _canSave() ? _saveAndClose : null,
                  icon: const Icon(Icons.check),
                  label: const Text('Aplicar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetOptions() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _PresetChip(
          label: 'Todo el día',
          icon: Icons.wb_sunny_rounded,
          startTime: const TimeOfDay(hour: 0, minute: 0),
          endTime: const TimeOfDay(hour: 23, minute: 59),
          onSelected: _selectPreset,
        ),
        _PresetChip(
          label: 'Comercial',
          icon: Icons.business_rounded,
          startTime: const TimeOfDay(hour: 9, minute: 0),
          endTime: const TimeOfDay(hour: 18, minute: 0),
          onSelected: _selectPreset,
        ),
        _PresetChip(
          label: 'Mañana',
          icon: Icons.wb_sunny_outlined,
          startTime: const TimeOfDay(hour: 6, minute: 0),
          endTime: const TimeOfDay(hour: 14, minute: 0),
          onSelected: _selectPreset,
        ),
        _PresetChip(
          label: 'Tarde',
          icon: Icons.wb_twilight_rounded,
          startTime: const TimeOfDay(hour: 14, minute: 0),
          endTime: const TimeOfDay(hour: 22, minute: 0),
          onSelected: _selectPreset,
        ),
        _PresetChip(
          label: 'Noche',
          icon: Icons.nightlight_rounded,
          startTime: const TimeOfDay(hour: 18, minute: 0),
          endTime: const TimeOfDay(hour: 2, minute: 0),
          onSelected: _selectPreset,
        ),
      ],
    );
  }

  Widget _buildCustomTimePickers() {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: _TimePickerButton(
            label: 'Hora de Inicio',
            icon: Icons.login_rounded,
            time: _startTime,
            onTap: () => _selectTime(isStart: true),
            theme: theme,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _TimePickerButton(
            label: 'Hora de Fin',
            icon: Icons.logout_rounded,
            time: _endTime,
            onTap: () => _selectTime(isStart: false),
            theme: theme,
          ),
        ),
      ],
    );
  }

  void _selectPreset(TimeOfDay start, TimeOfDay end) {
    setState(() {
      _startTime = start;
      _endTime = end;
    });
  }

  Future<void> _selectTime({required bool isStart}) async {
    final initialTime = isStart
        ? (_startTime ?? const TimeOfDay(hour: 9, minute: 0))
        : (_endTime ?? const TimeOfDay(hour: 18, minute: 0));

    final selectedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
      helpText: isStart ? 'Hora de inicio' : 'Hora de fin',
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );

    if (selectedTime != null) {
      setState(() {
        if (isStart) {
          _startTime = selectedTime;
        } else {
          _endTime = selectedTime;
        }
      });
    }
  }

  bool _canSave() {
    if (_startTime == null || _endTime == null) return false;
    
    final startMinutes = _startTime!.hour * 60 + _startTime!.minute;
    final endMinutes = _endTime!.hour * 60 + _endTime!.minute;
    
    return startMinutes < endMinutes;
  }

  void _saveAndClose() {
    if (_canSave()) {
      Navigator.of(context).pop(<String, TimeOfDay>{
        'start': _startTime!,
        'end': _endTime!,
      });
    }
  }
}

class _PresetChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final Function(TimeOfDay, TimeOfDay) onSelected;

  const _PresetChip({
    required this.label,
    required this.icon,
    required this.startTime,
    required this.endTime,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ActionChip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      onPressed: () => onSelected(startTime, endTime),
      backgroundColor: theme.colorScheme.surfaceContainerHighest,
      side: BorderSide(
        color: theme.colorScheme.outlineVariant,
      ),
    );
  }
}

class _TimePickerButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final TimeOfDay? time;
  final VoidCallback onTap;
  final ThemeData theme;

  const _TimePickerButton({
    required this.label,
    required this.icon,
    required this.time,
    required this.onTap,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: time != null
              ? theme.colorScheme.primaryContainer.withOpacity(0.5)
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: time != null
                ? theme.colorScheme.primary.withOpacity(0.5)
                : theme.colorScheme.outlineVariant,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: time != null
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              time != null ? _formatTime(time!) : '--:--',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: time != null
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
