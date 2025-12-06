import 'dart:convert';
import 'package:injectable/injectable.dart';
import 'package:sellweb/core/services/storage/app_data_persistence_service.dart';

/// Servicio de persistencia de preferencias de analíticas
///
/// **Responsabilidad:**
/// - Guardar y cargar tarjetas visibles por usuario
/// - Guardar y cargar el orden de las tarjetas
/// - Gestionar preferencias específicas de analytics
///
/// **Persistencia:**
/// - Usa `AppDataPersistenceService` (SharedPreferences)
/// - Las preferencias son específicas por accountId
/// - Formato: JSON array de IDs de tarjetas
@injectable
class AnalyticsPreferencesService {
  final AppDataPersistenceService _persistence;

  AnalyticsPreferencesService(this._persistence);

  /// Clave base para preferencias de analytics
  static const String _keyPrefix = 'analytics_';

  /// Genera la clave para tarjetas visibles de un usuario
  String _visibleCardsKey(String accountId) =>
      '${_keyPrefix}visible_cards_$accountId';

  /// Genera la clave para el orden de tarjetas de un usuario
  String _cardOrderKey(String accountId) =>
      '${_keyPrefix}card_order_$accountId';

  // ==========================================
  // TARJETAS VISIBLES
  // ==========================================

  /// Guarda las tarjetas visibles para un usuario
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
    try {
      if (accountId.isEmpty) {
        throw ArgumentError('accountId no puede estar vacío');
      }

      final key = _visibleCardsKey(accountId);
      final jsonString = jsonEncode(cardIds);

      await _saveString(key, jsonString);
    } catch (e) {
      rethrow;
    }
  }

  /// Carga las tarjetas visibles para un usuario
  ///
  /// **Retorna:**
  /// - `List<String>?`: Lista de IDs si existen preferencias guardadas
  /// - `null`: Si es la primera vez del usuario (sin preferencias)
  ///
  /// **Ejemplo:**
  /// ```dart
  /// final cards = await service.loadVisibleCards('user123');
  /// if (cards == null) {
  ///   // Primera vez, usar defaults
  /// }
  /// ```
  Future<List<String>?> loadVisibleCards(String accountId) async {
    try {
      if (accountId.isEmpty) {
        throw ArgumentError('accountId no puede estar vacío');
      }

      final key = _visibleCardsKey(accountId);
      final jsonString = await _getString(key);

      if (jsonString == null || jsonString.isEmpty) {
        return null;
      }

      final List<dynamic> decoded = jsonDecode(jsonString);
      return decoded.cast<String>();
    } catch (e) {
      // Si hay error al decodificar o cargar, retornar null
      return null;
    }
  }

  /// Limpia las preferencias de tarjetas visibles para un usuario
  Future<void> clearVisibleCards(String accountId) async {
    try {
      if (accountId.isEmpty) {
        throw ArgumentError('accountId no puede estar vacío');
      }

      final key = _visibleCardsKey(accountId);
      await _remove(key);
    } catch (e) {
      rethrow;
    }
  }

  // ==========================================
  // ORDEN DE TARJETAS
  // ==========================================

  /// Guarda el orden de las tarjetas para un usuario
  ///
  /// Este orden se usa para mantener la posición después de drag-and-drop
  ///
  /// **Parámetros:**
  /// - `accountId`: ID de la cuenta del usuario
  /// - `cardIds`: Lista ordenada de IDs de tarjetas
  Future<void> saveCardOrder(String accountId, List<String> cardIds) async {
    try {
      if (accountId.isEmpty) {
        throw ArgumentError('accountId no puede estar vacío');
      }

      final key = _cardOrderKey(accountId);
      final jsonString = jsonEncode(cardIds);

      await _saveString(key, jsonString);
    } catch (e) {
      rethrow;
    }
  }

  /// Carga el orden de las tarjetas para un usuario
  ///
  /// **Retorna:**
  /// - `List<String>?`: Lista ordenada de IDs si existe
  /// - `null`: Si no hay orden guardado
  Future<List<String>?> loadCardOrder(String accountId) async {
    try {
      if (accountId.isEmpty) {
        throw ArgumentError('accountId no puede estar vacío');
      }

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
  Future<void> clearCardOrder(String accountId) async {
    try {
      if (accountId.isEmpty) {
        throw ArgumentError('accountId no puede estar vacío');
      }

      final key = _cardOrderKey(accountId);
      await _remove(key);
    } catch (e) {
      rethrow;
    }
  }

  // ==========================================
  // OPERACIONES GENERALES
  // ==========================================

  /// Limpia todas las preferencias de analytics para un usuario
  Future<void> clearAllPreferences(String accountId) async {
    await Future.wait([
      clearVisibleCards(accountId),
      clearCardOrder(accountId),
    ]);
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
