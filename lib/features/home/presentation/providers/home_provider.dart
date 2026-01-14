import 'package:flutter/material.dart';

/// Provider para gestionar el estado de navegación del HomePage
///
/// **Responsabilidad:** Solo gestionar el índice de navegación entre páginas
/// - Maneja el estado de la página actual (Ventas, Analíticas, Catálogo, Usuarios, Historial de Caja)
/// - Proporciona métodos para cambiar entre páginas
/// - No contiene lógica de negocio
///
/// **Uso:**
/// ```dart
/// final homeProvider = Provider.of<HomeProvider>(context);
/// homeProvider.navigateToSell(); // Ir a página de ventas
/// homeProvider.navigateToAnalytics(); // Ir a página de analíticas
/// homeProvider.navigateToCatalogue(); // Ir a página de catálogo
/// homeProvider.navigateToUsers(); // Ir a página de usuarios
/// homeProvider.navigateToHistoryCashRegister(); // Ir a página de historial de caja
/// ```
class HomeProvider extends ChangeNotifier {
  // --- Estado de navegación ---
  int _currentPageIndex = 0;

  // --- Getters ---
  int get currentPageIndex => _currentPageIndex;

  /// Indica si la página actual es la de ventas (index 0)
  bool get isSellPage => _currentPageIndex == 0;

  /// Indica si la página actual es la de analíticas (index 1)
  bool get isAnalyticsPage => _currentPageIndex == 1;

  /// Indica si la página actual es la de catálogo (index 2)
  bool get isCataloguePage => _currentPageIndex == 2;

  /// Indica si la página actual es la de usuarios (index 3)
  bool get isUsersPage => _currentPageIndex == 3;

  /// Indica si la página actual es la de historial de caja (index 4)
  bool get isHistoryCashRegisterPage => _currentPageIndex == 4;

  // --- Métodos públicos ---

  /// Cambia la página actual según el índice proporcionado
  /// @param index Índice de la página
  /// - 0: Ventas
  /// - 1: Analíticas
  /// - 2: Catálogo
  /// - 3: Usuarios
  /// - 4: Historial de Caja
  void setPageIndex(int index) {
    if (_currentPageIndex != index && index >= 0 && index <= 4) {
      _currentPageIndex = index;
      notifyListeners();
    }
  }

  /// Navega a la página de ventas (index 0)
  void navigateToSell() {
    setPageIndex(0);
  }

  /// Navega a la página de analíticas (index 1)
  void navigateToAnalytics() {
    setPageIndex(1);
  }

  /// Navega a la página de catálogo (index 2)
  void navigateToCatalogue() {
    setPageIndex(2);
  }

  /// Navega a la página de usuarios (index 3)
  void navigateToUsers() {
    setPageIndex(3);
  }

  /// Navega a la página de historial de caja (index 4)
  void navigateToHistoryCashRegister() {
    setPageIndex(4);
  }

  /// Resetea el estado del provider a sus valores iniciales
  void reset() {
    _currentPageIndex = 0;
    notifyListeners();
  }
}
