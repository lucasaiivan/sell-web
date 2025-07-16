import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sellweb/core/widgets/dialogs/base/base_dialog.dart';
import 'package:sellweb/core/widgets/dialogs/components/dialog_components.dart';
import 'package:sellweb/core/widgets/responsive/responsive_helper.dart';
import '../../../../domain/entities/cash_register_model.dart';
import '../../../../presentation/providers/auth_provider.dart';
import '../../../../presentation/providers/cash_register_provider.dart';
import '../../../../presentation/providers/sell_provider.dart';
import '../../buttons/buttons.dart';
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
        final isMobile = ResponsiveHelper.isMobile(context);
        // dialog : base dialog
        return BaseDialog(
          title:sTitle,
          icon: Icons.point_of_sale_rounded,
          width: ResponsiveHelper.responsive(
            context: context,
            mobile: null,
            tablet: 600,
            desktop: 700,
          ),
          maxHeight: ResponsiveHelper.responsive(
            context: context,
            mobile: constraints.maxHeight * 0.9,
            tablet: 700,
            desktop: 800,
          ),
          content: Builder(
            builder: (context) { 

              // Si está cargando, mostrar indicador de progreso
              if (cashRegisterProvider.isLoadingActive) {
                return SizedBox(
                  height: ResponsiveHelper.responsive(
                    context: context,
                    mobile: 100,
                    desktop: 120,
                  ),
                  width: double.infinity,
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              // view : Construir contenido responsivo
              return _buildResponsiveContent(context, cashRegisterProvider, isMobile);
            },
          ),
        );
      },
    );
  }

  Widget _buildResponsiveContent(BuildContext context,CashRegisterProvider provider, bool isMobile) {
    return Padding(
      padding: const EdgeInsets.all( 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: ResponsiveHelper.getSpacing(context, scale: 0.5)),
           
          if (provider.hasActiveCashRegister)
            // view : Mostrar información de caja activa
            _buildActiveCashRegister(context, provider, isMobile)
          else
            // view : Mostrar mensaje de no caja activa
            _buildNoCashRegister(context, isMobile), 

          // Botones de acción de caja (Deseleccionar/Cerrar) - Solo si hay caja activa
          if (provider.hasActiveCashRegister) ...[
            SizedBox(height: ResponsiveHelper.getSpacing(context, scale: 1.5)),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: _buildCashRegisterActionButtons(context, provider, isMobile),
            ),
          ],
          
          // Mensaje de error con animación
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: provider.errorMessage != null
                ? Padding(
                    padding: EdgeInsets.only(
                      top: ResponsiveHelper.getSpacing(context, scale: 1.5),
                    ),
                    child: _buildErrorMessage(context, provider.errorMessage!),
                  )
                : const SizedBox.shrink(),
          ),
           
        ],
      ),
    );
  }

  Widget _buildErrorMessage(BuildContext context, String message) {
    final theme = Theme.of(context);
    
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 400),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.95 + (0.05 * value),
          child: Opacity(
            opacity: value,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.error.withValues(alpha: 0.2),
                ),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.error.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    color: theme.colorScheme.onErrorContainer,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      message,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActiveCashRegister( BuildContext context, CashRegisterProvider provider, bool isMobile) {
    
    final cashRegister = provider.currentActiveCashRegister!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [ 
        // view : Información de caja activa
        DialogComponents.infoSection(
          context: context,
          title: cashRegister.description,
          icon: Icons.point_of_sale_rounded,
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [ 
              SizedBox(height: isMobile ? 8 : 12),
              // view : Detalles de la caja
              DialogComponents.summaryContainer(
                context: context,
                label: 'Balance Actual',
                value: '\$${cashRegister.getExpectedBalance.toStringAsFixed(2)}',
                icon: Icons.monetization_on_rounded,
              ),
              SizedBox(height: isMobile ? 16 : 24),
              // view : Información de flujo de caja
              _cashFlowInformation(context, cashRegister),
              SizedBox(height: isMobile ? 16 : 24),
              // buttons : Acciones de caja
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: _buildCashFlowButtons(context, provider, isMobile),
                ),
            ],
          ),
        ), 
        
      ],
    );
  }

  Widget _buildCashRegisterActionButtons(
    BuildContext context, 
    CashRegisterProvider provider, 
    bool isMobile
  ) { 
    final cashRegister = provider.currentActiveCashRegister!;
    final theme = Theme.of(context);
    
    return Row(
      children: [
        Expanded(
          child: AppOutlinedButton(
            icon: const Icon(Icons.clear_rounded),
            text: 'Deseleccionar',
            onPressed: () => provider.clearSelectedCashRegister(),
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            margin: EdgeInsets.zero,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: AppFilledButton(
            icon: const Icon(Icons.lock_outlined),
            text: 'Cerrar Caja',
            onPressed: () => _showCloseDialog(context, cashRegister),
            backgroundColor: theme.colorScheme.error,
            foregroundColor: theme.colorScheme.onError,
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            margin: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }

  Widget _cashFlowInformation(BuildContext context, CashRegister cashRegister) {
    final theme = Theme.of(context);
    
    final items = [
      {
        'label': 'Ventas',
        'value': cashRegister.sales.toString(),
        'icon': Icons.shopping_cart_rounded,
      },
      {
        'label': 'Facturación',
        'value': '\$${cashRegister.billing.toStringAsFixed(2)}',
        'icon': Icons.attach_money_rounded,
      },
      {
        'label': 'Descuentos',
        'value': '\$${cashRegister.discount.toStringAsFixed(2)}',
        'icon': Icons.local_offer_rounded,
      },
    ];

    return Column(
      children: items.map((item) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                item['icon'] as IconData,
                size: 20,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                item['label'] as String,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            Text(
              item['value'] as String,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildNoCashRegister(BuildContext context, bool isMobile) {

    final theme = Theme.of(context);
    final provider = context.watch<CashRegisterProvider>();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Verificar si hay cajas disponibles
        if (provider.hasAvailableCashRegisters) ...[
          // view : Mostrar lista de cajas disponibles
          Padding(
            padding: EdgeInsets.only(bottom: isMobile ? 12 : 16),
            child: Text(
              'Cajas activas',
              style: (isMobile 
                ? theme.textTheme.titleSmall 
                : theme.textTheme.titleMedium)?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          // Mostrar lista de cajas disponibles
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: isMobile ? 200 : 300,
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const BouncingScrollPhysics(),
              itemCount: provider.activeCashRegisters.length,
              separatorBuilder: (context, index) => SizedBox(height: isMobile ? 6 : 8),
              itemBuilder: (context, index) {
                final cashRegister = provider.activeCashRegisters[index];
                return _buildCashRegisterTile(context, cashRegister, provider, isMobile);
              },
            ),
          ),
          SizedBox(height: isMobile ? 16 : 24), 
        ] else ...[
          // Mostrar mensaje de no cajas disponibles
          Container(
            padding: EdgeInsets.symmetric(
              vertical: isMobile ? 32 : 48,
              horizontal: isMobile ? 16 : 24,
            ),
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.all(isMobile ? 12 : 16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainer,
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
                    : theme.textTheme.bodyLarge)?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: isMobile ? 4 : 8),
                Text(
                  'Crea una nueva caja para comenzar',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ], 
        AppButton(
          icon: const Icon(Icons.add_rounded),
          text: 'Apertura de nueva caja',
          onPressed: () => _showOpenDialog(context),
          isLoading: provider.isLoadingActive, 
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 16 : 20,
            vertical: isMobile ? 12 : 16,
          ),
        ),  
      ],
    );
  }

  Widget _buildCashRegisterTile(
    BuildContext context, 
    CashRegister cashRegister, 
    CashRegisterProvider provider,
    bool isMobile
  ) {
    final theme = Theme.of(context);

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 300),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Card(
              elevation: 0,
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(isMobile ? 8 : 12),
                side: BorderSide(
                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(isMobile ? 8 : 12),
                  onTap: () => provider.selectCashRegister(cashRegister),
                  hoverColor: theme.colorScheme.primary.withValues(alpha: 0.05),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: EdgeInsets.all(isMobile ? 12 : 16),
                    child: Row(
                      children: [ 
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: EdgeInsets.all(isMobile ? 6 : 8),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(alpha: 0.1),
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
                              : theme.textTheme.bodyMedium)?.copyWith(
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
          ),
        );
      },
    );
  }

  Widget _buildCashFlowButtons(
      BuildContext context, CashRegisterProvider provider, bool isMobile) { 
    
    return Row(
      children: [
        Expanded(
          child: AppOutlinedButton(
            icon: const Icon(Icons.add_circle_outline_rounded),
            text: 'Ingreso',
            onPressed: provider.hasActiveCashRegister
                ? () => _showCashFlowDialog(context, true)
                : null,
            backgroundColor: provider.hasActiveCashRegister
                ? Colors.green.withValues(alpha: 0.1)
                : null,
            foregroundColor: provider.hasActiveCashRegister 
                ? Colors.green 
                : null,
            borderColor: provider.hasActiveCashRegister 
                ? Colors.green.withValues(alpha: 0.3)
                : null,
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            margin: EdgeInsets.zero,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: AppOutlinedButton(
            icon: const Icon(Icons.remove_circle_outline_rounded),
            text: 'Egreso',
            onPressed: provider.hasActiveCashRegister
                ? () => _showCashFlowDialog(context, false)
                : null,
            backgroundColor: provider.hasActiveCashRegister
                ? Colors.red.withValues(alpha: 0.1)
                : null,
            foregroundColor: provider.hasActiveCashRegister 
                ? Colors.red 
                : null,
            borderColor: provider.hasActiveCashRegister 
                ? Colors.red.withValues(alpha: 0.3)
                : null,
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            margin: EdgeInsets.zero,
          ),
        ),
      ],
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
          ChangeNotifierProvider<CashRegisterProvider>.value(value: cashRegisterProvider),
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
