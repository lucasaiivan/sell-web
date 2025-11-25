import '../../../../../core/core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../domain/entities/cash_register_model.dart';
import '../../../../../domain/entities/ticket_model.dart';
import 'package:sellweb/features/auth/presentation/providers/auth_provider.dart';
import '../../../../providers/cash_register_provider.dart';
import '../../../../providers/sell_provider.dart';
import '../../../graphics/graphics.dart';
import 'cash_flow_dialog.dart';
import 'cash_register_close_dialog.dart';
import 'cash_register_open_dialog.dart';

// ✅ CONSTANTES DE DISEÑO Y ANIMACIÓN
class _CashRegisterDialogConstants {
  // Duraciones de animación
  static const animationDuration = Duration(milliseconds: 300);
  static const fastAnimationDuration = Duration(milliseconds: 200);
  static const slideTransitionDuration = Duration(milliseconds: 300);

  // Border radius
  static const double borderRadiusMedium = 6.0;
  static const double borderRadiusLarge = 8.0;
  static const double borderRadiusXLarge = 12.0;

  // Opacidades
  static const double opacityLight = 0.05;
  static const double opacityMedium = 0.1;
  static const double opacityHeavy = 0.15;

  // Tamaños de iconos
  static const double iconSizeSmall = 14.0;
  static const double iconSizeXLarge = 24.0;

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

  /// Calcula y agrupa los métodos de pago
  Map<String, double> _calculatePaymentMethods() {
    final ranking = TicketModel.getPaymentMethodsRanking(
      tickets: _tickets,
      includeAnnulled: false,
    );

    final Map<String, double> grouped = {};
    for (final payment in ranking) {
      final description =
          (payment['description'] as String).trim().toLowerCase();
      final percentage = payment['percentage'] as double;

      String key;
      if (description == 'efectivo') {
        key = 'Efectivo';
      } else if (description == 'mercado pago' ||
          description == 'mercadopago') {
        key = 'Mercado Pago';
      } else if (description == 'tarjeta de crédito/débito' ||
          description == 'tarjeta' ||
          description == 'tarjeta de credito/debito') {
        key = 'Tarjeta';
      } else {
        key = 'Otros';
      }

      grouped[key] = (grouped[key] ?? 0) + percentage;
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
/// ## Uso:
/// ```dart
/// // Método 1: Mostrar como diálogo (recomendado para desktop sin caja activa)
/// CashRegisterManagementDialog.showAsDialog(context);
///
/// // Método 2: Mostrar en pantalla completa (recomendado cuando hay caja activa)
/// CashRegisterManagementDialog.showAsFullScreen(context);
///
/// // Método 3: Automático según estado de caja (RECOMENDADO)
/// // - Con caja activa: Pantalla completa para ver flujo de caja completo
/// // - Sin caja activa: Diálogo modal para seleccionar/crear caja
/// CashRegisterManagementDialog.showAdaptive(context);
/// ```
class CashRegisterManagementDialog extends StatefulWidget {
  /// Si es true, el diálogo ocupa toda la pantalla (usando Scaffold)
  final bool fullView;

  const CashRegisterManagementDialog({
    super.key,
    this.fullView = false,
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
    final cashRegisterProvider =
        Provider.of<CashRegisterProvider>(context, listen: false);
    final sellProvider = Provider.of<SellProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (_) => MultiProvider(
        providers: [
          ChangeNotifierProvider<CashRegisterProvider>.value(
              value: cashRegisterProvider),
          ChangeNotifierProvider<SellProvider>.value(value: sellProvider),
          ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        ],
        child: const CashRegisterManagementDialog(fullView: false),
      ),
    );
  }

  /// Muestra el diálogo de administración de caja en pantalla completa.
  /// Usa [Navigator.push] con transición deslizante y los providers necesarios ya configurados.
  ///
  /// [context]: BuildContext desde donde se navega
  /// [transitionDuration]: Duración de la animación de transición (default: 300ms)
  static Future<T?> showAsFullScreen<T>(
    BuildContext context, {
    Duration transitionDuration =
        _CashRegisterDialogConstants.slideTransitionDuration,
  }) {
    final cashRegisterProvider =
        Provider.of<CashRegisterProvider>(context, listen: false);
    final sellProvider = Provider.of<SellProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    return Navigator.of(context).push<T>(
      PageRouteBuilder<T>(
        pageBuilder: (context, animation, secondaryAnimation) => MultiProvider(
          providers: [
            ChangeNotifierProvider<CashRegisterProvider>.value(
                value: cashRegisterProvider),
            ChangeNotifierProvider<SellProvider>.value(value: sellProvider),
            ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
          ],
          child: const CashRegisterManagementDialog(fullView: true),
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.ease;

          var tween = Tween(begin: begin, end: end).chain(
            CurveTween(curve: curve),
          );

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
        transitionDuration: transitionDuration,
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
      return showAsFullScreen<T>(context);
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
    final cashRegisterProvider = context.read<CashRegisterProvider>();
    final sellProvider = context.read<SellProvider>();
    final accountId = sellProvider.profileAccountSelected.id;

    if (accountId.isNotEmpty) {
      cashRegisterProvider.loadCashRegisterTickets(accountId: accountId);
    }
  }

  /// Recarga los tickets manualmente (llamado después de acciones como anular ticket)
  void _reloadTickets() {
    final cashRegisterProvider = context.read<CashRegisterProvider>();
    final sellProvider = context.read<SellProvider>();
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
        // var
        final sTitle =
            hasActiveCashRegister ? 'Flujo de Caja' : 'Administración de Caja';

        // Si fullView es true, usar Scaffold para ocupar toda la pantalla
        if (widget.fullView) {
          // ✅ Usar context.read para acceder sin suscribirse a todos los cambios
          return _buildFullScreenView(context, sTitle);
        }

        // Vista normal en diálogo
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

  // view : Vista de pantalla completa usando Scaffold
  Widget _buildFullScreenView(BuildContext context, String title) {
    // ✅ Usar context.read para acceder al provider sin suscribirse
    final provider = context.read<CashRegisterProvider>();
    final isMobileDevice = isMobile(context);
    final screenWidth = MediaQuery.of(context).size.width;

    // ✅ Calcular padding horizontal adaptativo según el tamaño de pantalla
    // Pantallas grandes (>1200px): contenido centrado con max-width
    // Pantallas medianas (800-1200px): padding moderado
    // Pantallas pequeñas (<800px): padding mínimo para aprovechar espacio
    final horizontalPadding = getResponsiveValue(
      context,
      mobile: 16.0, // Móvil: padding mínimo
      tablet: 40.0, // Tablet: padding moderado
      desktop: screenWidth > 1400
          ? (screenWidth - 1200) / 2
          : 80.0, // Desktop: centrado con max-width
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        automaticallyImplyLeading: false,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          SingleChildScrollView(
            // ✅ Padding adaptativo: horizontal responsive + vertical fijo
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: 16,
            ),
            child: provider.isLoadingActive
                ? SizedBox(
                    height: MediaQuery.of(context).size.height * 0.5,
                    child: const Center(child: CircularProgressIndicator()),
                  )
                : _buildResponsiveContent(context, provider, isMobileDevice),
          ),
          // bottomNavigationBar : _buildCashRegisterActionButtons
          Positioned(
            bottom: 20,
            left: 0,
            right: 20,
            child: provider.hasActiveCashRegister
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: _buildCashRegisterActionButtons(
                        context, isMobileDevice),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
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
    // Obtener accountId desde SellProvider
    final sellProvider = context.read<SellProvider>();
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
          if (accountId.isNotEmpty &&
              provider.currentActiveCashRegister != null)
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

  List<Widget> _buildCashRegisterActionButtons(
      BuildContext context, bool isMobile) {
    // ✅ Usar context.read para acceder al provider sin suscribirse
    final provider = context.read<CashRegisterProvider>();
    final cashRegister = provider.currentActiveCashRegister!;

    return [
      // button : cierre de caja
      AppButton.fab(
        text: 'Cerrar Caja',
        icon: Icons.exit_to_app,
        onPressed: () => _showCloseDialog(context, cashRegister),
      ),
      SizedBox(width: isMobile ? 8 : 16),
      // button : cancelar el dialog
      AppButton.fab(
        text: 'ok',
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
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Verificar si hay cajas disponibles
            if (data.hasAvailable) ...[
              // Mostrar lista de cajas disponibles usando DialogComponents.itemList
              DialogComponents.itemList(
                context: context,
                title: 'Cajas activas',
                maxVisibleItems:
                    _CashRegisterDialogConstants.maxVisibleCashRegisters,
                expandText:
                    'Ver más cajas (${data.cashRegisters.length > _CashRegisterDialogConstants.maxVisibleCashRegisters ? data.cashRegisters.length - _CashRegisterDialogConstants.maxVisibleCashRegisters : 0})',
                collapseText: 'Ver menos',
                backgroundColor: theme.colorScheme.primary.withValues(
                    alpha: _CashRegisterDialogConstants.opacityLight - 0.01),
                borderColor: theme.colorScheme.primary.withValues(alpha: 0.01),
                items: data.cashRegisters.map((cashRegister) {
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
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: DialogComponents.primaryActionButton(
                        context: context,
                        text: 'Nueva caja',
                        onPressed: authProvider.isGuest
                            ? null
                            : () => _showOpenDialog(context),
                        isLoading: data.isLoading,
                      ),
                    ),
                    SizedBox(height: isMobile ? 4 : 8),
                    infoCashRegister,
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

    return TweenAnimationBuilder<double>(
      duration: _CashRegisterDialogConstants.animationDuration,
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
                borderRadius: BorderRadius.circular(
                    _CashRegisterDialogConstants.borderRadiusLarge),
                hoverColor: theme.colorScheme.primary.withValues(
                    alpha: _CashRegisterDialogConstants.opacityLight),
                child: AnimatedContainer(
                  duration: _CashRegisterDialogConstants.fastAnimationDuration,
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 8 : 12,
                    vertical: isMobile ? 8 : 12,
                  ),
                  child: Row(
                    children: [
                      AnimatedContainer(
                        duration:
                            _CashRegisterDialogConstants.fastAnimationDuration,
                        padding: EdgeInsets.all(isMobile ? 6 : 8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(
                              alpha:
                                  _CashRegisterDialogConstants.opacityMedium),
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
  Widget _buildCashFlowView(
      BuildContext context, CashRegisterProvider provider, bool isMobile) {
    final cashRegister = provider.currentActiveCashRegister!;

    // ✅ Usar widget separado que no depende de FutureBuilder
    return _CashFlowView(
      cashRegister: cashRegister,
      isMobile: isMobile,
    );
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
        todayOnly: true,
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
          return const SizedBox.shrink();
        }

        final tickets = snapshot.data!;
        final activeTickets =
            tickets.where((ticket) => !ticket.annulled).toList();

        if (activeTickets.isEmpty) {
          return const SizedBox.shrink();
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

  /// Helper: Obtener datos de color, icono y etiqueta para un método de pago
  Map<String, dynamic> _getPaymentMethodData({
    required String description,
    required double percentage,
    required ThemeData theme,
  }) {
    Color paymentColor;
    IconData paymentIcon;
    String fullLabel;

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
    final sellProvider = context.read<SellProvider>();
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
                // ✅ Información de flujo de caja con StreamBuilder solo para tickets
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

/// Widget separado para información de flujo de caja
/// ✅ OPTIMIZADO: Actualiza solo los datos sin reconstruir toda la vista
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

          // ✅ Balance total - Sección separada
          _BalanceSection(
            cashRegister: cashRegister,
            isMobile: isMobile,
          ),
          SizedBox(height: getResponsiveSpacing(context, scale: 1.5)),

          // ✅ Información financiera con StreamBuilder SOLO para tickets
          if (accountId.isNotEmpty && cashRegister.id.isNotEmpty)
            StreamBuilder<List<TicketModel>>(
              stream: cashRegisterProvider.getCashRegisterTicketsStream(
                accountId: accountId,
                cashRegisterId: cashRegister.id,
                todayOnly: true,
              ),
              builder: (context, snapshot) {
                final tickets = snapshot.data;
                return _FinancialInfoSection(
                  cashRegister: cashRegister,
                  isMobile: isMobile,
                  tickets: tickets,
                );
              },
            )
          else
            _FinancialInfoSection(
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

        final timeInfo = [
          {
            'icon': Icons.schedule_rounded,
            'label': 'Apertura',
            'value': DateFormatter.formatPublicationDate(
                dateTime: currentCashRegister.opening),
          },
          {
            'icon': Icons.timelapse_rounded,
            'label': 'Tiempo activo',
            'value': DateFormatter.getElapsedTime(
                fechaInicio: currentCashRegister.opening),
          },
          {
            'icon': Icons.person_rounded,
            'label': 'Cajero',
            'value': currentCashRegister.nameUser.isNotEmpty
                ? currentCashRegister.idUser
                : 'Desconocido',
          },
        ];

        return _CashRegisterExpandableHeader(
          cashRegister: currentCashRegister,
          theme: theme,
          isMobile: isMobile,
          timeInfo: timeInfo,
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

/// Widget separado para mostrar el balance total
/// ✅ OPTIMIZADO: Solo se reconstruye cuando cambia el balance
class _BalanceSection extends StatelessWidget {
  final CashRegister cashRegister;
  final bool isMobile;

  const _BalanceSection({
    required this.cashRegister,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Selector<CashRegisterProvider, double>(
      selector: (_, provider) {
        final cr = provider.currentActiveCashRegister ?? cashRegister;
        return cr.getExpectedBalance;
      },
      builder: (context, balance, child) {
        return Container(
          padding: EdgeInsets.all(isMobile ? 14 : 16),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Balance Total',
                style: (isMobile
                        ? theme.textTheme.titleSmall
                        : theme.textTheme.titleMedium)
                    ?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: isMobile ? 18 : 24,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const Spacer(),
              SizedBox(height: 4),
              Text(
                CurrencyFormatter.formatPrice(value: balance),
                style: (isMobile
                        ? theme.textTheme.headlineSmall
                        : theme.textTheme.headlineMedium)
                    ?.copyWith(
                  fontSize: isMobile ? 22 : 28,
                  fontWeight: FontWeight.w900,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Widget separado para la información financiera
/// ✅ OPTIMIZADO: Solo se reconstruye cuando cambian los datos financieros o tickets
class _FinancialInfoSection extends StatelessWidget {
  final CashRegister cashRegister;
  final bool isMobile;
  final List<TicketModel>? tickets;

  const _FinancialInfoSection({
    required this.cashRegister,
    required this.isMobile,
    this.tickets,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Selector<
        CashRegisterProvider,
        ({
          double ingresos,
          double egresos,
          double discount,
          double billing,
          double initialCash,
        })>(
      selector: (_, provider) {
        final cr = provider.currentActiveCashRegister ?? cashRegister;
        return (
          ingresos: cr.getTotalIngresos,
          egresos: cr.getTotalEgresos,
          discount: cr.discount,
          billing: cr.billing,
          initialCash: cr.initialCash,
        );
      },
      builder: (context, financialData, child) {
        // ✅ Calcular ganancias totales usando el método del modelo
        final currentCashRegister =
            context.read<CashRegisterProvider>().currentActiveCashRegister ??
                cashRegister;
        final totalProfit = tickets != null && tickets!.isNotEmpty
            ? currentCashRegister.calculateTotalProfit(tickets!)
            : 0.0;

        final financialItems = [
          // Facturación total - RESALTADA
          {
            'label': 'Facturación de ventas',
            'value':
                CurrencyFormatter.formatPrice(value: financialData.billing),
            'rawValue': financialData.billing,
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
          // Monto inicial
          if (financialData.initialCash > 0)
            {
              'label': 'Monto Inicial',
              'value': CurrencyFormatter.formatPrice(
                  value: financialData.initialCash),
              'rawValue': financialData.initialCash,
              'icon': Icons.attach_money_rounded,
              'color': theme.colorScheme.primary,
              'highlight': false,
            },
          // Ingresos en caja
          if (financialData.ingresos > 0)
            {
              'label': 'Ingresos en caja',
              'value':
                  CurrencyFormatter.formatPrice(value: financialData.ingresos),
              'rawValue': financialData.ingresos,
              'icon': Icons.call_received_rounded,
              'color': Colors.green,
              'highlight': false,
            },
          // Egresos en caja
          if (financialData.egresos > 0)
            {
              'label': 'Egresos en caja',
              'value':
                  '-${CurrencyFormatter.formatPrice(value: financialData.egresos)}',
              'rawValue': -financialData.egresos,
              'icon': Icons.arrow_outward_rounded,
              'color': Colors.red,
              'highlight': false,
            },
          // Descuentos
          if (financialData.discount > 0)
            {
              'label': 'Descuentos',
              'value':
                  '-${CurrencyFormatter.formatPrice(value: financialData.discount)}',
              'rawValue': -financialData.discount,
              'icon': Icons.discount_rounded,
              'color': Colors.red,
              'highlight': false,
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
                            color: itemColor.withValues(
                                alpha: isHighlight ? 0.15 : 0.1),
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
                                    : theme.textTheme.bodyLarge)
                                ?.copyWith(
                              color: isHighlight
                                  ? theme.colorScheme.onSurface
                                  : theme.colorScheme.onSurfaceVariant,
                              fontWeight: isHighlight
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                        // text : monto
                        Text(
                          item['value'] as String,
                          style: (isMobile
                                  ? theme.textTheme.titleSmall
                                  : theme.textTheme.titleMedium)
                              ?.copyWith(
                            fontWeight:
                                isHighlight ? FontWeight.w800 : FontWeight.w700,
                            color: itemColor,
                            fontSize: isHighlight ? (isMobile ? 15 : 17) : null,
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
      },
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
          key: ValueKey(
              'movements_${allMovements.length}_${totalIngresos}_$totalEgresos'),
          child: DialogComponents.itemList(
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
                title: 'Transacciones recientes',
                borderColor: theme.dividerColor.withValues(alpha: 0.3),
                trailing: Row(
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
    final sellProvider = context.read<SellProvider>();
    final cashRegisterProvider = context.read<CashRegisterProvider>();

    showDialog(
      context: context,
      builder: (_) => MultiProvider(
        providers: [
          ChangeNotifierProvider<SellProvider>.value(value: sellProvider),
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

/// Widget expandible para el encabezado de caja registradora
/// Muestra el nombre de la caja y tiempo activo con opción de expandir para ver detalles
class _CashRegisterExpandableHeader extends StatefulWidget {
  final CashRegister cashRegister;
  final ThemeData theme;
  final bool isMobile;
  final List<Map<String, dynamic>> timeInfo;

  const _CashRegisterExpandableHeader({
    required this.cashRegister,
    required this.theme,
    required this.isMobile,
    required this.timeInfo,
  });

  @override
  State<_CashRegisterExpandableHeader> createState() =>
      _CashRegisterExpandableHeaderState();
}

class _CashRegisterExpandableHeaderState
    extends State<_CashRegisterExpandableHeader>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _iconRotation;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    // ✅ OPTIMIZADO: Usar constante para duración
    _animationController = AnimationController(
      duration: _CashRegisterDialogConstants.animationDuration,
      vsync: this,
    );

    // ✅ OPTIMIZADO: Usar Tween const cuando sea posible
    _iconRotation = Tween<double>(begin: 0.0, end: 0.5).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    // ✅ IMPORTANTE: Disponer del controller para evitar memory leaks
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Calcular tiempo activo para mostrar en el encabezado
    final activeTime =
        DateFormatter.getElapsedTime(fechaInicio: widget.cashRegister.opening);

    return AnimatedContainer(
      duration: _CashRegisterDialogConstants.animationDuration,
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: widget.theme.colorScheme.surfaceContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(
            _CashRegisterDialogConstants.borderRadiusXLarge),
        border: Border.all(
          color: _isExpanded
              ? widget.theme.colorScheme.primary.withValues(alpha: 0.3)
              : widget.theme.dividerColor.withValues(alpha: 0.5),
          width: _isExpanded ? 1.5 : 0.5,
        ),
      ),
      child: Column(
        children: [
          // Encabezado clickeable
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _toggleExpanded,
              borderRadius: BorderRadius.circular(
                  _CashRegisterDialogConstants.borderRadiusXLarge),
              child: Padding(
                padding: EdgeInsets.all(widget.isMobile ? 12 : 14),
                child: Row(
                  children: [
                    // Icono de caja con animación
                    AnimatedContainer(
                      duration: _CashRegisterDialogConstants.animationDuration,
                      padding: EdgeInsets.all(widget.isMobile ? 8 : 10),
                      decoration: BoxDecoration(
                        color: _isExpanded
                            ? widget.theme.colorScheme.primary.withValues(
                                alpha:
                                    _CashRegisterDialogConstants.opacityHeavy)
                            : widget.theme.colorScheme.primary.withValues(
                                alpha:
                                    _CashRegisterDialogConstants.opacityMedium),
                        borderRadius: BorderRadius.circular(
                            _CashRegisterDialogConstants.borderRadiusLarge),
                      ),
                      child: Icon(
                        Icons.point_of_sale_rounded,
                        size: widget.isMobile
                            ? 20
                            : _CashRegisterDialogConstants.iconSizeXLarge,
                        color: widget.theme.colorScheme.primary,
                      ),
                    ),
                    SizedBox(width: widget.isMobile ? 12 : 14),

                    // Información principal (nombre y tiempo activo)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Nombre de la caja
                          Text(
                            widget.cashRegister.description,
                            style: (widget.isMobile
                                    ? widget.theme.textTheme.titleMedium
                                    : widget.theme.textTheme.titleLarge)
                                ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: widget.theme.colorScheme.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: widget.isMobile ? 4 : 6),

                          // Tiempo activo con icono
                          Row(
                            children: [
                              Icon(
                                Icons.timelapse_rounded,
                                size: widget.isMobile ? 14 : 16,
                                color: widget.theme.colorScheme.onSurfaceVariant
                                    .withValues(alpha: 0.7),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                activeTime,
                                style: (widget.isMobile
                                        ? widget.theme.textTheme.bodySmall
                                        : widget.theme.textTheme.bodyMedium)
                                    ?.copyWith(
                                  color:
                                      widget.theme.colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Badge de estado ACTIVA
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: widget.isMobile ? 8 : 10,
                        vertical: widget.isMobile ? 4 : 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: widget.isMobile ? 6 : 8,
                            height: widget.isMobile ? 6 : 8,
                            decoration: BoxDecoration(
                              color: Colors.green.shade700,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'ACTIVA',
                            style: (widget.isMobile
                                    ? widget.theme.textTheme.labelSmall
                                    : widget.theme.textTheme.labelMedium)
                                ?.copyWith(
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Icono de expansión animado
                    RotationTransition(
                      turns: _iconRotation,
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: widget.isMobile ? 24 : 28,
                        color: widget.theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Contenido expandible con información detallada
          SizeTransition(
            sizeFactor: _expandAnimation,
            axisAlignment: -1.0,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                widget.isMobile ? 12 : 14,
                0,
                widget.isMobile ? 12 : 14,
                widget.isMobile ? 12 : 14,
              ),
              child: Column(
                children: [
                  // Divisor sutil
                  Container(
                    height: 1,
                    margin: EdgeInsets.only(
                      bottom: widget.isMobile ? 12 : 14,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          widget.theme.dividerColor.withValues(alpha: 0.3),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),

                  // Lista de información detallada
                  ...widget.timeInfo.map((info) => _buildInfoRow(
                        icon: info['icon'] as IconData,
                        label: info['label'] as String,
                        value: info['value'] as String,
                      )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: widget.isMobile ? 10 : 12),
      child: Row(
        children: [
          // Icono con fondo
          Container(
            padding: EdgeInsets.all(widget.isMobile ? 6 : 8),
            decoration: BoxDecoration(
              color: widget.theme.colorScheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              icon,
              size: widget.isMobile ? 16 : 18,
              color: widget.theme.colorScheme.primary.withValues(alpha: 0.8),
            ),
          ),
          SizedBox(width: widget.isMobile ? 10 : 12),

          // Label
          Expanded(
            child: Text(
              label,
              style: (widget.isMobile
                      ? widget.theme.textTheme.bodySmall
                      : widget.theme.textTheme.bodyMedium)
                  ?.copyWith(
                color: widget.theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          // Valor
          Text(
            value,
            style: (widget.isMobile
                    ? widget.theme.textTheme.bodySmall
                    : widget.theme.textTheme.bodyMedium)
                ?.copyWith(
              fontWeight: FontWeight.w700,
              color: widget.theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
