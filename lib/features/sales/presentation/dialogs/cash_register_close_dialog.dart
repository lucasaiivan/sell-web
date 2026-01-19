import '../../../../../../../core/core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sellweb/core/presentation/widgets/success/process_success_view.dart';
import 'package:sellweb/features/cash_register/domain/entities/cash_register.dart';
import 'package:sellweb/features/cash_register/domain/entities/cash_register_metrics.dart';
import 'package:sellweb/features/cash_register/presentation/providers/cash_register_provider.dart';
import 'package:sellweb/features/sales/presentation/providers/sales_provider.dart';

/// Diálogo para cerrar una caja registradora
class CashRegisterCloseDialog extends StatefulWidget {
  final CashRegister cashRegister;
  final bool fullView;

  const CashRegisterCloseDialog({
    super.key,
    required this.cashRegister,
    this.fullView = false,
  });

  @override
  State<CashRegisterCloseDialog> createState() =>
      _CashRegisterCloseDialogState();
}

class _CashRegisterCloseDialogState extends State<CashRegisterCloseDialog> {

  String? _arqueoError; // Error para el campo de arqueo de fondos
  late CashRegisterProvider _provider;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _provider = context.read<CashRegisterProvider>();
  }

  @override
  void initState() {
    super.initState();
    // Limpiar errores previos al inicializar el diálogo
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _provider.clearError();

        // Limpiar el campo de balance final para empezar con valor vacío
        _provider.finalBalanceController.clear();

        // Escuchar cambios en el balance final para calcular la diferencia en tiempo real
        _provider.finalBalanceController.addListener(_updateDifference);
        
        // Agregar listener para limpiar error de arqueo al escribir
        _provider.finalBalanceController.addListener(_clearArqueoError);
      }
    });
  }

  @override
  void dispose() {
    // Remover los listeners cuando se destruya el widget
    _provider.finalBalanceController.removeListener(_updateDifference);
    _provider.finalBalanceController.removeListener(_clearArqueoError);
    super.dispose();
  }

  void _clearArqueoError() {
    if (mounted) {
      setState(() {
        _arqueoError = null;
      });
    }
  }

  void _updateDifference() {
    if (mounted) {
      setState(() {
        // Actualizar UI para recalcular diferencia en build
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cashRegisterProvider = context.watch<CashRegisterProvider>();
    final sellProvider = context.read<SalesProvider>();

    // ✅ OPTIMIZACIÓN: Usar métricas cacheadas para renderizado inmediato
    final cachedMetrics = cashRegisterProvider.cachedMetrics;
    
    // Si hay métricas en caché, usarlas inmediatamente
    if (cachedMetrics != null && cachedMetrics.cashRegister.id == widget.cashRegister.id) {
      return _buildDialog(context, cashRegisterProvider, cachedMetrics);
    }

    // Si no hay caché, usar StreamBuilder (primera carga)
    return StreamBuilder<CashRegisterMetrics>(
      stream: cashRegisterProvider.getCashRegisterMetricsStream(
        accountId: sellProvider.profileAccountSelected.id,
      ),
      builder: (context, snapshot) {
        // Usar métricas del stream o fallback a valores del cashRegister
        final metrics = snapshot.data;
        return _buildDialog(context, cashRegisterProvider, metrics);
      },
    );
  }

  Widget _buildDialog(
    BuildContext context,
    CashRegisterProvider cashRegisterProvider,
    CashRegisterMetrics? metrics,
  ) {
    // ✅ Calcular balance esperado con la fuente de verdad más reciente (Métricas > CashRegister inicial)
    // Esto corrige el problema de "valores no coherentes" al asegurar que usamos datos frescos
    final expectedBalance = metrics?.expectedBalance ?? widget.cashRegister.getExpectedBalance;
        
        return BaseDialog(
          title: 'Cierre de Caja',
          icon: Icons.lock_rounded,
          width: 500,
          fullView: widget.fullView,
          headerColor:
              Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.3),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DialogComponents.sectionSpacing,
              // view : resumen de caja
              DialogComponents.buildIconTitleLabel(icon: Icons.point_of_sale_outlined, label: 'Resumen de Caja'),
              _expandableListTile(context, metrics),
              const SizedBox(height: 16),
              // view : input de arqueo de fondos
              DialogComponents.buildIconTitleLabel(icon: Icons.monetization_on_outlined, label: 'Arqueo de Fondos'),
              // indicator : diferencia
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: cashRegisterProvider.finalBalanceController.text.trim().isNotEmpty
                    ? _buildDifferenceIndicator(expectedBalance)
                    : const SizedBox.shrink(),
              ),
              // input : arqueo de fondos
              MoneyInputTextField(
                controller: cashRegisterProvider.finalBalanceController,
                helperText: 'Ingresar lo que realmente cobraste en efectivo y otros medios',
                hintText: '0.0',
                errorText: _arqueoError,
              ), 
              const SizedBox(height: 12),
              DialogComponents.buildIconTitleLabel(icon: Icons.edit_outlined, label: 'Notas (Opcional)'),
              InputTextField(
                controller: cashRegisterProvider.noteController,
                hintText: 'Notas sobre el cierre de caja...',
                maxLines: 3,
                minLines: 1,
              ),
              const SizedBox(height: 16),
              // text : Mensaje de error si existe
              if (cashRegisterProvider.errorMessage != null)
                Text(
                  cashRegisterProvider.errorMessage!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              DialogComponents.sectionSpacing,
            ],
          ),
          actions: [
            // button : Cerrar caja
            Consumer<SalesProvider>(
              builder: (context, sellProvider, child) {
                return DialogComponents.primaryActionButton(
                  context: context,
                  text: 'Confirmar Cierre',
                  icon: Icons.lock_rounded,
                  isLoading: cashRegisterProvider.isProcessing,
                  onPressed: () {
                    if (cashRegisterProvider.isProcessing) return;
                    _handleCloseCashRegister(
                      context,
                      cashRegisterProvider,
                      sellProvider,
                    );
                  },
                );
              },
            ),
          ],
        );
  }

  /// Construye el indicador de diferencia con diseño mejorado
  Widget _buildDifferenceIndicator(double expectedBalance) {
    final theme = Theme.of(context);
    
    final finalBalance = _provider.finalBalanceController.doubleValue;
    final difference = finalBalance - expectedBalance;
    
    // Determinar el estado del arqueo
    final bool isPerfecto = difference == 0;
    final bool isSobrante = difference > 0;
    
    // Configurar colores, íconos y labels según el estado
    final Color color;
    final IconData icon;
    final String label;
    
    if (isPerfecto) {
      color = Colors.blue;
      icon = Icons.check_circle_rounded;
      label = 'Arqueo perfecto';
    } else if (isSobrante) {
      color = Colors.green;
      icon = Icons.arrow_upward_rounded;
      label = 'Sobrante';
    } else {
      color = Colors.red;
      icon = Icons.arrow_downward_rounded;
      label = 'Faltante';
    }

    return Container(
      margin: const EdgeInsets.only(top: 6, bottom:8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12), 
      ),
      child: Row(
        children: [
          // Icono
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          // Texto y monto
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (!isPerfecto)
            Text(
              CurrencyFormatter.formatPrice(value: difference.abs()),
              style: theme.textTheme.titleMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
    );
  }

  Widget _expandableListTile(BuildContext context, CashRegisterMetrics? metrics) {
    final theme = Theme.of(context);
    final isMobile = MediaQuery.of(context).size.width < 600;
    
    // Calcular tiempo transcurrido desde la apertura
    final timeElapsed = DateFormatter.getElapsedTime(
      fechaInicio: widget.cashRegister.opening,
    );

    // ✅ Usar métricas centralizadas cuando estén disponibles
    final expectedBalance = metrics?.expectedBalance ?? widget.cashRegister.getExpectedBalance;
    final totalBilling = metrics?.totalBilling ?? widget.cashRegister.billing;
    final totalDiscount = metrics?.totalDiscount ?? widget.cashRegister.discount;
    final totalInflows = metrics?.totalInflows ?? widget.cashRegister.cashInFlow;
    final totalOutflows = metrics?.totalOutflows ?? widget.cashRegister.cashOutFlow.abs();
    final initialCash = metrics?.initialCash ?? widget.cashRegister.initialCash;
    final salesCount = metrics?.effectiveSalesCount ?? widget.cashRegister.sales;

    return ExpandablePremiumListTile( 
      iconColor: theme.colorScheme.primary,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Balance Esperado',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            CurrencyFormatter.formatPrice(value: expectedBalance),
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
      subtitle: Row(
        children: [
          Icon(
            Icons.schedule_rounded,
            size: 14,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 6),
          Text(
            'Tiempo transcurrido: $timeElapsed',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
      expandedInfo: [
        ExpandableInfoItem(
          icon: Icons.schedule_rounded,
          label: 'Apertura',
          value: DateFormatter.formatPublicationDate(
            dateTime: widget.cashRegister.opening,
          ),
        ),
        ExpandableInfoItem(
          icon: Icons.attach_money_rounded,
          label: 'Monto Inicial',
          value: CurrencyFormatter.formatPrice(
            value: initialCash,
          ),
        ),
        ExpandableInfoItem(
          icon: Icons.receipt_long_rounded,
          label: 'Ventas',
          value: salesCount.toString(),
        ),
        ExpandableInfoItem(
          icon: Icons.trending_up_rounded,
          label: 'Facturación',
          value: CurrencyFormatter.formatPrice(
            value: totalBilling,
          ),
        ),
        ExpandableInfoItem(
          icon: Icons.discount_rounded,
          label: 'Descuentos',
          value: CurrencyFormatter.formatPrice(
            value: totalDiscount,
          ),
        ),
        ExpandableInfoItem(
          icon: Icons.arrow_downward_rounded,
          label: 'Ingresos',
          value: CurrencyFormatter.formatPrice(
            value: totalInflows,
          ),
        ),
        ExpandableInfoItem(
          icon: Icons.arrow_upward_rounded,
          label: 'Egresos',
          value: CurrencyFormatter.formatPrice(
            value: totalOutflows,
          ),
        ),
      ],
      isMobile: isMobile,
      initiallyExpanded: false,
    );
  }


  Future<void> _handleCloseCashRegister(
    BuildContext context,
    CashRegisterProvider cashRegisterProvider,
    SalesProvider sellProvider,
  ) async {
    // ⚠️ VALIDACIÓN: El arqueo de fondos es obligatorio
    final arqueoText = cashRegisterProvider.finalBalanceController.text.trim();
    if (arqueoText.isEmpty) {
      setState(() {
        _arqueoError = 'Debe ingresar el arqueo de fondos';
      });
      return;
    }

    // ⚠️ VALIDACIÓN: El monto debe ser diferente de 0
    final arqueoValue = cashRegisterProvider.finalBalanceController.doubleValue;
    if (arqueoValue == 0) {
      setState(() {
        _arqueoError = 'El monto debe ser diferente de 0';
      });
      return;
    }

    // Mostrar ProcessSuccessView mientras se ejecuta el cierre
    if (!context.mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ProcessSuccessView(
          loadingText: 'Cerrando caja...',
          successTitle: '¡Caja cerrada!',
          successSubtitle: widget.cashRegister.description,
          finalText: 'Balance: ${CurrencyFormatter.formatPrice(value: _provider.finalBalanceController.doubleValue)}',
          popCount: 2, // Cerrar ProcessSuccessView + CashRegisterCloseDialog
          action: () async {
            final success = await cashRegisterProvider.closeCashRegister(
              sellProvider.profileAccountSelected.id,
              widget.cashRegister.id,
            );
            
            if (!success) {
              throw Exception(cashRegisterProvider.errorMessage ?? 'Error al cerrar la caja');
            }
          },
          onError: (error) {
            // Mostrar error con SnackBar
            if (context.mounted) {
              Navigator.of(context).pop(); // Cerrar ProcessSuccessView
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(error.toString().replaceAll('Exception: ', '')),
                  backgroundColor: Theme.of(context).colorScheme.error,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
        ),
      ),
    );
  }
}
