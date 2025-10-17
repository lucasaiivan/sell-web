import '../../../../core/core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../domain/entities/cash_register_model.dart';
import '../../../../domain/entities/ticket_model.dart';
import '../../../../presentation/providers/auth_provider.dart';
import '../../../../presentation/providers/cash_register_provider.dart';
import '../../../../presentation/providers/sell_provider.dart';
import '../../graphics/graphics.dart';
import 'cash_flow_dialog.dart';
import 'cash_register_close_dialog.dart';
import 'cash_register_open_dialog.dart';

/// Diálogo principal para administrar cajas registradoras con diseño responsivo.
/// Optimizado para experiencia móvil y desktop siguiendo Material Design 3.
/// 
/// ✅ OPTIMIZADO: Carga los tickets UNA SOLA VEZ y los comparte entre todas las vistas
/// para evitar llamadas duplicadas a la base de datos.
class CashRegisterManagementDialog extends StatefulWidget {
  const CashRegisterManagementDialog({super.key});

  @override
  State<CashRegisterManagementDialog> createState() => _CashRegisterManagementDialogState();
}

class _CashRegisterManagementDialogState extends State<CashRegisterManagementDialog> {
  /// Future compartido para los tickets del día
  /// Se carga una sola vez y se comparte entre _buildCashFlowView y RecentTicketsView
  Future<List<TicketModel>?>? _ticketsFuture;
  
  /// ID de la caja registradora actual para detectar cambios
  String? _currentCashRegisterId;

  @override
  void initState() {
    super.initState();
    // Se cargará en el primer build cuando tengamos el contexto
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadTicketsIfNeeded();
  }

  /// Carga los tickets solo si:
  /// 1. Aún no se han cargado (_ticketsFuture == null)
  /// 2. La caja registradora cambió
  void _loadTicketsIfNeeded() {
    final cashRegisterProvider = context.watch<CashRegisterProvider>();
    final sellProvider = context.watch<SellProvider>();
    final accountId = sellProvider.profileAccountSelected.id;
    final cashRegisterId = cashRegisterProvider.currentActiveCashRegister?.id ?? '';

    // Solo recargar si cambió la caja o no hay datos
    if (_ticketsFuture == null || _currentCashRegisterId != cashRegisterId) {
      _currentCashRegisterId = cashRegisterId;
      if (accountId.isNotEmpty && cashRegisterId.isNotEmpty) {
        // get : Usar getCashRegisterTickets para obtener tickets de la caja activa
        _ticketsFuture = cashRegisterProvider.getCashRegisterTickets(
          accountId: accountId,
          cashRegisterId: cashRegisterId,
        );
      } else {
        _ticketsFuture = Future.value(null);
      }
    }
  }

  /// Recarga los tickets manualmente (llamado después de acciones como anular ticket)
  void _reloadTickets() {
    final cashRegisterProvider = context.read<CashRegisterProvider>();
    final sellProvider = context.read<SellProvider>();
    final accountId = sellProvider.profileAccountSelected.id;
    final cashRegisterId = cashRegisterProvider.currentActiveCashRegister?.id ?? '';

    if (accountId.isNotEmpty && cashRegisterId.isNotEmpty) {
      setState(() {
        // ✅ MEJORADO: Usar getCashRegisterTickets para obtener tickets de la caja activa
        _ticketsFuture = cashRegisterProvider.getCashRegisterTickets(
          accountId: accountId,
          cashRegisterId: cashRegisterId,
        );
      });
    }
  }

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // view : información de flujo de caja (usa _ticketsFuture compartido)
        _buildCashFlowView(context, provider, isMobile),  
        SizedBox(height: getResponsiveSpacing(context, scale:2)),
        // view : resumen de métodos de pago
        FutureBuilder<List<TicketModel>?>(
          future: _ticketsFuture,
          builder: (context, snapshot) {
            if (snapshot.hasData && snapshot.data != null && snapshot.data!.isNotEmpty) {
              final tickets = snapshot.data!;
              final activeTickets = tickets.where((ticket) => !ticket.annulled).toList();
              
              if (activeTickets.isEmpty) {
                return const SizedBox.shrink();
              }
              
              final paymentMethodsRanking = TicketModel.getPaymentMethodsRanking(
                tickets: activeTickets,
                includeAnnulled: false,
              );
              final theme = Theme.of(context);
              
              return Column(
                children: [
                  // view : muestra resumen de métodos de pago
                  _buildSalesSummaryInfo(
                    context: context,
                    theme: theme,
                    paymentMethodsRanking: paymentMethodsRanking,
                    isMobile: isMobile,
                  ),
                  SizedBox(height: getResponsiveSpacing(context, scale:2)),
                ],
              );
            }
            return const SizedBox.shrink();
          },
        ),
        // view : lista de las ultimas ventas (usa _ticketsFuture compartido)
        RecentTicketsView(
          ticketsFuture: _ticketsFuture,
          cashRegisterProvider: provider,
          isMobile: isMobile,
          onTicketUpdated: _reloadTickets,
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

  Widget _cashFlowInformation(BuildContext context, CashRegister cashRegister, {List<TicketModel>? tickets}) {
    final theme = Theme.of(context);
    final isMobileDevice = isMobile(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sección: Nombre/Descripción de la caja con información temporal
        _buildCashRegisterHeader(context, cashRegister, theme, isMobileDevice),  
        SizedBox(height: getResponsiveSpacing(context, scale: 1.5)),    
        // Sección: Estadísticas de ventas con cards destacadas
        _buildStatsCards(context, cashRegister, isMobileDevice),
        SizedBox(height: getResponsiveSpacing(context, scale:1.5)),
        // view : texto de Balance total actual
        _buildCurrentBalance(context, cashRegister, isMobileDevice),
        SizedBox(height: getResponsiveSpacing(context, scale:1.5)),
        // Sección: Información financiera
        _buildFinancialInfo(context, cashRegister, theme, isMobileDevice, tickets: tickets),
      ],
    );
  }

  // Stats Cards: Muestra estadísticas principales en formato de tarjetas
  Widget _buildStatsCards(BuildContext context, CashRegister cashRegister, bool isMobile) {
    final theme = Theme.of(context);
    
    final stats = [
      {
        'label': 'Transacciones',
        'value': '${cashRegister.sales}',
        'icon': Icons.receipt_long_rounded,
        'color': theme.colorScheme.primary,
      },
      {
        'label': 'Efectivas',
        'value': '${cashRegister.getEffectiveSales}',
        'icon': Icons.check_circle_rounded,
        'color': Colors.green,
      },
      {
        'label': 'Anulados',
        'value': '${cashRegister.annulledTickets}',
        'icon': Icons.cancel_rounded,
        'color': Colors.red,
      },
      
    ];

    return Row(
      children: stats.map((stat) {
        final color = stat['color'] as Color;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(
              right: stat == stats.last ? 0 : (isMobile ? 6 : 8),
            ),
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 8 : 12,
              vertical: isMobile ? 10 : 12,
            ),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8), 
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(
                      stat['icon'] as IconData,
                      size: isMobile ? 16 : 18,
                      color: color,
                    ),
                    Text(
                      stat['value'] as String,
                      style: (isMobile 
                        ? theme.textTheme.titleMedium 
                        : theme.textTheme.titleLarge)?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: isMobile ? 4 : 6),
                Text(
                  stat['label'] as String,
                  style: (isMobile 
                    ? theme.textTheme.labelSmall 
                    : theme.textTheme.labelMedium)?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // widget : devuelve  el balance total actual de la caja activa
  Widget _buildCurrentBalance(BuildContext context, CashRegister cashRegister, bool isMobile){
    final theme = Theme.of(context);
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 16,
        vertical: isMobile ? 10 : 14,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Balance Actual',
            style: (isMobile 
              ? theme.textTheme.labelLarge 
              : theme.textTheme.titleSmall)?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: isMobile ? 4 : 6),
          Text(
            CurrencyFormatter.formatPrice(value: cashRegister.getExpectedBalance),
            style: (isMobile 
              ? theme.textTheme.titleMedium 
              : theme.textTheme.titleLarge)?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
              fontSize: isMobile ? 24 : 28,
            ),
          ),
        ],
      ),
    );
  }

  // Cash Register Header: Muestra el nombre/descripción de la caja con información temporal
  Widget _buildCashRegisterHeader(BuildContext context, CashRegister cashRegister, ThemeData theme, bool isMobile) {
    final timeInfo = [
      {
        'icon': Icons.schedule_rounded,
        'label': 'Apertura',
        'value': DateFormatter.formatPublicationDate(dateTime: cashRegister.opening),
      },
      {
        'icon': Icons.timelapse_rounded,
        'label': 'Tiempo activo',
        'value': DateFormatter.getElapsedTime(fechaInicio: cashRegister.opening),
      },  
      // nombre del usuario que abrió la caja
      {
        'icon': Icons.person_rounded,
        'label': 'Cajero',
        'value': cashRegister.nameUser.isNotEmpty ? cashRegister.idUser : 'Desconocido',
      },
    ];

    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.5),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con nombre de caja y badge
          Row(
            children: [
              Icon(
                Icons.point_of_sale_rounded,
                size: isMobile ? 18 : 20,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  cashRegister.description,
                  style: (isMobile 
                    ? theme.textTheme.titleMedium 
                    : theme.textTheme.titleLarge)?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              // Badge minimalista
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'ACTIVA',
                  style: (isMobile 
                    ? theme.textTheme.labelSmall 
                    : theme.textTheme.labelMedium)?.copyWith(
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          
          SizedBox(height: isMobile ? 10 : 12),
          
          // Lista de información temporal
          ...timeInfo.map((info) => Padding(
            padding: EdgeInsets.only(bottom: isMobile ? 6 : 8),
            child: Row(
              children: [
                Icon(
                  info['icon'] as IconData,
                  size: isMobile ? 14 : 16,
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 8),
                Text(
                  info['label'] as String,
                  style: (isMobile 
                    ? theme.textTheme.bodySmall 
                    : theme.textTheme.bodyMedium)?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                Text(
                  info['value'] as String,
                  style: (isMobile 
                    ? theme.textTheme.bodySmall 
                    : theme.textTheme.bodyMedium)?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  // Financial Info: Información financiera detallada
  Widget _buildFinancialInfo(BuildContext context, CashRegister cashRegister, ThemeData theme, bool isMobile, {List<TicketModel>? tickets}) {
    // ✅ Optimizado: Usar getters del modelo para mejor semántica y performance
    final totalIngresos = cashRegister.getTotalIngresos;
    final totalEgresos = cashRegister.getTotalEgresos;

    // ✅ Calcular ganancias totales usando el método del modelo
    final totalProfit = tickets != null && tickets.isNotEmpty ? cashRegister.calculateTotalProfit(tickets) : 0.0;

    final financialItems = [
      // Monto inicial
      if (cashRegister.initialCash > 0)
        {
          'label': 'Monto Inicial',
          'value': CurrencyFormatter.formatPrice(value: cashRegister.initialCash),
          'rawValue': cashRegister.initialCash,
          'icon': Icons.attach_money_rounded,
          'color': theme.colorScheme.primary,
          'highlight': false,
        },
      // Ingresos en caja
      if (totalIngresos > 0)
        {
          'label': 'Ingresos en caja',
          'value': CurrencyFormatter.formatPrice(value: totalIngresos),
          'rawValue': totalIngresos,
          'icon': Icons.arrow_downward_rounded,
          'color': Colors.green,
          'highlight': false,
        },
      // Egresos en caja
      if (totalEgresos > 0)
        {
          'label': 'Egresos en caja',
          'value': '-${CurrencyFormatter.formatPrice(value: totalEgresos)}',
          'rawValue': -totalEgresos,
          'icon': Icons.arrow_outward_rounded,
          'color': Colors.red,
          'highlight': false,
        },
      // Descuentos
      if (cashRegister.discount > 0)
        {
          'label': 'Descuentos',
          'value': '-${CurrencyFormatter.formatPrice(value: cashRegister.discount)}',
          'rawValue': -cashRegister.discount,
          'icon': Icons.discount_rounded,
          'color': theme.colorScheme.secondary,
          'highlight': false,
        },
      // Facturación total - RESALTADA
      {
        'label': 'Facturación de ventas',
        'value': CurrencyFormatter.formatPrice(value: cashRegister.billing),
        'rawValue': cashRegister.billing,
        'icon': Icons.receipt_long_rounded,
        'color': theme.colorScheme.primary,
        'highlight': true,
      },
      // 5. Ganancias totales - RESALTADA
      if (totalProfit > 0)
        {
          'label': 'Ganancias totales',
          'value': CurrencyFormatter.formatPrice(value: totalProfit),
          'rawValue': totalProfit,
          'icon': Icons.trending_up_rounded,
          'color': Colors.green.shade700,
          'highlight': true,
        },
    ];

    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.5),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Información Financiera',
              style: (isMobile 
                ? theme.textTheme.labelLarge 
                : theme.textTheme.titleSmall)?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          // Lista de items financieros
          ...financialItems.map((item) {

            final isHighlight = item['highlight'] as bool;
            final itemColor = item['color'] as Color;
            
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Container(
                padding: isHighlight 
                    ? EdgeInsets.symmetric(
                        horizontal: isMobile ? 8 : 10,
                        vertical: isMobile ? 6 : 8,
                      )
                    : EdgeInsets.zero,
                decoration: isHighlight 
                    ? BoxDecoration(
                        color: itemColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8), 
                      )
                    : null,
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(isMobile ? 6 : 8),
                      decoration: BoxDecoration(
                        color: itemColor.withValues(alpha: isHighlight ? 0.15 : 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        item['icon'] as IconData,
                        size: isMobile ? 16 : 18,
                        color: itemColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item['label'] as String,
                        style: (isMobile 
                          ? theme.textTheme.bodyMedium 
                          : theme.textTheme.bodyLarge)?.copyWith(
                          color: isHighlight 
                              ? theme.colorScheme.onSurface
                              : theme.colorScheme.onSurfaceVariant,
                          fontWeight: isHighlight ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ),
                    Text(
                      item['value'] as String,
                      style: (isMobile 
                        ? theme.textTheme.titleSmall 
                        : theme.textTheme.titleMedium)?.copyWith(
                        fontWeight: isHighlight ? FontWeight.w800 : FontWeight.w700,
                        color: isHighlight ? itemColor : theme.colorScheme.onSurface,
                        fontSize: isHighlight 
                            ? (isMobile ? 15 : 17)
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
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
 

  /// Construye la vista de flujo de caja con información financiera 
  Widget _buildCashFlowView(BuildContext context, CashRegisterProvider provider, bool isMobile) {
    final cashRegister = provider.currentActiveCashRegister!;

    return FutureBuilder<List<TicketModel>?>(
      future: _ticketsFuture, 
      builder: (context, snapshot) {
        final tickets = snapshot.data;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // view : muestra información de flujo de caja con contadores en tiempo real
            _cashFlowInformation(context, cashRegister, tickets: tickets),
            SizedBox(height: getResponsiveSpacing(context, scale:2)),
            // buttons : botones de ingreso y egreso de caja
            Row(
              children: [
                Expanded(
                  child: Container(
                    margin: EdgeInsets.zero,
                    child: ButtonApp.outlined(
                      borderRadius: 4,
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
                      borderRadius: 4,
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
            SizedBox(height: getResponsiveSpacing(context, scale:1)), 
            // Lista de movimientos de caja
            if (cashRegister.cashInFlowList.isNotEmpty || cashRegister.cashOutFlowList.isNotEmpty) ...[ 
              _buildCashFlowMovements(context, cashRegister, isMobile),
            ],
          ],
        );
      },
    );
  }

  Widget _buildCashFlowMovements(
      BuildContext context, CashRegister cashRegister, bool isMobile) {
    final theme = Theme.of(context);
    
    // Combinar y ordenar movimientos por fecha (más recientes primero)
    final allMovements = <Map<String, dynamic>>[];

    // Calcular totales de ingresos y egresos
    double totalIngresos = 0;
    double totalEgresos = 0;

    // Agregar ingresos
    for (final movement in cashRegister.cashInFlowList) {
      final cashFlow = movement is Map<String, dynamic>
          ? CashFlow.fromMap(movement)
          : movement as CashFlow;
      totalIngresos += cashFlow.amount;
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
      totalEgresos += cashFlow.amount;
      allMovements.add({
        'type': 'egreso',
        'cashFlow': cashFlow,
        'date': cashFlow.date,
      });
    }

    // Ordenar por fecha (más recientes primero)
    allMovements.sort((a, b) => b['date'].compareTo(a['date']));

    // Calcular balance neto
    final balanceNeto = totalIngresos - totalEgresos;

    return DialogComponents.itemList(
      context: context,
      useFillStyle: true,
      showDividers: true, 
      borderColor: theme.dividerColor.withValues(alpha: 0.3),
      title: 'Movimientos de caja',
      trailing: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Total de ingresos
          if (totalIngresos > 0) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.arrow_downward_rounded,
                    size: isMobile ? 12 : 14,
                    color: Colors.green.shade700,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    CurrencyFormatter.formatPrice(value: totalIngresos),
                    style: (isMobile
                            ? theme.textTheme.bodySmall
                            : theme.textTheme.bodyMedium)
                        ?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
          ],
          // Total de egresos
          if (totalEgresos > 0) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.arrow_outward_rounded,
                    size: isMobile ? 12 : 14,
                    color: Colors.red.shade700,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    CurrencyFormatter.formatPrice(value: totalEgresos),
                    style: (isMobile
                            ? theme.textTheme.bodySmall
                            : theme.textTheme.bodyMedium)
                        ?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
          ],
          // Balance neto
          if (totalIngresos > 0 || totalEgresos > 0) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: balanceNeto >= 0 
                    ? theme.colorScheme.primary.withValues(alpha: 0.1)
                    : Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    balanceNeto >= 0 ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                    size: isMobile ? 12 : 14,
                    color: balanceNeto >= 0 
                        ? theme.colorScheme.primary
                        : Colors.orange.shade700,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    CurrencyFormatter.formatPrice(value: balanceNeto.abs()),
                    style: (isMobile
                            ? theme.textTheme.bodySmall
                            : theme.textTheme.bodyMedium)
                        ?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: balanceNeto >= 0 
                          ? theme.colorScheme.primary
                          : Colors.orange.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      maxVisibleItems: 5,
      expandText: 'Ver más (${allMovements.length > 5 ? allMovements.length - 5 : 0})',
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
    ).then((_) {
      // ✅ Recargar tickets después de agregar un movimiento de caja
      _reloadTickets();
    });
  }

  /// Widget: Resumen visual de métodos de pago con gráfico de barras
  Widget _buildSalesSummaryInfo({
    required BuildContext context,
    required ThemeData theme,
    required List<Map<String, dynamic>> paymentMethodsRanking,
    required bool isMobile,
  }) {
    if (paymentMethodsRanking.isEmpty) {
      return const SizedBox.shrink();
    }

    // ✅ Reagrupar los métodos de pago: separar los 3 principales y agrupar el resto en "Otros"
    final Map<String, double> groupedPayments = {};
    
    for (final payment in paymentMethodsRanking) {
      final description = (payment['description'] as String).trim().toLowerCase();
      final percentage = payment['percentage'] as double;
      
      // Identificar si es uno de los 3 métodos principales
      String key;
      if (description == 'efectivo') {
        key = 'Efectivo';
      } else if (description == 'mercado pago' || description == 'mercadopago') {
        key = 'Mercado Pago';
      } else if (description == 'tarjeta de crédito/débito' || 
                 description == 'tarjeta' ||
                 description == 'tarjeta de credito/debito') {
        key = 'Tarjeta';
      } else {
        // Todo lo demás se agrupa como "Otros"
        key = 'Otros';
      }
      
      // Sumar porcentajes si ya existe la clave
      groupedPayments[key] = (groupedPayments[key] ?? 0) + percentage;
    }
    
    // ✅ Convertir a PercentageBarData usando el helper
    final chartData = groupedPayments.entries.map((entry) {
      final paymentData = _getPaymentMethodData(
        description: entry.key,
        percentage: entry.value,
        theme: theme,
      );
      
      return PercentageBarData(
        label: paymentData['label'] as String,
        percentage: paymentData['percentage'] as double,
        color: paymentData['color'] as Color,
        icon: paymentData['icon'] as IconData,
      );
    }).toList();

    // ✅ Usar el componente reutilizable PercentageBarChart
    return PercentageBarChart(
      title: 'Métodos de pago',
      data: chartData,
      isMobile: isMobile,
    );
  }

  /// Helper: Obtener datos de color, icono y etiqueta para un método de pago
  /// Solo reconoce 3 métodos principales: Efectivo, Mercado Pago y Tarjeta
  /// Todo lo demás se agrupa como "Otros"
  Map<String, dynamic> _getPaymentMethodData({
    required String description,
    required double percentage,
    required ThemeData theme,
  }) {
    Color paymentColor;
    IconData paymentIcon;
    String fullLabel;

    // Trabajar con la descripción ya normalizada (viene de _buildSalesSummaryInfo)
    switch (description) {
      case 'Efectivo':
        paymentColor = Colors.orange.shade700;
        paymentIcon = Icons.payments_rounded;
        fullLabel = 'Efectivo';
        break;
      case 'Mercado Pago':
        paymentColor = Colors.blue.shade700;
        paymentIcon = Icons.qr_code_rounded;
        fullLabel = 'Mercado Pago';
        break;
      case 'Tarjeta':
        paymentColor = Colors.purple.shade700;
        paymentIcon = Icons.credit_card_rounded;
        fullLabel = 'Tarjeta';
        break;
      case 'Otros':
      default:
        // Todos los demás métodos
        paymentColor = Colors.grey.shade600;
        paymentIcon = Icons.more_horiz_rounded;
        fullLabel = 'Otros';
        break;
    }

    return {
      'color': paymentColor,
      'icon': paymentIcon,
      'label': fullLabel,
      'percentage': percentage,
    };
  }
}

/// Widget separado para manejar la lista de tickets recientes de manera eficiente
/// ✅ Recibe el Future de tickets como parámetro en lugar de cargarlo internamente
/// Evita rebuilds innecesarios y llamadas duplicadas a la base de datos
class RecentTicketsView extends StatefulWidget {
  /// Future compartido con los tickets ya cargados
  final Future<List<TicketModel>?>? ticketsFuture;
  final CashRegisterProvider cashRegisterProvider;
  final bool isMobile;
  /// Callback para recargar tickets después de acciones (anular, etc.)
  final VoidCallback? onTicketUpdated;

  const RecentTicketsView({
    super.key,
    required this.ticketsFuture,
    required this.cashRegisterProvider,
    required this.isMobile,
    this.onTicketUpdated,
  });

  @override
  State<RecentTicketsView> createState() => _RecentTicketsViewState();
}

class _RecentTicketsViewState extends State<RecentTicketsView> {

  @override
  Widget build(BuildContext context) {

    final sellProvider = context.watch<SellProvider>();
    final accountId = sellProvider.profileAccountSelected.id;

    if (accountId.isEmpty) return const SizedBox();

    if (widget.ticketsFuture == null) {
      return _buildEmptyTicketsView(context, widget.isMobile);
    }

    return FutureBuilder<List<TicketModel>?>(
      future: widget.ticketsFuture, // ✅ Usar Future compartido recibido como parámetro
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          // Log del error para debug
          debugPrint('Error loading tickets: ${snapshot.error}');
          return _buildEmptyTicketsView(context, widget.isMobile);
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyTicketsView(context, widget.isMobile);
        }

        final allTickets = snapshot.data!;
        // Convertir a TicketModel y ordenar por fecha (más recientes primero)
        final tickets = allTickets.map((ticketData) {
          try {
            // Crear TicketModel desde Map usando los datos directamente
            return TicketModel.fromMap(ticketData.toMap());
          } catch (e) {
            debugPrint('Error converting ticket data: $e');
            return null;
          }
        }).where((ticket) => ticket != null).cast<TicketModel>().toList();

        // Ordenar por fecha de creación (más recientes primero)
        tickets.sort((a, b) => b.creation.compareTo(a.creation));

        if (tickets.isEmpty) {
          return _buildEmptyTicketsView(context, widget.isMobile);
        }

        // Tomar solo los primeros 5 para mostrar
        final recentTickets = tickets.take(5).toList();
        final hasMoreTickets = tickets.length > 5;
        final theme = Theme.of(context);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Calcular el total de facturación y ganancia de TODOS los tickets activos (no anulados)
            Builder(
              builder: (context) {
                // Usar TODOS los tickets, no solo los recientes
                final activeTickets = tickets.where((ticket) => !ticket.annulled).toList();
                final totalBilling = activeTickets.fold<double>(0, (sum, ticket) => sum + ticket.getTotalPrice);
                // ✅ Usar el método del modelo para calcular ganancias
                final cashRegister = widget.cashRegisterProvider.currentActiveCashRegister!;
                final totalProfit = cashRegister.calculateTotalProfit(activeTickets);

                return DialogComponents.itemList(
                  context: context, 
                  useFillStyle: true,
                  padding: EdgeInsets.all(widget.isMobile ? 12 : 14),
                  showDividers: true,
                  title: 'Transacciones recientes',
                  borderColor: theme.dividerColor.withValues(alpha: 0.3), 
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Total de facturación
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Total ${CurrencyFormatter.formatPrice(value: totalBilling)}',
                          style: (widget.isMobile
                                  ? theme.textTheme.bodySmall
                                  : theme.textTheme.bodyMedium)
                              ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                      // Ganancia total (si existe)
                      if (totalProfit > 0) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.trending_up_rounded,
                                size: widget.isMobile ? 12 : 14,
                                color: Colors.green.shade700,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                CurrencyFormatter.formatPrice(value: totalProfit),
                                style: (widget.isMobile
                                        ? theme.textTheme.bodySmall
                                        : theme.textTheme.bodyMedium)
                                    ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: Colors.green.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  maxVisibleItems: 5,
                  expandText: '',
                  collapseText: '',
                  items: [
                    // view : listado de tickets recientes
                    ...recentTickets.map((ticket) {
                      return _buildTicketTile(
                        context, 
                        ticket, 
                        widget.isMobile, 
                        onTicketUpdated: widget.onTicketUpdated, // ✅ Usar callback compartido
                      );
                  }),
                  ]
                );
              },
            ),
            
            // Botón "Ver más" si hay más de 5 tickets
            if (hasMoreTickets) ...[
              SizedBox(height: widget.isMobile ? 8 : 12),
              Center(
                child: TextButton.icon(
                  onPressed: () => _showAllTicketsDialog(context, tickets),
                  icon: const Icon(Icons.security),
                  label: Text('Ver más (${tickets.length - 5} tickets)'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
              SizedBox(height: widget.isMobile ? 8 : 12),
            ],
          ],
        );
      },
    );
  }


  void _showAllTicketsDialog(BuildContext context, List<TicketModel> tickets) {
    final theme = Theme.of(context);
    final sellProvider = context.read<SellProvider>();
    final cashRegisterProvider = context.read<CashRegisterProvider>(); 
    
    showDialog(
      context: context,
      builder: (_) => MultiProvider(
        providers: [
          ChangeNotifierProvider<SellProvider>.value(value: sellProvider),
          ChangeNotifierProvider<CashRegisterProvider>.value(value: cashRegisterProvider),
        ],
        child: BaseDialog(
          title: 'Todos los Tickets de Hoy',
          icon: Icons.receipt_long_rounded,
          headerColor: theme.colorScheme.primaryContainer.withValues(alpha: 0.85), 
          content: ListView.separated(
            shrinkWrap: true,
            itemCount: tickets.length,
            separatorBuilder: (context, index) => const AppDivider(),
            itemBuilder: (context, index) {
              final ticket = tickets[index];
              return _buildTicketTile(
                context,
                ticket,
                isMobile(context),
                onTicketUpdated: () {
                  // Recargar tickets y cerrar diálogo
                  widget.onTicketUpdated?.call(); // ✅ Usar callback compartido
                  Navigator.of(context).pop();
                },
              );
            },
          ),
          actions: [
            DialogComponents.secondaryActionButton(
              context: context,
              text: 'Cerrar',
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
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

  //  Construcción del tile del ticket //
  Widget _buildTicketTile(
    BuildContext context, 
    TicketModel ticket, 
    bool isMobile, {
    VoidCallback? onTicketUpdated,
  }) {

    // styles
    final theme = Theme.of(context);
    // providers
    final sellProvider = context.read<SellProvider>();
    final cashRegisterProvider = context.read<CashRegisterProvider>();
    
    // Información adicional
    final hasDiscount = ticket.discount > 0;
    final hasProfit = ticket.getProfit > 0;
    final paymentMethodIcon = _getPaymentMethodIcon(ticket.payMode);
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => showLastTicketDialog(
          context: context,
          ticket: ticket,
          businessName: sellProvider.profileAccountSelected.name.isNotEmpty 
            ? sellProvider.profileAccountSelected.name 
            : 'PUNTO DE VENTA',
          onTicketAnnulled: () async {
            // Verificar si este ticket es el último ticket vendido
            final isLastSoldTicket = sellProvider.lastSoldTicket?.id == ticket.id;
            
            if (isLastSoldTicket) {
              // Si es el último ticket vendido, usar el método unificado
              await sellProvider.annullLastSoldTicket(context: context, ticket: ticket);
            } else {
              // Si no es el último ticket, solo anular en la caja registradora
              await cashRegisterProvider.annullTicket(
                accountId: sellProvider.profileAccountSelected.id, 
                ticket: ticket,
              );
            }
            
            // Forzar la recarga de la lista de tickets si hay callback
            onTicketUpdated?.call();
          },  
        ),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: EdgeInsets.symmetric(
            vertical: isMobile ? 8 : 10,
            horizontal: isMobile ? 8 : 10,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Icono del ticket con estado
              Container(
                padding: EdgeInsets.all(isMobile ? 7 : 9),
                decoration: BoxDecoration(
                  color: ticket.annulled
                      ? Colors.red.withValues(alpha: 0.1)
                      : theme.colorScheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  ticket.annulled ? Icons.receipt_long_rounded : Icons.receipt_rounded,
                  size: isMobile ? 14 : 18,
                  color: ticket.annulled ? Colors.red : theme.colorScheme.primary,
                ),
              ),
              SizedBox(width: isMobile ? 10 : 12),

              // Información principal del ticket
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header: ID y badges
                    Row(
                      children: [
                        // ID del ticket
                        Expanded(
                          child: Text(
                            'Ticket #${ticket.id.length > 8 ? ticket.id.substring(ticket.id.length - 8) : ticket.id}',
                            style: (isMobile
                                    ? theme.textTheme.bodySmall
                                    : theme.textTheme.bodyMedium)
                                ?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: ticket.annulled 
                                  ? theme.colorScheme.onSurfaceVariant
                                  : theme.colorScheme.onSurface,
                              decoration: ticket.annulled 
                                  ? TextDecoration.lineThrough
                                  : null,
                              decorationColor: ticket.annulled 
                                  ? theme.colorScheme.onSurfaceVariant
                                  : null,
                              decorationThickness: ticket.annulled ? 2.0 : null,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        
                        // Badge de anulado
                        if (ticket.annulled) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'ANULADO',
                              style: (isMobile
                                      ? theme.textTheme.labelSmall
                                      : theme.textTheme.labelMedium)
                                  ?.copyWith(
                                color: Colors.red.shade700,
                                fontWeight: FontWeight.w700,
                                fontSize: isMobile ? 9 : 10,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    
                    SizedBox(height: isMobile ? 4 : 6),
                    
                    // Info row: Productos, método de pago y descuento (si aplica)
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        // Cantidad de productos
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.shopping_bag_outlined,
                              size: isMobile ? 12 : 13,
                              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${ticket.getProductsQuantity()} ${ticket.getProductsQuantity() == 1 ? 'item' : 'items'}',
                              style: (isMobile
                                      ? theme.textTheme.labelSmall
                                      : theme.textTheme.labelMedium)
                                  ?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                        
                        // Separador
                        Container(
                          width: 3,
                          height: 3,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                            shape: BoxShape.circle,
                          ),
                        ),
                        
                        // Método de pago
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              paymentMethodIcon,
                              size: isMobile ? 12 : 13,
                              color: _getPaymentMethodColor(ticket.payMode),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _getPaymentMethodFullLabel(ticket.payMode),
                              style: (isMobile
                                      ? theme.textTheme.labelSmall
                                      : theme.textTheme.labelMedium)
                                  ?.copyWith(
                                color: _getPaymentMethodColor(ticket.payMode),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        
                        // Descuento (si aplica) - RESALTADO
                        if (hasDiscount) ...[
                          // Separador
                          Container(
                            width: 3,
                            height: 3,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                              shape: BoxShape.circle,
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.discount_rounded,
                                size: isMobile ? 12 : 13,
                                color: Colors.orange.shade700,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Descuento',
                                style: (isMobile
                                        ? theme.textTheme.labelSmall
                                        : theme.textTheme.labelMedium)
                                    ?.copyWith(
                                  color: Colors.orange.shade700,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                    // Fecha y hora
                  Text(
                    _formatDateTime(ticket.creation.toDate()),
                    style: (isMobile
                            ? theme.textTheme.labelSmall
                            : theme.textTheme.labelMedium)
                        ?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                      fontSize: isMobile ? 10 : 11,
                    ),
                  ),
                  ],
                ),
              ),

              SizedBox(width: isMobile ? 8 : 10),

              // Columna derecha: Monto total, descuento, ganancia y fecha
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Descuento (si existe)
                  if (hasDiscount) ...[
                    SizedBox(height: isMobile ? 2 : 3),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '-${CurrencyFormatter.formatPrice(value: ticket.getDiscountAmount)}',
                        style: (isMobile
                                ? theme.textTheme.labelSmall
                                : theme.textTheme.labelMedium)
                            ?.copyWith(
                          color: ticket.annulled 
                              ? theme.colorScheme.onSurfaceVariant
                              : Colors.orange.shade800,
                          fontWeight: FontWeight.w700,
                          fontSize: isMobile ? 10 : 11,
                          decoration: ticket.annulled 
                              ? TextDecoration.lineThrough
                              : null,
                          decorationColor: ticket.annulled 
                              ? theme.colorScheme.onSurfaceVariant
                              : null,
                          decorationThickness: ticket.annulled ? 2.0 : null,
                        ),
                      ),
                    ),
                  ],
                  // Monto total
                  Text(
                    CurrencyFormatter.formatPrice(value: ticket.getTotalPrice),
                    style: (theme.textTheme.titleLarge)
                        ?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: ticket.annulled 
                          ? theme.colorScheme.onSurfaceVariant
                          : theme.colorScheme.primary,
                      decoration: ticket.annulled 
                          ? TextDecoration.lineThrough
                          : null,
                      decorationColor: ticket.annulled 
                          ? theme.colorScheme.onSurfaceVariant
                          : null,
                      decorationThickness: ticket.annulled ? 2.0 : null,
                    ),
                  ),

                  // Ganancia (si existe)
                  if (hasProfit) ...[
                    SizedBox(height: isMobile ? 2 : 3),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.trending_up_rounded,
                            size: isMobile ? 12 : 13,
                            color: ticket.annulled 
                                ? theme.colorScheme.onSurfaceVariant
                                : Colors.green.shade800,
                          ),
                          const SizedBox(width: 4),
                          Text(CurrencyFormatter.formatPrice(value: ticket.getProfit),
                            style: (isMobile
                                    ? theme.textTheme.labelSmall
                                    : theme.textTheme.labelMedium)
                                ?.copyWith(
                              color: ticket.annulled 
                                  ? theme.colorScheme.onSurfaceVariant
                                  : Colors.green.shade800,
                              fontWeight: FontWeight.w700,
                              fontSize: isMobile ? 10 : 11,
                              decoration: ticket.annulled 
                                  ? TextDecoration.lineThrough
                                  : null,
                              decorationColor: ticket.annulled 
                                  ? theme.colorScheme.onSurfaceVariant
                                  : null,
                              decorationThickness: ticket.annulled ? 2.0 : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  
                ],
              ),
              SizedBox(width: isMobile ? 4 : 6),
              // Icono indicador de que es clickeable
              Center(
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: isMobile ? 12 : 16,
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper: Obtener icono del método de pago
  IconData _getPaymentMethodIcon(String payMode) {
    switch (payMode.toLowerCase()) {
      case 'effective':
      case 'efectivo':
        return Icons.payments_rounded;
      case 'card':
      case 'tarjeta':
        return Icons.credit_card_rounded;
      case 'mercadopago':
      case 'qr':
        return Icons.qr_code_rounded;
      case 'transfer':
      case 'transferencia':
        return Icons.account_balance_rounded;
      default:
        return Icons.attach_money_rounded;
    }
  }

  // Helper: Obtener color del método de pago
  Color _getPaymentMethodColor(String payMode) {
    switch (payMode.toLowerCase()) {
      case 'effective':
      case 'efectivo':
        return Colors.orange.shade700;
      case 'card':
      case 'tarjeta':
        return Colors.purple.shade700;
      case 'mercadopago':
      case 'qr':
        return Colors.blue.shade700;
      case 'transfer':
      case 'transferencia':
        return Colors.teal.shade700;
      default:
        return Colors.grey.shade600;
    }
  }

  // Helper: Obtener label completo del método de pago
  String _getPaymentMethodFullLabel(String payMode) {
    switch (payMode.toLowerCase()) {
      case 'effective':
      case 'efectivo':
        return 'Efectivo';
      case 'card':
      case 'tarjeta':
        return 'Tarjeta';
      case 'mercadopago':
        return 'Mercado Pago';
      case 'qr':
        return 'QR';
      case 'transfer':
      case 'transferencia':
        return 'Transferencia';
      default:
        return 'Otro';
    }
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
}
