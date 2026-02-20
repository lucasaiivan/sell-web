import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:sellweb/core/services/database/firestore_paths.dart';
import 'package:sellweb/core/services/database/i_firestore_datasource.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'i_sync_service.dart';

@LazySingleton(as: ISyncService)
class SyncServiceImpl implements ISyncService {
  final IFirestoreDataSource _firestore;
  final SharedPreferences _prefs;

  SyncServiceImpl(this._firestore, this._prefs);

  static const String _prefix = 'last_sync_';

  @override
  Future<bool> needsUpdate(String accountId, SyncDataType type) async {
    try {
      // 1. Verificar conectividad primero
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult.contains(ConnectivityResult.none)) {
        if (kDebugMode) {
          debugPrint('🚫 [Sync] Offline mode: Usando data local para ${type.name}');
        }
        return false;
      }

      // 2. Obtener timestamp local
      final localTimestamp = _prefs.getInt('${_prefix}${type.name}_$accountId') ?? 0;

      // 3. Obtener metada remota
      // TODO: Optimizar: Podríamos leer un solo doc de Metadata con TODOS los timestamps
      // para evitar 1 lectura por cada tipo de dato si chequeamos varios a la vez.
      // Por ahora, asumimos que el documento metadata tiene campos como 'products_updated_at'
      final path = FirestorePaths.accountMetadata(accountId);
      final docSnapshot = await _firestore.document(path).get();

      if (!docSnapshot.exists) {
        // Si no existe metadata remota, asumimos que necesitamos sync (o inicializar)
        return true;
      }

      final data = docSnapshot.data() as Map<String, dynamic>;
      final fieldName = _getFieldNameForType(type);
      
      if (!data.containsKey(fieldName)) {
         return true; // Campo no existe, forzar update
      }

      final remoteTimestamp = (data[fieldName] as Timestamp).millisecondsSinceEpoch;

      final needsUpdate = remoteTimestamp > localTimestamp;

      if (kDebugMode) {
        debugPrint(
            '🔄 [Sync] ${type.name}: Local($localTimestamp) vs Remote($remoteTimestamp) -> Update: $needsUpdate');
      }

      return needsUpdate;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ [Sync] Error chequeando update: $e');
      }
      return false; // Ante error, protegemos la UI y usamos local
    }
  }

  @override
  Future<void> markAsUpdated(String accountId, SyncDataType type) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await _prefs.setInt('${_prefix}${type.name}_$accountId', now);
    if (kDebugMode) {
      debugPrint('✅ [Sync] ${type.name} marcado como actualizado a $now');
    }
  }

  @override
  Future<void> clearSyncState() async {
    final keys = _prefs.getKeys();
    for (final key in keys) {
      if (key.startsWith(_prefix)) {
        await _prefs.remove(key);
      }
    }
  }

  @override
  int getLastSyncTime(String accountId, SyncDataType type) {
    return _prefs.getInt('${_prefix}${type.name}_$accountId') ?? 0;
  }

  String _getFieldNameForType(SyncDataType type) {
    switch (type) {
      case SyncDataType.products:
        return 'products_last_update';
      case SyncDataType.categories:
        return 'categories_last_update';
      case SyncDataType.settings:
        return 'settings_last_update';
    }
  }
}
