import 'package:shared_preferences/shared_preferences.dart';

/// Utilidad de desarrollo para resetear todos los showcases
/// USAR SOLO EN DESARROLLO - Eliminar antes de producción
class ShowcaseDevUtils {
  static Future<void> resetAllShowcases() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Showcases del sistema
    await prefs.remove('guest_mode_showcase_shown');
    await prefs.remove('drawer_showcase_shown');
    await prefs.remove('sales_page_showcase_shown');
    await prefs.remove('sales_page_showcase_part2_shown');
    await prefs.remove('sales_page_showcase_part3_shown');
    await prefs.remove('catalogue_page_showcase_shown');
    
    print('✅ Todos los showcases han sido reseteados');
  }
  
  static Future<void> resetShowcase(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
    print('✅ Showcase "$key" reseteado');
  }
}
