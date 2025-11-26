import 'package:flutter/material.dart';

/// Provider para gestionar el estado de navegación del HomePage
///
/// **Responsabilidad:** Solo gestionar el índice de navegación entre páginas
/// - Maneja el estado de la página actual (Ventas, Catálogo o Analíticas)
/// - Proporciona métodos para cambiar entre páginas
/// - No contiene lógica de negocio
///
/// **Uso:**
/// ```dart
/// final homeProvider = Provider.of<HomeProvider>(context);
/// homeProvider.navigateToSell(); // Ir a página de ventas
/// homeProvider.navigateToCatalogue(); // Ir a página de catálogo
/// homeProvider.navigateToAnalytics(); // Ir a página de analíticas
/// ```
class HomeProvider extends ChangeNotifier {
  // --- Estado de navegación ---
  int _currentPageIndex = 0;

  // --- Getters ---
  int get currentPageIndex => _currentPageIndex;

  /// Indica si la página actual es la de ventas
  bool get isSellPage => _currentPageIndex == 0;

  /// Indica si la página actual es la de catálogo
  bool get isCataloguePage => _currentPageIndex == 1;

  /// Indica si la página actual es la de analíticas
  bool get isAnalyticsPage => _currentPageIndex == 2;

  // --- Métodos públicos ---

  /// Cambia la página actual según el índice proporcionado
  /// @param index Índice de la página (0: Ventas, 1: Catálogo, 2: Analíticas)
  void setPageIndex(int index) {
    if (_currentPageIndex != index && index >= 0 && index <= 2) {
      _currentPageIndex = index;
      notifyListeners();
    }
  }

  /// Navega a la página de ventas
  void navigateToSell() {
    setPageIndex(0);
  }

  /// Navega a la página de catálogo
  void navigateToCatalogue() {
    setPageIndex(1);
  }

  /// Navega a la página de analíticas
  void navigateToAnalytics() {
    setPageIndex(2);
  }

  /// Resetea el estado del provider a sus valores iniciales
  void reset() {
    _currentPageIndex = 0;
    notifyListeners();
  }
}
