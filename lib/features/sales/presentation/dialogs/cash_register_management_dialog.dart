import '../../../../../core/core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sellweb/core/constants/payment_methods.dart';
import 'package:sellweb/features/cash_register/domain/entities/cash_register.dart';
import 'package:sellweb/features/cash_register/domain/entities/cash_register_metrics.dart';
import 'package:sellweb/features/sales/domain/entities/ticket_model.dart';
import 'package:sellweb/features/auth/presentation/providers/auth_provider.dart';
import 'package:sellweb/features/sales/presentation/providers/sales_provider.dart';
import 'package:sellweb/features/cash_register/presentation/providers/cash_register_provider.dart';
import 'package:sellweb/features/cash_register/presentation/dialogs/cash_flow_dialog.dart';
import 'package:sellweb/core/services/demo_account/helpers/guest_mode_helper.dart';
import 'cash_register_close_dialog.dart';
import 'cash_register_open_dialog.dart';

// ✅ CONSTANTES DE DISEÑO Y ANIMACIÓN
class _CashRegisterDialogConstants {
  // Duraciones de animación
  static const animationDuration = Duration(milliseconds: 300);
  static const fastAnimationDuration = Duration(milliseconds: 200);
   
  // Border radius
  static const double borderRadiusMedium = 6.0;

  // Opacidades
  static const double opacityMedium = 0.1;

  // Tamaños de iconos
  static const double iconSizeSmall = 14.0;

  // Anchos de diálogo
  static const double dialogWidthTablet = 600.0;
  static const double dialogWidthDesktop = 700.0;

  // Items visibles
  static const int maxVisibleCashRegisters = 4;
  static const int maxVisibleTickets = 5;
  static const int maxVisibleMovements = 5;
}

/// Clase que cachea cálculos costosos de tickets para optimizar performance
/// ✅ OPTIMIZACIÓN: Evita recalcular en cada rebuild
class _TicketStatistics {
  final List<TicketModel> _tickets;

  // Caché interno
  Map<String, double>? _cachedPaymentMethods;
  List<TicketModel>? _lastTickets;
  double? _cachedTotalBilling;
  double? _cachedTotalProfit;
  int? _cachedActiveCount;

  _TicketStatistics(this._tickets);

  /// Verifica si el caché es válido
  bool get _isCacheValid => identical(_lastTickets, _tickets);

  /// Invalida el caché
  void _invalidateCache() {
    _lastTickets = _tickets;
  }

  /// Obtiene el ranking de métodos de pago agrupados (cacheado)
  Map<String, double> get paymentMethodsGrouped {
    if (_cachedPaymentMethods == null || !_isCacheValid) {
      _cachedPaymentMethods = _calculatePaymentMethods();
      _invalidateCache();
    }
    return _cachedPaymentMethods!;
  }

  /// Obtiene la facturación total de tickets activos (cacheado)
  double get totalBilling {
    if (_cachedTotalBilling == null || !_isCacheValid) {
      _cachedTotalBilling = _tickets
          .where((ticket) => !ticket.annulled)
          .fold<double>(0, (sum, ticket) => sum + ticket.priceTotal);
      _invalidateCache();
    }
    return _cachedTotalBilling!;
  }

  /// Obtiene la ganancia total de tickets activos (cacheado)
  double get totalProfit {
    if (_cachedTotalProfit == null || !_isCacheValid) {
      _cachedTotalProfit = _tickets
          .where((ticket) => !ticket.annulled)
          .fold<double>(0, (sum, ticket) => sum + ticket.getProfit);
      _invalidateCache();
    }
    return _cachedTotalProfit!;
  }

  /// Obtiene la cantidad de tickets activos (cacheado)
  int get activeTicketsCount {
    if (_cachedActiveCount == null || !_isCacheValid) {
      _cachedActiveCount = _tickets.where((ticket) => !ticket.annulled).length;
      _invalidateCache();
    }
    return _cachedActiveCount!;
  }

  /// Calcula y agrupa los métodos de pago usando el enum centralizado
  Map<String, double> _calculatePaymentMethods() {
    final ranking = TicketModel.getPaymentMethodsRanking(
      tickets: _tickets,
      includeAnnulled: false,
    );

    final Map<String, double> grouped = {};
    for (final payment in ranking) {
      // La description ya viene normalizada desde getPaymentMethodsRanking
      final description = (payment['description'] as String).trim();
      final percentage = payment['percentage'] as double;

      // Usar el displayName como key directamente
      grouped[description] = (grouped[description] ?? 0) + percentage;
    }

    return grouped;
  }
}

/// Diálogo principal para administrar cajas registradoras con diseño responsivo.
/// Optimizado para experiencia móvil y desktop siguiendo Material Design 3.
///
/// ✅ OPTIMIZADO: La gestión de tickets se realiza en [CashRegisterProvider]
/// con cache inteligente para evitar llamadas duplicadas a la base de datos.
/// Los tickets se cargan automáticamente y se comparten entre todas las vistas.
///
class CashRegisterManagementDialog extends StatefulWidget { 

  const CashRegisterManagementDialog({
    super.key, 
  });

  /// Muestra el diálogo de administración de caja como un diálogo modal.
  /// Usa [showDialog] con los providers necesarios ya configurados.
  ///
  /// [context]: BuildContext desde donde se muestra el diálogo
  /// [barrierDismissible]: Si se puede cerrar tocando fuera del diálogo (default: true)
  static Future<T?> showAsDialog<T>(
    BuildContext context, {
    bool barrierDismissible = true,
  }) {
    final cashRegisterProvider = Provider.of<CashRegisterProvider>(context, listen: false);
    final sellProvider = Provider.of<SalesProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    

    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (_) => MultiProvider(
        providers: [
          ChangeNotifierProvider<CashRegisterProvider>.value(value: cashRegisterProvider),
          ChangeNotifierProvider<SalesProvider>.value(value: sellProvider),
          ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        ],
        child: const CashRegisterManagementDialog(),
      ),
    );
  }


  /// Muestra el diálogo de administración de caja de forma adaptativa.
  /// - Con caja activa: Usa pantalla completa ([showAsFullScreen])
  /// - Sin caja activa: Usa diálogo modal ([showAsDialog])
  ///
  /// Esta estrategia permite una mejor experiencia al usuario:
  /// - Cuando ya tiene una caja activa, necesita más espacio para ver el flujo de caja completo
  /// - Cuando no tiene caja, solo necesita ver la lista de cajas disponibles o crear una nueva
  ///
  /// [context]: BuildContext desde donde se muestra
  /// [barrierDismissible]: Si se puede cerrar tocando fuera (solo para diálogo modal)
  static Future<T?> showAdaptive<T>(
    BuildContext context, {
    bool barrierDismissible = true,
  }) {
    // ✅ Verificar si hay una caja activa para decidir el tipo de presentación
    final cashRegisterProvider =
        Provider.of<CashRegisterProvider>(context, listen: false);
    final hasActiveCashRegister = cashRegisterProvider.hasActiveCashRegister;

    // Si hay caja activa → Pantalla completa (más espacio para ver flujo de caja)
    // Si NO hay caja activa → Diálogo modal (solo para seleccionar/crear caja)
    if (hasActiveCashRegister) {
      return showAsDialog<T>(context);
    } else {
      return showAsDialog<T>(context, barrierDismissible: barrierDismissible);
    }
  }

  @override
  State<CashRegisterManagementDialog> createState() =>
      _CashRegisterManagementDialogState();
}

class _CashRegisterManagementDialogState
    extends State<CashRegisterManagementDialog> {
  @override
  void initState() {
    super.initState();
    // ✅ La carga de tickets ahora se maneja en el provider
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Cargar tickets después del frame actual para evitar setState durante build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTicketsIfNeeded();
    });
  }

  /// Carga los tickets usando el provider solo cuando sea necesario
  void _loadTicketsIfNeeded() {
    if (!mounted) return; // ← Verificar si está montado

    final cashRegisterProvider = context.read<CashRegisterProvider>();
    final sellProvider = context.read<SalesProvider>();
    final accountId = sellProvider.profileAccountSelected.id;

    if (accountId.isNotEmpty) {
      cashRegisterProvider.loadCashRegisterTickets(accountId: accountId);
    }
  }

  /// Recarga los tickets manualmente (llamado después de acciones como anular ticket)
  void _reloadTickets() {
    if (!mounted) return; // ← Verificar si está montado

    final cashRegisterProvider = context.read<CashRegisterProvider>();
    final sellProvider = context.read<SalesProvider>();
    final accountId = sellProvider.profileAccountSelected.id;

    // ✅ Usar el método del provider para forzar la recarga
    if (accountId.isNotEmpty) {
      cashRegisterProvider.reloadTickets(accountId: accountId);
    }
  }

  @override
  Widget build(BuildContext context) {
 
    // ✅ Usar Selector para escuchar SOLO hasActiveCashRegister y evitar rebuilds innecesarios
    return Selector<CashRegisterProvider, bool>(
      selector: (_, provider) => provider.hasActiveCashRegister,
      builder: (context, hasActiveCashRegister, child) { 


        // Vista normal en diálogo
        return LayoutBuilder(
          builder: (context, constraints) {
            // render : Responsive design
            final isMobileDevice = isMobile(context);
            // dialog : base dialog
            return BaseDialog(
              fullView: true,
              title: 'Gestión de Caja', 
              subtitle: 'Administración de caja',
              icon: Icons.point_of_sale_rounded,
              headerColor: Theme.of(context)
                  .colorScheme
                  .secondaryContainer
                  .withValues(alpha: 0.85),
              width: getResponsiveValue(
                context,
                mobile: null,
                tablet: _CashRegisterDialogConstants.dialogWidthTablet,
                desktop: _CashRegisterDialogConstants.dialogWidthDesktop,
              ),
              maxHeight: getResponsiveValue(
                context,
                mobile: constraints.maxHeight * 0.9,
                tablet: 700,
                desktop: 800,
              ),
              content: Builder(
                builder: (context) {
                  // ✅ Usar Selector solo para isLoadingActive
                  return Selector<CashRegisterProvider, bool>(
                    selector: (_, provider) => provider.isLoadingActive,
                    builder: (context, isLoading, child) {
                      if (isLoading) {
                        return SizedBox(
                          height: getResponsiveValue(context,
                              mobile: 100, desktop: 120),
                          width: double.infinity,
                          child:
                              const Center(child: CircularProgressIndicator()),
                        );
                      }
                      // ✅ Usar context.read para acceder sin suscribirse
                      final provider = context.read<CashRegisterProvider>();
                      return _buildResponsiveContent(
                          context, provider, isMobileDevice);
                    },
                  );
                },
              ),
              actions: [
                // Botones de acción de caja (Deseleccionar/Cerrar) - Solo si hay caja activa
                if (hasActiveCashRegister)
                  ..._buildCashRegisterActionButtons(context, isMobileDevice),
              ],
            );
          },
        );
      },
    );
  }


  // view : Construir contenido responsivo de la información de caja existente o muestra mensaje de no caja activa
  Widget _buildResponsiveContent(
      BuildContext context, CashRegisterProvider provider, bool isMobile) {
    return Column(
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: getResponsiveSpacing(context, scale: 0.5)),
        if (provider.hasActiveCashRegister)
          // view : Mostrar información de caja activa
          _buildActiveCashRegister(context, provider, isMobile)
        else
          // view : selección de caja activa
          _buildNoCashRegister(context, isMobile),
      ],
    );
  }

  // view : información de caja activa
  Widget _buildActiveCashRegister(
      BuildContext context, CashRegisterProvider provider, bool isMobile) {
    // Obtener accountId desde SalesProvider
    final sellProvider = context.read<SalesProvider>();
    final accountId = sellProvider.profileAccountSelected.id;

    return AnimatedSwitcher(
      duration: _CashRegisterDialogConstants.fastAnimationDuration,
      switchInCurve: Curves.easeInOut,
      switchOutCurve: Curves.easeInOut,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // view : información de flujo de caja (usa stream del provider)
          _buildCashFlowView(context, provider, isMobile),
          SizedBox(height: getResponsiveSpacing(context, scale: 2)), 
          // view : metodo de pago y ventas recientes
          if (accountId.isNotEmpty && provider.currentActiveCashRegister != null)
            _PaymentMethodsAndRecentSalesSection(
              accountId: accountId,
              cashRegisterId: provider.currentActiveCashRegister!.id,
              provider: provider,
              isMobile: isMobile,
              onTicketUpdated: _reloadTickets,
            ),

          DialogComponents.sectionSpacing,
        ],
      ),
    );
  }

  List<Widget> _buildCashRegisterActionButtons(BuildContext context, bool isMobile) {
    // ✅ Usar context.read para acceder al provider sin suscribirse
    final provider = context.read<CashRegisterProvider>();
    final cashRegister = provider.currentActiveCashRegister!;

    return [
      // button : cierre de caja
      Material(
        child: DialogComponents.primaryActionButton(
          context: context,
          text: 'Cerrar Caja',
          accentColor:Colors.red.shade400,
          icon: Icons.point_of_sale_rounded,
          onPressed: () => _showCloseDialog(context, cashRegister),
        ),
      ),
      // button : cancelar el dialog
      DialogComponents.secondaryActionButton(
        context: context,
        text: 'Ok',
        onPressed: () => Navigator.of(context).pop(),
      ),
    ];
  }

  Widget _buildNoCashRegister(BuildContext context, bool isMobile) {
    final theme = Theme.of(context);
    // ✅ OPTIMIZADO: Usar Selector para escuchar solo los datos necesarios
    return Selector<
        CashRegisterProvider,
        ({
          bool hasAvailable,
          List<CashRegister> cashRegisters,
          bool isLoading
        })>(
      selector: (_, provider) => (
        hasAvailable: provider.hasAvailableCashRegisters,
        cashRegisters: provider.activeCashRegisters,
        isLoading: provider.isLoadingActive,
      ),
      builder: (context, data, child) {
        // ✅ Obtener authProvider con read (no watch) para evitar rebuilds innecesarios
        final authProvider = context.read<AuthProvider>();
        final provider = context.read<CashRegisterProvider>();

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Verificar si hay cajas disponibles
            if (data.hasAvailable) ...[
              // Título de sección estilizado
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 12),
                child: Text(
                  'CAJAS DISPONIBLES',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              // Mostrar lista de cajas disponibles con diseño premium
              DialogComponents.itemList(
                context: context,
                maxVisibleItems:
                    _CashRegisterDialogConstants.maxVisibleCashRegisters,
                expandText:
                    'Ver más cajas (${data.cashRegisters.length > _CashRegisterDialogConstants.maxVisibleCashRegisters ? data.cashRegisters.length - _CashRegisterDialogConstants.maxVisibleCashRegisters : 0})',
                collapseText: 'Ver menos',
                showDividers: true,
                borderRadius: 16,
                useFillStyle: true,
                backgroundColor: theme.colorScheme.surfaceContainerLow,
                padding: const EdgeInsets.symmetric(vertical: 4),
                items: [
                  ...data.cashRegisters.map((cashRegister) {
                    return _buildCashRegisterTile(
                        context, cashRegister, provider, isMobile);
                  }),
                  // Item: Abrir nueva caja
                  _buildCreateCashRegisterItem(context, authProvider, isMobile),
                ],
              ),
              SizedBox(height: isMobile ? 16 : 24),
            ] else ...[
              // view : Mostrar mensaje de no cajas disponibles con diseño mejorado
              Container(
                padding: EdgeInsets.symmetric(
                  vertical: isMobile ? 40 : 56,
                  horizontal: isMobile ? 24 : 32,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icono destacado con gradiente sutil
                    Container(
                      padding: EdgeInsets.all(isMobile ? 16 : 20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                            theme.colorScheme.secondaryContainer.withValues(alpha: 0.2),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(isMobile ? 16 : 20),
                        border: Border.all(
                          color: theme.colorScheme.outline.withValues(alpha: 0.1),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        Icons.point_of_sale,
                        size: isMobile ? 48 : 64,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    SizedBox(height: isMobile ? 20 : 24),
                    
                    // Título principal
                    Text(
                      'Sin cajas abiertas',
                      style: (isMobile
                              ? theme.textTheme.titleLarge
                              : theme.textTheme.headlineSmall)
                          ?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: isMobile ? 8 : 12),
                    
                    // Descripción mejorada
                    Text(
                      'Abre una caja para comenzar a registrar\nventas y gestionar tu flujo de efectivo',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: isMobile ? 24 : 32),
                    
                    // Botón de acción principal
                    DialogComponents.primaryActionButton(
                      context: context,
                      text: authProvider.isGuest 
                          ? '🔒 Inicia sesión para abrir caja' 
                          : 'Abrir nueva caja',
                      icon: authProvider.isGuest 
                          ? Icons.lock_outline 
                          : Icons.add_circle_outline_rounded,
                      onPressed: authProvider.isGuest
                          ? () {
                              // Importar al inicio del archivo si no existe:
                              // import 'package:sellweb/core/services/demo_account/helpers/guest_mode_helper.dart';
                              GuestModeHelper.showRestrictionDialog(
                                context,
                                featureName: 'Apertura de Caja',
                              );
                            }
                          : () => _showOpenDialog(context),
                      isLoading: data.isLoading,
                    ),
                    SizedBox(height: isMobile ? 16 : 20),
                    
                    // Info badge mejorado
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: theme.colorScheme.outline.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            size: 16,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'Cada caja representa un arqueo en un tiempo determinado o turno de trabajo',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildCashRegisterTile(BuildContext context, CashRegister cashRegister,
      CashRegisterProvider provider, bool isMobile) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => provider.selectCashRegister(cashRegister),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.transparent, width: 1),
          ),
          child: Row(
            children: [
              // Avatar de la caja con sombra
              Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colorScheme.surfaceContainerHigh,
                      ),
                      child: Icon(
                        Icons.point_of_sale_rounded,
                        size: 20,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),

              // Información de la caja
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cashRegister.description,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          Icons.history_rounded,
                          size: 14,
                          color: colorScheme.primary.withValues(alpha: 0.7),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '${cashRegister.opening.day.toString().padLeft(2, '0')}/${cashRegister.opening.month.toString().padLeft(2, '0')} ${cashRegister.opening.hour.toString().padLeft(2, '0')}:${cashRegister.opening.minute.toString().padLeft(2, '0')} • ${DateTime.now().difference(cashRegister.opening).inHours}h ${DateTime.now().difference(cashRegister.opening).inMinutes % 60}m',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Flecha indicadora
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: colorScheme.surfaceContainerHigh,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Item para abrir una nueva caja
  Widget _buildCreateCashRegisterItem(
    BuildContext context,
    AuthProvider authProvider,
    bool isMobile,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: authProvider.isGuest
            ? null
            : () => _showOpenDialog(context),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.transparent, width: 1),
          ),
          child: Row(
            children: [
              // Icono de +
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colorScheme.surfaceContainerHigh.withValues(alpha: 0.5),
                  border: Border.all(
                    color: colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
                child: Icon(
                  Icons.add_rounded,
                  color: colorScheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),

              // Texto
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Abrir nueva caja',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      'Inicia un nuevo turno de caja',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              // Flecha
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: colorScheme.surfaceContainerHigh,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Construye la vista de flujo de caja con información financiera
  Widget _buildCashFlowView(BuildContext context, CashRegisterProvider provider, bool isMobile) {
    final cashRegister = provider.currentActiveCashRegister!;

    // ✅ Usar widget separado que no depende de FutureBuilder
    return _CashFlowView(
      cashRegister: cashRegister,
      isMobile: isMobile,
    );
  }

  void _showOpenDialog(BuildContext context) {
    // Capturar los providers antes de mostrar el diálogo
    final cashRegisterProvider = Provider.of<CashRegisterProvider>(context, listen: false);
    final sellProvider = Provider.of<SalesProvider>(context, listen: false);

    // ✅ Cerrar el diálogo actual antes de abrir el nuevo
    Navigator.of(context).pop();

    // ✅ Usar addPostFrameCallback para asegurar que el pop se complete antes del showDialog
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        builder: (_) => MultiProvider(
          providers: [
            ChangeNotifierProvider<CashRegisterProvider>.value(value: cashRegisterProvider),
            ChangeNotifierProvider<SalesProvider>.value(value: sellProvider),
          ],
          child: const CashRegisterOpenDialog(),
        ),
      );
    });
  }

  void _showCloseDialog(BuildContext context, CashRegister cashRegister) {
    // Capturar los providers antes de mostrar el diálogo
    final cashRegisterProvider = Provider.of<CashRegisterProvider>(context, listen: false);
    final sellProvider = Provider.of<SalesProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (_) => MultiProvider(
        providers: [
          ChangeNotifierProvider<CashRegisterProvider>.value(value: cashRegisterProvider),
          ChangeNotifierProvider<SalesProvider>.value(value: sellProvider),
        ],
        child: CashRegisterCloseDialog(cashRegister: cashRegister),
      ),
    );
  }
}

/// Widget separado para métodos de pago y ventas recientes
/// ✅ OPTIMIZADO: Solo actualiza los datos sin reconstruir toda la vista
class _PaymentMethodsAndRecentSalesSection extends StatelessWidget {
  final String accountId;
  final String cashRegisterId;
  final CashRegisterProvider provider;
  final bool isMobile;
  final VoidCallback onTicketUpdated;

  const _PaymentMethodsAndRecentSalesSection({
    required this.accountId,
    required this.cashRegisterId,
    required this.provider,
    required this.isMobile,
    required this.onTicketUpdated,
  });

  @override
  Widget build(BuildContext context) {
    // ✅ Usar AnimatedSize para transiciones suaves al cambiar contenido
    return AnimatedSize(
      duration: _CashRegisterDialogConstants.animationDuration,
      curve: Curves.easeInOut,
      child: _TicketsStreamListener(
        accountId: accountId,
        cashRegisterId: cashRegisterId,
        provider: provider,
        isMobile: isMobile,
        onTicketUpdated: onTicketUpdated,
      ),
    );
  }
}

/// Widget interno que escucha el stream de tickets
/// ✅ OPTIMIZADO: Separado para que la Column padre no se reconstruya
class _TicketsStreamListener extends StatelessWidget {
  final String accountId;
  final String cashRegisterId;
  final CashRegisterProvider provider;
  final bool isMobile;
  final VoidCallback onTicketUpdated;

  const _TicketsStreamListener({
    required this.accountId,
    required this.cashRegisterId,
    required this.provider,
    required this.isMobile,
    required this.onTicketUpdated,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<TicketModel>>(
      stream: provider.getCashRegisterTicketsStream(
        accountId: accountId,
        cashRegisterId: cashRegisterId,
      ),
      // ✅ Usar builder con child estático para optimización
      builder: (context, snapshot) {
        // Estados de carga y error - widgets const para no reconstruir
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Error al cargar tickets: ${snapshot.error}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        // Sin datos o lista vacía
        if (!snapshot.hasData ||
            snapshot.data == null ||
            snapshot.data!.isEmpty) {
          return _buildEmptyTransactionsMessage(context);
        }

        final tickets = snapshot.data!;
        final activeTickets =
            tickets.where((ticket) => !ticket.annulled).toList();

        if (activeTickets.isEmpty) {
          return _buildEmptyTransactionsMessage(context);
        }

        // ✅ Usar AnimatedSwitcher para transiciones suaves entre estados
        return AnimatedSwitcher(
          duration: _CashRegisterDialogConstants.fastAnimationDuration,
          switchInCurve: Curves.easeInOut,
          switchOutCurve: Curves.easeInOut,
          child: _PaymentAndTicketsContent(
            // ✅ Key basada en hash de datos relevantes (no lista completa)
            key: ValueKey(Object.hash(
              tickets.length,
              activeTickets.length,
              tickets.fold<double>(0, (sum, t) => sum + t.priceTotal),
            )),
            tickets: tickets,
            activeTickets: activeTickets,
            provider: provider,
            isMobile: isMobile,
            onTicketUpdated: onTicketUpdated,
          ),
        );
      },
    );
  }

  /// Construye el mensaje cuando no hay transacciones
  Widget _buildEmptyTransactionsMessage(BuildContext context) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Text(
          'Sin transacciones aún',
          style: (isMobile 
              ? theme.textTheme.bodyMedium 
              : theme.textTheme.bodyLarge)?.copyWith(
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

/// Widget que contiene el contenido cuando hay datos
/// ✅ OPTIMIZADO: Recibe los datos ya procesados
class _PaymentAndTicketsContent extends StatelessWidget {
  final List<TicketModel> tickets;
  final List<TicketModel> activeTickets;
  final CashRegisterProvider provider;
  final bool isMobile;
  final VoidCallback onTicketUpdated;

  const _PaymentAndTicketsContent({
    super.key,
    required this.tickets,
    required this.activeTickets,
    required this.provider,
    required this.isMobile,
    required this.onTicketUpdated,
  });

  @override
  Widget build(BuildContext context) {
    // 🔍 DEBUG: Descomentar para verificar que NO se reconstruye innecesariamente
    // print('🔄 _PaymentAndTicketsContent rebuild - Tickets: ${tickets.length}');

    // ✅ Envolver en RepaintBoundary para aislar repintados
    return RepaintBoundary(
      child: Column(
        children: [
          // view : muestra resumen de métodos de pago
          _PaymentMethodsSummary(
            tickets: activeTickets,
            isMobile: isMobile,
          ),
          SizedBox(height: getResponsiveSpacing(context, scale: 2)),
          // view : ventas recientes
          RecentTicketsView(
            tickets: tickets,
            cashRegisterProvider: provider,
            isMobile: isMobile,
            onTicketUpdated: onTicketUpdated,
          ),
        ],
      ),
    );
  }
}

/// Widget separado para el resumen de métodos de pago
/// ✅ OPTIMIZADO: Solo se reconstruye cuando cambian los tickets
class _PaymentMethodsSummary extends StatelessWidget {
  final List<TicketModel> tickets;
  final bool isMobile;

  const _PaymentMethodsSummary({
    required this.tickets,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    // 🔍 DEBUG: Descomentar para verificar reconstrucciones
    // print('🔄 _PaymentMethodsSummary rebuild - Tickets: ${tickets.length}');

    final theme = Theme.of(context);

    // ✅ OPTIMIZADO: Usar caché de cálculos con _TicketStatistics
    final statistics = _TicketStatistics(tickets);
    final groupedPayments = statistics.paymentMethodsGrouped;

    if (groupedPayments.isEmpty) {
      return const SizedBox.shrink();
    }

    // ✅ Convertir a PercentageBarData usando el helper (ya agrupados)
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

    // ✅ Envolver en RepaintBoundary y AnimatedOpacity para transiciones suaves
    return RepaintBoundary(
      child: TweenAnimationBuilder<double>(
        duration: _CashRegisterDialogConstants.fastAnimationDuration,
        tween: Tween(begin: 0.95, end: 1.0),
        curve: Curves.easeInOut,
        builder: (context, value, child) {
          return Transform.scale(
            scale: value,
            child: Opacity(
              opacity: value,
              child: child,
            ),
          );
        },
        child: PercentageBarChart(
          title: 'Métodos de pago',
          data: chartData,
          isMobile: isMobile,
        ),
      ),
    );
  }

  /// Helper: Obtener datos de color, icono y etiqueta para un método de pago usando el enum
  Map<String, dynamic> _getPaymentMethodData({
    required String description,
    required double percentage,
    required ThemeData theme,
  }) {
    // Intentar obtener el PaymentMethod desde el displayName
    PaymentMethod paymentMethod;
    try {
      // Buscar por displayName
      paymentMethod = PaymentMethod.values.firstWhere(
        (method) => method.displayName == description,
        orElse: () => PaymentMethod.unspecified,
      );
    } catch (e) {
      paymentMethod = PaymentMethod.unspecified;
    }

    return {
      'color': paymentMethod.color,
      'icon': paymentMethod.icon,
      'label': paymentMethod.displayName,
      'percentage': percentage,
    };
  }
}

/// Widget separado para la vista de flujo de caja
/// ✅ OPTIMIZADO: Escucha cambios en tiempo real del cashRegister
class _CashFlowView extends StatefulWidget {
  final CashRegister cashRegister;
  final bool isMobile;

  const _CashFlowView({
    required this.cashRegister,
    required this.isMobile,
  });

  @override
  State<_CashFlowView> createState() => _CashFlowViewState();
}

class _CashFlowViewState extends State<_CashFlowView> {
  @override
  Widget build(BuildContext context) {
    final sellProvider = context.read<SalesProvider>();
    final accountId = sellProvider.profileAccountSelected.id;

    // ✅ Usar Selector para escuchar solo cambios relevantes del cashRegister
    return Selector<CashRegisterProvider, ({String? id, int version})>(
      selector: (_, provider) {
        final cashRegister = provider.currentActiveCashRegister;
        // Versión basada en campos que afectan esta vista
        final version = cashRegister != null
            ? Object.hash(
                cashRegister.id,
                cashRegister.getTotalIngresos,
                cashRegister.getTotalEgresos,
                cashRegister.getExpectedBalance,
                cashRegister.sales,
              )
            : 0;
        return (id: cashRegister?.id, version: version);
      },
      builder: (context, data, child) {
        // Si no hay caja activa, usar la caja del parámetro
        final cashRegisterProvider = context.read<CashRegisterProvider>();
        final currentCashRegister =
            cashRegisterProvider.currentActiveCashRegister ??
                widget.cashRegister;

        // ✅ Envolver en RepaintBoundary para aislar repintados
        return RepaintBoundary(
          child: AnimatedSwitcher(
            duration: _CashRegisterDialogConstants.fastAnimationDuration,
            switchInCurve: Curves.easeInOut,
            switchOutCurve: Curves.easeInOut,
            child: Column(
              key: ValueKey(data.version),
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // view : Información de flujo de caja  
                _CashFlowInformation(
                  cashRegister: currentCashRegister,
                  isMobile: widget.isMobile,
                  accountId: accountId,
                ),

                SizedBox(height: getResponsiveSpacing(context, scale: 2)),

                // buttons : botones de ingreso y egreso de caja
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        margin: EdgeInsets.zero,
                        child: AppButton.outlined(
                          borderRadius: 4,
                          icon: const Icon(Icons.arrow_downward_rounded),
                          text: 'Ingreso',
                          onPressed: cashRegisterProvider.hasActiveCashRegister
                              ? () => _showCashFlowDialog(context, true)
                              : null,
                          backgroundColor:
                              cashRegisterProvider.hasActiveCashRegister
                                  ? Colors.green.withValues(alpha: 0.1)
                                  : null,
                          foregroundColor:
                              cashRegisterProvider.hasActiveCashRegister
                                  ? Colors.green
                                  : null,
                          borderColor:
                              cashRegisterProvider.hasActiveCashRegister
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
                        child: AppButton.outlined(
                          borderRadius: 4,
                          icon: const Icon(Icons.arrow_upward),
                          text: 'Egreso',
                          onPressed: cashRegisterProvider.hasActiveCashRegister
                              ? () => _showCashFlowDialog(context, false)
                              : null,
                          backgroundColor:
                              cashRegisterProvider.hasActiveCashRegister
                                  ? Colors.red.withValues(alpha: 0.1)
                                  : null,
                          foregroundColor:
                              cashRegisterProvider.hasActiveCashRegister
                                  ? Colors.red
                                  : null,
                          borderColor:
                              cashRegisterProvider.hasActiveCashRegister
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

                SizedBox(height: getResponsiveSpacing(context, scale: 1)),

                // Lista de movimientos de caja
                if (currentCashRegister.cashInFlowList.isNotEmpty ||
                    currentCashRegister.cashOutFlowList.isNotEmpty) ...[
                  _CashFlowMovementsList(
                    cashRegister: currentCashRegister,
                    isMobile: widget.isMobile,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  void _showCashFlowDialog(BuildContext context, bool isInflow) {
    // Capturar todos los providers necesarios antes de mostrar el diálogo
    final cashRegisterProvider =
        Provider.of<CashRegisterProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final sellProvider = Provider.of<SalesProvider>(context, listen: false);

    if (!cashRegisterProvider.hasActiveCashRegister) return;

    final cashRegister = cashRegisterProvider.currentActiveCashRegister!;

    showDialog(
      context: context,
      builder: (_) => MultiProvider(
        providers: [
          ChangeNotifierProvider<CashRegisterProvider>.value(
              value: cashRegisterProvider),
          ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
          ChangeNotifierProvider<SalesProvider>.value(value: sellProvider),
        ],
        child: CashFlowDialog(
          isInflow: isInflow,
          cashRegisterId: cashRegister.id,
          accountId: sellProvider.profileAccountSelected.id,
          userId: authProvider.user?.email ?? '',
          fullView: true,
        ),
      ),
    );
  }
}

/// Widget separado para información de flujo de caja
/// ✅ OPTIMIZADO: Usa CashRegisterMetrics centralizado para evitar recálculos
class _CashFlowInformation extends StatelessWidget {
  final CashRegister cashRegister;
  final bool isMobile;
  final String accountId;

  const _CashFlowInformation({
    required this.cashRegister,
    required this.isMobile,
    required this.accountId,
  });

  @override
  Widget build(BuildContext context) {
    final cashRegisterProvider = context.read<CashRegisterProvider>();

    // ✅ Envolver en RepaintBoundary para aislar repintados de esta sección
    return RepaintBoundary(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sección: Nombre/Descripción de la caja con información temporal
          _CashRegisterHeaderSection(
            cashRegister: cashRegister,
            isMobile: isMobile,
          ),
          SizedBox(height: getResponsiveSpacing(context, scale: 1.5)),

          // Sección: Estadísticas de ventas con cards destacadas
          _StatsCardsSection(
            cashRegister: cashRegister,
            isMobile: isMobile,
          ),
          SizedBox(height: getResponsiveSpacing(context, scale: 1.5)),

          // ✅ OPTIMIZADO: Usar métricas cacheadas o stream
          if (accountId.isNotEmpty && cashRegister.id.isNotEmpty) ...[
            // Intentar usar caché primero para renderizado inmediato
            Builder(
              builder: (context) {
                final cachedMetrics = cashRegisterProvider.cachedMetrics;
                
                // Si hay métricas en caché de esta caja, usarlas directamente
                if (cachedMetrics != null && cachedMetrics.cashRegister.id == cashRegister.id) {
                  return _FinancialSummarySection(
                    cashRegister: cashRegister,
                    isMobile: isMobile,
                    metrics: cachedMetrics,
                  );
                }
                
                // Si no hay caché, usar StreamBuilder con skeleton
                return StreamBuilder<CashRegisterMetrics>(
                  stream: cashRegisterProvider.getCashRegisterMetricsStream(
                    accountId: accountId,
                  ),
                  builder: (context, snapshot) {
                    // Mostrar skeleton solo si aún no hay datos
                    if (!snapshot.hasData) {
                      return _FinancialSummarySkeleton(isMobile: isMobile);
                    }

                    final metrics = snapshot.data;
                    return _FinancialSummarySection(
                      cashRegister: cashRegister,
                      isMobile: isMobile,
                      metrics: metrics,
                    );
                  },
                );
              },
            ),
          ] else
            _FinancialSummarySection(
              cashRegister: cashRegister,
              isMobile: isMobile,
            ),
        ],
      ),
    );
  }
}

/// Widget separado para el header de la caja registradora
/// ✅ OPTIMIZADO: Solo se reconstruye cuando cambian los datos del cashRegister
class _CashRegisterHeaderSection extends StatelessWidget {
  final CashRegister cashRegister;
  final bool isMobile;

  const _CashRegisterHeaderSection({
    required this.cashRegister,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Selector<CashRegisterProvider, CashRegister?>(
      selector: (_, provider) => provider.currentActiveCashRegister,
      builder: (context, activeCashRegister, child) {
        final currentCashRegister = activeCashRegister ?? cashRegister;

        // ✅ Calcular tiempo activo para el subtítulo
        final activeTime = DateFormatter.getElapsedTime(
          fechaInicio: currentCashRegister.opening,
        );

        // ✅ Usar el nuevo componente reutilizable ExpandablePremiumListTile
        return ExpandablePremiumListTile(
          icon: Icons.point_of_sale_rounded,
          iconColor: theme.colorScheme.primary,
          title: currentCashRegister.description,
          subtitle: Row(
            children: [
              Icon(
                Icons.timelapse_rounded,
                size: isMobile ? 14 : 16,
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 6),
              Text(
                activeTime,
                style: (isMobile
                        ? theme.textTheme.bodySmall
                        : theme.textTheme.bodyMedium)
                    ?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          badge: PremiumListTileBadge(
            label: 'ACTIVA',
            color: Colors.green.shade700,
            showDot: true,
          ),
          expandedInfo: [
            ExpandableInfoItem(
              icon: Icons.schedule_rounded,
              label: 'Apertura',
              value: DateFormatter.formatPublicationDate(
                dateTime: currentCashRegister.opening,
              ),
            ),
            ExpandableInfoItem(
              icon: Icons.timelapse_rounded,
              label: 'Tiempo activo',
              value: activeTime,
            ),
            ExpandableInfoItem(
              icon: Icons.person_rounded,
              label: 'Cajero',
              value: currentCashRegister.nameUser.isNotEmpty
                  ? currentCashRegister.idUser
                  : 'Desconocido',
            ),
          ],
          isMobile: isMobile,
          initiallyExpanded: false,
        );
      },
    );
  }
}

/// Widget separado para las cards de estadísticas
/// ✅ OPTIMIZADO: Solo se reconstruye cuando cambian las estadísticas
class _StatsCardsSection extends StatelessWidget {
  final CashRegister cashRegister;
  final bool isMobile;

  const _StatsCardsSection({
    required this.cashRegister,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Selector<CashRegisterProvider,
        ({int sales, int effective, int annulled})>(
      selector: (_, provider) {
        final cr = provider.currentActiveCashRegister ?? cashRegister;
        return (
          sales: cr.sales,
          effective: cr.getEffectiveSales,
          annulled: cr.annulledTickets,
        );
      },
      builder: (context, stats, child) {
        final statsList = [
          {
            'label': 'Transacciones',
            'value': '${stats.sales}',
            'icon': Icons.receipt_long_rounded,
            'color': theme.colorScheme.primary,
          },
          {
            'label': 'Efectivas',
            'value': '${stats.effective}',
            'icon': Icons.check_circle_rounded,
            'color': Colors.green,
          },
          {
            'label': 'Anulados',
            'value': '${stats.annulled}',
            'icon': Icons.cancel_rounded,
            'color': Colors.red,
          },
        ];

        // ✅ Usar RepaintBoundary y animación sutil
        return RepaintBoundary(
          child: TweenAnimationBuilder<double>(
            duration: _CashRegisterDialogConstants.fastAnimationDuration,
            tween: Tween(begin: 0.98, end: 1.0),
            curve: Curves.easeOut,
            builder: (context, scale, child) => Transform.scale(
              scale: scale,
              child: child,
            ),
            child: Row(
              children: statsList.map((stat) {
                final color = stat['color'] as Color;
                return Expanded(
                  child: Container(
                    margin: EdgeInsets.only(
                      right: stat == statsList.last ? 0 : (isMobile ? 6 : 8),
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 8 : 12,
                      vertical: isMobile ? 10 : 12,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              stat['value'] as String,
                              style: (isMobile
                                      ? theme.textTheme.titleMedium
                                      : theme.textTheme.titleLarge)
                                  ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                            ),
                            Icon(
                              stat['icon'] as IconData,
                              size: isMobile ? 18 : 20,
                              color: color.withValues(alpha: 0.7),
                            ),
                          ],
                        ),
                        SizedBox(height: isMobile ? 4 : 6),
                        Text(
                          stat['label'] as String,
                          style: (isMobile
                                  ? theme.textTheme.bodySmall
                                  : theme.textTheme.bodyMedium)
                              ?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: isMobile ? 11 : 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }
}

/// Widget consolidado para resumen financiero con ExpandablePremiumListTile
/// ✅ OPTIMIZADO: Usa CashRegisterMetrics pre-calculado para evitar recálculos O(n)
class _FinancialSummarySection extends StatelessWidget {
  final CashRegister cashRegister;
  final bool isMobile;
  final CashRegisterMetrics? metrics;

  const _FinancialSummarySection({
    required this.cashRegister,
    required this.isMobile,
    this.metrics,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // ✅ Usar métricas pre-calculadas o valores del cashRegister como fallback
    final totalProfit = metrics?.totalProfit ?? 0.0;
    final totalDiscount = metrics?.totalDiscount ?? cashRegister.discount;
    final totalBilling = metrics?.totalBilling ?? cashRegister.billing;
    final expectedBalance = metrics?.expectedBalance ?? cashRegister.getExpectedBalance;
    final totalIngresos = metrics?.totalInflows ?? cashRegister.getTotalIngresos;
    final totalEgresos = metrics?.totalOutflows ?? cashRegister.getTotalEgresos;
    final initialCash = metrics?.initialCash ?? cashRegister.initialCash;

    // Construir items expandibles solo con información secundaria
    final List<ExpandableInfoItem> expandedInfo = [];

    // Facturación total
    if (totalBilling > 0) {
      expandedInfo.add(
        ExpandableInfoItem(
          icon: Icons.receipt_long_rounded,
          label: 'Facturación de ventas',
          valueWidget: Text(
            CurrencyFormatter.formatPrice(value: totalBilling),
            style: (isMobile
                    ? theme.textTheme.bodySmall
                    : theme.textTheme.bodyMedium)
                ?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
      );
    }

    // Monto inicial
    if (initialCash > 0) {
      expandedInfo.add(
        ExpandableInfoItem(
          icon: Icons.attach_money_rounded,
          label: 'Monto Inicial',
          valueWidget: Text(
            CurrencyFormatter.formatPrice(value: initialCash),
            style: (isMobile
                    ? theme.textTheme.bodySmall
                    : theme.textTheme.bodyMedium)
                ?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
      );
    }

    // Ingresos en caja
    if (totalIngresos > 0) {
      expandedInfo.add(
        ExpandableInfoItem(
          icon: Icons.call_received_rounded,
          label: 'Ingresos en caja',
          valueWidget: Text(
            CurrencyFormatter.formatPrice(value: totalIngresos),
            style: (isMobile
                    ? theme.textTheme.bodySmall
                    : theme.textTheme.bodyMedium)
                ?.copyWith(
              fontWeight: FontWeight.w700,
              color: Colors.green,
            ),
          ),
        ),
      );
    }

    // Egresos en caja
    if (totalEgresos > 0) {
      expandedInfo.add(
        ExpandableInfoItem(
          icon: Icons.arrow_outward_rounded,
          label: 'Egresos en caja',
          valueWidget: Text(
            '-${CurrencyFormatter.formatPrice(value: totalEgresos)}',
            style: (isMobile
                    ? theme.textTheme.bodySmall
                    : theme.textTheme.bodyMedium)
                ?.copyWith(
              fontWeight: FontWeight.w700,
              color: Colors.red,
            ),
          ),
        ),
      );
    }

    // Descuentos
    if (totalDiscount > 0) {
      expandedInfo.add(
        ExpandableInfoItem(
          icon: Icons.discount_rounded,
          label: 'Descuentos',
          valueWidget: Text(
            '-${CurrencyFormatter.formatPrice(value: totalDiscount)}',
            style: (isMobile
                    ? theme.textTheme.bodySmall
                    : theme.textTheme.bodyMedium)
                ?.copyWith(
              fontWeight: FontWeight.w700,
              color: Colors.red,
            ),
          ),
        ),
      );
    }

    // Construir el ExpandablePremiumListTile con Balance y Ganancia en header
    return ExpandablePremiumListTile(
      iconColor: theme.colorScheme.primary,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                Icons.point_of_sale_rounded,
                size: isMobile ? 16 : 18,
                color: theme.colorScheme.primary.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 6),
              Text(
                'Balance Total',
                style: (isMobile
                        ? theme.textTheme.bodyMedium
                        : theme.textTheme.bodyLarge)
                    ?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Icon(
                Icons.trending_up_rounded,
                size: isMobile ? 16 : 18,
                color: Colors.green.shade700.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 6),
              Text(
                'Ganancias',
                style: (isMobile
                        ? theme.textTheme.bodyMedium
                        : theme.textTheme.bodyLarge)
                    ?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
      // Mostrar Balance y Ganancia en el header
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                CurrencyFormatter.formatPrice(value: expectedBalance),
                style: (isMobile
                        ? theme.textTheme.titleMedium
                        : theme.textTheme.titleLarge)
                    ?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.primary,
                ),
              ),
              Text(
                CurrencyFormatter.formatPrice(value: totalProfit),
                style: (isMobile
                        ? theme.textTheme.titleMedium
                        : theme.textTheme.titleLarge)
                    ?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: Colors.green.shade700,
                ),
              ),
            ],
          ),
        ],
      ),
      expandedInfo: expandedInfo,
      isMobile: isMobile,
      initiallyExpanded: false,
    );
  }
}

/// Widget separado para lista de movimientos de caja
/// ✅ OPTIMIZADO: Solo se reconstruye cuando cambian los movimientos
class _CashFlowMovementsList extends StatelessWidget {
  final CashRegister cashRegister;
  final bool isMobile;

  const _CashFlowMovementsList({
    required this.cashRegister,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
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

    // ✅ Envolver en RepaintBoundary y AnimatedSwitcher para transiciones suaves
    return RepaintBoundary(
      child: AnimatedSwitcher(
        duration: _CashRegisterDialogConstants.fastAnimationDuration,
        switchInCurve: Curves.easeInOut,
        switchOutCurve: Curves.easeInOut,
        child: Container(
          key: ValueKey('movements_${allMovements.length}_${totalIngresos}_$totalEgresos'),
          child: DialogComponents.itemList(
            context: context,
            useFillStyle: true,
            showDividers: true,
            borderColor: theme.dividerColor.withValues(alpha: 0.3),
            title: 'Movimientos',
            trailing: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Total de ingresos
                  if (totalIngresos > 0) ...[
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(
                            alpha: _CashRegisterDialogConstants.opacityMedium),
                        borderRadius: BorderRadius.circular(
                            _CashRegisterDialogConstants.borderRadiusMedium),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.arrow_downward_rounded,
                            size: isMobile
                                ? _CashRegisterDialogConstants.iconSizeSmall - 2
                                : _CashRegisterDialogConstants.iconSizeSmall,
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
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(
                            alpha: _CashRegisterDialogConstants.opacityMedium),
                        borderRadius: BorderRadius.circular(
                            _CashRegisterDialogConstants.borderRadiusMedium),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.arrow_outward_rounded,
                            size: isMobile
                                ? _CashRegisterDialogConstants.iconSizeSmall - 2
                                : _CashRegisterDialogConstants.iconSizeSmall,
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
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                            balanceNeto >= 0
                                ? Icons.trending_up_rounded
                                : Icons.trending_down_rounded,
                            size: isMobile ? 12 : 14,
                            color: balanceNeto >= 0
                                ? theme.colorScheme.primary
                                : Colors.orange.shade700,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            CurrencyFormatter.formatPrice(
                                value: balanceNeto.abs()),
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
            ),
            maxVisibleItems: _CashRegisterDialogConstants.maxVisibleMovements,
            expandText:
                'Ver más (${allMovements.length > _CashRegisterDialogConstants.maxVisibleMovements ? allMovements.length - _CashRegisterDialogConstants.maxVisibleMovements : 0})',
            collapseText: 'Ver menos',
            items: allMovements.map((movement) {
              return _buildCashFlowMovementTile(
                  context, movement, isMobile, theme);
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildCashFlowMovementTile(BuildContext context,
      Map<String, dynamic> movement, bool isMobile, ThemeData theme) {
    final cashFlow = movement['cashFlow'] as CashFlow;
    final isIngreso = movement['type'] == 'ingreso';

    final iconColor = isIngreso ? Colors.green : Colors.red;
    final icon = isIngreso ? Icons.call_received : Icons.arrow_outward_rounded;

    return Row(
      children: [
        // Icono del tipo de movimiento
        Icon(
          icon,
          size: isMobile ? 14 : 16,
          color: iconColor,
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
}

/// Widget separado para manejar la lista de tickets recientes de manera eficiente
/// Evita rebuilds innecesarios y llamadas duplicadas a la base de datos
class RecentTicketsView extends StatefulWidget {
  /// Lista de tickets a mostrar
  final List<TicketModel> tickets;

  final CashRegisterProvider cashRegisterProvider;
  final bool isMobile;

  /// Callback para recargar tickets después de acciones (anular, etc.)
  final VoidCallback? onTicketUpdated;

  const RecentTicketsView({
    super.key,
    required this.tickets,
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
    // Si no hay tickets, mostrar vista vacía
    if (widget.tickets.isEmpty) {
      return _buildEmptyTicketsView(context, widget.isMobile);
    }

    // Construir la lista de tickets
    return _buildTicketsList(widget.tickets);
  }

  /// Construye la lista de tickets
  Widget _buildTicketsList(List<TicketModel> allTickets) {
    // Convertir a TicketModel y ordenar por fecha (más recientes primero)
    final tickets = allTickets
        .map((ticketData) {
          try {
            // Si ya es TicketModel, usarlo directamente
            return ticketData;
          } catch (e) {
            debugPrint('Error processing ticket data: $e');
            return null;
          }
        })
        .where((ticket) => ticket != null)
        .cast<TicketModel>()
        .toList();

    // Ordenar por fecha de creación (más recientes primero)
    tickets.sort((a, b) => b.creation.compareTo(a.creation));

    if (tickets.isEmpty) {
      return _buildEmptyTicketsView(context, widget.isMobile);
    }

    // ✅ Tomar solo los primeros N para mostrar usando constante
    final recentTickets =
        tickets.take(_CashRegisterDialogConstants.maxVisibleTickets).toList();
    final hasMoreTickets =
        tickets.length > _CashRegisterDialogConstants.maxVisibleTickets;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Calcular el total de facturación y ganancia de TODOS los tickets activos (no anulados)
        // ✅ OPTIMIZADO: Usar _TicketStatistics para caché
        Builder(
          builder: (context) {
            // ✅ Usar TODOS los tickets activos con caché optimizado
            final activeTickets =
                tickets.where((ticket) => !ticket.annulled).toList();
            final statistics = _TicketStatistics(activeTickets);
            final totalBilling = statistics.totalBilling;

            // ✅ Usar el método del modelo para calcular ganancias
            final cashRegister =
                widget.cashRegisterProvider.currentActiveCashRegister!;
            final totalProfit =
                cashRegister.calculateTotalProfit(activeTickets);

            return DialogComponents.itemList(
                context: context,
                useFillStyle: true,
                padding: EdgeInsets.all(widget.isMobile ? 12 : 14),
                showDividers: true,
                title: 'Transacciones',
                borderColor: theme.dividerColor.withValues(alpha: 0.3),
                trailing: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Total de facturación
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
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
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
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
                ),
                maxVisibleItems: 5,
                expandText: '',
                collapseText: '',
                items: [
                  // view : listado de tickets recientes
                  ...recentTickets.map((ticket) {
                    return _buildTicketTile(context, ticket, widget.isMobile,
                        onTicketUpdated: widget.onTicketUpdated);
                  }),
                ]);
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          SizedBox(height: widget.isMobile ? 8 : 12),
        ],
      ],
    );
  }

  void _showAllTicketsDialog(BuildContext context, List<TicketModel> tickets) {
    final theme = Theme.of(context);
    final sellProvider = context.read<SalesProvider>();
    final cashRegisterProvider = context.read<CashRegisterProvider>();

    showDialog(
      context: context,
      builder: (_) => MultiProvider(
        providers: [
          ChangeNotifierProvider<SalesProvider>.value(value: sellProvider),
          ChangeNotifierProvider<CashRegisterProvider>.value(
              value: cashRegisterProvider),
        ],
        child: BaseDialog(
          title: 'Todos los Tickets de Hoy',
          icon: Icons.receipt_long_rounded,
          headerColor:
              theme.colorScheme.primaryContainer.withValues(alpha: 0.85),
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
    final sellProvider = context.read<SalesProvider>();
    final cashRegisterProvider = context.read<CashRegisterProvider>();

    // Información adicional
    final hasDiscount = ticket.discount > 0;
    final hasProfit = ticket.getProfit > 0;
    final paymentMethodIcon = _getPaymentMethodIcon(ticket.payMode);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => showTicketDetailDialog(
          context: context,
          ticket: ticket,
          businessName: sellProvider.profileAccountSelected.name.isNotEmpty
              ? sellProvider.profileAccountSelected.name
              : 'PUNTO DE VENTA',
          onTicketAnnulled: () async {
            // Verificar si este ticket es el último ticket vendido
            final isLastSoldTicket =
                sellProvider.lastSoldTicket?.id == ticket.id;

            if (isLastSoldTicket) {
              // Si es el último ticket vendido, usar el método unificado
              await sellProvider.annullLastSoldTicket(
                  context: context, ticket: ticket);
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
                  ticket.annulled
                      ? Icons.receipt_long_rounded
                      : Icons.receipt_rounded,
                  size: isMobile ? 14 : 18,
                  color:
                      ticket.annulled ? Colors.red : theme.colorScheme.primary,
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
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
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
                              color: theme.colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.6),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${ticket.getProductsQuantity()} ${ticket.getProductsQuantity() == 1 ? 'item' : 'items'}',
                              style: (isMobile
                                      ? theme.textTheme.labelSmall
                                      : theme.textTheme.labelMedium)
                                  ?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant
                                    .withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),

                        // Separador
                        Container(
                          width: 3,
                          height: 3,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.3),
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
                              color: theme.colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.3),
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
                        color: theme.colorScheme.onSurfaceVariant
                            .withValues(alpha: 0.6),
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
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
                    style: (theme.textTheme.titleLarge)?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: ticket.annulled
                          ? theme.colorScheme.onSurfaceVariant
                          : theme.colorScheme.primary,
                      decoration:
                          ticket.annulled ? TextDecoration.lineThrough : null,
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
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
                          Text(
                            CurrencyFormatter.formatPrice(
                                value: ticket.getProfit),
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
            ],
          ),
        ),
      ),
    );
  }

  // Helper: Obtener icono del método de pago
  IconData _getPaymentMethodIcon(String payMode) {
    // Normalizar código y obtener el método de pago desde el enum
    final paymentMethod = PaymentMethod.fromCode(payMode);
    return paymentMethod.icon;
  }

  // Helper: Obtener color del método de pago
  Color _getPaymentMethodColor(String payMode) {
    // Normalizar código y obtener el método de pago desde el enum
    final paymentMethod = PaymentMethod.fromCode(payMode);
    return paymentMethod.color;
  }

  // Helper: Obtener label completo del método de pago
  String _getPaymentMethodFullLabel(String payMode) {
    // Normalizar código y obtener el método de pago desde el enum
    final paymentMethod = PaymentMethod.fromCode(payMode);
    return paymentMethod.displayName;
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


/// Skeleton loader para _FinancialSummarySection
/// ✅ UX: Muestra un placeholder animado mientras se cargan las métricas
class _FinancialSummarySkeleton extends StatefulWidget {
  final bool isMobile;

  const _FinancialSummarySkeleton({
    required this.isMobile,
  });

  @override
  State<_FinancialSummarySkeleton> createState() => _FinancialSummarySkeletonState();
}

class _FinancialSummarySkeletonState extends State<_FinancialSummarySkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = widget.isMobile;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.1),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con títulos
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildShimmerBox(
                    width: isMobile ? 100 : 120,
                    height: isMobile ? 16 : 18,
                    opacity: _animation.value,
                  ),
                  _buildShimmerBox(
                    width: isMobile ? 80 : 100,
                    height: isMobile ? 16 : 18,
                    opacity: _animation.value,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Valores principales
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildShimmerBox(
                    width: isMobile ? 90 : 110,
                    height: isMobile ? 24 : 28,
                    opacity: _animation.value,
                  ),
                  _buildShimmerBox(
                    width: isMobile ? 90 : 110,
                    height: isMobile ? 24 : 28,
                    opacity: _animation.value,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildShimmerBox({
    required double width,
    required double height,
    required double opacity,
  }) {
    final theme = Theme.of(context);
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withValues(alpha: opacity * 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }
}

/// Widget expandible para el encabezado de caja registradora
/// Muestra el nombre de la caja y tiempo activo con opción de expandir para ver detalles
// ✅ ELIMINADO: _CashRegisterExpandableHeader - Ahora se usa ExpandablePremiumListTile del core
// Este widget ha sido reemplazado por el componente reutilizable premium_list_tile.dart
