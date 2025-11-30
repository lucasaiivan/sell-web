import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';
import 'package:sellweb/core/services/storage/app_data_persistence_service.dart';
import 'package:sellweb/core/services/theme/theme_service.dart';

/// Provider para gestionar el tema de la aplicación
///
/// **Responsabilidad:** Coordinar UI y servicios de tema
/// - Delega lógica de tema a ThemeService
/// - Persiste configuración con AppDataPersistenceService
/// - No contiene lógica de negocio, solo coordinación
///
/// **Memory Safety:**
/// - Listeners dispuestos en [dispose] para evitar leaks
/// - Referencias guardadas para poder removerlas
///
/// **Uso:**
/// ```dart
/// final themeProvider = Provider.of<ThemeDataAppProvider>(context);
/// themeProvider.toggleTheme(); // Alternar entre claro/oscuro
/// themeProvider.changeSeedColor(Colors.blue); // Cambiar color semilla
/// ```
@injectable
class ThemeDataAppProvider extends ChangeNotifier {
  final ThemeService _themeService;
  final AppDataPersistenceService _persistenceService;

  // Referencias a listeners para poder removerlos
  late final VoidCallback _themeModeListener;
  late final VoidCallback _seedColorListener;

  ThemeDataAppProvider(this._themeService, this._persistenceService) {
    _loadTheme();
    _loadSeedColor();

    // Guardar referencias a listeners
    _themeModeListener = () => notifyListeners();
    _seedColorListener = () => notifyListeners();

    // Registrar listeners
    _themeService.themeModeNotifier.addListener(_themeModeListener);
    _themeService.seedColorNotifier.addListener(_seedColorListener);
  }

  @override
  void dispose() {
    // CRÍTICO: Remover listeners para evitar memory leaks
    _themeService.themeModeNotifier.removeListener(_themeModeListener);
    _themeService.seedColorNotifier.removeListener(_seedColorListener);
    super.dispose();
  }

  ThemeMode get themeMode => _themeService.themeMode;
  Color get seedColor => _themeService.seedColor;
  ThemeData get lightTheme => _themeService.lightTheme;
  ThemeData get darkTheme => _themeService.darkTheme;

  /// Cambia entre modo claro y oscuro
  void toggleTheme() {
    final newMode = _themeService.themeMode == ThemeMode.light
        ? ThemeMode.dark
        : ThemeMode.light;
    _themeService.setThemeMode(newMode);
    _saveTheme();
  }

  /// Cambia el color semilla del tema
  void changeSeedColor(Color color) {
    _themeService.setSeedColor(color);
    _saveSeedColor();
  }

  /// Carga el tema guardado
  Future<void> _loadTheme() async {
    final mode = await _persistenceService.getThemeMode();
    if (mode == 'dark') {
      _themeService.setThemeMode(ThemeMode.dark);
    } else {
      _themeService.setThemeMode(ThemeMode.light);
    }
  }

  /// Carga el color semilla guardado
  Future<void> _loadSeedColor() async {
    final colorValue = await _persistenceService.getSeedColor();
    if (colorValue != null) {
      _themeService.setSeedColor(Color(colorValue));
    }
  }

  /// Guarda el tema seleccionado
  Future<void> _saveTheme() async {
    final themeValue =
        _themeService.themeMode == ThemeMode.dark ? 'dark' : 'light';
    await _persistenceService.saveThemeMode(themeValue);
  }

  /// Guarda el color semilla seleccionado
  Future<void> _saveSeedColor() async {
    await _persistenceService.saveSeedColor(_themeService.seedColor.toARGB32());
  }
}
