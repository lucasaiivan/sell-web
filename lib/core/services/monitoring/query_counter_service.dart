import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:intl/intl.dart';
import '../storage/app_data_persistence_service.dart';

/// Servicio para monitorear y contar las consultas a Firestore.
/// Persiste los contadores diariamente para control de costos/uso.
@lazySingleton
class QueryCounterService {
  final AppDataPersistenceService _persistence;

  // Keys para persistencia
  static const _kLastResetDate = 'query_counter_date';
  static const _kReadsCount = 'query_counter_reads';
  static const _kWritesCount = 'query_counter_writes';

  // Notifiers para UI reactiva
  final ValueNotifier<int> reads = ValueNotifier(0);
  final ValueNotifier<int> writes = ValueNotifier(0);

  QueryCounterService(this._persistence) {
    _initialize();
  }

  Future<void> _initialize() async {
    final now = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(now);

    final storedDate = await _persistence.getString(_kLastResetDate);

    if (storedDate != todayStr) {
      // Nuevo día, resetear contadores
      await _resetCounters(todayStr);
    } else {
      // Mismo día, cargar valores
      reads.value = await _persistence.getInt(_kReadsCount) ?? 0;
      writes.value = await _persistence.getInt(_kWritesCount) ?? 0;
    }
  }

  Future<void> _resetCounters(String todayStr) async {
    reads.value = 0;
    writes.value = 0;
    await Future.wait([
      _persistence.setString(_kLastResetDate, todayStr),
      _persistence.setInt(_kReadsCount, 0),
      _persistence.setInt(_kWritesCount, 0),
    ]);
  }

  /// Incrementa el contador de lecturas
  void incrementReads(int amount) {
    if (amount <= 0) return;
    reads.value += amount;
    _persistence.setInt(_kReadsCount, reads.value);
  }

  /// Incrementa el contador de escrituras
  void incrementWrites(int amount) {
    if (amount <= 0) return;
    writes.value += amount;
    _persistence.setInt(_kWritesCount, writes.value);
  }
}
