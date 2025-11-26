import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import '../../domain/entities/date_filter.dart';
import '../../domain/entities/sales_analytics.dart';
import '../../domain/usecases/get_sales_analytics_usecase.dart';

/// Estado interno del provider
class _AnalyticsState {
  final SalesAnalytics? analytics;
  final bool isLoading;
  final String? errorMessage;
  final DateFilter selectedFilter;

  const _AnalyticsState({
    this.analytics,
    this.isLoading = false,
    this.errorMessage,
    this.selectedFilter = DateFilter.today,
  });

  _AnalyticsState copyWith({
    SalesAnalytics? analytics,
    bool? isLoading,
    String? errorMessage,
    DateFilter? selectedFilter,
    bool clearError = false,
    bool clearAnalytics = false,
  }) {
    return _AnalyticsState(
      analytics: clearAnalytics ? null : (analytics ?? this.analytics),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      selectedFilter: selectedFilter ?? this.selectedFilter,
    );
  }
}

/// Provider: Analíticas
///
/// **Responsabilidad:**
/// - Gestionar estado de analíticas de ventas
/// - Gestionar filtro de fecha seleccionado
/// - Exponer datos calculados y lista de transacciones a la UI
/// - Coordinar carga de datos mediante UseCase
///
/// **Dependencias:** [GetSalesAnalyticsUseCase]
/// **Inyección DI:** @injectable
@injectable
class AnalyticsProvider extends ChangeNotifier {
  final GetSalesAnalyticsUseCase _getSalesAnalyticsUseCase;

  _AnalyticsState _state = const _AnalyticsState();
  String _currentAccountId = '';

  AnalyticsProvider(this._getSalesAnalyticsUseCase);

  // --- Getters públicos ---

  /// Analíticas de ventas actuales
  SalesAnalytics? get analytics => _state.analytics;

  /// Indica si está cargando datos
  bool get isLoading => _state.isLoading;

  /// Mensaje de error si existe
  String? get errorMessage => _state.errorMessage;

  /// Indica si hay datos cargados
  bool get hasData => _state.analytics != null;

  /// Filtro de fecha seleccionado
  DateFilter get selectedFilter => _state.selectedFilter;

  // --- Métodos públicos ---

  /// Carga las analíticas para una cuenta específica
  ///
  /// [accountId] ID de la cuenta
  Future<void> loadAnalytics(String accountId) async {
    if (accountId.isEmpty) return;

    _currentAccountId = accountId;
    _state = _state.copyWith(isLoading: true, clearError: true);
    notifyListeners();

    final result = await _getSalesAnalyticsUseCase(
      AnalyticsParams(
        accountId: accountId,
        dateFilter: _state.selectedFilter,
      ),
    );

    result.fold(
      (failure) {
        _state = _state.copyWith(
          isLoading: false,
          errorMessage: failure.message,
        );
      },
      (analytics) {
        _state = _state.copyWith(
          isLoading: false,
          analytics: analytics,
        );
      },
    );

    notifyListeners();
  }

  /// Cambia el filtro de fecha y recarga los datos
  Future<void> setDateFilter(DateFilter filter) async {
    if (_state.selectedFilter == filter) return;

    _state = _state.copyWith(
      selectedFilter: filter,
      clearAnalytics: true,
    );
    notifyListeners();

    if (_currentAccountId.isNotEmpty) {
      await loadAnalytics(_currentAccountId);
    }
  }

  /// Recarga las analíticas (útil para pull-to-refresh)
  Future<void> refresh(String accountId) async {
    await loadAnalytics(accountId);
  }

  /// Limpia el estado del provider
  void clear() {
    _state = const _AnalyticsState();
    _currentAccountId = '';
    notifyListeners();
  }
}
