# Feature: Analytics

## Propósito

Mostrar métricas y transacciones del negocio en tiempo real con filtros por período de tiempo. Diseñado para ser escalable a futuras funcionalidades como productos más vendidos y tendencias.

## Responsabilidades

- Calcular y mostrar total de transacciones
- Calcular y mostrar ganancia total acumulada
- Filtrar transacciones por período (Hoy, Ayer, Este mes, Mes pasado, Este año, Año pasado)
- Mostrar lista detallada de transacciones
- Proporcionar métricas derivadas (promedio por transacción)
- Gestionar estados de carga, error y éxito

## Estructura

```
analytics/
├── README.md
├── domain/
│   ├── entities/
│   │   ├── sales_analytics.dart      # Entity inmutable con transacciones
│   │   └── date_filter.dart          # Enum de filtros de fecha
│   ├── repositories/
│   │   └── analytics_repository.dart # Contrato
│   └── usecases/
│       └── get_sales_analytics_usecase.dart
├── data/
│   ├── datasources/
│   │   └── analytics_remote_datasource.dart
│   ├── models/
│   │   └── sales_analytics_model.dart
│   └── repositories/
│       └── analytics_repository_impl.dart
└── presentation/
    ├── providers/
    │   └── analytics_provider.dart
    ├── pages/
    │   └── analytics_page.dart
    └── widgets/
        ├── metric_card.dart
        ├── date_filter_chips.dart
        └── transaction_list_item.dart
```

## Provider Principal

### `AnalyticsProvider`

**Responsabilidad:** Gestionar estado de analíticas, filtros y lista de transacciones

**Inyección de Dependencias:**
```dart
@injectable
class AnalyticsProvider extends ChangeNotifier {
  final GetSalesAnalyticsUseCase _getSalesAnalyticsUseCase;
  // ...
}
```

**Estado interno:**
- `analytics`: SalesAnalytics? - Métricas y transacciones
- `isLoading`: bool - Estado de carga
- `errorMessage`: String? - Mensaje de error
- `selectedFilter`: DateFilter - Filtro de fecha actual

**Métodos públicos:**
- `loadAnalytics(accountId)`: Carga inicial
- `setDateFilter(filter)`: Cambia filtro y recarga
- `refresh(accountId)`: Recarga datos
- `clear()`: Limpia estado

## Entity: SalesAnalytics (Inmutable)

```dart
class SalesAnalytics {
  final int totalTransactions;          // Total de transacciones
  final double totalProfit;              // Ganancia total
  final DateTime calculatedAt;           // Timestamp del cálculo
  final List<TicketModel> transactions; // Lista de transacciones
  
  double get averageProfitPerTransaction; // Getter computado
  double get totalSales;                  // Suma de ventas totales
}
```

## Filtros de Fecha

```dart
enum DateFilter {
  today('Hoy'),
  yesterday('Ayer'),
  thisMonth('Este mes'),
  lastMonth('Mes pasado'),
  thisYear('Este año'),
  lastYear('Año pasado');
  
  (DateTime, DateTime) getDateRange(); // Retorna (inicio, fin)
}
```

## Use Cases

| UseCase | Descripción | Parámetros |
|---------|-------------|------------|
| `GetSalesAnalyticsUseCase` | Obtiene métricas y transacciones | `AnalyticsParams(accountId, dateFilter?)` |

## Datasource

### `AnalyticsRemoteDataSource`

**Colección consultada:** `ACCOUNTS/{accountId}/TRANSACTIONS`

**Query con filtro:**
```dart
query = query
  .where('creation', isGreaterThanOrEqualTo: startDate)
  .where('creation', isLessThan: endDate)
  .orderBy('creation', descending: true);
```

## Widgets

| Widget | Descripción |
|--------|-------------|
| `MetricCard` | Card para mostrar una métrica con icono |
| `DateFilterChips` | Chips horizontales para seleccionar período |
| `TransactionListItem` | Item de lista con info de transacción |

## Formateo de Moneda

Usa `NumberFormat.currency()` de `intl` para formateo regional:

```dart
final currencyFormat = NumberFormat.currency(
  locale: 'es_AR',
  symbol: '\$',
  decimalDigits: 2,
);
```

## Performance (Futuras Iteraciones)

Para cuentas con muchos tickets, considerar:

- **Paginación**: Limitar documentos por consulta
- **Caché local**: Almacenar métricas con timestamp
- **Agregación server-side**: Cuando Firestore lo soporte

## Navegación

Accesible desde `HomePage` como tercera pestaña junto a Ventas y Catálogo.

## Testing

```bash
# Ejecutar tests del feature
flutter test test/features/analytics/

# Análisis estático
flutter analyze lib/features/analytics/
```
