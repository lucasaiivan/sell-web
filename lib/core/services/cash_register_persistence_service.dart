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
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        SharedPrefsKeys.selectedCashRegisterId, cashRegisterId);
  }

  /// Obtiene el ID de la caja registradora seleccionada
  Future<String?> getSelectedCashRegisterId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(SharedPrefsKeys.selectedCashRegisterId);
  }

  /// Elimina el ID de la caja registradora seleccionada
  Future<void> clearSelectedCashRegisterId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(SharedPrefsKeys.selectedCashRegisterId);
  }

  /// Verifica si hay una caja registradora guardada
  Future<bool> hasSelectedCashRegister() async {
    final cashRegisterId = await getSelectedCashRegisterId();
    return cashRegisterId != null && cashRegisterId.isNotEmpty;
  }
}
