import 'package:flutter/material.dart';
import 'package:sellweb/core/services/external/thermal_printer_http_service.dart';
import 'package:sellweb/presentation/widgets/dialogs/base/base_dialog.dart';
import 'package:sellweb/presentation/widgets/dialogs/base/standard_dialogs.dart';
import 'package:sellweb/presentation/widgets/dialogs/components/dialog_components.dart';
import 'package:sellweb/domain/entities/ticket_model.dart';
import '../../../../core/utils/fuctions.dart';

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

class _TicketOptionsDialogState extends State<TicketOptionsDialog> {
  bool _downloadPdf = false;
  bool _printDirectly = false;
  bool _shareTicket = false;
  bool _printBrowser = false;
  bool _isProcessing = false;
  bool _printerConnected = false;

  @override
  void initState() {
    super.initState();
    _checkPrinterAndSetDefaults();
  }

  Future<void> _checkPrinterAndSetDefaults() async {
    final printerService = ThermalPrinterHttpService();
    await printerService.initialize();

    setState(() {
      _printerConnected = printerService.isConnected;

      // Establecer valores por defecto
      if (_printerConnected) {
        _printDirectly = true;
      } else {
        _downloadPdf = true;
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

          // Estado de la impresora
          _buildPrinterStatus(),

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
                subtitle: _printerConnected
                    ? 'Enviar a impresora térmica conectada'
                    : 'No hay impresora conectada',
                value: _printDirectly && _printerConnected,
                onChanged: _printerConnected
                    ? (value) => setState(() => _printDirectly = value ?? false)
                    : null,
                iconColor: _printerConnected ? Colors.green : Colors.grey,
                enabled: _printerConnected,
              ),
              _buildOptionTile(
                icon: Icons.download_rounded,
                title: 'Descargar PDF',
                subtitle: 'Guardar ticket en formato PDF',
                value: _downloadPdf,
                onChanged: (value) =>
                    setState(() => _downloadPdf = value ?? false),
                iconColor: Colors.blue,
                enabled: true,
              ),
              _buildOptionTile(
                icon: Icons.print_outlined,
                title: 'Imprimir en Navegador',
                subtitle: 'Abrir administrador de impresión con PDF',
                value: _printBrowser,
                onChanged: (value) =>
                    setState(() => _printBrowser = value ?? false),
                iconColor: Colors.purple,
                enabled: true,
              ),
              _buildOptionTile(
                icon: Icons.share_rounded,
                title: 'Compartir Ticket',
                subtitle: 'Generar imagen para compartir (próximamente)',
                value: _shareTicket,
                onChanged: (value) =>
                    setState(() => _shareTicket = value ?? false),
                iconColor: Colors.orange,
                enabled: false, // Temporalmente deshabilitado
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

  Widget _buildPrinterStatus() {
    final theme = Theme.of(context);

    return DialogComponents.infoSection(
      context: context,
      title: 'Estado de la Impresora',
      icon: Icons.print_rounded,
      backgroundColor: _printerConnected
          ? Colors.green.withValues(alpha: 0.1)
          : Colors.orange.withValues(alpha: 0.1),
      content: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _printerConnected
                  ? Colors.green.withValues(alpha: 0.2)
                  : Colors.orange.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _printerConnected
                  ? Icons.check_circle_rounded
                  : Icons.warning_rounded,
              color: _printerConnected ? Colors.green[700] : Colors.orange[700],
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _printerConnected ? 'Impresora Conectada' : 'Sin Impresora',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: _printerConnected
                        ? Colors.green[700]
                        : Colors.orange[700],
                  ),
                ),
                Text(
                  _printerConnected
                      ? 'Lista para imprimir tickets'
                      : 'Usa otras opciones para procesar el ticket',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

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
    return !_isProcessing &&
        (_downloadPdf || _printDirectly || _shareTicket || _printBrowser);
  }

  Future<void> _processTicketOptions() async {
    setState(() => _isProcessing = true);

    try {
      final printerService = ThermalPrinterHttpService();
      await printerService.initialize();

      // Preparar datos del ticket
      final products = widget.ticket.products.map((item) {
        return {
          'quantity': item.quantity,
          'description': item.description,
          'price': Publications.getFormatoPrecio(value: item.salePrice),
        };
      }).toList();

      // Determinar método de pago
      String paymentMethod = 'Efectivo';
      switch (widget.ticket.payMode) {
        case 'mercadopago':
          paymentMethod = 'Mercado Pago';
          break;
        case 'card':
          paymentMethod = 'Tarjeta Déb/Créd';
          break;
        default:
          paymentMethod = 'Efectivo';
      }

      List<String> successMessages = [];
      List<String> errorMessages = [];

      // Procesar cada opción
      if (_printDirectly && printerService.isConnected) {
        final success = await printerService.printTicket(
          businessName: widget.businessName,
          products: products,
          total: widget.ticket.getTotalPrice,
          paymentMethod: paymentMethod,
          cashReceived: widget.ticket.valueReceived > 0
              ? widget.ticket.valueReceived
              : null,
          change: widget.ticket.valueReceived > widget.ticket.getTotalPrice
              ? widget.ticket.valueReceived - widget.ticket.getTotalPrice
              : null,
        );

        if (success) {
          successMessages.add('Ticket impreso correctamente');
        } else {
          errorMessages.add('Error al imprimir ticket');
        }
      }

      if (_downloadPdf) {
        final success = await printerService.generateTicketPdf(
          businessName: widget.businessName,
          products: products,
          total: widget.ticket.getTotalPrice,
          paymentMethod: paymentMethod,
          cashReceived: widget.ticket.valueReceived > 0
              ? widget.ticket.valueReceived
              : null,
          change: widget.ticket.valueReceived > widget.ticket.getTotalPrice
              ? widget.ticket.valueReceived - widget.ticket.getTotalPrice
              : null,
          ticketId: widget.ticket.id,
        );

        if (success) {
          successMessages.add('PDF descargado correctamente');
        } else {
          errorMessages.add('Error al generar PDF');
        }
      }

      if (_printBrowser) {
        final success = await printerService.printTicketWithBrowser(
          businessName: widget.businessName,
          products: products,
          total: widget.ticket.getTotalPrice,
          paymentMethod: paymentMethod,
          cashReceived: widget.ticket.valueReceived > 0
              ? widget.ticket.valueReceived
              : null,
          change: widget.ticket.valueReceived > widget.ticket.getTotalPrice
              ? widget.ticket.valueReceived - widget.ticket.getTotalPrice
              : null,
          ticketId: widget.ticket.id,
        );

        if (success) {
          successMessages.add('PDF abierto en administrador de impresión');
        } else {
          errorMessages.add('Error al abrir administrador de impresión');
        }
      }

      if (_shareTicket) {
        successMessages.add('Función de compartir disponible próximamente');
      }

      // Mostrar resultados
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
