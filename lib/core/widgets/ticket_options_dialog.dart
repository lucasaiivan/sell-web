import 'package:flutter/material.dart';
import 'package:sellweb/core/services/thermal_printer_service.dart';
import 'package:sellweb/domain/entities/ticket_model.dart';

/// Diálogo para seleccionar opciones del ticket después de confirmar la venta
class TicketOptionsDialog extends StatefulWidget {
  final TicketModel ticket;
  final String businessName;
  final VoidCallback onComplete;

  const TicketOptionsDialog({
    super.key,
    required this.ticket,
    required this.businessName,
    required this.onComplete,
  });

  @override
  State<TicketOptionsDialog> createState() => _TicketOptionsDialogState();
}

class _TicketOptionsDialogState extends State<TicketOptionsDialog> {
  bool _downloadPdf = false;
  bool _printDirectly = false;
  bool _shareTicket = false;
  bool _printBrowser = false; // Nueva opción para imprimir en navegador
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    // Verificar estado de impresora al inicializar
    _checkPrinterAndSetDefaults();
  }

  /// Verifica el estado de la impresora y establece valores por defecto
  Future<void> _checkPrinterAndSetDefaults() async {
    final printerService = ThermalPrinterService();
    await printerService.initialize();
    
    setState(() {
      // Si hay impresora conectada, activar impresión por defecto
      if (printerService.isConnected) {
        _printDirectly = true;
      } else {
        // Si no hay impresora, activar descarga PDF por defecto
        _downloadPdf = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: colorScheme.surface,
      title: Row(
        children: [
          Icon(Icons.receipt_long, color: colorScheme.primary),
          const SizedBox(width: 8),
          const Text('Opciones del ticket'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Selecciona las acciones que deseas realizar con tu ticket:',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 20),
          
          // Opción: Descargar PDF
          _buildOptionTile(
            icon: Icons.download,
            title: 'Descargar PDF',
            subtitle: 'Guardar ticket en formato PDF',
            value: _downloadPdf,
            onChanged: (value) => setState(() => _downloadPdf = value ?? false),
            iconColor: Colors.blue,
          ),
          
          const SizedBox(height: 12),
          
          // Opción: Imprimir directamente
          FutureBuilder<bool>(
            future: _checkPrinterStatus(),
            builder: (context, snapshot) {
              final isConnected = snapshot.data ?? false;
              return _buildOptionTile(
                icon: Icons.print,
                title: 'Imprimir directamente',
                subtitle: isConnected 
                  ? 'Enviar a impresora térmica'
                  : 'No hay impresora conectada',
                value: _printDirectly && isConnected,
                onChanged: isConnected 
                  ? (value) => setState(() => _printDirectly = value ?? false)
                  : null,
                iconColor: isConnected ? Colors.green : Colors.grey,
                enabled: isConnected,
              );
            },
          ),
          
          const SizedBox(height: 12),
          
          // Opción: Compartir
          _buildOptionTile(
            icon: Icons.share,
            title: 'Compartir ticket',
            subtitle: 'Generar imagen para compartir',
            value: _shareTicket,
            onChanged: (value) => setState(() => _shareTicket = value ?? false),
            iconColor: Colors.orange,
          ),
          
          const SizedBox(height: 12),
          
          // Opción: Imprimir en navegador
          _buildOptionTile(
            icon: Icons.print_outlined,
            title: 'Imprimir en navegador',
            subtitle: 'Abrir administrador de impresión con PDF',
            value: _printBrowser,
            onChanged: (value) => setState(() => _printBrowser = value ?? false),
            iconColor: Colors.purple,
          ),
          
          if (_isProcessing) ...[
            const SizedBox(height: 20),
            const Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 12),
                  Text('Procesando...'),
                ],
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isProcessing ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          icon: const Icon(Icons.check),
          label: const Text('Procesar'),
          onPressed: _isProcessing || (!_downloadPdf && !_printDirectly && !_shareTicket && !_printBrowser)
            ? null 
            : _processTicketOptions,
          style: FilledButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
          ),
        ),
      ],
    );
  }

  /// Construye un tile para cada opción
  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool?>? onChanged,
    required Color iconColor,
    bool enabled = true,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: enabled 
            ? colorScheme.outline.withValues(alpha: 0.2)
            : colorScheme.outline.withValues(alpha: 0.1),
        ),
        borderRadius: BorderRadius.circular(12),
        color: enabled && value
          ? colorScheme.primaryContainer.withValues(alpha: 0.1)
          : null,
      ),
      child: CheckboxListTile(
        value: value,
        onChanged: enabled ? onChanged : null,
        secondary: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: enabled 
              ? iconColor.withValues(alpha: 0.1)
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
              ? colorScheme.onSurface
              : colorScheme.onSurface.withValues(alpha: 0.5),
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: enabled 
              ? colorScheme.onSurface.withValues(alpha: 0.7)
              : colorScheme.onSurface.withValues(alpha: 0.4),
          ),
        ),
        controlAffinity: ListTileControlAffinity.trailing,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
        enabled: enabled,
      ),
    );
  }

  /// Verifica el estado de la impresora
  Future<bool> _checkPrinterStatus() async {
    final printerService = ThermalPrinterService();
    await printerService.initialize();
    return printerService.isConnected;
  }

  /// Procesa las opciones seleccionadas del ticket
  Future<void> _processTicketOptions() async {
    setState(() => _isProcessing = true);

    try {
      final printerService = ThermalPrinterService();
      await printerService.initialize();

      // Preparar datos del ticket
      final products = widget.ticket.listPoduct.map((item) {
        final product = item is Map ? item : item.toMap();
        return {
          'quantity': product['quantity'],
          'description': product['description'],
          'price': '\$${(product['salePrice'] * product['quantity']).toStringAsFixed(2)}',
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

      // Procesar cada opción seleccionada
      if (_printDirectly && printerService.isConnected) {
        final printSuccess = await printerService.printTicket(
          businessName: widget.businessName,
          products: products,
          total: widget.ticket.getTotalPrice,
          paymentMethod: paymentMethod,
          cashReceived: widget.ticket.valueReceived > 0 ? widget.ticket.valueReceived : null,
          change: widget.ticket.valueReceived > widget.ticket.getTotalPrice 
            ? widget.ticket.valueReceived - widget.ticket.getTotalPrice 
            : null,
        );

        if (printSuccess) {
          successMessages.add('Ticket impreso correctamente');
        } else {
          errorMessages.add('Error al imprimir ticket');
        }
      }

      if (_downloadPdf) {
        final pdfSuccess = await printerService.generateTicketPdf(
          businessName: widget.businessName,
          products: products,
          total: widget.ticket.getTotalPrice,
          paymentMethod: paymentMethod,
          cashReceived: widget.ticket.valueReceived > 0 ? widget.ticket.valueReceived : null,
          change: widget.ticket.valueReceived > widget.ticket.getTotalPrice 
            ? widget.ticket.valueReceived - widget.ticket.getTotalPrice 
            : null,
          ticketId: widget.ticket.id,
        );

        if (pdfSuccess) {
          successMessages.add('PDF descargado correctamente');
        } else {
          errorMessages.add('Error al generar PDF');
        }
      }

      if (_shareTicket) {
        try {
          // Por ahora, marcar como completado - la implementación de compartir
          // se puede integrar más adelante con la función existente del proyecto
          successMessages.add('Función de compartir disponible próximamente');
        } catch (e) {
          errorMessages.add('Error al compartir ticket');
        }
      }

      if (_printBrowser) {
        final browserPrintSuccess = await printerService.printTicketWithBrowser(
          businessName: widget.businessName,
          products: products,
          total: widget.ticket.getTotalPrice,
          paymentMethod: paymentMethod,
          cashReceived: widget.ticket.valueReceived > 0 ? widget.ticket.valueReceived : null,
          change: widget.ticket.valueReceived > widget.ticket.getTotalPrice 
            ? widget.ticket.valueReceived - widget.ticket.getTotalPrice 
            : null,
          ticketId: widget.ticket.id,
        );

        if (browserPrintSuccess) {
          successMessages.add('PDF abierto en administrador de impresión');
        } else {
          errorMessages.add('Error al abrir administrador de impresión');
        }
      }

      // Mostrar resultados
      if (mounted) {
        Navigator.of(context).pop();

        // Mostrar mensaje de éxito
        if (successMessages.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(successMessages.join('\n')),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }

        // Mostrar errores si los hay
        if (errorMessages.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessages.join('\n')),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }

        // Completar proceso
        widget.onComplete();
      }

    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al procesar opciones: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    setState(() => _isProcessing = false);
  }
}

/// Función helper para mostrar el diálogo de opciones de ticket
Future<void> showTicketOptionsDialog({
  required BuildContext context,
  required TicketModel ticket,
  required String businessName,
  required VoidCallback onComplete,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return TicketOptionsDialog(
        ticket: ticket,
        businessName: businessName,
        onComplete: onComplete,
      );
    },
  );
}
