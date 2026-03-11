import 'package:flutter/material.dart';
import 'package:sellweb/features/sales/domain/entities/ticket_model.dart';
import 'package:provider/provider.dart';
import 'package:sellweb/core/presentation/dialogs/dialogs.dart';
import 'package:sellweb/features/sales/presentation/providers/cloud_print_provider.dart';
import 'package:sellweb/features/sales/presentation/providers/sales_provider.dart';
import 'package:intl/intl.dart';

Future<void> showCloudPrintQueueDialog(BuildContext context) {
  return showDialog(
    context: context,
    builder: (context) => const CloudPrintQueueDialog(),
  );
}

// ======================================================================
// Dialog principal de la cola de impresión
// ======================================================================
class CloudPrintQueueDialog extends StatelessWidget {
  const CloudPrintQueueDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final salesProvider = context.read<SalesProvider>();
    final cloudPrintProvider = context.read<CloudPrintProvider>();
    final businessId = salesProvider.profileAccountSelected.id;

    if (businessId.isEmpty) {
      return BaseDialog(
        title: 'Cola de Impresión',
        icon: Icons.print_rounded,
        width: 500,
        content: const Center(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Text('No hay una cuenta de negocio seleccionada.'),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      );
    }

    return StreamBuilder<List<TicketModel>>(
      stream: cloudPrintProvider.getTicketQueue(businessId),
      builder: (context, snapshot) {
        final tickets = snapshot.data ?? [];
        final isLoading =
            snapshot.connectionState == ConnectionState.waiting;

        return BaseDialog(
          title: 'Cola de Impresión',
          icon: Icons.print_rounded,
          subtitle: isLoading
              ? 'Cargando...'
              : '${tickets.length} documento${tickets.length != 1 ? 's' : ''} en cola',
          width: 620,
          maxHeight: 560,
          scrollable: false,
          content: _PrintQueueContent(
            snapshot: snapshot,
            tickets: tickets,
            isLoading: isLoading,
            businessId: businessId,
            cloudPrintProvider: cloudPrintProvider,
          ),
          actions: [
            if (tickets.isNotEmpty)
              TextButton.icon(
                onPressed: () => _confirmClearAll(
                    context, cloudPrintProvider, businessId),
                icon: const Icon(Icons.delete_sweep_rounded,
                    color: Colors.redAccent),
                label: const Text(
                  'Limpiar todo',
                  style: TextStyle(color: Colors.redAccent),
                ),
              ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  // Diálogo de confirmación para limpiar TODA la cola
  void _confirmClearAll(BuildContext context, CloudPrintProvider provider,
      String businessId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.delete_sweep_rounded,
            color: Colors.redAccent, size: 36),
        title: const Text('Limpiar cola de impresión'),
        content: const Text(
          '¿Estás seguro de que deseas eliminar TODOS los documentos de la cola?\n\nEsta acción no se puede deshacer.',
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await provider.clearQueue(businessId);
            },
            child: const Text('Eliminar todo'),
          ),
        ],
      ),
    );
  }
}

// ======================================================================
// Contenido principal de la cola
// ======================================================================
class _PrintQueueContent extends StatelessWidget {
  const _PrintQueueContent({
    required this.snapshot,
    required this.tickets,
    required this.isLoading,
    required this.businessId,
    required this.cloudPrintProvider,
  });

  final AsyncSnapshot<List<TicketModel>> snapshot;
  final List<TicketModel> tickets;
  final bool isLoading;
  final String businessId;
  final CloudPrintProvider cloudPrintProvider;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isLoading) {
      return const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (snapshot.hasError) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(
                'Error al cargar la cola:\n${snapshot.error}',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      );
    }

    if (tickets.isEmpty) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.done_all_rounded,
                color: theme.colorScheme.primary.withValues(alpha: 0.4),
                size: 56,
              ),
              const SizedBox(height: 16),
              Text(
                'Cola vacía',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'No hay documentos pendientes de impresión.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: 400,
      child: ListView.separated(
        itemCount: tickets.length,
        separatorBuilder: (_, __) => Divider(
          height: 1,
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
        itemBuilder: (context, index) {
          return _PrintQueueItem(
            ticket: tickets[index],
            businessId: businessId,
            provider: cloudPrintProvider,
          );
        },
      ),
    );
  }
}

// ======================================================================
// Item individual de la cola
// ======================================================================
class _PrintQueueItem extends StatelessWidget {
  const _PrintQueueItem({
    required this.ticket,
    required this.businessId,
    required this.provider,
  });

  final TicketModel ticket;
  final String businessId;
  final CloudPrintProvider provider;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Datos formateados
    final currencySymbol = ticket.currencySymbol;
    final total = ticket.getTotalPrice;
    final totalFormatted =
        '$currencySymbol${NumberFormat('#,##0.00', 'es').format(total)}';
    final itemCount = ticket.getProductsQuantity();
    final itemCountLabel =
        '${itemCount % 1 == 0 ? itemCount.toInt() : itemCount} artículo${itemCount != 1 ? 's' : ''}';
    final date = ticket.creation.toDate();
    final dateLabel = DateFormat('dd/MM/yy • HH:mm').format(date);
    final payMode = ticket.getNamePayMode;
    final payModeColor = ticket.getPayModeColor;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ícono de ticket 
          Icon(Icons.receipt_long_rounded, color: theme.colorScheme.primary, size: 30),
          const SizedBox(width: 12),

          // Datos del ticket
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Fila: monto total + badge de estado
                Row(
                  children: [
                    Text(
                      totalFormatted,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    _PrintStatusChip(printStatus: ticket.printStatus),
                  ],
                ),
                const SizedBox(height: 4),
                // Cantidad de artículos + método de pago
                Row(
                  children: [
                    Icon(
                      Icons.shopping_bag_outlined,
                      size: 13,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      itemCountLabel,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: payModeColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      payMode,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                // Fecha y hora
                Row(
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: 13,
                      color: theme.colorScheme.onSurfaceVariant
                          .withValues(alpha: 0.65),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      dateLabel,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant
                            .withValues(alpha: 0.65),
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Botón de eliminar
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            color: theme.colorScheme.error,
            tooltip: 'Eliminar de la cola',
            visualDensity: VisualDensity.compact,
            onPressed: () =>
                _confirmDelete(context, provider, businessId, ticket.id),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    CloudPrintProvider prov,
    String bId,
    String ticketId,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar documento'),
        content: const Text(
            '¿Deseas eliminar este documento de la cola de impresión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await prov.removeTicket(bId, ticketId);
            },
            child: Text(
              'Eliminar',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }
}


// ======================================================================
// Chip semántico del estado de impresión
// ======================================================================
class _PrintStatusChip extends StatelessWidget {
  const _PrintStatusChip({required this.printStatus});

  final String printStatus;

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = switch (printStatus) {
      'printed' => ('Impreso', Colors.green, Icons.check_rounded),
      'failed' => ('Fallido', Colors.redAccent, Icons.warning_amber_rounded),
      _ => ('En espera', Colors.orange, Icons.hourglass_top_rounded),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
