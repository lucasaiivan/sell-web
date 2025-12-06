import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants/shared_prefs_keys.dart';

/// Servicio centralizado para gestionar la persistencia local de datos de configuración de la aplicación
///
/// Este servicio maneja todo el almacenamiento local usando SharedPreferences para:
/// - Persistencia de cuenta seleccionada
/// - Persistencia de caja registradora seleccionada
/// - Persistencia del estado del tema de la aplicación
/// - Persistencia de tickets (actual y último vendido)
/// - Persistencia de configuraciones de impresión
/// - Otras configuraciones locales de la aplicación
@lazySingleton
class AppDataPersistenceService {
  final SharedPreferences _prefs;

  AppDataPersistenceService(this._prefs);

  // ==========================================
  // GESTIÓN DE CUENTAS
  // ==========================================

  /// Guarda el ID de la cuenta seleccionada
  Future<void> saveSelectedAccountId(String accountId) async {
    try {
      await _prefs.setString(SharedPrefsKeys.selectedAccountId, accountId);
    } catch (e) {
      rethrow;
    }
  }

  /// Obtiene el ID de la cuenta seleccionada
  Future<String?> getSelectedAccountId() async {
    try {
      return _prefs.getString(SharedPrefsKeys.selectedAccountId);
    } catch (e) {
      return null;
    }
  }

  /// Elimina el ID de la cuenta seleccionada
  Future<void> clearSelectedAccountId() async {
    try {
      await _prefs.remove(SharedPrefsKeys.selectedAccountId);
    } catch (e) {
      rethrow;
    }
  }

  /// Verifica si hay una cuenta guardada
  Future<bool> hasSelectedAccount() async {
    final accountId = await getSelectedAccountId();
    return accountId != null && accountId.isNotEmpty;
  }

  /// Guarda el AdminProfile actual en formato JSON
  Future<void> saveCurrentAdminProfile(String adminProfileJson) async {
    try {
      await _prefs.setString(
          SharedPrefsKeys.currentAdminProfile, adminProfileJson);
    } catch (e) {
      rethrow;
    }
  }

  /// Obtiene el AdminProfile actual desde persistencia
  Future<String?> getCurrentAdminProfile() async {
    try {
      return _prefs.getString(SharedPrefsKeys.currentAdminProfile);
    } catch (e) {
      return null;
    }
  }

  /// Elimina el AdminProfile guardado
  Future<void> clearCurrentAdminProfile() async {
    try {
      await _prefs.remove(SharedPrefsKeys.currentAdminProfile);
    } catch (e) {
      rethrow;
    }
  }

  // ==========================================
  // GESTIÓN DE CAJAS REGISTRADORAS
  // ==========================================

  /// Guarda el ID de la caja registradora seleccionada
  Future<void> saveSelectedCashRegisterId(String cashRegisterId) async {
    try {
      await _prefs.setString(
          SharedPrefsKeys.selectedCashRegisterId, cashRegisterId);
    } catch (e) {
      rethrow;
    }
  }

  /// Obtiene el ID de la caja registradora seleccionada
  Future<String?> getSelectedCashRegisterId() async {
    try {
      return _prefs.getString(SharedPrefsKeys.selectedCashRegisterId);
    } catch (e) {
      return null;
    }
  }

  /// Elimina el ID de la caja registradora seleccionada
  Future<void> clearSelectedCashRegisterId() async {
    try {
      await _prefs.remove(SharedPrefsKeys.selectedCashRegisterId);
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
      await _prefs.setString(SharedPrefsKeys.themeMode, themeMode);
    } catch (e) {
      rethrow;
    }
  }

  /// Obtiene el modo del tema de la aplicación
  Future<String?> getThemeMode() async {
    try {
      return _prefs.getString(SharedPrefsKeys.themeMode);
    } catch (e) {
      return null;
    }
  }

  /// Elimina la configuración del tema
  Future<void> clearThemeMode() async {
    try {
      // Using injected _prefs
      await _prefs.remove(SharedPrefsKeys.themeMode);
    } catch (e) {
      rethrow;
    }
  }

  /// Guarda el color semilla del tema
  Future<void> saveSeedColor(int colorValue) async {
    try {
      // Using injected _prefs
      await _prefs.setInt(SharedPrefsKeys.seedColor, colorValue);
    } catch (e) {
      rethrow;
    }
  }

  /// Obtiene el color semilla del tema
  Future<int?> getSeedColor() async {
    try {
      // Using injected _prefs
      return _prefs.getInt(SharedPrefsKeys.seedColor);
    } catch (e) {
      return null;
    }
  }

  /// Elimina la configuración del color semilla
  Future<void> clearSeedColor() async {
    try {
      // Using injected _prefs
      await _prefs.remove(SharedPrefsKeys.seedColor);
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
      // Using injected _prefs
      await _prefs.setString(SharedPrefsKeys.currentTicket, ticketJson);
    } catch (e) {
      rethrow;
    }
  }

  /// Obtiene el ticket actual en progreso
  Future<String?> getCurrentTicket() async {
    try {
      // Using injected _prefs
      return _prefs.getString(SharedPrefsKeys.currentTicket);
    } catch (e) {
      return null;
    }
  }

  /// Elimina el ticket actual
  Future<void> clearCurrentTicket() async {
    try {
      // Using injected _prefs
      await _prefs.remove(SharedPrefsKeys.currentTicket);
    } catch (e) {
      rethrow;
    }
  }

  /// Guarda el último ticket vendido
  Future<void> saveLastSoldTicket(String ticketJson) async {
    try {
      // Using injected _prefs
      await _prefs.setString(SharedPrefsKeys.lastSoldTicket, ticketJson);
    } catch (e) {
      rethrow;
    }
  }

  /// Obtiene el último ticket vendido
  Future<String?> getLastSoldTicket() async {
    try {
      // Using injected _prefs
      return _prefs.getString(SharedPrefsKeys.lastSoldTicket);
    } catch (e) {
      return null;
    }
  }

  /// Elimina el último ticket vendido
  Future<void> clearLastSoldTicket() async {
    try {
      // Using injected _prefs
      await _prefs.remove(SharedPrefsKeys.lastSoldTicket);
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
      // Using injected _prefs
      await _prefs.setBool(SharedPrefsKeys.shouldPrintTicket, shouldPrint);
    } catch (e) {
      rethrow;
    }
  }

  /// Obtiene el estado de si se debe imprimir ticket automáticamente
  Future<bool> getShouldPrintTicket() async {
    try {
      // Using injected _prefs
      return _prefs.getBool(SharedPrefsKeys.shouldPrintTicket) ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Guarda el nombre de la impresora térmica
  Future<void> savePrinterName(String printerName) async {
    try {
      // Using injected _prefs
      await _prefs.setString(SharedPrefsKeys.printerName, printerName);
    } catch (e) {
      rethrow;
    }
  }

  /// Obtiene el nombre de la impresora térmica
  Future<String?> getPrinterName() async {
    try {
      // Using injected _prefs
      return _prefs.getString(SharedPrefsKeys.printerName);
    } catch (e) {
      return null;
    }
  }

  /// Guarda el vendor ID de la impresora térmica
  Future<void> savePrinterVendorId(String vendorId) async {
    try {
      // Using injected _prefs
      await _prefs.setString(SharedPrefsKeys.printerVendorId, vendorId);
    } catch (e) {
      rethrow;
    }
  }

  /// Obtiene el vendor ID de la impresora térmica
  Future<String?> getPrinterVendorId() async {
    try {
      // Using injected _prefs
      return _prefs.getString(SharedPrefsKeys.printerVendorId);
    } catch (e) {
      return null;
    }
  }

  /// Guarda el product ID de la impresora térmica
  Future<void> savePrinterProductId(String productId) async {
    try {
      // Using injected _prefs
      await _prefs.setString(SharedPrefsKeys.printerProductId, productId);
    } catch (e) {
      rethrow;
    }
  }

  /// Obtiene el product ID de la impresora térmica
  Future<String?> getPrinterProductId() async {
    try {
      // Using injected _prefs
      return _prefs.getString(SharedPrefsKeys.printerProductId);
    } catch (e) {
      return null;
    }
  }

  /// Guarda el host del servidor de impresión
  Future<void> savePrinterServerHost(String host) async {
    try {
      await _prefs.setString(SharedPrefsKeys.printerHost, host);
    } catch (e) {
      rethrow;
    }
  }

  /// Obtiene el host del servidor de impresión
  Future<String?> getPrinterServerHost() async {
    try {
      return _prefs.getString(SharedPrefsKeys.printerHost);
    } catch (e) {
      return null;
    }
  }

  /// Guarda el puerto del servidor de impresión
  Future<void> savePrinterServerPort(int port) async {
    try {
      await _prefs.setInt(SharedPrefsKeys.printerPort, port);
    } catch (e) {
      rethrow;
    }
  }

  /// Obtiene el puerto del servidor de impresión
  Future<int?> getPrinterServerPort() async {
    try {
      return _prefs.getInt(SharedPrefsKeys.printerPort);
    } catch (e) {
      return null;
    }
  }

  /// Guarda la configuración JSON de la impresora
  Future<void> savePrinterConfig(String configJson) async {
    try {
      await _prefs.setString(SharedPrefsKeys.printerConfig, configJson);
    } catch (e) {
      rethrow;
    }
  }

  /// Obtiene la configuración JSON de la impresora
  Future<String?> getPrinterConfig() async {
    try {
      return _prefs.getString(SharedPrefsKeys.printerConfig);
    } catch (e) {
      return null;
    }
  }

  /// Elimina todas las configuraciones de impresora
  Future<void> clearPrinterSettings() async {
    try {
      // Using injected _prefs
      await Future.wait([
        _prefs.remove(SharedPrefsKeys.printerName),
        _prefs.remove(SharedPrefsKeys.printerVendorId),
        _prefs.remove(SharedPrefsKeys.printerProductId),
        _prefs.remove(SharedPrefsKeys.printerHost),
        _prefs.remove(SharedPrefsKeys.printerPort),
        _prefs.remove(SharedPrefsKeys.printerConfig),
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
      // Using injected _prefs
      await _prefs.clear();
    } catch (e) {
      rethrow;
    }
  }

  /// Limpia solo los datos de sesión (mantiene configuraciones generales como tema)
  Future<void> clearSessionData() async {
    try {
      // Using injected _prefs
      await Future.wait([
        _prefs.remove(SharedPrefsKeys.selectedAccountId),
        _prefs.remove(SharedPrefsKeys.currentAdminProfile),
        _prefs.remove(SharedPrefsKeys.selectedCashRegisterId),
        _prefs.remove(SharedPrefsKeys.currentTicket),
        _prefs.remove(SharedPrefsKeys.lastSoldTicket),
      ]);
    } catch (e) {
      rethrow;
    }
  }

  /// Obtiene todas las claves almacenadas (útil para debugging)
  Future<Set<String>> getAllKeys() async {
    try {
      // Using injected _prefs
      return _prefs.getKeys();
    } catch (e) {
      return <String>{};
    }
  }

  /// Verifica si existe una clave específica
  Future<bool> containsKey(String key) async {
    try {
      // Using injected _prefs
      return _prefs.containsKey(key);
    } catch (e) {
      return false;
    }
  }

  // ==========================================
  // MÉTODOS GENÉRICOS para PERSONALIZACIÓN
  // ==========================================

  /// Guarda un string con una clave personalizada
  ///
  /// **Uso:** Para datos que no tienen un método específico
  /// **Ejemplo:** Preferencias de features, configuraciones personalizadas
  Future<void> setString(String key, String value) async {
    try {
      await _prefs.setString(key, value);
    } catch (e) {
      rethrow;
    }
  }

  /// Obtiene un string con una clave personalizada
  Future<String?> getString(String key) async {
    try {
      return _prefs.getString(key);
    } catch (e) {
      return null;
    }
  }

  /// Guarda un int con una clave personalizada
  Future<void> setInt(String key, int value) async {
    try {
      await _prefs.setInt(key, value);
    } catch (e) {
      rethrow;
    }
  }

  /// Obtiene un int con una clave personalizada
  Future<int?> getInt(String key) async {
    try {
      return _prefs.getInt(key);
    } catch (e) {
      return null;
    }
  }

  /// Guarda un bool con una clave personalizada
  Future<void> setBool(String key, bool value) async {
    try {
      await _prefs.setBool(key, value);
    } catch (e) {
      rethrow;
    }
  }

  /// Obtiene un bool con una clave personalizada
  Future<bool?> getBool(String key) async {
    try {
      return _prefs.getBool(key);
    } catch (e) {
      return null;
    }
  }

  /// Elimina un valor con una clave personalizada
  Future<void> remove(String key) async {
    try {
      await _prefs.remove(key);
    } catch (e) {
      rethrow;
    }
  }
}
