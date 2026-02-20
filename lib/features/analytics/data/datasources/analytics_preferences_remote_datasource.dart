import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart';
import 'package:sellweb/core/services/database/firestore_paths.dart';
import 'package:sellweb/core/services/database/i_firestore_datasource.dart';

/// Modelo de preferencias de analíticas para Firestore
///
/// **Estructura del documento:**
/// ```json
/// {
///   "visibleCards": ["billing", "profit", "sales"],
///   "cardOrder": ["billing", "profit", "sales", "products"],
///   "lastUpdated": Timestamp,
///   "version": 1
/// }
/// ```
class AnalyticsPreferencesData {
  final List<String> visibleCards;
  final List<String> cardOrder;
  final DateTime? lastUpdated;
  final int version;

  const AnalyticsPreferencesData({
    this.visibleCards = const [],
    this.cardOrder = const [],
    this.lastUpdated,
    this.version = 1,
  });

  factory AnalyticsPreferencesData.fromMap(Map<String, dynamic> map) {
    return AnalyticsPreferencesData(
      visibleCards: List<String>.from(map['visibleCards'] ?? []),
      cardOrder: List<String>.from(map['cardOrder'] ?? []),
      lastUpdated: (map['lastUpdated'] as Timestamp?)?.toDate(),
      version: map['version'] ?? 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'visibleCards': visibleCards,
      'cardOrder': cardOrder,
      'lastUpdated': FieldValue.serverTimestamp(),
      'version': version,
    };
  }

  AnalyticsPreferencesData copyWith({
    List<String>? visibleCards,
    List<String>? cardOrder,
    DateTime? lastUpdated,
    int? version,
  }) {
    return AnalyticsPreferencesData(
      visibleCards: visibleCards ?? this.visibleCards,
      cardOrder: cardOrder ?? this.cardOrder,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      version: version ?? this.version,
    );
  }

  /// Verifica si las preferencias están vacías
  bool get isEmpty => visibleCards.isEmpty && cardOrder.isEmpty;

  /// Verifica si las preferencias tienen datos
  bool get isNotEmpty => !isEmpty;
}

/// DataSource remoto para preferencias de analíticas
///
/// **Responsabilidad:**
/// - Leer/escribir preferencias de tarjetas desde Firestore
/// - Manejar sincronización con la nube
/// - Proporcionar datos asociados a la cuenta del comercio
///
/// **Ubicación en Firestore:**
/// `/ACCOUNTS/{accountId}/SETTINGS/analytics_preferences`
///
/// **Estrategia:**
/// - Fuente de verdad: Firestore
/// - Fallback: Datos locales (gestionado por el servicio)
/// - Merge: Usa setDocument con merge:true para actualizaciones parciales
@lazySingleton
class AnalyticsPreferencesRemoteDataSource {
  final IFirestoreDataSource _dataSource;

  AnalyticsPreferencesRemoteDataSource(this._dataSource);

  /// Carga las preferencias de analíticas desde Firestore
  ///
  /// **Retorna:**
  /// - `AnalyticsPreferencesData`: Datos de preferencias si existen
  /// - `null`: Si no hay preferencias guardadas en la nube
  ///
  /// **Errores:**
  /// - Lanza excepción si hay error de red (el llamador debe manejar)
  Future<AnalyticsPreferencesData?> loadPreferences(String accountId) async {
    if (accountId.isEmpty) {
      throw ArgumentError('accountId no puede estar vacío');
    }

    final path = FirestorePaths.analyticsPreferences(accountId);
    final docRef = _dataSource.document(path);
    final snapshot = await docRef.get();

    if (!snapshot.exists || snapshot.data() == null) {
      return null;
    }

    return AnalyticsPreferencesData.fromMap(snapshot.data()!);
  }

  /// Guarda las preferencias de analíticas en Firestore
  ///
  /// **Comportamiento:**
  /// - Crea el documento si no existe
  /// - Actualiza campos existentes (merge: true)
  /// - Agrega timestamp de última actualización
  ///
  /// **Parámetros:**
  /// - `accountId`: ID de la cuenta del comercio
  /// - `preferences`: Datos de preferencias a guardar
  Future<void> savePreferences(
    String accountId,
    AnalyticsPreferencesData preferences,
  ) async {
    if (accountId.isEmpty) {
      throw ArgumentError('accountId no puede estar vacío');
    }

    final path = FirestorePaths.analyticsPreferences(accountId);
    await _dataSource.setDocument(
      path,
      preferences.toMap(),
      merge: true,
    );
  }

  /// Guarda solo las tarjetas visibles
  ///
  /// Método conveniente para actualizar únicamente la lista de tarjetas visibles
  Future<void> saveVisibleCards(
    String accountId,
    List<String> cardIds,
  ) async {
    if (accountId.isEmpty) {
      throw ArgumentError('accountId no puede estar vacío');
    }

    final path = FirestorePaths.analyticsPreferences(accountId);
    await _dataSource.setDocument(
      path,
      {
        'visibleCards': cardIds,
        'lastUpdated': FieldValue.serverTimestamp(),
      },
      merge: true,
    );
  }

  /// Guarda solo el orden de tarjetas
  ///
  /// Método conveniente para actualizar únicamente el orden
  Future<void> saveCardOrder(
    String accountId,
    List<String> cardIds,
  ) async {
    if (accountId.isEmpty) {
      throw ArgumentError('accountId no puede estar vacío');
    }

    final path = FirestorePaths.analyticsPreferences(accountId);
    await _dataSource.setDocument(
      path,
      {
        'cardOrder': cardIds,
        'lastUpdated': FieldValue.serverTimestamp(),
      },
      merge: true,
    );
  }

  /// Elimina las preferencias de analíticas
  ///
  /// **Uso:** Principalmente para limpieza o reset
  Future<void> deletePreferences(String accountId) async {
    if (accountId.isEmpty) {
      throw ArgumentError('accountId no puede estar vacío');
    }

    final path = FirestorePaths.analyticsPreferences(accountId);
    await _dataSource.deleteDocument(path);
  }

  /// Escucha cambios en las preferencias en tiempo real
  ///
  /// **Uso:** Para sincronización entre dispositivos
  /// **Retorna:** Stream de preferencias que emite cada vez que hay cambios
  Stream<AnalyticsPreferencesData?> streamPreferences(String accountId) {
    if (accountId.isEmpty) {
      return Stream.value(null);
    }

    final path = FirestorePaths.analyticsPreferences(accountId);
    final docRef = _dataSource.document(path);

    return docRef.snapshots().map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) {
        return null;
      }
      return AnalyticsPreferencesData.fromMap(snapshot.data()!);
    });
  }
}
