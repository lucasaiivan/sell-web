import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:sellweb/core/services/storage/app_data_persistence_service.dart';
import '../datasources/analytics_preferences_remote_datasource.dart';

/// Servicio de persistencia de preferencias de analíticas
///
/// **Responsabilidad:**
/// - Guardar y cargar tarjetas visibles por usuario
/// - Guardar y cargar el orden de las tarjetas
/// - Gestionar preferencias específicas de analytics
///
/// **Estrategia de Persistencia (Cloud-First):**
/// - **Fuente de verdad:** Firestore (asociado a la cuenta del comercio)
/// - **Caché local:** SharedPreferences (fallback para offline)
/// - **Migración automática:** Si existen datos locales sin datos remotos,
///   se migran a la nube y se eliminan localmente
///
/// **Beneficios:**
/// - Sincronización entre dispositivos
/// - Persistencia asociada a la cuenta, no al dispositivo
/// - Funciona offline con caché local
@injectable
class AnalyticsPreferencesService {
  final AppDataPersistenceService _persistence;
  final AnalyticsPreferencesRemoteDataSource _remoteDataSource;

  AnalyticsPreferencesService(
    this._persistence,
    this._remoteDataSource,
  );

  /// Clave base para preferencias de analytics
  static const String _keyPrefix = 'analytics_';

  /// Genera la clave para tarjetas visibles de un usuario
  String _visibleCardsKey(String accountId) =>
      '${_keyPrefix}visible_cards_$accountId';

  /// Genera la clave para el orden de tarjetas de un usuario
  String _cardOrderKey(String accountId) =>
      '${_keyPrefix}card_order_$accountId';

  // ==========================================
  // TARJETAS VISIBLES (Cloud-First)
  // ==========================================

  /// Guarda las tarjetas visibles para un usuario
  ///
  /// **Estrategia Cloud-First:**
  /// 1. Guarda en Firestore (fuente de verdad)
  /// 2. Actualiza caché local (para fallback offline)
  ///
  /// **Parámetros:**
  /// - `accountId`: ID de la cuenta del usuario
  /// - `cardIds`: Lista de IDs de tarjetas que el usuario quiere ver
  ///
  /// **Ejemplo:**
  /// ```dart
  /// await service.saveVisibleCards('user123', ['billing', 'profit', 'sales']);
  /// ```
  Future<void> saveVisibleCards(String accountId, List<String> cardIds) async {
    if (accountId.isEmpty) {
      throw ArgumentError('accountId no puede estar vacío');
    }

    // 1. Guardar en la nube (fuente de verdad)
    try {
      await _remoteDataSource.saveVisibleCards(accountId, cardIds);
    } catch (e) {
      // Si falla la nube, continuar con local para no perder datos
      debugPrint('⚠️ Error guardando en la nube, usando solo local: $e');
    }

    // 2. Guardar en caché local (backup/offline)
    final key = _visibleCardsKey(accountId);
    final jsonString = jsonEncode(cardIds);
    await _saveString(key, jsonString);
  }

  /// Carga las tarjetas visibles para un usuario
  ///
  /// **Estrategia Cloud-First con Migración:**
  /// 1. Intenta cargar desde Firestore
  /// 2. Si hay datos remotos → actualizar caché local y retornar
  /// 3. Si NO hay datos remotos → verificar datos locales (migración)
  /// 4. Si hay datos locales → migrar a la nube, limpiar local, retornar
  /// 5. Si no hay nada → retornar null (primera vez)
  ///
  /// **Retorna:**
  /// - `List<String>?`: Lista de IDs si existen preferencias guardadas
  /// - `null`: Si es la primera vez del usuario (sin preferencias)
  Future<List<String>?> loadVisibleCards(String accountId) async {
    if (accountId.isEmpty) {
      throw ArgumentError('accountId no puede estar vacío');
    }

    try {
      // 1. Intentar cargar desde la nube
      final remotePrefs = await _remoteDataSource.loadPreferences(accountId);

      if (remotePrefs != null && remotePrefs.visibleCards.isNotEmpty) {
        // Datos en la nube encontrados - actualizar caché local
        final key = _visibleCardsKey(accountId);
        await _saveString(key, jsonEncode(remotePrefs.visibleCards));
        return remotePrefs.visibleCards;
      }

      // 2. No hay datos en la nube - verificar si hay datos locales para migrar
      final localCards = await _loadVisibleCardsLocal(accountId);

      if (localCards != null && localCards.isNotEmpty) {
        // Migrar datos locales a la nube
        debugPrint('🔄 Migrando preferencias locales a la nube...');
        await _remoteDataSource.saveVisibleCards(accountId, localCards);

        // Opcional: limpiar datos locales después de migrar
        // await _clearLocalPreferences(accountId);

        return localCards;
      }

      // 3. No hay datos en ningún lado - primera vez
      return null;
    } catch (e) {
      // Error de red - usar caché local como fallback
      debugPrint('⚠️ Error cargando de la nube, usando caché local: $e');
      return await _loadVisibleCardsLocal(accountId);
    }
  }

  /// Carga tarjetas visibles solo desde almacenamiento local
  Future<List<String>?> _loadVisibleCardsLocal(String accountId) async {
    try {
      final key = _visibleCardsKey(accountId);
      final jsonString = await _getString(key);

      if (jsonString == null || jsonString.isEmpty) {
        return null;
      }

      final List<dynamic> decoded = jsonDecode(jsonString);
      return decoded.cast<String>();
    } catch (e) {
      return null;
    }
  }

  /// Limpia las preferencias de tarjetas visibles para un usuario
  ///
  /// Limpia tanto datos remotos como locales
  Future<void> clearVisibleCards(String accountId) async {
    if (accountId.isEmpty) {
      throw ArgumentError('accountId no puede estar vacío');
    }

    // Limpiar local
    final key = _visibleCardsKey(accountId);
    await _remove(key);

    // Intentar limpiar remoto
    try {
      await _remoteDataSource.saveVisibleCards(accountId, []);
    } catch (e) {
      debugPrint('⚠️ Error limpiando preferencias remotas: $e');
    }
  }

  // ==========================================
  // ORDEN DE TARJETAS (Cloud-First)
  // ==========================================

  /// Guarda el orden de las tarjetas para un usuario
  ///
  /// **Estrategia Cloud-First:**
  /// 1. Guarda en Firestore (fuente de verdad)
  /// 2. Actualiza caché local (para fallback offline)
  ///
  /// Este orden se usa para mantener la posición después de drag-and-drop
  ///
  /// **Parámetros:**
  /// - `accountId`: ID de la cuenta del usuario
  /// - `cardIds`: Lista ordenada de IDs de tarjetas
  Future<void> saveCardOrder(String accountId, List<String> cardIds) async {
    if (accountId.isEmpty) {
      throw ArgumentError('accountId no puede estar vacío');
    }

    // 1. Guardar en la nube (fuente de verdad)
    try {
      await _remoteDataSource.saveCardOrder(accountId, cardIds);
    } catch (e) {
      debugPrint('⚠️ Error guardando orden en la nube, usando solo local: $e');
    }

    // 2. Guardar en caché local (backup/offline)
    final key = _cardOrderKey(accountId);
    final jsonString = jsonEncode(cardIds);
    await _saveString(key, jsonString);
  }

  /// Carga el orden de las tarjetas para un usuario
  ///
  /// **Estrategia Cloud-First con Migración:**
  /// Similar a loadVisibleCards pero para el orden
  ///
  /// **Retorna:**
  /// - `List<String>?`: Lista ordenada de IDs si existe
  /// - `null`: Si no hay orden guardado
  Future<List<String>?> loadCardOrder(String accountId) async {
    if (accountId.isEmpty) {
      throw ArgumentError('accountId no puede estar vacío');
    }

    try {
      // 1. Intentar cargar desde la nube
      final remotePrefs = await _remoteDataSource.loadPreferences(accountId);

      if (remotePrefs != null && remotePrefs.cardOrder.isNotEmpty) {
        // Datos en la nube encontrados - actualizar caché local
        final key = _cardOrderKey(accountId);
        await _saveString(key, jsonEncode(remotePrefs.cardOrder));
        return remotePrefs.cardOrder;
      }

      // 2. No hay datos en la nube - verificar datos locales para migrar
      final localOrder = await _loadCardOrderLocal(accountId);

      if (localOrder != null && localOrder.isNotEmpty) {
        // Migrar datos locales a la nube
        debugPrint('🔄 Migrando orden de tarjetas a la nube...');
        await _remoteDataSource.saveCardOrder(accountId, localOrder);
        return localOrder;
      }

      return null;
    } catch (e) {
      // Error de red - usar caché local como fallback
      debugPrint('⚠️ Error cargando orden de la nube, usando caché local: $e');
      return await _loadCardOrderLocal(accountId);
    }
  }

  /// Carga el orden de tarjetas solo desde almacenamiento local
  Future<List<String>?> _loadCardOrderLocal(String accountId) async {
    try {
      final key = _cardOrderKey(accountId);
      final jsonString = await _getString(key);

      if (jsonString == null || jsonString.isEmpty) {
        return null;
      }

      final List<dynamic> decoded = jsonDecode(jsonString);
      return decoded.cast<String>();
    } catch (e) {
      return null;
    }
  }

  /// Limpia el orden de tarjetas para un usuario
  ///
  /// Limpia tanto datos remotos como locales
  Future<void> clearCardOrder(String accountId) async {
    if (accountId.isEmpty) {
      throw ArgumentError('accountId no puede estar vacío');
    }

    // Limpiar local
    final key = _cardOrderKey(accountId);
    await _remove(key);

    // Intentar limpiar remoto
    try {
      await _remoteDataSource.saveCardOrder(accountId, []);
    } catch (e) {
      debugPrint('⚠️ Error limpiando orden remoto: $e');
    }
  }

  // ==========================================
  // OPERACIONES GENERALES
  // ==========================================

  /// Limpia todas las preferencias de analytics para un usuario
  ///
  /// Limpia tanto datos locales como remotos
  Future<void> clearAllPreferences(String accountId) async {
    await Future.wait([
      clearVisibleCards(accountId),
      clearCardOrder(accountId),
    ]);

    // Intentar eliminar documento remoto completo
    try {
      await _remoteDataSource.deletePreferences(accountId);
    } catch (e) {
      debugPrint('⚠️ Error eliminando preferencias remotas: $e');
    }
  }

  // ==========================================
  // HELPERS PRIVADOS para acceso a SharedPreferences
  // ==========================================

  /// Helper para guardar string en SharedPreferences
  Future<void> _saveString(String key, String value) async {
    await _persistence.setString(key, value);
  }

  /// Helper para obtener string de SharedPreferences
  Future<String?> _getString(String key) async {
    return await _persistence.getString(key);
  }

  /// Helper para remover clave de SharedPreferences
  Future<void> _remove(String key) async {
    await _persistence.remove(key);
  }
}
