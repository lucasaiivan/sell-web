# Feature: Analytics 📊

**Mostrar métricas y transacciones del negocio en tiempo real con filtros por período de tiempo.**

## 🎯 Descripción

Este feature proporciona una vista completa de las analíticas de ventas del negocio, permitiendo a los usuarios visualizar métricas clave como facturación, ganancias, cantidad de transacciones y productos vendidos. 

Incluye actualización en tiempo real mediante streams de Firestore, filtrado por períodos de tiempo (hoy, ayer, este mes, etc.), desglose por métodos de pago y visualización de cajas registradoras activas. El diseño implementa un layout responsive tipo "Bento Box" para pantallas pequeñas/medianas y fila horizontal para pantallas grandes.

El feature está diseñado para ser escalable a futuras funcionalidades como análisis de productos más vendidos, tendencias de ventas y reportes exportables.

## 📦 Componentes Principales

### Entities
- `SalesAnalytics`: Métricas calculadas de ventas (inmutable)
  - Propiedades: totalTransactions, totalProfit, totalSales, calculatedAt, transactions
  - Métricas derivadas: paymentMethodsBreakdown, paymentMethodsCount, averageProfitPerTransaction, totalProductsSold
- `DateFilter`: Enum con períodos de tiempo (today, yesterday, thisMonth, lastMonth, thisYear, lastYear)

### Use Cases
- `GetSalesAnalyticsUseCase`: Obtiene métricas y transacciones con actualización en tiempo real vía Stream
  - Parámetros: `AnalyticsParams(accountId, dateFilter?)`
  - Retorna: `Stream<Either<Failure, SalesAnalytics>>`

### Providers
- `AnalyticsProvider`: Gestiona estado de analíticas, suscripción a streams y filtros de fecha
  - Implementa: `InitializableProvider`
  - Métodos: `subscribeToAnalytics()`, `setDateFilter()`, `clear()`, `initialize()`, `cleanup()`

### Repositories
- `AnalyticsRepository`: Contrato para obtener analíticas
- `AnalyticsRepositoryImpl`: Implementación que delega a datasource

### DataSources
- `AnalyticsRemoteDataSource`: Consulta Firestore en tiempo real
  - Colección: `ACCOUNTS/{accountId}/TRANSACTIONS`
  - Stream con filtrado por fechas y ordenamiento

### Models
- `SalesAnalyticsModel`: DTO con serialización desde Firestore
  - Conversión: `fromFirestore()`, `toEntity()`

## 📐 Estructura

```
analytics/
├── README.md
├── domain/
│   ├── entities/
│   │   ├── sales_analytics.dart      # Entity inmutable con métricas
│   │   └── date_filter.dart          # Enum de períodos de tiempo
│   ├── repositories/
│   │   └── analytics_repository.dart # Contrato
│   └── usecases/
│       └── get_sales_analytics_usecase.dart # @lazySingleton
├── data/
│   ├── datasources/
│   │   └── analytics_remote_datasource.dart # @lazySingleton
│   ├── models/
│   │   └── sales_analytics_model.dart       # DTO
│   └── repositories/
│       └── analytics_repository_impl.dart   # @LazySingleton
└── presentation/
    ├── providers/
    │   └── analytics_provider.dart          # @injectable
    ├── pages/
    │   └── analytics_page.dart              # Página principal (layout responsivo)
    └── widgets/
        ├── analytics_base_card.dart         # Widget base para todas las tarjetas
        ├── metric_card.dart                 # Card de métrica numérica
        ├── products_metric_card.dart        # Card de productos vendidos
        ├── profitability_metric_card.dart   # Card de rentabilidad
        ├── seller_ranking_card.dart         # Card de ranking de vendedores
        ├── peak_hours_card.dart             # Card de horas pico
        ├── slow_moving_products_card.dart   # Card de productos de lenta rotación
        ├── payment_methods_card.dart        # Desglose por métodos de pago
        ├── active_cash_registers_card.dart  # Cajas activas
        ├── date_filter_chips.dart           # Selector de período
        ├── transaction_list_item.dart       # Item de transacción
        └── shimmer_widget.dart              # Loading placeholder
```

## 🔄 Flujos Principales

### Flujo 1: Carga Inicial y Suscripción
```
Usuario abre Analytics → AnalyticsPage
  ↓
Provider.initialize(accountId) → subscribeToAnalytics()
  ↓
GetSalesAnalyticsUseCase(params) → Stream<Either<Failure, SalesAnalytics>>
  ↓
AnalyticsRepository.getTransactions() → Stream
  ↓
AnalyticsRemoteDataSource.getTransactions() → Firestore Stream
  ↓
UI se actualiza automáticamente con cada evento del stream
```

### Flujo 2: Cambio de Filtro
```
Usuario selecciona filtro (ej: "Este mes")
  ↓
DateFilterChips → onFilterSelected(DateFilter.thisMonth)
  ↓
Provider.setDateFilter(filter) → cancela stream anterior
  ↓
Provider.subscribeToAnalytics() → nuevo stream con filtro actualizado
  ↓
UI muestra datos filtrados en tiempo real
```

### Flujo 3: Visualización de Transacciones
```
Stream emite SalesAnalytics
  ↓
Provider notifica listeners
  ↓
Consumer<AnalyticsProvider> reconstruye
  ↓
_buildSuccessState() renderiza:
  - Grid responsive con métricas (Bento Box < 900px, Row >= 900px)
  - PaymentMethodsCard con desglose
  - ActiveCashRegistersCard
  - TransactionListItem para cada transacción
```

## 🔌 Integración

### Registro en main.dart
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  configureDependencies(); // Registra @injectable y @lazySingleton
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => getIt<AnalyticsProvider>()),
        // ... otros providers
      ],
      child: MyApp(),
    ),
  );
}
```

### Uso en Página
```dart
// La página usa Consumer para reactividad
Consumer<AnalyticsProvider>(
  builder: (context, provider, _) {
    if (provider.isLoading && !provider.hasData) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (provider.hasData) {
      final analytics = provider.analytics!;
      return Column(
        children: [
          MetricCard(
            title: 'Facturación',
            value: CurrencyHelper.formatCurrency(analytics.totalSales),
            icon: Icons.attach_money_rounded,
          ),
          // ... más métricas
        ],
      );
    }
    
    return _buildEmptyState();
  },
)
```

### DateFilter
```dart
// Obtener rango de fechas
final filter = DateFilter.thisMonth;
final (startDate, endDate) = filter.getDateRange();

// Cambiar filtro desde UI
DateFilterChips(
  selectedFilter: provider.selectedFilter,
  onFilterSelected: (filter) => provider.setDateFilter(filter),
)
```

## ⚙️ Configuración

### Firestore Query
El datasource realiza consultas filtradas y ordenadas:
```dart
Stream<List<TicketModel>> getTransactions(
  String accountId, {
  DateFilter? dateFilter,
}) {
  var query = _firestore
      .collection('ACCOUNTS')
      .doc(accountId)
      .collection('TRANSACTIONS')
      .orderBy('creation', descending: true);

  if (dateFilter != null) {
    final (startDate, endDate) = dateFilter.getDateRange();
    query = query
        .where('creation', isGreaterThanOrEqualTo: startDate)
        .where('creation', isLessThan: endDate);
  }

  return query.snapshots().map(/* conversión a TicketModel */);
}
```

### Formateo de Moneda
Utiliza `CurrencyHelper` de `core/utils/`:
```dart
// Formateo automático con locale
String formattedValue = CurrencyHelper.formatCurrency(analytics.totalSales);
// Ejemplo: $1,234.56
```

### Métricas Disponibles
```dart
// Desde SalesAnalytics entity
analytics.totalTransactions      // Total de tickets/ventas
analytics.totalProfit            // Ganancia neta
analytics.totalSales             // Ingresos brutos
analytics.totalProductsSold      // Cantidad total de productos
analytics.averageProfitPerTransaction  // Promedio por venta
analytics.paymentMethodsBreakdown     // Map<String, double> por método
analytics.paymentMethodsCount         // Map<String, int> cantidad por método
```

## 🎨 UI/UX

### Layout Responsive
- **< 900px**: Grid tipo Bento Box con `StaggeredGrid` (métricas de diferentes tamaños)
- **≥ 900px**: Fila horizontal con cards uniformes

### Widgets Especializados
- `MetricCard`: Card con título, valor, icono y color personalizado
- `DateFilterChips`: Chips horizontales para selección de período
- `TransactionListItem`: Item con detalles de transacción (fecha, productos, total, método de pago)
- `PaymentMethodsCard`: Card con desglose visual por método de pago
- `ActiveCashRegistersCard`: Muestra cajas registradoras abiertas
- `ShimmerWidget`: Placeholder animado durante carga

### Estados UI
1. **Loading inicial**: `CircularProgressIndicator` centrado
2. **Success**: Grid de métricas + lista de transacciones
3. **Error**: Mensaje de error con botón retry
4. **Empty**: Mensaje "Sin datos para el período seleccionado"

## 🔧 Performance

### Optimizaciones Actuales
- **Stream de Firestore**: Actualización en tiempo real sin polling
- **Cancelación de suscripción**: Al cambiar filtro o dispose del provider
- **InitializableProvider**: Lifecycle management correcto
- **Equatable en Entity**: Comparación eficiente de estados

### Mejoras Futuras
Para cuentas con alto volumen de transacciones:
- **Paginación**: Limitar documentos por consulta (ej: primeros 100)
- **Caché local**: Almacenar métricas agregadas con timestamp
- **Agregación server-side**: Cloud Functions para cálculos pesados
- **Índices compuestos**: Optimizar queries complejas en Firestore

## 📍 Navegación

- Accesible desde `HomePage` como pestaña de navegación
- Ruta: `/analytics` (configurada en routing)
- Drawer: Opción "Analíticas" con icono `Icons.analytics`

## ✅ Estado

- ✅ Feature completo y funcional
- ✅ Actualización en tiempo real con Streams
- ✅ Filtrado por períodos de tiempo
- ✅ Layout responsive (Bento Box + Row)
- ✅ Desglose por métodos de pago
- ✅ Visualización de cajas activas
- ✅ Documentación completa
- ⚠️ Tests pendientes
- ⚠️ Exportación de reportes (roadmap)

## 🧪 Testing

```bash
# Ejecutar tests del feature (cuando se implementen)
flutter test test/features/analytics/

# Análisis estático
flutter analyze lib/features/analytics/

# Regenerar DI si se agregan anotaciones
dart run build_runner build --delete-conflicting-outputs
```

---

**Última actualización:** 30 de noviembre de 2025  
**Versión:** 2.0.0  
**Estado:** ✅ Producción
