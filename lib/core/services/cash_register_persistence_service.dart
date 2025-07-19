import 'package:shared_preferences/shared_preferences.dart';
import '../utils/shared_prefs_keys.dart';

/// Servicio para gestionar la persistencia local de cajas registradoras
///
/// Maneja:
/// - Persistencia del ID de caja registradora seleccionada
/// - Limpieza de preferencias cuando se cierra una caja
class CashRegisterPersistenceService {
  static CashRegisterPersistenceService? _instance;
  static CashRegisterPersistenceService get instance {
    _instance ??= CashRegisterPersistenceService._();
    return _instance!;
  }

  CashRegisterPersistenceService._();

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
}
