import '../../../../../../../core/core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sellweb/core/presentation/widgets/success/process_success_view.dart';
import 'package:sellweb/features/cash_register/domain/entities/cash_register.dart';
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
  double _currentDifference = 0.0;
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
        final finalBalance = _provider.finalBalanceController.doubleValue;
        final expectedBalance = widget.cashRegister.getExpectedBalance;

        // Diferencia = Balance Final (lo que hay) - Balance Esperado (lo que debería haber)
        // Positivo = sobrante (verde), Negativo = faltante (rojo)
        _currentDifference = finalBalance - expectedBalance;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cashRegisterProvider = context.watch<CashRegisterProvider>();

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
          _buildSummaryCard(context),
          const SizedBox(height: 16),
          DialogComponents.buildIconTitleLabel(icon: Icons.monetization_on_outlined, label: 'Arqueo de Fondos'),
          MoneyInputTextField(
            controller: cashRegisterProvider.finalBalanceController,
            helperText: 'Ingresar lo que realmente cobraste en efectivo y otros medios',
            hintText: '0.0',
            errorText: _arqueoError,
          ),
          // Mostrar diferencia en tiempo real con contenedor animado
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: cashRegisterProvider.finalBalanceController.text.trim().isNotEmpty
                ? _buildDifferenceIndicator()
                : const SizedBox.shrink(),
          ),
          const SizedBox(height: 16),
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
  Widget _buildDifferenceIndicator() {
    final theme = Theme.of(context);
    
    // Determinar el estado del arqueo
    final bool isPerfecto = _currentDifference == 0;
    final bool isSobrante = _currentDifference > 0;
    
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
      margin: const EdgeInsets.only(top: 12, bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12), 
      ),
      child: Row(
        children: [
          // Icono
          Container(
            padding: const EdgeInsets.all(6),
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
              CurrencyFormatter.formatPrice(value: _currentDifference.abs()),
              style: theme.textTheme.titleMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Arqueo de Caja',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            // apertura de caja : widget.cashRegister.opening
            _buildSummaryRow(
                'Apertura:',
                DateFormatter.formatPublicationDate(  dateTime: widget.cashRegister.opening)),
            _buildSummaryRow(
                'Monto Inicial de caja:',
                CurrencyFormatter.formatPrice(
                    value: widget.cashRegister.initialCash)),
            _buildSummaryRow('Ventas:', widget.cashRegister.sales.toString()),
            _buildSummaryRow(
                'Facturación:',
                CurrencyFormatter.formatPrice(
                    value: widget.cashRegister.billing)),
            _buildSummaryRow(
                'Descuentos:',
                CurrencyFormatter.formatPrice(
                    value: widget.cashRegister.discount)),
            _buildSummaryRow(
                'Ingresos:',
                CurrencyFormatter.formatPrice(
                    value: widget.cashRegister.cashInFlow)),
            _buildSummaryRow(
                'Egresos:',
                CurrencyFormatter.formatPrice(
                    value: widget.cashRegister.cashOutFlow)),
            const Divider(),
            _buildSummaryRow(
              'Balance Esperado:',
              CurrencyFormatter.formatPrice(
                  value: widget.cashRegister.getExpectedBalance),
              true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, [bool isTotal = false]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
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
