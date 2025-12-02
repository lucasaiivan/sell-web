import 'package:flutter/material.dart';

/// Widget: Selector de rango de horario
///
/// **Responsabilidad:**
/// - Proveer UI amigable para seleccionar rango de horarios
/// - Mostrar visualmente el horario seleccionado
/// - Ofrecer horarios predefinidos (todo el día, comercial, etc.)
/// - Permitir selección manual personalizada
/// - Validar que la hora de inicio sea menor que la de fin
class TimeRangeSelector extends StatelessWidget {
  final TimeOfDay? startTime;
  final TimeOfDay? endTime;
  final Function(TimeOfDay, TimeOfDay) onTimeSelected;
  final bool hasError;
  final String? errorMessage;

  const TimeRangeSelector({
    super.key,
    required this.startTime,
    required this.endTime,
    required this.onTimeSelected,
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
        // Horarios predefinidos
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _PresetChip(
              label: 'Todo el día',
              icon: Icons.wb_sunny_rounded,
              startTime: const TimeOfDay(hour: 0, minute: 0),
              endTime: const TimeOfDay(hour: 23, minute: 59),
              isSelected: _isPresetSelected(
                const TimeOfDay(hour: 0, minute: 0),
                const TimeOfDay(hour: 23, minute: 59),
              ),
              onSelected: onTimeSelected,
              theme: theme,
            ),
            _PresetChip(
              label: 'Comercial',
              icon: Icons.business_rounded,
              startTime: const TimeOfDay(hour: 9, minute: 0),
              endTime: const TimeOfDay(hour: 18, minute: 0),
              isSelected: _isPresetSelected(
                const TimeOfDay(hour: 9, minute: 0),
                const TimeOfDay(hour: 18, minute: 0),
              ),
              onSelected: onTimeSelected,
              theme: theme,
            ),
            _PresetChip(
              label: 'Mañana',
              icon: Icons.wb_sunny_outlined,
              startTime: const TimeOfDay(hour: 6, minute: 0),
              endTime: const TimeOfDay(hour: 14, minute: 0),
              isSelected: _isPresetSelected(
                const TimeOfDay(hour: 6, minute: 0),
                const TimeOfDay(hour: 14, minute: 0),
              ),
              onSelected: onTimeSelected,
              theme: theme,
            ),
            _PresetChip(
              label: 'Tarde',
              icon: Icons.wb_twilight_rounded,
              startTime: const TimeOfDay(hour: 14, minute: 0),
              endTime: const TimeOfDay(hour: 22, minute: 0),
              isSelected: _isPresetSelected(
                const TimeOfDay(hour: 14, minute: 0),
                const TimeOfDay(hour: 22, minute: 0),
              ),
              onSelected: onTimeSelected,
              theme: theme,
            ),
            _PresetChip(
              label: 'Noche',
              icon: Icons.nightlight_rounded,
              startTime: const TimeOfDay(hour: 18, minute: 0),
              endTime: const TimeOfDay(hour: 2, minute: 0),
              isSelected: _isPresetSelected(
                const TimeOfDay(hour: 18, minute: 0),
                const TimeOfDay(hour: 2, minute: 0),
              ),
              onSelected: onTimeSelected,
              theme: theme,
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Selector manual
        hasSelection
            ? _buildSelectedTime(context, theme)
            : _buildEmptyState(context, theme),
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

  bool _isPresetSelected(TimeOfDay presetStart, TimeOfDay presetEnd) {
    if (startTime == null || endTime == null) return false;
    return startTime!.hour == presetStart.hour &&
        startTime!.minute == presetStart.minute &&
        endTime!.hour == presetEnd.hour &&
        endTime!.minute == presetEnd.minute;
  }

  Future<void> _selectCustomTime(BuildContext context, {required bool isStart}) async {
    final initialTime = isStart
        ? (startTime ?? const TimeOfDay(hour: 9, minute: 0))
        : (endTime ?? const TimeOfDay(hour: 18, minute: 0));

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
      if (isStart) {
        final end = endTime ?? const TimeOfDay(hour: 18, minute: 0);
        onTimeSelected(selectedTime, end);
      } else {
        final start = startTime ?? const TimeOfDay(hour: 9, minute: 0);
        onTimeSelected(start, selectedTime);
      }
    }
  }

  Widget _buildSelectedTime(BuildContext context, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(0),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => _selectCustomTime(context, isStart: true),
              borderRadius: BorderRadius.circular(12),
              child: _TimeCard(
                label: 'Inicio',
                time: startTime!,
                icon: Icons.login_rounded,
                theme: theme,
              ),
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
            child: InkWell(
              onTap: () => _selectCustomTime(context, isStart: false),
              borderRadius: BorderRadius.circular(12),
              child: _TimeCard(
                label: 'Fin',
                time: endTime!,
                icon: Icons.logout_rounded,
                theme: theme,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Icon(
            Icons.access_time_rounded,
            size: 40,
            color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
          ),
          const SizedBox(height: 12),
          Text(
            'Selecciona un horario predefinido o personalizado',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'Toca en los chips de arriba para elegir',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
            ),
          ),
        ],
      ),
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

class _PresetChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final bool isSelected;
  final Function(TimeOfDay, TimeOfDay) onSelected;
  final ThemeData theme;

  const _PresetChip({
    required this.label,
    required this.icon,
    required this.startTime,
    required this.endTime,
    required this.isSelected,
    required this.onSelected,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(   
      avatar:!isSelected
          ? Icon(
              icon,
              size: 20, 
            )
          : null,
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(startTime, endTime),   
    );
  }
}
