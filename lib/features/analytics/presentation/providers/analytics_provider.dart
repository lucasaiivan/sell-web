import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:sellweb/core/presentation/providers/initializable_provider.dart';
import '../../domain/entities/date_filter.dart';
import '../../domain/entities/sales_analytics.dart';
import '../../domain/usecases/get_sales_analytics_usecase.dart';

/// Estado interno del provider (inmutable)
class _AnalyticsState {
  final SalesAnalytics? analytics;
  final bool isLoading;
  final String? errorMessage;
  final DateFilter selectedFilter;
  final Map<String, bool> expandedMonths;

  const _AnalyticsState({
    this.analytics,
    this.isLoading = false,
    this.errorMessage,
    this.selectedFilter = DateFilter.today,
    this.expandedMonths = const {},
  });

  _AnalyticsState copyWith({
    SalesAnalytics? analytics,
    bool? isLoading,
    String? errorMessage,
    DateFilter? selectedFilter,
    Map<String, bool>? expandedMonths,
    bool clearError = false,
    bool clearAnalytics = false,
  }) {
    return _AnalyticsState(
      analytics: clearAnalytics ? null : (analytics ?? this.analytics),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      selectedFilter: selectedFilter ?? this.selectedFilter,
      expandedMonths: expandedMonths ?? this.expandedMonths,
    );
  }
}

/// Provider: Analíticas
///
/// **Responsabilidad:**
/// - Gestionar estado de analíticas de ventas
/// - Manejar filtro de fecha
/// - Exponer métricas pre-calculadas a la UI
///
/// **Estrategia de datos:**
/// - Carga TODOS los documentos del rango de fecha seleccionado
/// - Sin límite artificial: las métricas siempre son precisas
/// - El filtro de fecha controla el volumen de datos
@injectable
class AnalyticsProvider extends ChangeNotifier
    implements InitializableProvider {
  final GetSalesAnalyticsUseCase _getSalesAnalyticsUseCase;

  _AnalyticsState _state = const _AnalyticsState();
  String _currentAccountId = '';
  StreamSubscription<dynamic>? _subscription;

  AnalyticsProvider(this._getSalesAnalyticsUseCase);

  // === Getters públicos ===

  SalesAnalytics? get analytics => _state.analytics;
  bool get isLoading => _state.isLoading;
  String? get errorMessage => _state.errorMessage;
  bool get hasData => _state.analytics != null;
  DateFilter get selectedFilter => _state.selectedFilter;

  /// Número de transacciones cargadas
  int get transactionCount => _state.analytics?.transactions.length ?? 0;

  /// Verifica si un mes está expandido (por defecto colapsado)
  bool isMonthExpanded(String monthKey) {
    return _state.expandedMonths[monthKey] ?? false;
  }

  // === Métodos públicos ===

  /// Alterna expansión de un mes en la lista de transacciones
  void toggleMonthExpansion(String monthKey) {
    final currentExpanded = _state.expandedMonths[monthKey] ?? false;
    final newExpandedMonths = Map<String, bool>.from(_state.expandedMonths);
    newExpandedMonths[monthKey] = !currentExpanded;

    _state = _state.copyWith(expandedMonths: newExpandedMonths);
    notifyListeners();
  }

  /// Suscribe a analíticas con actualización en tiempo real
  void subscribeToAnalytics(String accountId) {
    if (accountId.isEmpty) return;

    _subscription?.cancel();
    _currentAccountId = accountId;
    _state = _state.copyWith(isLoading: true, clearError: true);
    notifyListeners();

    _subscription = _getSalesAnalyticsUseCase(
      AnalyticsParams(
        accountId: accountId,
        dateFilter: _state.selectedFilter,
      ),
    ).listen(
      (result) {
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
      },
      onError: (error) {
        _state = _state.copyWith(
          isLoading: false,
          errorMessage: 'Error: ${error.toString()}',
        );
        notifyListeners();
      },
    );
  }

  /// Cambia el filtro de fecha y re-suscribe
  void setDateFilter(DateFilter filter) {
    if (_state.selectedFilter == filter) return;

    _state = _state.copyWith(
      selectedFilter: filter,
      clearAnalytics: true,
      expandedMonths: const {}, // Resetear expansión de meses
    );
    notifyListeners();

    if (_currentAccountId.isNotEmpty) {
      subscribeToAnalytics(_currentAccountId);
    }
  }

  /// Limpia el estado del provider
  void clear() {
    _subscription?.cancel();
    _state = const _AnalyticsState();
    _currentAccountId = '';
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Future<void> initialize(String accountId) async {
    subscribeToAnalytics(accountId);
  }

  @override
  void cleanup() {
    _subscription?.cancel();
    _subscription = null;
    _state = const _AnalyticsState();
    _currentAccountId = '';

    try {
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ AnalyticsProvider.cleanup: Provider ya disposed');
      }
    }
  }
}
