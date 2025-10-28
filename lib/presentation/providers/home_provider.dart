import 'package:flutter/material.dart';

/// Provider para gestionar el estado de navegación y UI del HomePage
/// Centraliza la lógica de navegación entre las pantallas principales
class HomeProvider extends ChangeNotifier {
  // --- Estado de navegación ---
  int _currentPageIndex = 0;

  // --- Getters ---
  int get currentPageIndex => _currentPageIndex;

  /// Indica si la página actual es la de ventas
  bool get isSellPage => _currentPageIndex == 0;

  /// Indica si la página actual es la de catálogo
  bool get isCataloguePage => _currentPageIndex == 1;

  // --- Métodos públicos ---

  /// Cambia la página actual según el índice proporcionado
  /// @param index Índice de la página (0: Ventas, 1: Catálogo)
  void setPageIndex(int index) {
    if (_currentPageIndex != index && index >= 0 && index <= 1) {
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

  /// Resetea el estado del provider a sus valores iniciales
  void reset() {
    _currentPageIndex = 0;
    notifyListeners();
  }
}
