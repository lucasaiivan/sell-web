

/// Tipos de datos que requieren sincronización
enum SyncDataType {
  products,
  categories,
  settings,
}

/// Servicio base para gestionar la sincronización de datos
abstract class ISyncService {
  /// Verifica si es necesario actualizar un tipo de dato
  ///
  /// Compara timestamp local vs remoto
  Future<bool> needsUpdate(String accountId, SyncDataType type);

  /// Marca un tipo de dato como actualizado al momento actual
  Future<void> markAsUpdated(String accountId, SyncDataType type);
  
  /// Obtiene el timestamp de la última sincronización
  int getLastSyncTime(String accountId, SyncDataType type);
  
  /// Limpia el estado de sincronización (ej: al cerrar sesión)
  Future<void> clearSyncState();
}
