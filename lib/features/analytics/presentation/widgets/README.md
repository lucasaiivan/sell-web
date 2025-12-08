# 📊 Analytics Widgets

Este directorio contiene todos los componentes visuales del módulo de Analytics, organizados por responsabilidad.

## 📁 Estructura

### `core/`
Componentes base y utilidades compartidas.
- `analytics_base_card.dart`: Tarjeta base con diseño responsivo y estado de carga.
- `analytics_modal.dart`: Wrapper base para todos los modales de detalle.
- `reorderable_analytics_grid.dart`: Grid con soporte para drag and drop.

### `cards/`
Tarjetas individuales de métricas (Widgets visuales del dashboard).
- `metric_card.dart`: Tarjeta genérica para métricas simples (Ventas, Ganancia, Facturación).
- `sales_trend_card.dart`: Gráfico de tendencia de ventas.
- `peak_hours_card.dart`: Análisis de horas pico.
- `category_distribution_card.dart`: Gráfico de distribución por categoría.
- ...y otras tarjetas específicas.

### `modals/`
Vistas de detalle que se abren al hacer tap en una tarjeta.
- `profit_modal.dart`: Detalle de ganancias y rentabilidad.
- `average_ticket_modal.dart`: Análisis de ticket promedio.

### `dialogs/`
Diálogos de pantalla completa o complejos.
- `transactions_dialog.dart`: Explorador de transacciones con agrupamiento mensual.
- `customize_cards_dialog.dart`: Personalización del dashboard.

### `transactions/`
Componentes específicos listar transacciones.
- `month_grouped_transactions_list.dart`: Lista agrupada.
- `transaction_list_item.dart`: Item individual de transacción.

### `registry/`
Gestión y configuración de componentes.
- `analytics_card_registry.dart`: Factory central que mapea IDs a Widgets. Maneja la creación dinámica.
- `analytics_metrics.dart`: Definiciones de métricas y helpers de construcción.

## 🛠️ Uso

Para agregar una nueva tarjeta de analítica:
1. Crear el widget en `cards/`.
2. Si requiere modal de detalle, crearlo en `modals/`.
3. Registrar la definición en `AnalyticsCardRegistry` (`registry/analytics_card_registry.dart`).
4. Agregar el case en el método `buildCard` del registry.
5. Exportar los nuevos widgets en los barrel files correspondientes.
