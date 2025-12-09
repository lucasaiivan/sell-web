import 'package:shared_preferences/shared_preferences.dart';

/// Servicio para persistir el orden de las tarjetas de Analytics
///
/// **Responsabilidad:**
/// - Guardar el orden de las tarjetas por layout (mobile/tablet/desktop)
/// - Cargar el orden guardado
/// - Resetear al orden por defecto
class AnalyticsOrderService {
  static const String _keyPrefix = 'analytics_card_order_';

  /// Guarda el orden de las tarjetas para un layout específico
  ///
  /// [layoutType] puede ser: 'mobile', 'tablet', 'desktop'
  /// [orderedIndices] es la lista de índices en el orden actual
  static Future<void> saveOrder({
    required String layoutType,
    required List<int> orderedIndices,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_keyPrefix$layoutType';

    // Guardar como string separado por comas para eficiencia
    final orderString = orderedIndices.join(',');
    await prefs.setString(key, orderString);
  }

  /// Carga el orden de las tarjetas para un layout específico
  ///
  /// Retorna null si no hay orden guardado (usar orden por defecto)
  static Future<List<int>?> loadOrder({
    required String layoutType,
    required int expectedLength,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_keyPrefix$layoutType';

    final orderString = prefs.getString(key);
    if (orderString == null || orderString.isEmpty) {
      return null;
    }

    try {
      final indices = orderString.split(',').map(int.parse).toList();

      // Validar que la longitud coincide (por si cambiaron las tarjetas)
      if (indices.length != expectedLength) {
        // Orden inválido, resetear
        await resetOrder(layoutType: layoutType);
        return null;
      }

      // Validar que todos los índices son válidos
      final isValid = indices.every((i) => i >= 0 && i < expectedLength) &&
          indices.toSet().length == expectedLength; // Sin duplicados

      if (!isValid) {
        await resetOrder(layoutType: layoutType);
        return null;
      }

      return indices;
    } catch (e) {
      // Error parseando, resetear
      await resetOrder(layoutType: layoutType);
      return null;
    }
  }

  /// Resetea el orden al valor por defecto para un layout
  static Future<void> resetOrder({required String layoutType}) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_keyPrefix$layoutType';
    await prefs.remove(key);
  }

  /// Resetea el orden de todos los layouts
  static Future<void> resetAllOrders() async {
    await resetOrder(layoutType: 'mobile');
    await resetOrder(layoutType: 'tablet');
    await resetOrder(layoutType: 'desktop');
  }
}
