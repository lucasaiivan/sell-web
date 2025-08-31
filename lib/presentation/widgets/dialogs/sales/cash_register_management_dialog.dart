import '../../../../core/core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../widgets/dialogs/tickets/last_ticket_dialog.dart';
import '../../../../domain/entities/cash_register_model.dart';
import '../../../../domain/entities/ticket_model.dart';
import '../../../../presentation/providers/auth_provider.dart';
import '../../../../presentation/providers/cash_register_provider.dart';
import '../../../../presentation/providers/sell_provider.dart';
import 'cash_flow_dialog.dart';
import 'cash_register_close_dialog.dart';
import 'cash_register_open_dialog.dart';

/// Diálogo principal para administrar cajas registradoras con diseño responsivo.
/// Optimizado para experiencia móvil y desktop siguiendo Material Design 3.
class CashRegisterManagementDialog extends StatelessWidget {
  const CashRegisterManagementDialog({super.key});

  @override
  Widget build(BuildContext context) {
    // var
    String sTitle = 'Administración de Caja';

    // provider : Obtener el provider de caja
    final cashRegisterProvider = context.watch<CashRegisterProvider>();

    // si existe una caja seleccionada => sTitle => 'Flujo de Caja'
    if (cashRegisterProvider.hasActiveCashRegister) {
      sTitle = 'Flujo de Caja';
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // render : Responsive design
        final isMobileDevice = isMobile(context);
        // dialog : base dialog
        return BaseDialog(
          title: sTitle,
          icon: Icons.point_of_sale_rounded,
          headerColor: Theme.of(context)
              .colorScheme
              .secondaryContainer
              .withValues(alpha: 0.85),
          width: getResponsiveValue(
            context,
            mobile: null,
            tablet: 600,
            desktop: 700,
          ),
          maxHeight: getResponsiveValue(
            context,
            mobile: constraints.maxHeight * 0.9,
            tablet: 700,
            desktop: 800,
          ),
          content: Builder(
            builder: (context) {
              // Si está cargando, mostrar indicador de progreso
              if (cashRegisterProvider.isLoadingActive) {
                return SizedBox(
                  height:getResponsiveValue(context, mobile: 100, desktop: 120),
                  width: double.infinity,
                  child: const Center(child: CircularProgressIndicator()),
                );
              }
              // view : Construir contenido responsivo de la  información de caja
              return _buildResponsiveContent(context, cashRegisterProvider, isMobileDevice);
            },
          ),
          actions: [
            // Botones de acción de caja (Deseleccionar/Cerrar) - Solo si hay caja activa
            if (cashRegisterProvider.hasActiveCashRegister)
              ..._buildCashRegisterActionButtons(
                  context, cashRegisterProvider, isMobileDevice),
          ],
        );
      },
    );
  }

  // view : Construir contenido responsivo de la información de caja existente o muestra mensaje de no caja activa
  Widget _buildResponsiveContent(BuildContext context, CashRegisterProvider provider, bool isMobile) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: getResponsiveSpacing(context, scale: 0.5)),
        if (provider.hasActiveCashRegister)
          // view : Mostrar información de caja activa
          _buildActiveCashRegister(context, provider, isMobile)
        else
          // view : Mostrar mensaje de no caja activa
          _buildNoCashRegister(context, isMobile),
      ],
    );
  }

  // view : información de caja activa
  Widget _buildActiveCashRegister(BuildContext context, CashRegisterProvider provider, bool isMobile) {

    final cashRegister = provider.currentActiveCashRegister!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // view : balance total y botones de flujo de caja
        DialogComponents.summaryContainer(
          context: context,
          label: 'Balance total',
          value: CurrencyFormatter.formatPrice(value: cashRegister.getExpectedBalance),
          icon: Icons.monetization_on_rounded,
          backgroundColor:Theme.of(context).colorScheme.primary.withValues(alpha: 0.03),
          child: Column(
            children: [
              // view : información de flujo de caja
              _buildCashFlowView(context, provider, isMobile), 
              SizedBox(height: getResponsiveSpacing(context, scale: 1.5)),
              // view : lista de las ultimas ventas
              _buildRecentTicketsView(context, provider, isMobile),
            ],
          ),
        ),
        DialogComponents.sectionSpacing,
      ],
    );
  }

  List<Widget> _buildCashRegisterActionButtons(
      BuildContext context, CashRegisterProvider provider, bool isMobile) {
    final cashRegister = provider.currentActiveCashRegister!;

    return [
      // button : cierre de caja
      DialogComponents.primaryActionButton(
        context: context,
        text: 'Cerrar Caja',
        icon: Icons.output_rounded,
        onPressed: () => _showCloseDialog(context, cashRegister),
      ),
      // button : cancelar el dialog
      DialogComponents.secondaryActionButton(
        context: context,
        text: 'Cancelar',
        onPressed: () => Navigator.of(context).pop(),
      ),
    ];
  }

  Widget _cashFlowInformation(BuildContext context, CashRegister cashRegister) {
    final theme = Theme.of(context);

    final items = [
      {
        'label': 'Ventas',
        'value': cashRegister.sales.toString(),
      },
      {
        'label': 'Facturación',
        'value': CurrencyFormatter.formatPrice(value: cashRegister.billing),
      },
      {
        'label': 'Descuentos',
        'value': CurrencyFormatter.formatPrice(value: cashRegister.discount),
      },
      {
        'label': 'Fecha de creación',
        'value':
            DateFormatter.formatPublicationDate(dateTime: cashRegister.opening),
      },
      {
        'label': 'Tiempo transcurrido',
        'value':
            DateFormatter.getElapsedTime(fechaInicio: cashRegister.opening),
      },
    ];

    return Column(
      children: [
        for (int i = 0; i < items.length; i++) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  items[i]['label'] as String,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  items[i]['value'] as String,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          if (i < items.length - 1) const AppDivider(),
        ],
      ],
    );
  }

  Widget _buildNoCashRegister(BuildContext context, bool isMobile) {
    final theme = Theme.of(context);
    final provider = context.watch<CashRegisterProvider>();
    final authProvider = context.watch<AuthProvider>();

    // widgets
    Widget infoCashRegister = DialogComponents.infoBadge(
      context: context,
      margin: EdgeInsets.only(bottom: isMobile ? 16 : 24),
      borderRadius: 5,
      text:
          'Las cajas te permiten diferenciar tus transacciones y llevar un control de tu flujo de caja de cada turno',
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Verificar si hay cajas disponibles
        if (provider.hasAvailableCashRegisters) ...[
          // Mostrar lista de cajas disponibles usando DialogComponents.itemList
          DialogComponents.itemList(
            context: context,
            title: 'Cajas activas',
            maxVisibleItems: 4,
            expandText:
                'Ver más cajas (${provider.activeCashRegisters.length > 4 ? provider.activeCashRegisters.length - 4 : 0})',
            collapseText: 'Ver menos',
            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.04),
            borderColor: theme.colorScheme.primary.withValues(alpha: 0.01),
            items: provider.activeCashRegisters.map((cashRegister) {
              return _buildCashRegisterTile(
                  context, cashRegister, provider, isMobile);
            }).toList(),
          ),
          SizedBox(height: isMobile ? 16 : 24),
        ] else ...[
          // view : Mostrar mensaje de no cajas disponibles
          Container(
            padding: EdgeInsets.symmetric(
              vertical: isMobile ? 32 : 48,
              horizontal: isMobile ? 16 : 24,
            ),
            child: Column(
              children: [
                // icon and text : Icono y texto representativo para vista sin cajas
                Container(
                  padding: EdgeInsets.all(isMobile ? 12 : 16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainer
                        .withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
                  ),
                  child: Icon(
                    Icons.point_of_sale_outlined,
                    size: isMobile ? 36 : 48,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                SizedBox(height: isMobile ? 12 : 16),
                Text(
                  'No hay cajas disponibles',
                  style: (isMobile
                          ? theme.textTheme.bodyMedium
                          : theme.textTheme.bodyLarge)
                      ?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant
                        .withValues(alpha: 0.7),
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: isMobile ? 4 : 8),
                infoCashRegister,
              ],
            ),
          ),
        ],
        Row(
          children: [
            const Spacer(),
            DialogComponents.primaryActionButton(
              context: context,
              text: 'Nueva caja',
              onPressed:
                  authProvider.isGuest ? null : () => _showOpenDialog(context),
              isLoading: provider.isLoadingActive,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCashRegisterTile(BuildContext context, CashRegister cashRegister,
      CashRegisterProvider provider, bool isMobile) {
    final theme = Theme.of(context);

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 300),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 10 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => provider.selectCashRegister(cashRegister),
                borderRadius: BorderRadius.circular(8),
                hoverColor: theme.colorScheme.primary.withValues(alpha: 0.05),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 8 : 12,
                    vertical: isMobile ? 8 : 12,
                  ),
                  child: Row(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: EdgeInsets.all(isMobile ? 6 : 8),
                        decoration: BoxDecoration(
                          color:
                              theme.colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(isMobile ? 4 : 6),
                        ),
                        child: Icon(
                          Icons.point_of_sale_rounded,
                          size: isMobile ? 14 : 16,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      SizedBox(width: isMobile ? 10 : 12),
                      Expanded(
                        child: Text(
                          cashRegister.description,
                          style: (isMobile
                                  ? theme.textTheme.bodySmall
                                  : theme.textTheme.bodyMedium)
                              ?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      AnimatedRotation(
                        duration: const Duration(milliseconds: 200),
                        turns: 0,
                        child: Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: isMobile ? 12 : 16,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecentTicketsView(
      BuildContext context, CashRegisterProvider provider, bool isMobile) {
    final sellProvider = context.watch<SellProvider>();
    final accountId = sellProvider.profileAccountSelected.id;

    if (accountId.isEmpty) return const SizedBox();

    return FutureBuilder<List<Map<String, dynamic>>?>(
      future: provider.getTodayTickets(accountId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyTicketsView(context, isMobile);
        }

        final allTickets = snapshot.data!;
        // Convertir a TicketModel y ordenar por fecha (más recientes primero)
        final tickets = allTickets.map((ticketData) {
          try {
            // Crear TicketModel desde Map usando los datos directamente
            return TicketModel(
              id: ticketData['id'] ?? '',
              payMode: ticketData['payMode'] ?? '',
              sellerName: ticketData['sellerName'] ?? '',
              sellerId: ticketData['sellerId'] ?? '',
              currencySymbol: ticketData['currencySymbol'] ?? '\$',
              cashRegisterName: ticketData['cashRegisterName'] ?? ticketData['cashRegister'] ?? '',
              cashRegisterId: ticketData['cashRegisterId'] ?? '',
              priceTotal: (ticketData['priceTotal'] ?? 0).toDouble(),
              valueReceived: (ticketData['valueReceived'] ?? 0).toDouble(),
              discount: (ticketData['discount'] ?? 0).toDouble(),
              discountIsPercentage: ticketData['discountIsPercentage'] ?? false,
              transactionType: ticketData['transactionType'] ?? 'sale',
              listPoduct: ticketData['listPoduct'] != null
                  ? List<Map<String, dynamic>>.from((ticketData['listPoduct'] as List).map(
                      (item) => item is Map<String, dynamic>
                          ? item
                          : Map<String, dynamic>.from(item as Map)))
                  : [],
              creation: ticketData['creation'] ?? Timestamp.now(),
            );
          } catch (e) {
            return null;
          }
        }).where((ticket) => ticket != null).cast<TicketModel>().toList();

        // Ordenar por fecha de creación (más recientes primero)
        tickets.sort((a, b) => b.creation.compareTo(a.creation));

        // Tomar solo los últimos 5
        final recentTickets = tickets.take(5).toList();

        if (recentTickets.isEmpty) {
          return _buildEmptyTicketsView(context, isMobile);
        }

        return DialogComponents.itemList(
          context: context,
          useFillStyle: true,
          showDividers: true,
          title: 'Últimas Ventas',
          maxVisibleItems: 5,
          expandText: '',
          collapseText: '',
          items: recentTickets.map((ticket) {
            return _buildTicketTile(context, ticket, isMobile);
          }).toList(),
        );
      },
    );
  }

  Widget _buildEmptyTicketsView(BuildContext context, bool isMobile) {
    final theme = Theme.of(context);
    
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: isMobile ? 20 : 24,
        horizontal: isMobile ? 16 : 20,
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(isMobile ? 8 : 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainer.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(isMobile ? 8 : 12),
            ),
            child: Icon(
              Icons.receipt_long_outlined,
              size: isMobile ? 24 : 32,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: isMobile ? 8 : 12),
          Text(
            'No hay ventas recientes',
            style: (isMobile
                    ? theme.textTheme.bodyMedium
                    : theme.textTheme.bodyLarge)
                ?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTicketTile(BuildContext context, TicketModel ticket, bool isMobile) {
    final theme = Theme.of(context);
    final sellProvider = context.read<SellProvider>();
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showLastTicketDialog(context, ticket, sellProvider.profileAccountSelected.name),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: Row(
            children: [
              // Icono del ticket
              Container(
                padding: EdgeInsets.all(isMobile ? 6 : 8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(isMobile ? 6 : 8),
                ),
                child: Icon(
                  Icons.receipt_rounded,
                  size: isMobile ? 14 : 16,
                  color: theme.colorScheme.primary,
                ),
              ),
              SizedBox(width: isMobile ? 8 : 12),

              // Información del ticket
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ticket ${ticket.id.length > 8 ? ticket.id.substring(ticket.id.length - 8) : ticket.id}',
                      style: (isMobile
                              ? theme.textTheme.bodySmall
                              : theme.textTheme.bodyMedium)
                          ?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: isMobile ? 2 : 4),
                    Text(
                      '${ticket.getProductsQuantity()} ${ticket.getProductsQuantity() == 1 ? 'producto' : 'productos'}',
                      style: (isMobile
                              ? theme.textTheme.labelSmall
                              : theme.textTheme.labelMedium)
                          ?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),

              // Monto y fecha del ticket
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    CurrencyFormatter.formatPrice(value: ticket.getTotalPrice),
                    style: (isMobile
                            ? theme.textTheme.bodySmall
                            : theme.textTheme.bodyMedium)
                        ?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  SizedBox(height: isMobile ? 2 : 4),
                  Text(
                    _formatDateTime(ticket.creation.toDate()),
                    style: (isMobile
                            ? theme.textTheme.labelSmall
                            : theme.textTheme.labelMedium)
                        ?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
              
              // Icono indicador de que es clickeable
              SizedBox(width: isMobile ? 4 : 8),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: isMobile ? 12 : 16,
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Muestra el diálogo del ticket seleccionado
  void _showLastTicketDialog(BuildContext context, TicketModel ticket, String businessName) {
    showLastTicketDialog(
      context: context,
      ticket: ticket,
      businessName: businessName.isNotEmpty ? businessName : 'PUNTO DE VENTA',
    );
  }

  Widget _buildCashFlowView(
      BuildContext context, CashRegisterProvider provider, bool isMobile) {
    final cashRegister = provider.currentActiveCashRegister!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // view : muestra información de flujo de caja
        _cashFlowInformation(context, cashRegister),
        SizedBox(height: getResponsiveSpacing(context, scale: 1.5)),
        // buttons : Botones de ingreso y egreso
        Row(
          children: [
            Expanded(
              child: Container(
                margin: EdgeInsets.zero,
                child: ButtonApp.outlined(
                  icon: const Icon(Icons.arrow_downward_rounded),
                  text: 'Ingreso',
                  onPressed: provider.hasActiveCashRegister
                      ? () => _showCashFlowDialog(context, true)
                      : null,
                  backgroundColor: provider.hasActiveCashRegister
                      ? Colors.green.withValues(alpha: 0.1)
                      : null,
                  foregroundColor:
                      provider.hasActiveCashRegister ? Colors.green : null,
                  borderColor: provider.hasActiveCashRegister
                      ? Colors.green.withValues(alpha: 0.3)
                      : null,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Container(
                margin: EdgeInsets.zero,
                child: ButtonApp.outlined(
                  icon: const Icon(Icons.arrow_outward_rounded),
                  text: 'Egreso',
                  onPressed: provider.hasActiveCashRegister
                      ? () => _showCashFlowDialog(context, false)
                      : null,
                  backgroundColor: provider.hasActiveCashRegister
                      ? Colors.red.withValues(alpha: 0.1)
                      : null,
                  foregroundColor:
                      provider.hasActiveCashRegister ? Colors.red : null,
                  borderColor: provider.hasActiveCashRegister
                      ? Colors.red.withValues(alpha: 0.3)
                      : null,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
            ),
          ],
        ),

        // Lista de movimientos de caja
        if (cashRegister.cashInFlowList.isNotEmpty || cashRegister.cashOutFlowList.isNotEmpty) ...[
          SizedBox(height: getResponsiveSpacing(context, scale: 1.5)),
          _buildCashFlowMovements(context, cashRegister, isMobile),
        ],
      ],
    );
  }

  Widget _buildCashFlowMovements(
      BuildContext context, CashRegister cashRegister, bool isMobile) {
    // Combinar y ordenar movimientos por fecha (más recientes primero)
    final allMovements = <Map<String, dynamic>>[];

    // Agregar ingresos
    for (final movement in cashRegister.cashInFlowList) {
      final cashFlow = movement is Map<String, dynamic>
          ? CashFlow.fromMap(movement)
          : movement as CashFlow;
      allMovements.add({
        'type': 'ingreso',
        'cashFlow': cashFlow,
        'date': cashFlow.date,
      });
    }

    // Agregar egresos
    for (final movement in cashRegister.cashOutFlowList) {
      final cashFlow = movement is Map<String, dynamic>
          ? CashFlow.fromMap(movement)
          : movement as CashFlow;
      allMovements.add({
        'type': 'egreso',
        'cashFlow': cashFlow,
        'date': cashFlow.date,
      });
    }

    // Ordenar por fecha (más recientes primero)
    allMovements.sort((a, b) => b['date'].compareTo(a['date']));

    return DialogComponents.itemList(
      context: context,
      useFillStyle: true,
      showDividers: true,
      title: 'Movimientos de caja',
      maxVisibleItems: 5,
      expandText:
          'Ver más (${allMovements.length > 5 ? allMovements.length - 5 : 0})',
      collapseText: 'Ver menos',
      items: allMovements.map((movement) {
        return _buildCashFlowMovementTile(context, movement, isMobile);
      }).toList(),
    );
  }

  Widget _buildCashFlowMovementTile(
      BuildContext context, Map<String, dynamic> movement, bool isMobile) {
    final theme = Theme.of(context);
    final cashFlow = movement['cashFlow'] as CashFlow;
    final isIngreso = movement['type'] == 'ingreso';

    final iconColor = isIngreso ? Colors.green : Colors.red;
    final icon =
        isIngreso ? Icons.arrow_downward_rounded : Icons.arrow_outward_rounded;

    // Retornar solo el contenido del tile sin el divisor
    // El divisor es manejado por DialogComponents.itemList
    return Row(
      children: [
        // Icono del tipo de movimiento
        Container(
          padding: EdgeInsets.all(isMobile ? 6 : 8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(isMobile ? 6 : 8),
          ),
          child: Icon(
            icon,
            size: isMobile ? 14 : 16,
            color: iconColor,
          ),
        ),
        SizedBox(width: isMobile ? 8 : 12),

        // Información del movimiento
        Expanded(
          child: Text(
            cashFlow.description,
            style: (isMobile
                    ? theme.textTheme.bodySmall
                    : theme.textTheme.bodyMedium)
                ?.copyWith(
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),

        // Monto y fecha del movimiento
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${isIngreso ? '+' : '-'}${CurrencyFormatter.formatPrice(value: cashFlow.amount)}',
              style: (isMobile
                      ? theme.textTheme.bodySmall
                      : theme.textTheme.bodyMedium)
                  ?.copyWith(
                fontWeight: FontWeight.w600,
                color: iconColor,
              ),
            ),
            SizedBox(height: isMobile ? 2 : 4),
            Text(
              _formatDateTime(cashFlow.date),
              style: (isMobile
                      ? theme.textTheme.labelSmall
                      : theme.textTheme.labelMedium)
                  ?.copyWith(
                color:
                    theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    final timeString =
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';

    if (messageDate == today) {
      return 'Hoy $timeString';
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      return 'Ayer $timeString';
    } else {
      return DateFormatter.formatPublicationDate(dateTime: dateTime);
    }
  }

  void _showOpenDialog(BuildContext context) {
    // Capturar los providers antes de mostrar el diálogo
    final cashRegisterProvider =
        Provider.of<CashRegisterProvider>(context, listen: false);
    final sellProvider = Provider.of<SellProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (_) => MultiProvider(
        providers: [
          ChangeNotifierProvider<CashRegisterProvider>.value(
              value: cashRegisterProvider),
          ChangeNotifierProvider<SellProvider>.value(value: sellProvider),
        ],
        child: const CashRegisterOpenDialog(),
      ),
    );
  }

  void _showCloseDialog(BuildContext context, CashRegister cashRegister) {
    // Capturar los providers antes de mostrar el diálogo
    final cashRegisterProvider =
        Provider.of<CashRegisterProvider>(context, listen: false);
    final sellProvider = Provider.of<SellProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (_) => MultiProvider(
        providers: [
          ChangeNotifierProvider<CashRegisterProvider>.value(
              value: cashRegisterProvider),
          ChangeNotifierProvider<SellProvider>.value(value: sellProvider),
        ],
        child: CashRegisterCloseDialog(cashRegister: cashRegister),
      ),
    );
  }

  void _showCashFlowDialog(BuildContext context, bool isInflow) {
    // Capturar todos los providers necesarios antes de mostrar el diálogo
    final cashRegisterProvider =
        Provider.of<CashRegisterProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final sellProvider = Provider.of<SellProvider>(context, listen: false);

    if (!cashRegisterProvider.hasActiveCashRegister) return;

    final cashRegister = cashRegisterProvider.currentActiveCashRegister!;

    showDialog(
      context: context,
      builder: (_) => MultiProvider(
        providers: [
          ChangeNotifierProvider<CashRegisterProvider>.value(
              value: cashRegisterProvider),
          ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
          ChangeNotifierProvider<SellProvider>.value(value: sellProvider),
        ],
        child: CashFlowDialog(
          isInflow: isInflow,
          cashRegisterId: cashRegister.id,
          accountId: sellProvider.profileAccountSelected.id,
          userId: authProvider.user?.email ?? '',
        ),
      ),
    );
  }
}
