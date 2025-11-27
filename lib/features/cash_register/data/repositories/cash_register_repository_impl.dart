import 'package:injectable/injectable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sellweb/core/core.dart';
import 'package:sellweb/core/services/database/i_firestore_datasource.dart';
import 'package:sellweb/core/services/database/firestore_paths.dart';
import 'package:sellweb/features/cash_register/domain/entities/cash_register.dart';
import 'package:sellweb/features/cash_register/domain/repositories/cash_register_repository.dart';

/// Implementación del repositorio de caja registradora usando Firebase
///
/// **Refactorizado:** Usa [IFirestoreDataSource] en lugar de DatabaseCloudService
/// 
/// Maneja todas las operaciones CRUD para:
/// - Cajas registradoras activas
/// - Historial de arqueos
/// - Descripciones fijas
/// - Flujos de caja
@LazySingleton(as: CashRegisterRepository)
class CashRegisterRepositoryImpl implements CashRegisterRepository {
  final IFirestoreDataSource _dataSource;

  CashRegisterRepositoryImpl(this._dataSource);

  // ==========================================
  // CAJAS REGISTRADORAS ACTIVAS
  // ==========================================

  @override
  Future<List<CashRegister>> getActiveCashRegisters(String accountId) async {
    try {
      final path = FirestorePaths.accountCashRegisters(accountId);
      final collection = _dataSource.collection(path);
      final querySnapshot = await _dataSource.getDocuments(collection);

      return querySnapshot.docs.map((doc) {
        return CashRegister.fromMap(doc.data());
      }).toList();
    } catch (e) {
      throw Exception('Error al obtener cajas registradoras activas: $e');
    }
  }

  @override
  Stream<List<CashRegister>> getActiveCashRegistersStream(String accountId) {
    final path = FirestorePaths.accountCashRegisters(accountId);
    return _dataSource.collectionStream(path)
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
      final path = FirestorePaths.accountCashRegister(accountId, cashRegister.id);
      await _dataSource.setDocument(
        path,
        cashRegister.toJson(),
        merge: true, // merge para actualizar campos específicos
      );
    } catch (e) {
      throw Exception('Error al guardar caja registradora: $e');
    }
  }

  @override
  Future<void> deleteCashRegister(
      String accountId, String cashRegisterId) async {
    try {
      final path = FirestorePaths.accountCashRegister(accountId, cashRegisterId);
      await _dataSource.deleteDocument(path);
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
      final path = FirestorePaths.accountCashRegisterHistory(accountId);
      final collection = _dataSource.collection(path);
      final query = collection.orderBy('opening', descending: true);
      final querySnapshot = await _dataSource.getDocuments(query);
      return querySnapshot.docs.map((doc) {
        return CashRegister.fromMap(doc.data());
      }).toList();
    } catch (e) {
      throw Exception('Error al obtener historial de cajas: $e');
    }
  }

  @override
  Stream<List<CashRegister>> getCashRegisterHistoryStream(String accountId) {
    final path = FirestorePaths.accountCashRegisterHistory(accountId);
    final collection = _dataSource.collection(path);
    final query = collection.orderBy('opening', descending: true);
    return _dataSource.streamDocuments(query)
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
      final path = FirestorePaths.accountCashRegisterHistory(accountId);
      final collection = _dataSource.collection(path);
      final cutoffDate = DateTime.now().subtract(Duration(days: days));
      final query = collection
          .where('opening', isGreaterThan: cutoffDate)
          .orderBy('opening', descending: true);
      final querySnapshot = await _dataSource.getDocuments(query);
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
      final path = FirestorePaths.accountCashRegisterHistory(accountId);
      final collection = _dataSource.collection(path);
      final query = collection
          .where('opening', isGreaterThan: startDate)
          .where('opening', isLessThan: endDate)
          .orderBy('opening', descending: true);
      final querySnapshot = await _dataSource.getDocuments(query);
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
      final path = FirestorePaths.accountCashRegisterHistory(accountId);
      final collection = _dataSource.collection(path);
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final query = collection.where('opening', isGreaterThanOrEqualTo: yesterday);
      final querySnapshot = await _dataSource.getDocuments(query);
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
      final path = '${FirestorePaths.accountCashRegisterHistory(accountId)}/${cashRegister.id}';
      await _dataSource.setDocument(path, cashRegister.toJson());
    } catch (e) {
      throw Exception('Error al agregar arqueo al historial: $e');
    }
  }

  @override
  Future<void> deleteCashRegisterFromHistory(
      String accountId, CashRegister cashRegister) async {
    try {
      final path = '${FirestorePaths.accountCashRegisterHistory(accountId)}/${cashRegister.id}';
      await _dataSource.deleteDocument(path);
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
      final path = '${FirestorePaths.accountFixedDescriptions(accountId)}/$description';
      await _dataSource.setDocument(path, {'description': description});
    } catch (e) {
      throw Exception('Error al crear descripción fija: $e');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getCashRegisterFixedDescriptions(
      String accountId) async {
    try {
      final path = FirestorePaths.accountFixedDescriptions(accountId);
      final collection = _dataSource.collection(path);
      final querySnapshot = await _dataSource.getDocuments(collection);
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
      final path = '${FirestorePaths.accountFixedDescriptions(accountId)}/$descriptionId';
      final docRef = _dataSource.document(path);

      // Verificar si el documento existe antes de eliminar
      final docSnapshot = await docRef.get();
      if (!docSnapshot.exists) {
        throw Exception('La descripción "$descriptionId" no existe');
      }

      await _dataSource.deleteDocument(path);
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
    required String cashierName,
  }) async {
    try {
      final cashRegisterId = UidHelper.generateUid();
      final now = DateTime.now();

      final cashRegister = CashRegister(
        id: cashRegisterId,
        description: description,
        idUser: cashierId,
        nameUser: cashierName,
        initialCash: initialCash,
        opening: now,
        closure: now, // Se actualizará al cerrar
        sales: 0,
        annulledTickets: 0,
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
    // ⚠️ IMPORTANTE: Este método SOLO debe usarse para VENTAS EFECTIVAS
    // Para anulaciones, usar updateBillingOnAnnullment() que NO incrementa sales
    try {
      // Obtener la caja registradora actual
      final activeCashRegisters = await getActiveCashRegisters(accountId);
      final cashRegister = activeCashRegisters.firstWhere(
        (cr) => cr.id == cashRegisterId,
        orElse: () => throw Exception('Caja registradora no encontrada'),
      );

      // Actualizar totales de ventas
      final updatedCashRegister = cashRegister.update(
        sales:
            cashRegister.sales + 1, // ✅ Incrementa contador de ventas efectivas
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

  /// Actualiza billing y discount al anular un ticket (NO incrementa sales)
  ///
  /// RESPONSABILIDAD: Restar montos de venta anulada sin modificar contador de ventas
  /// - Decrementa billing (restar precio total del ticket)
  /// - Decrementa discount (restar descuento del ticket)
  /// - NO modifica sales (las ventas efectivas no incluyen anulaciones)
  /// - Incrementar annulledTickets es responsabilidad del llamador
  @override
  Future<void> updateBillingOnAnnullment({
    required String accountId,
    required String cashRegisterId,
    required double
        billingDecrement, // Monto a restar de billing (valor positivo)
    required double
        discountDecrement, // Monto a restar de discount (valor positivo)
  }) async {
    try {
      // Obtener la caja registradora actual
      final activeCashRegisters = await getActiveCashRegisters(accountId);
      final cashRegister = activeCashRegisters.firstWhere(
        (cr) => cr.id == cashRegisterId,
        orElse: () => throw Exception('Caja registradora no encontrada'),
      );

      // Actualizar solo billing y discount (sales NO se modifica)
      final updatedCashRegister = cashRegister.update(
        // NO modificar sales - las ventas efectivas no incluyen anulaciones
        billing: cashRegister.billing - billingDecrement, // Restar facturación
        discount: cashRegister.discount - discountDecrement, // Restar descuento
        annulledTickets: cashRegister.annulledTickets +
            1, // ✅ Incrementar contador de anulados
      );

      await setCashRegister(accountId, updatedCashRegister);
    } catch (e) {
      throw Exception('Error al actualizar billing por anulación: $e');
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
      print('💾 [CashRegister] Guardando transacción:');
      print('   AccountId: $accountId');
      print('   TicketId: $ticketId');
      print('   Creation: ${transactionData['creation']}');
      print('   PriceTotal: ${transactionData['priceTotal']}');
      print('   Products: ${(transactionData['listPoduct'] as List?)?.length ?? 0}');
      
      final path = FirestorePaths.accountTransaction(accountId, ticketId);
      await _dataSource.setDocument(path, transactionData, merge: true);
      
      print('✅ [CashRegister] Transacción guardada exitosamente en Firestore');
      print('   Ruta: /ACCOUNTS/$accountId/TRANSACTIONS/$ticketId');
    } catch (e, stackTrace) {
      print('❌ [CashRegister] Error al guardar transacción: $e');
      print('❌ [CashRegister] StackTrace: $stackTrace');
      throw Exception('Error al guardar transacción: $e');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getTransactionsByDateRange({
    required String accountId,
    required DateTime startDate,
    required DateTime endDate,
    String cashRegisterId = '', // filtrado opcional por caja
  }) async {
    try {
      final startTimestamp = Timestamp.fromDate(startDate);
      final endTimestamp = Timestamp.fromDate(endDate);

      final path = FirestorePaths.accountTransactions(accountId);
      final collection = _dataSource.collection(path);
      final query = collection
          .where('creation', isGreaterThanOrEqualTo: startTimestamp)
          .where('creation', isLessThanOrEqualTo: endTimestamp);
      final querySnapshot = await _dataSource.getDocuments(query);

      final result = querySnapshot.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data(),
              })
          .toList();

      return result;
    } catch (e) {
      throw Exception('Error al obtener transacciones por rango de fechas: $e');
    }
  }

  @override
  Stream<List<Map<String, dynamic>>> getTransactionsStream(String accountId) {
    final path = FirestorePaths.accountTransactions(accountId);
    return _dataSource.collectionStream(path)
        .map((querySnapshot) {
      return querySnapshot.docs
          .map((doc) {
            final data = doc.data();
            // Normalizar timestamps en el documento
            final normalizedData = _normalizeTimestampsInTransaction(data);
            return {
              'id': doc.id,
              ...normalizedData,
            };
          })
          .toList();
    });
  }

  /// Normaliza todos los campos de timestamp en una transacción
  Map<String, dynamic> _normalizeTimestampsInTransaction(Map<String, dynamic> data) {
    final normalized = Map<String, dynamic>.from(data);
    
    // Normalizar timestamps a nivel de documento
    final timestampFields = [
      'creation',
      'upgrade',
      'documentCreation',
      'documentUpgrade',
      'timestamp_actualizacion',
      'timestamp_creation',
      'timestamp_creation_document',
      'timestamp_upgrade_document',
    ];
    
    for (final field in timestampFields) {
      if (normalized.containsKey(field) && normalized[field] is int) {
        normalized[field] = Timestamp.fromMillisecondsSinceEpoch(normalized[field] as int);
      }
    }
    
    // Normalizar timestamps en productos (array)
    if (normalized.containsKey('products') && normalized['products'] is List) {
      final products = normalized['products'] as List;
      normalized['products'] = products.map((product) {
        if (product is Map<String, dynamic>) {
          final normalizedProduct = Map<String, dynamic>.from(product);
          for (final field in timestampFields) {
            if (normalizedProduct.containsKey(field) && normalizedProduct[field] is int) {
              normalizedProduct[field] = Timestamp.fromMillisecondsSinceEpoch(normalizedProduct[field] as int);
            }
          }
          return normalizedProduct;
        }
        return product;
      }).toList();
    }
    
    return normalized;
  }

  @override
  Future<Map<String, dynamic>?> getTransactionDetail({
    required String accountId,
    required String transactionId,
  }) async {
    try {
      final path = FirestorePaths.accountTransaction(accountId, transactionId);
      final docRef = _dataSource.document(path);
      final docSnapshot = await docRef.get();

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
      final path = FirestorePaths.accountTransaction(accountId, transactionId);
      await _dataSource.deleteDocument(path);
    } catch (e) {
      throw Exception('Error al eliminar transacción: $e');
    }
  }
}
