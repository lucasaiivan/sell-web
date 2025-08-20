import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/shared_prefs_keys.dart';

/// Servicio centralizado para gestionar la persistencia local de datos de configuración de la aplicación
///
/// Este servicio maneja todo el almacenamiento local usando SharedPreferences para:
/// - Persistencia de cuenta seleccionada
/// - Persistencia de caja registradora seleccionada
/// - Persistencia del estado del tema de la aplicación
/// - Persistencia de tickets (actual y último vendido)
/// - Persistencia de configuraciones de impresión
/// - Otras configuraciones locales de la aplicación
class AppDataPersistenceService {
  static AppDataPersistenceService? _instance;
  static AppDataPersistenceService get instance {
    _instance ??= AppDataPersistenceService._();
    return _instance!;
  }

  AppDataPersistenceService._();

  // ==========================================
  // GESTIÓN DE CUENTAS
  // ==========================================

  /// Guarda el ID de la cuenta seleccionada
  Future<void> saveSelectedAccountId(String accountId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(SharedPrefsKeys.selectedAccountId, accountId);
    } catch (e) {
      rethrow;
    }
  }

  /// Obtiene el ID de la cuenta seleccionada
  Future<String?> getSelectedAccountId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(SharedPrefsKeys.selectedAccountId);
    } catch (e) {
      return null;
    }
  }

  /// Elimina el ID de la cuenta seleccionada
  Future<void> clearSelectedAccountId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(SharedPrefsKeys.selectedAccountId);
    } catch (e) {
      rethrow;
    }
  }

  /// Verifica si hay una cuenta guardada
  Future<bool> hasSelectedAccount() async {
    final accountId = await getSelectedAccountId();
    return accountId != null && accountId.isNotEmpty;
  }

  // ==========================================
  // GESTIÓN DE CAJAS REGISTRADORAS
  // ==========================================

  /// Guarda el ID de la caja registradora seleccionada
  Future<void> saveSelectedCashRegisterId(String cashRegisterId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          SharedPrefsKeys.selectedCashRegisterId, cashRegisterId);
    } catch (e) {
      rethrow;
    }
  }

  /// Obtiene el ID de la caja registradora seleccionada
  Future<String?> getSelectedCashRegisterId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(SharedPrefsKeys.selectedCashRegisterId);
    } catch (e) {
      return null;
    }
  }

  /// Elimina el ID de la caja registradora seleccionada
  Future<void> clearSelectedCashRegisterId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(SharedPrefsKeys.selectedCashRegisterId);
    } catch (e) {
      rethrow;
    }
  }

  /// Verifica si hay una caja registradora guardada
  Future<bool> hasSelectedCashRegister() async {
    final cashRegisterId = await getSelectedCashRegisterId();
    return cashRegisterId != null && cashRegisterId.isNotEmpty;
  }

  // ==========================================
  // GESTIÓN DE TEMA DE LA APLICACIÓN
  // ==========================================

  /// Guarda el modo del tema de la aplicación
  Future<void> saveThemeMode(String themeMode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(SharedPrefsKeys.themeMode, themeMode);
    } catch (e) {
      rethrow;
    }
  }

  /// Obtiene el modo del tema de la aplicación
  Future<String?> getThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(SharedPrefsKeys.themeMode);
    } catch (e) {
      return null;
    }
  }

  /// Elimina la configuración del tema
  Future<void> clearThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(SharedPrefsKeys.themeMode);
    } catch (e) {
      rethrow;
    }
  }

  /// Guarda el color semilla del tema
  Future<void> saveSeedColor(int colorValue) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(SharedPrefsKeys.seedColor, colorValue);
    } catch (e) {
      rethrow;
    }
  }

  /// Obtiene el color semilla del tema
  Future<int?> getSeedColor() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(SharedPrefsKeys.seedColor);
    } catch (e) {
      return null;
    }
  }

  /// Elimina la configuración del color semilla
  Future<void> clearSeedColor() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(SharedPrefsKeys.seedColor);
    } catch (e) {
      rethrow;
    }
  }

  // ==========================================
  // GESTIÓN DE TICKETS
  // ==========================================

  /// Guarda el ticket actual en progreso
  Future<void> saveCurrentTicket(String ticketJson) async { 
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(SharedPrefsKeys.currentTicket, ticketJson);
    } catch (e) {
      rethrow;
    }
  }

  /// Obtiene el ticket actual en progreso
  Future<String?> getCurrentTicket() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(SharedPrefsKeys.currentTicket);
    } catch (e) {
      return null;
    }
  }

  /// Elimina el ticket actual
  Future<void> clearCurrentTicket() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(SharedPrefsKeys.currentTicket);
    } catch (e) {
      rethrow;
    }
  }

  /// Guarda el último ticket vendido
  Future<void> saveLastSoldTicket(String ticketJson) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(SharedPrefsKeys.lastSoldTicket, ticketJson);
    } catch (e) {
      rethrow;
    }
  }

  /// Obtiene el último ticket vendido
  Future<String?> getLastSoldTicket() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(SharedPrefsKeys.lastSoldTicket);
    } catch (e) {
      return null;
    }
  }

  /// Elimina el último ticket vendido
  Future<void> clearLastSoldTicket() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(SharedPrefsKeys.lastSoldTicket);
    } catch (e) {
      rethrow;
    }
  }

  // ==========================================
  // CONFIGURACIONES DE IMPRESIÓN
  // ==========================================

  /// Guarda el estado de si se debe imprimir ticket automáticamente
  Future<void> saveShouldPrintTicket(bool shouldPrint) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(SharedPrefsKeys.shouldPrintTicket, shouldPrint);
    } catch (e) {
      rethrow;
    }
  }

  /// Obtiene el estado de si se debe imprimir ticket automáticamente
  Future<bool> getShouldPrintTicket() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(SharedPrefsKeys.shouldPrintTicket) ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Guarda el nombre de la impresora térmica
  Future<void> savePrinterName(String printerName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(SharedPrefsKeys.printerName, printerName);
    } catch (e) {
      rethrow;
    }
  }

  /// Obtiene el nombre de la impresora térmica
  Future<String?> getPrinterName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(SharedPrefsKeys.printerName);
    } catch (e) {
      return null;
    }
  }

  /// Guarda el vendor ID de la impresora térmica
  Future<void> savePrinterVendorId(String vendorId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(SharedPrefsKeys.printerVendorId, vendorId);
    } catch (e) {
      rethrow;
    }
  }

  /// Obtiene el vendor ID de la impresora térmica
  Future<String?> getPrinterVendorId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(SharedPrefsKeys.printerVendorId);
    } catch (e) {
      return null;
    }
  }

  /// Guarda el product ID de la impresora térmica
  Future<void> savePrinterProductId(String productId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(SharedPrefsKeys.printerProductId, productId);
    } catch (e) {
      rethrow;
    }
  }

  /// Obtiene el product ID de la impresora térmica
  Future<String?> getPrinterProductId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(SharedPrefsKeys.printerProductId);
    } catch (e) {
      return null;
    }
  }

  /// Elimina todas las configuraciones de impresora
  Future<void> clearPrinterSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await Future.wait([
        prefs.remove(SharedPrefsKeys.printerName),
        prefs.remove(SharedPrefsKeys.printerVendorId),
        prefs.remove(SharedPrefsKeys.printerProductId),
      ]);
    } catch (e) {
      rethrow;
    }
  }

  // ==========================================
  // OPERACIONES GENERALES
  // ==========================================

  /// Limpia todas las configuraciones almacenadas (útil para logout completo)
  Future<void> clearAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } catch (e) {
      rethrow;
    }
  }

  /// Limpia solo los datos de sesión (mantiene configuraciones generales como tema)
  Future<void> clearSessionData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await Future.wait([
        prefs.remove(SharedPrefsKeys.selectedAccountId),
        prefs.remove(SharedPrefsKeys.selectedCashRegisterId),
        prefs.remove(SharedPrefsKeys.currentTicket),
        prefs.remove(SharedPrefsKeys.lastSoldTicket),
      ]);
    } catch (e) {
      rethrow;
    }
  }

  /// Obtiene todas las claves almacenadas (útil para debugging)
  Future<Set<String>> getAllKeys() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getKeys();
    } catch (e) {
      return <String>{};
    }
  }

  /// Verifica si existe una clave específica
  Future<bool> containsKey(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(key);
    } catch (e) {
      return false;
    }
  }
}
