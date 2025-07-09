import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/sell_provider.dart';
import '../providers/cash_register_provider.dart';
import '../../domain/entities/ticket_model.dart';
import '../../domain/entities/cash_register_model.dart';

/// Ejemplo de integración del sistema de caja registradora con ventas
/// 
/// Este archivo muestra cómo:
/// - Validar que hay una caja abierta antes de vender
/// - Registrar automáticamente las ventas en la caja
/// - Manejar el flujo completo de venta con caja
class SellWithCashRegisterExample {
  
  /// Confirma una venta y la registra en la caja registradora
  /// 
  /// Este método integra ambos providers para:
  /// 1. Validar que hay una caja registradora abierta
  /// 2. Procesar la venta
  /// 3. Registrar la venta en la caja
  /// 4. Actualizar los totales de la caja
  static Future<bool> confirmSaleWithCashRegister({
    required BuildContext context,
    required String accountId,
    required String userId,
  }) async {
    final sellProvider = context.read<SellProvider>();
    final cashRegisterProvider = context.read<CashRegisterProvider>();

    try {
      // 1. Validar que hay productos en el ticket
      if (sellProvider.ticket.listPoduct.isEmpty) {
        _showErrorMessage(context, 'No hay productos en el ticket');
        return false;
      }

      // 2. Validar que hay una caja registradora abierta
      if (!cashRegisterProvider.hasActiveCashRegister) {
        _showErrorMessage(context, 'No hay una caja registradora abierta. Debe abrir una caja antes de vender.');
        return false;
      }

      // 3. Calcular totales de la venta
      final saleTotal = sellProvider.ticket.getTotalPriceWithoutDiscount;
      final discountAmount = sellProvider.ticket.discount;
      final itemCount = sellProvider.ticket.listPoduct.length;

      // 4. Validar método de pago para caja registradora
      if (sellProvider.ticket.payMode == 'effective') {
        // Validar que el monto recibido sea suficiente
        if (sellProvider.ticket.valueReceived < sellProvider.ticket.getTotalPrice) {
          _showErrorMessage(context, 'El monto recibido es insuficiente');
          return false;
        }
      }

      // 5. Registrar la venta en la caja registradora
      final saleRegistered = await cashRegisterProvider.registerSale(
        accountId: accountId,
        saleAmount: saleTotal,
        discountAmount: discountAmount,
        itemCount: itemCount,
      );

      if (!saleRegistered) {
        _showErrorMessage(context, 'Error al registrar la venta en la caja: ${cashRegisterProvider.errorMessage}');
        return false;
      }

      // 6. Procesar la venta (guardar en historial, etc.)
      // Aquí iría la lógica para guardar la venta en la base de datos
      await _processSale(sellProvider, accountId);

      // 7. Guardar el último ticket vendido
      await sellProvider.saveLastSoldTicket();

      // 8. Limpiar el ticket actual para la próxima venta
      sellProvider.ticket = TicketModel(listPoduct: [], creation: Timestamp.now());

      // 9. Mostrar mensaje de éxito
      _showSuccessMessage(context, 'Venta registrada exitosamente');

      return true;
    } catch (e) {
      _showErrorMessage(context, 'Error al procesar la venta: $e');
      return false;
    }
  }

  /// Abre una caja registradora con validaciones adicionales
  static Future<bool> openCashRegisterWithValidations({
    required BuildContext context,
    required String accountId,
    required String userId,
    required String description,
    required double initialCash,
  }) async {
    final cashRegisterProvider = context.read<CashRegisterProvider>();

    try {
      // Validaciones adicionales
      if (description.trim().isEmpty) {
        _showErrorMessage(context, 'La descripción de la caja es obligatoria');
        return false;
      }

      if (initialCash < 0) {
        _showErrorMessage(context, 'El monto inicial no puede ser negativo');
        return false;
      }

      // Confirmar apertura con el usuario
      final confirmed = await _showConfirmationDialog(
        context,
        'Confirmar Apertura',
        '¿Está seguro de abrir la caja con un monto inicial de \$${initialCash.toStringAsFixed(2)}?',
      );

      if (!confirmed) return false;

      // Abrir la caja
      cashRegisterProvider.openDescriptionController.text = description;
      cashRegisterProvider.initialCashController.text = initialCash.toString();

      final success = await cashRegisterProvider.openCashRegister(accountId, userId);

      if (success) {
        _showSuccessMessage(context, 'Caja registradora abierta exitosamente');
      }

      return success;
    } catch (e) {
      _showErrorMessage(context, 'Error al abrir la caja: $e');
      return false;
    }
  }

  /// Cierra una caja registradora con cálculos automáticos
  static Future<bool> closeCashRegisterWithCalculations({
    required BuildContext context,
    required String accountId,
    required double actualBalance,
  }) async {
    final cashRegisterProvider = context.read<CashRegisterProvider>();

    try {
      if (!cashRegisterProvider.hasActiveCashRegister) {
        _showErrorMessage(context, 'No hay una caja registradora abierta');
        return false;
      }

      final currentCashRegister = cashRegisterProvider.currentActiveCashRegister!;
      final expectedBalance = currentCashRegister.getExpectedBalance;
      final difference = actualBalance - expectedBalance;

      // Mostrar resumen antes del cierre
      final confirmed = await _showCashRegisterSummaryDialog(
        context,
        currentCashRegister,
        actualBalance,
        difference,
      );

      if (!confirmed) return false;

      // Cerrar la caja
      cashRegisterProvider.finalBalanceController.text = actualBalance.toString();

      final success = await cashRegisterProvider.closeCashRegister(
        accountId,
        currentCashRegister.id,
      );

      if (success) {
        _showSuccessMessage(context, 'Caja registradora cerrada exitosamente');
      }

      return success;
    } catch (e) {
      _showErrorMessage(context, 'Error al cerrar la caja: $e');
      return false;
    }
  }

  /// Widget que muestra el status de caja en la interfaz de ventas
  static Widget buildCashRegisterStatusForSales(BuildContext context) {
    return Consumer<CashRegisterProvider>(
      builder: (context, provider, child) {
        if (!provider.hasActiveCashRegister) {
          return Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade300),
            ),
            child: Row(
              children: [
                Icon(Icons.warning, color: Colors.orange.shade700),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'No hay caja registradora abierta',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // Navegar a la pantalla de caja o mostrar diálogo de apertura
                  },
                  child: const Text('Abrir Caja'),
                ),
              ],
            ),
          );
        }

        final cashRegister = provider.currentActiveCashRegister!;
        return Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.green.shade100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green.shade300),
          ),
          child: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green.shade700),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Caja: ${cashRegister.description}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Ventas: ${cashRegister.sales} | Total: \$${cashRegister.billing.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.info_outline),
                onPressed: () {
                  // Mostrar detalles de la caja
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // ==========================================
  // MÉTODOS PRIVADOS
  // ==========================================

  static Future<void> _processSale(SellProvider sellProvider, String accountId) async {
    // Aquí iría la lógica para:
    // 1. Guardar la venta en la base de datos (/ACCOUNTS/{accountId}/TRANSACTIONS)
    // 2. Actualizar el stock de los productos
    // 3. Registrar métricas de venta
    
    // Ejemplo de estructura:
    // final transaction = TicketModel(
    //   listPoduct: sellProvider.ticket.listPoduct,
    //   creation: Timestamp.now(),
    //   payMode: sellProvider.ticket.payMode,
    //   valueReceived: sellProvider.ticket.valueReceived,
    // );
    
    // await transactionRepository.addTransaction(accountId, transaction);
  }

  static void _showErrorMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static void _showSuccessMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static Future<bool> _showConfirmationDialog(
    BuildContext context,
    String title,
    String message,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  static Future<bool> _showCashRegisterSummaryDialog(
    BuildContext context,
    CashRegister cashRegister,
    double actualBalance,
    double difference,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Resumen de Cierre de Caja'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Caja: ${cashRegister.description}'),
            const SizedBox(height: 8),
            Text('Monto Inicial: \$${cashRegister.initialCash.toStringAsFixed(2)}'),
            Text('Ventas Realizadas: ${cashRegister.sales}'),
            Text('Total Facturado: \$${cashRegister.billing.toStringAsFixed(2)}'),
            Text('Ingresos Adicionales: \$${cashRegister.cashInFlow.toStringAsFixed(2)}'),
            Text('Egresos: \$${cashRegister.cashOutFlow.toStringAsFixed(2)}'),
            const Divider(),
            Text(
              'Balance Esperado: \$${cashRegister.getExpectedBalance.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              'Balance Real: \$${actualBalance.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              'Diferencia: \$${difference.toStringAsFixed(2)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: difference == 0
                    ? Colors.green
                    : difference > 0
                        ? Colors.blue
                        : Colors.red,
              ),
            ),
            if (difference != 0) ...[
              const SizedBox(height: 8),
              Text(
                difference > 0 ? 'Sobrante en caja' : 'Faltante en caja',
                style: TextStyle(
                  color: difference > 0 ? Colors.blue : Colors.red,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Cerrar Caja'),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}
