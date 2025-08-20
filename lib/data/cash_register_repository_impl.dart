import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/services/database/database_cloud.dart';
import '../../core/utils/fuctions.dart';
import '../../domain/entities/cash_register_model.dart';
import '../../domain/repositories/cash_register_repository.dart';

/// Implementación del repositorio de caja registradora usando Firebase
///
/// Maneja todas las operaciones CRUD para:
/// - Cajas registradoras activas
/// - Historial de arqueos
/// - Descripciones fijas
/// - Flujos de caja
class CashRegisterRepositoryImpl implements CashRegisterRepository {
  // ==========================================
  // CAJAS REGISTRADORAS ACTIVAS
  // ==========================================

  @override
  Future<List<CashRegister>> getActiveCashRegisters(String accountId) async {
    try {
      final querySnapshot =
          await DatabaseCloudService.getActiveCashRegisters(accountId);

      return querySnapshot.docs.map((doc) {
        return CashRegister.fromMap(doc.data());
      }).toList();
    } catch (e) {
      throw Exception('Error al obtener cajas registradoras activas: $e');
    }
  }

  @override
  Stream<List<CashRegister>> getActiveCashRegistersStream(String accountId) {
    return DatabaseCloudService.activeCashRegistersStream(accountId)
        .map((querySnapshot) {
      return querySnapshot.docs.map((doc) {
        return CashRegister.fromMap(doc.data());
      }).toList();
    });
  }

  @override
  Future<void> setCashRegister(
      String accountId, CashRegister cashRegister) async {
    // procede a guardar o actualizar la caja registradora
    try {
      await DatabaseCloudService.accountCashRegisters(accountId)
          .doc(cashRegister.id)
          .set(
              cashRegister.toJson(),
              SetOptions(
                  merge: true)); // merge para actualizar campos específicos
    } catch (e) {
      throw Exception('Error al guardar caja registradora: $e');
    }
  }

  @override
  Future<void> deleteCashRegister(
      String accountId, String cashRegisterId) async {
    try {
      await DatabaseCloudService.accountCashRegisters(accountId)
          .doc(cashRegisterId)
          .delete();
    } catch (e) {
      throw Exception('Error al eliminar caja registradora: $e');
    }
  }

  // ==========================================
  // HISTORIAL DE ARQUEOS
  // ==========================================

  @override
  Future<List<CashRegister>> getCashRegisterHistory(String accountId) async {
    try {
      final querySnapshot =
          await DatabaseCloudService.getCashRegisterHistory(accountId);
      return querySnapshot.docs.map((doc) {
        return CashRegister.fromMap(doc.data());
      }).toList();
    } catch (e) {
      throw Exception('Error al obtener historial de cajas: $e');
    }
  }

  @override
  Stream<List<CashRegister>> getCashRegisterHistoryStream(String accountId) {
    return DatabaseCloudService.cashRegisterHistoryStream(accountId)
        .map((querySnapshot) {
      return querySnapshot.docs.map((doc) {
        return CashRegister.fromMap(doc.data());
      }).toList();
    });
  }

  @override
  Future<List<CashRegister>> getCashRegisterByDays(
      String accountId, int days) async {
    try {
      final querySnapshot = await DatabaseCloudService.getCashRegisterByDays(
        accountId: accountId,
        days: days,
      );
      return querySnapshot.docs.map((doc) {
        return CashRegister.fromMap(doc.data());
      }).toList();
    } catch (e) {
      throw Exception('Error al obtener arqueos por días: $e');
    }
  }

  @override
  Future<List<CashRegister>> getCashRegisterByDateRange({
    required String accountId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final querySnapshot =
          await DatabaseCloudService.getCashRegisterByDateRange(
        accountId: accountId,
        startDate: startDate,
        endDate: endDate,
      );
      return querySnapshot.docs.map((doc) {
        return CashRegister.fromMap(doc.data());
      }).toList();
    } catch (e) {
      throw Exception('Error al obtener arqueos por rango de fechas: $e');
    }
  }

  @override
  Future<List<CashRegister>> getTodayCashRegisters(String accountId) async {
    try {
      final querySnapshot =
          await DatabaseCloudService.getTodayCashRegisters(accountId);
      return querySnapshot.docs.map((doc) {
        return CashRegister.fromMap(doc.data());
      }).toList();
    } catch (e) {
      throw Exception('Error al obtener arqueos de hoy: $e');
    }
  }

  @override
  Future<void> addCashRegisterToHistory(
      String accountId, CashRegister cashRegister) async {
    try {
      await DatabaseCloudService.accountCashRegisterHistory(accountId)
          .add(cashRegister.toJson());
    } catch (e) {
      throw Exception('Error al agregar arqueo al historial: $e');
    }
  }

  @override
  Future<void> deleteCashRegisterFromHistory(
      String accountId, CashRegister cashRegister) async {
    try {
      await DatabaseCloudService.accountCashRegisterHistory(accountId)
          .doc(cashRegister.id)
          .delete();
    } catch (e) {
      throw Exception('Error al eliminar arqueo del historial: $e');
    }
  }

  // ==========================================
  // DESCRIPCIONES FIJAS PARA NOMBRES DE CAJA
  // ==========================================

  @override
  Future<void> createCashRegisterFixedDescription(
      String accountId, String description) async {
    try {
      await DatabaseCloudService.accountFixedDescriptions(accountId)
          .doc(description)
          .set({'description': description});
    } catch (e) {
      throw Exception('Error al crear descripción fija: $e');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getCashRegisterFixedDescriptions(
      String accountId) async {
    try {
      final querySnapshot =
          await DatabaseCloudService.accountFixedDescriptions(accountId).get();
      return querySnapshot.docs.map((doc) {
        return doc.data();
      }).toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<void> deleteCashRegisterFixedDescription(
      String accountId, String descriptionId) async {
    try {
      final docRef = DatabaseCloudService.accountFixedDescriptions(accountId)
          .doc(descriptionId);

      // Verificar si el documento existe antes de eliminar
      final docSnapshot = await docRef.get();
      if (!docSnapshot.exists) {
        throw Exception('La descripción "$descriptionId" no existe');
      }

      await docRef.delete();
    } catch (e) {
      throw Exception('Error al eliminar descripción fija: $e');
    }
  }

  // ==========================================
  // OPERACIONES DE CAJA
  // ==========================================

  @override
  Future<CashRegister> openCashRegister({
    required String accountId,
    required String description,
    required double initialCash,
    required String cashierId,
  }) async {
    try {
      final cashRegisterId = Publications.generateUid();
      final now = DateTime.now();

      final cashRegister = CashRegister(
        id: cashRegisterId,
        description: description,
        initialCash: initialCash,
        opening: now,
        closure: now, // Se actualizará al cerrar
        sales: 0,
        billing: 0.0,
        discount: 0.0,
        cashInFlow: 0.0,
        cashOutFlow: 0.0,
        expectedBalance: initialCash,
        balance: 0.0, // Se actualizará al cerrar
        cashInFlowList: [],
        cashOutFlowList: [],
      );
      // cres la caja registradora en la base de datos
      await setCashRegister(accountId, cashRegister);

      return cashRegister;
    } catch (e) {
      throw Exception('Error al abrir caja registradora: $e');
    }
  }

  @override
  Future<CashRegister> closeCashRegister({
    required String accountId,
    required String cashRegisterId,
    required double finalBalance,
  }) async {
    try {
      // Obtener la caja registradora actual
      final activeCashRegisters = await getActiveCashRegisters(accountId);
      final cashRegister = activeCashRegisters.firstWhere(
        (cr) => cr.id == cashRegisterId,
        orElse: () => throw Exception('Caja registradora no encontrada'),
      );

      // Actualizar datos de cierre
      final updatedCashRegister = cashRegister.update(
        closure: DateTime.now(),
        balance: finalBalance,
      );

      // Mover al historial
      await addCashRegisterToHistory(accountId, updatedCashRegister);

      // Eliminar de cajas activas
      await deleteCashRegister(accountId, cashRegisterId);

      return updatedCashRegister;
    } catch (e) {
      throw Exception('Error al cerrar caja registradora: $e');
    }
  }

  @override
  Future<void> addCashInflow({
    required String accountId,
    required String cashRegisterId,
    required CashFlow cashFlow,
  }) async {
    try {
      // Obtener la caja registradora actual
      final activeCashRegisters = await getActiveCashRegisters(accountId);
      final cashRegister = activeCashRegisters.firstWhere(
        (cr) => cr.id == cashRegisterId,
        orElse: () => throw Exception('Caja registradora no encontrada'),
      );

      // Actualizar listas y totales
      final updatedInflows = List<dynamic>.from(cashRegister.cashInFlowList)
        ..add(cashFlow.toJson());

      final updatedCashRegister = cashRegister.update(
        cashInFlow: cashRegister.cashInFlow + cashFlow.amount,
        cashInFlowList: updatedInflows,
      );

      await setCashRegister(accountId, updatedCashRegister);
    } catch (e) {
      throw Exception('Error al agregar ingreso de caja: $e');
    }
  }

  @override
  Future<void> addCashOutflow({
    required String accountId,
    required String cashRegisterId,
    required CashFlow cashFlow,
  }) async {
    try {
      // Obtener la caja registradora actual
      final activeCashRegisters = await getActiveCashRegisters(accountId);
      final cashRegister = activeCashRegisters.firstWhere(
        (cr) => cr.id == cashRegisterId,
        orElse: () => throw Exception('Caja registradora no encontrada'),
      );

      // Actualizar listas y totales (egreso es negativo)
      final updatedOutflows = List<dynamic>.from(cashRegister.cashOutFlowList)
        ..add(cashFlow.toJson());

      final updatedCashRegister = cashRegister.update(
        cashOutFlow: cashRegister.cashOutFlow -
            cashFlow.amount, // Se resta porque es egreso
        cashOutFlowList: updatedOutflows,
      );

      await setCashRegister(accountId, updatedCashRegister);
    } catch (e) {
      throw Exception('Error al agregar egreso de caja: $e');
    }
  }

  @override
  Future<void> updateSalesAndBilling({
    required String accountId, // obtiene el id de la cuenta
    required String cashRegisterId, // obtiene el id de la caja registradora
    required double billingIncrement, // incrementa la facturación
    required double discountIncrement, // incrementa el descuento
  }) async {
    // updateSalesAndBilling : actualiza los totales de ventas y facturación de una caja registradora
    try {
      // Obtener la caja registradora actual
      final activeCashRegisters = await getActiveCashRegisters(accountId);
      final cashRegister = activeCashRegisters.firstWhere(
        (cr) => cr.id == cashRegisterId,
        orElse: () => throw Exception('Caja registradora no encontrada'),
      );

      // Actualizar totales de ventas
      final updatedCashRegister = cashRegister.update(
        sales: cashRegister.sales + 1, // Incrementa las ventas de la caja
        billing: cashRegister.billing +
            billingIncrement, // Incrementa la facturación
        discount: cashRegister.discount +
            discountIncrement, // Incrementa el descuento
      );

      await setCashRegister(accountId, updatedCashRegister);
    } catch (e) {
      throw Exception('Error al actualizar ventas y facturación: $e');
    }
  }

  // ==========================================
  // TRANSACCIONES HISTÓRICAS
  // ==========================================

  @override
  Future<void> saveTicketTransaction({
    required String accountId,
    required String ticketId,
    required Map<String, dynamic> transactionData,
  }) async {
    try {
      await DatabaseCloudService.accountTransactions(accountId)
          .doc(ticketId)
          .set(transactionData);
    } catch (e) {
      throw Exception('Error al guardar transacción: $e');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getTransactionsByDateRange({
    required String accountId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final startTimestamp = Timestamp.fromDate(startDate);
      final endTimestamp = Timestamp.fromDate(endDate);

      final querySnapshot =
          await DatabaseCloudService.getTransactionsByDateRange(
        accountId: accountId,
        startDate: startTimestamp,
        endDate: endTimestamp,
      );

      return querySnapshot.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data(),
              })
          .toList();
    } catch (e) {
      throw Exception('Error al obtener transacciones por rango de fechas: $e');
    }
  }

  @override
  Stream<List<Map<String, dynamic>>> getTransactionsStream(String accountId) {
    return DatabaseCloudService.accountTransactionsStream(accountId)
        .map((querySnapshot) {
      return querySnapshot.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data(),
              })
          .toList();
    });
  }

  @override
  Future<Map<String, dynamic>?> getTransactionDetail({
    required String accountId,
    required String transactionId,
  }) async {
    try {
      final docSnapshot =
          await DatabaseCloudService.accountTransactions(accountId)
              .doc(transactionId)
              .get();

      if (docSnapshot.exists) {
        return {
          'id': docSnapshot.id,
          ...docSnapshot.data()!,
        };
      }
      return null;
    } catch (e) {
      throw Exception('Error al obtener detalle de transacción: $e');
    }
  }

  @override
  Future<void> deleteTransaction({
    required String accountId,
    required String transactionId,
  }) async {
    try {
      await DatabaseCloudService.accountTransactions(accountId)
          .doc(transactionId)
          .delete();
    } catch (e) {
      throw Exception('Error al eliminar transacción: $e');
    }
  }
}
