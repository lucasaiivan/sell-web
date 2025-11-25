import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sellweb/core/presentation/widgets/inputs/inputs.dart';
import 'package:sellweb/features/cash_register/presentation/providers/cash_register_provider.dart';
import 'package:sellweb/core/presentation/widgets/buttons/app_button.dart';

/// Diálogo para registrar ingresos o egresos de caja
class CashFlowDialog extends StatefulWidget {
  final bool isInflow;
  final String cashRegisterId;
  final String accountId;
  final String userId;

  const CashFlowDialog({
    super.key,
    required this.isInflow,
    required this.cashRegisterId,
    required this.accountId,
    required this.userId,
  });

  @override
  State<CashFlowDialog> createState() => _CashFlowDialogState();
}

class _CashFlowDialogState extends State<CashFlowDialog> {
  String? _amountError;
  String? _descriptionError;

  @override
  void initState() {
    super.initState();

    // Limpiar errores previos al inicializar el diálogo
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final provider = context.read<CashRegisterProvider>();
        provider.clearError();

        // Limpiar los campos de texto para empezar con valores vacíos
        provider.movementAmountController.clear();
        provider.movementDescriptionController.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cashRegisterProvider = context.watch<CashRegisterProvider>();

    final title =
        widget.isInflow ? 'Ingreso de Efectivo' : 'Egreso de Efectivo';
    final buttonText =
        widget.isInflow ? 'Registrar Ingreso' : 'Registrar Egreso';
    final Widget iconTitle = widget.isInflow
        ? const Icon(Icons.arrow_downward, color: Colors.green)
        : const Icon(Icons.arrow_outward_rounded, color: Colors.red);

    return AlertDialog(
      title: Row(
        children: [
          iconTitle,
          const SizedBox(width: 8),
          Text(title),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // input : Monto
            MoneyInputTextField(
              controller: cashRegisterProvider.movementAmountController,
              labelText: 'Monto',
              errorText: _amountError,
              onTextChanged: (value) {
                if (_amountError != null) {
                  setState(() {
                    _amountError = null;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            // input : Descripción de ingreso/egreso en la caja
            InputTextField(
              controller: cashRegisterProvider.movementDescriptionController,
              labelText: 'Descripción',
              hintText: 'Motivo del ${widget.isInflow ? "ingreso" : "egreso"}',
              errorText: _descriptionError,
              onChanged: (value) {
                if (_descriptionError != null) {
                  setState(() {
                    _descriptionError = null;
                  });
                }
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        AppButton.primary(
          onPressed: cashRegisterProvider.isProcessing
              ? null
              : () => _handleCashFlow(context, cashRegisterProvider),
          isLoading: cashRegisterProvider.isProcessing,
          text: buttonText,
        ),
      ],
    );
  }

  bool _validateForm(CashRegisterProvider provider) {
    bool isValid = true;

    // Validar monto
    final amount = provider.movementAmountController.doubleValue;
    if (amount <= 0) {
      setState(() {
        _amountError = 'El monto debe ser mayor a cero';
      });
      isValid = false;
    }

    // Validar descripción
    if (provider.movementDescriptionController.text.trim().isEmpty) {
      setState(() {
        _descriptionError = 'La descripción es obligatoria';
      });
      isValid = false;
    }

    return isValid;
  }

  Future<void> _handleCashFlow(
    BuildContext context,
    CashRegisterProvider provider,
  ) async {
    // Validar formulario antes de proceder
    if (!_validateForm(provider)) {
      return;
    }

    final success = widget.isInflow
        ? await provider.addCashInflow(
            widget.accountId, widget.cashRegisterId, widget.userId)
        : await provider.addCashOutflow(
            widget.accountId, widget.cashRegisterId, widget.userId);

    if (success && context.mounted) {
      Navigator.of(context).pop();
    } else {
      // Si hay error del provider, mostrarlo en descripción como fallback
      if (provider.errorMessage != null) {
        setState(() {
          _descriptionError = provider.errorMessage;
        });
      }
    }
  }
}
