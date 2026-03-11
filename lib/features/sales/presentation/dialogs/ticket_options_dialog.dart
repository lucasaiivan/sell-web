// ignore_for_file: use_build_context_synchronously
import '../../../../../core/core.dart';
import 'package:flutter/material.dart';
// import removed
import 'package:sellweb/features/sales/presentation/providers/cloud_print_provider.dart';
import 'package:sellweb/features/sales/presentation/providers/sales_provider.dart';
import 'package:provider/provider.dart';
import 'package:sellweb/features/sales/domain/entities/ticket_model.dart';
import 'package:sellweb/features/sales/presentation/dialogs/share_ticket_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';
// print_job.dart import removed

/// Diálogo modernizado para opciones del ticket siguiendo Material Design 3
class TicketOptionsDialog extends StatefulWidget {
  const TicketOptionsDialog({
    super.key,
    required this.ticket,
    required this.businessName,
    required this.onComplete,
  });

  final TicketModel ticket;
  final String businessName;
  final VoidCallback onComplete;

  @override
  State<TicketOptionsDialog> createState() => _TicketOptionsDialogState();
}

/// Clave de SharedPreferences para la preferencia de opción de ticket.
/// Valores: 'print', 'share', o vacío (sin preferencia).
const String _kTicketOptionPrefKey = 'ticket_option_preference';

/// Guarda la preferencia de opción de ticket en SharedPreferences.
Future<void> saveTicketOptionPreference(String value) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_kTicketOptionPrefKey, value);
}

/// Obtiene la preferencia guardada de opción de ticket. Retorna '' si no hay.
Future<String> getTicketOptionPreference() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString(_kTicketOptionPrefKey) ?? '';
}

class _TicketOptionsDialogState extends State<TicketOptionsDialog> {
  bool _printDirectly = false;
  bool _shareTicket = false;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _loadPreference();
  }

  Future<void> _loadPreference() async {
    final pref = await getTicketOptionPreference();
    if (!mounted) return;
    setState(() {
      if (pref == 'print') {
        _printDirectly = true;
        _shareTicket = false;
      } else if (pref == 'share') {
        _shareTicket = true;
        _printDirectly = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BaseDialog(
      title: 'Opciones del Ticket',
      icon: Icons.receipt_long_rounded,
      width: 500,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Información introductoria
          DialogComponents.infoSection(
            context: context,
            title: 'Procesar Ticket',
            icon: Icons.info_outline_rounded,
            content: Text(
              'Selecciona las acciones que deseas realizar con tu ticket de venta.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),

          DialogComponents.sectionSpacing,

          // Ya no necesitamos mostrar estado de la impresora localmente
          DialogComponents.sectionSpacing,

          // Opciones disponibles
          Text(
            'Opciones Disponibles',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          DialogComponents.itemSpacing,

          // Lista de opciones
          DialogComponents.itemList(
            context: context,
            showDividers: true,
            items: [
              _buildOptionTile(
                icon: Icons.print_rounded,
                title: 'Imprimir Directamente',
                subtitle: 'Enviar ticket a la cola de impresión',
                value: _printDirectly,
                onChanged: (value) =>
                    setState(() => _printDirectly = value ?? false),
                iconColor: Colors.blue,
                enabled: true,
              ),
              _buildOptionTile(
                icon: Icons.share_rounded,
                title: 'Compartir Ticket',
                subtitle: 'Texto, PDF, WhatsApp y más',
                value: _shareTicket,
                onChanged: (value) =>
                    setState(() => _shareTicket = value ?? false),
                iconColor: Colors.deepPurple,
                enabled: true,
              ),
            ],
          ),

          // Mostrar indicador de procesamiento
          if (_isProcessing) ...[
            DialogComponents.sectionSpacing,
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Procesando opciones del ticket...',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      actions: [
        DialogComponents.secondaryActionButton(
          context: context,
          text: 'Cancelar',
          onPressed: _isProcessing ? null : () => Navigator.of(context).pop(),
        ),
        DialogComponents.primaryActionButton(
          context: context,
          text: 'Procesar Ticket',
          icon: Icons.check_rounded,
          onPressed: _canProcess() ? _processTicketOptions : null,
          isLoading: _isProcessing,
        ),
      ],
    );
  }

  // El método _buildPrinterStatus() ha sido removido

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool?>? onChanged,
    required Color iconColor,
    required bool enabled,
  }) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: enabled && value
            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
            : null,
        borderRadius: BorderRadius.circular(8),
      ),
      child: CheckboxListTile(
        value: enabled ? value : false,
        onChanged: enabled ? onChanged : null,
        secondary: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: enabled
                ? iconColor.withValues(alpha: 0.15)
                : Colors.grey.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: enabled ? iconColor : Colors.grey,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            color: enabled
                ? theme.colorScheme.onSurface
                : theme.colorScheme.onSurface.withValues(alpha: 0.5),
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: enabled
                ? theme.colorScheme.onSurfaceVariant
                : theme.colorScheme.onSurface.withValues(alpha: 0.4),
          ),
        ),
        controlAffinity: ListTileControlAffinity.trailing,
        contentPadding: const EdgeInsets.symmetric(horizontal: 4),
        enabled: enabled,
      ),
    );
  }

  bool _canProcess() {
    return !_isProcessing && (_printDirectly || _shareTicket);
  }

  Future<void> _processTicketOptions() async {
    setState(() => _isProcessing = true);

    try {
      final cloudPrintProvider = context.read<CloudPrintProvider>();
      final salesProvider = context.read<SalesProvider>();
      
      final currentBusinessId = salesProvider.profileAccountSelected.id;
      if (_printDirectly && currentBusinessId.isEmpty) {
         throw Exception('No hay una cuenta de negocio seleccionada activa.');
      }

      List<String> successMessages = [];
      List<String> errorMessages = [];

      // Guardar preferencia del usuario
      if (_printDirectly) {
        await saveTicketOptionPreference('print');
      } else if (_shareTicket) {
        await saveTicketOptionPreference('share');
      }

      // Procesar cada opción
      if (_printDirectly) {
        final success = await cloudPrintProvider.enqueueTicket(
            businessId: currentBusinessId, 
            job: widget.ticket.copyWith(printStatus: 'waiting'),
        );

        if (success) {
          successMessages.add('Ticket enviado a la cola de impresión');
        } else {
          errorMessages.add(cloudPrintProvider.lastError ?? 'Error al poner en cola');
        }
      }

      if (_shareTicket) {
        if (mounted) {
          // Capturar el navigator y el contexto ANTES de hacer pop.
          // Después del pop el widget se desmonta y mounted == false,
          // por eso debemos guardarlo en variable local primero.
          final navigator = Navigator.of(context);
          final rootContext = navigator.context;

          navigator.pop();

          if (errorMessages.isNotEmpty) {
            showErrorDialog(
              context: rootContext,
              title: 'Algunos Errores Ocurrieron',
              message: errorMessages.join('\n'),
            );
          }

          widget.onComplete();

          // Pequeña pausa para que el pop termine su animación.
          await Future.delayed(const Duration(milliseconds: 300));

          // Usamos rootContext en lugar de `context` (ya desmontado).
          await showShareTicketDialog(
            context: rootContext,
            ticket: widget.ticket,
            businessName: widget.businessName,
          );
          return;
        }
      }

      // Mostrar resultados (solo llega aquí si _shareTicket == false)
      if (mounted) {
        Navigator.of(context).pop();

        if (errorMessages.isNotEmpty) {
          showErrorDialog(
            context: context,
            title: 'Algunos Errores Ocurrieron',
            message: errorMessages.join('\n'),
          );
        }

        widget.onComplete();
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        showErrorDialog(
          context: context,
          title: 'Error al Procesar',
          message: 'Ocurrió un error al procesar las opciones del ticket.',
          details: e.toString(),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }
}

/// Helper function para mostrar el diálogo de opciones del ticket
Future<void> showTicketOptionsDialog({
  required BuildContext context,
  required TicketModel ticket,
  required String businessName,
  required VoidCallback onComplete,
}) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => TicketOptionsDialog(
      ticket: ticket,
      businessName: businessName,
      onComplete: onComplete,
    ),
  );
}
