# Graphics Widgets

Componentes gráficos reutilizables para visualización de datos en la aplicación.

## 📊 Descripción

Esta carpeta contiene widgets especializados para representar información de manera visual y atractiva, facilitando la comprensión de datos complejos mediante gráficos y visualizaciones interactivas.

## 📁 Contenido

```
graphics/
├── percentage_bar_chart.dart    # Gráfico de barras horizontales con porcentajes
├── graphics.dart                 # Exportaciones centralizadas
└── README.md                     # Este archivo
```

### Componentes Disponibles

#### 1. **PercentageBarChart**
Gráfico de barras horizontales divididas para mostrar distribuciones porcentuales.

**Características:**
- ✅ Barras divididas con esquinas redondeadas
- ✅ Diseño responsive (mobile y desktop)
- ✅ Filtro automático de segmentos pequeños (<5%)
- ✅ Etiquetas con puntos de color
- ✅ Altamente personalizable
- ✅ Animaciones suaves con FittedBox
- ✅ Prevención de desbordamiento

**Uso básico:**
```dart
import 'package:sell_web/presentation/widgets/graphics/graphics.dart';

PercentageBarChart(
  title: 'Métodos de pago',
  data: [
    PercentageBarData(
      label: 'Efectivo',
      percentage: 45.0,
      color: Colors.orange.shade700,
    ),
    PercentageBarData(
      label: 'Tarjeta',
      percentage: 35.0,
      color: Colors.purple.shade700,
    ),
    PercentageBarData(
      label: 'Mercado Pago',
      percentage: 20.0,
      color: Colors.blue.shade700,
    ),
  ],
  isMobile: isMobile(context),
)
```

**Uso avanzado con personalización:**
```dart
PercentageBarChart(
  title: 'Distribución de Ventas',
  data: paymentMethodsData,
  isMobile: isMobile(context),
  barHeight: 30,                    // Altura personalizada
  barBorderRadius: 8,               // Radio de esquinas
  barSpacing: 4,                    // Espaciado entre barras
  minPercentageToShow: 3.0,         // Umbral mínimo (3% en lugar de 5%)
  backgroundColor: Colors.grey.shade100,
  borderColor: Colors.grey.shade300,
  showLabels: true,                 // Mostrar/ocultar etiquetas
  labelSpacing: 12,                 // Espaciado con etiquetas
)
```

**Modelo de datos - PercentageBarData:**
```dart
PercentageBarData(
  label: 'Efectivo',                // Etiqueta descriptiva
  percentage: 45.0,                  // Porcentaje (0-100)
  color: Colors.orange.shade700,     // Color de la barra
  opacity: 0.9,                      // Opacidad (opcional)
  textColor: Colors.white,           // Color del texto (opcional)
  icon: Icons.payments_rounded,      // Icono asociado (opcional)
)
```

## 🎯 Casos de Uso

### 1. Análisis de Métodos de Pago
Visualizar la distribución de métodos de pago en ventas:
```dart
final paymentMethods = TicketModel.getPaymentMethodsRanking(
  tickets: activeTickets,
  includeAnnulled: false,
);

final chartData = paymentMethods.map((method) {
  return PercentageBarData(
    label: method['description'],
    percentage: method['percentage'],
    color: _getColorForPaymentMethod(method['description']),
  );
}).toList();

PercentageBarChart(
  title: 'Métodos de pago',
  data: chartData,
  isMobile: isMobile(context),
)
```

### 2. Dashboard de Categorías de Productos
```dart
PercentageBarChart(
  title: 'Ventas por Categoría',
  data: [
    PercentageBarData(
      label: 'Electrónica',
      percentage: 40.0,
      color: Colors.blue.shade700,
    ),
    PercentageBarData(
      label: 'Ropa',
      percentage: 35.0,
      color: Colors.green.shade700,
    ),
    PercentageBarData(
      label: 'Alimentos',
      percentage: 25.0,
      color: Colors.orange.shade700,
    ),
  ],
  isMobile: isMobile(context),
)
```

### 3. Análisis de Rendimiento
```dart
PercentageBarChart(
  title: 'Estado de Tareas',
  data: [
    PercentageBarData(
      label: 'Completadas',
      percentage: 60.0,
      color: Colors.green,
    ),
    PercentageBarData(
      label: 'En Progreso',
      percentage: 30.0,
      color: Colors.orange,
    ),
    PercentageBarData(
      label: 'Pendientes',
      percentage: 10.0,
      color: Colors.red,
    ),
  ],
  isMobile: isMobile(context),
  showLabels: true,
)
```

## 🎨 Personalización

### Colores Recomendados

```dart
// Paleta de colores para diferentes categorías
final paymentColors = {
  'Efectivo': Colors.orange.shade700,
  'Mercado Pago': Colors.blue.shade700,
  'Tarjeta': Colors.purple.shade700,
  'Transferencia': Colors.green.shade700,
  'Otros': Colors.grey.shade600,
};

// Paleta para estados
final statusColors = {
  'Exitoso': Colors.green.shade700,
  'Pendiente': Colors.orange.shade700,
  'Fallido': Colors.red.shade700,
  'Cancelado': Colors.grey.shade600,
};
```

### Responsive Design

El componente se adapta automáticamente a diferentes tamaños de pantalla:

| Propiedad | Móvil | Desktop |
|-----------|-------|---------|
| Altura de barra | 16px | 24px |
| Espaciado entre barras | 1px | 3px |
| Tamaño de fuente | 11px | 13px |
| Tamaño de puntos | 8px | 10px |
| Padding del contenedor | 10px | 12px |

## 📋 Buenas Prácticas

1. **Porcentajes Válidos**: Asegurarse de que la suma de porcentajes sea ~100%
   ```dart
   // ✅ Correcto
   final total = data.fold<double>(0, (sum, item) => sum + item.percentage);
   assert(total >= 99.0 && total <= 101.0, 'La suma debe ser ~100%');
   ```

2. **Filtrado Automático**: Los segmentos <5% se ocultan automáticamente
   ```dart
   // El componente maneja esto internamente
   minPercentageToShow: 5.0, // Valor por defecto
   ```

3. **Colores Consistentes**: Usar una paleta de colores coherente
   ```dart
   // ✅ Usar helper para colores consistentes
   Color _getColorForCategory(String category) {
     return categoryColors[category] ?? Colors.grey;
   }
   ```

4. **Accesibilidad**: Usar colores con buen contraste
   ```dart
   PercentageBarData(
     color: Colors.blue.shade700,
     textColor: Colors.white, // Buen contraste
   )
   ```

## 🔧 Mantenimiento

### Agregar Nuevos Widgets Gráficos

1. Crear el archivo del widget en esta carpeta
2. Exportarlo en `graphics.dart`
3. Actualizar este README con la documentación
4. Agregar ejemplos de uso

### Convenciones de Nomenclatura

- Usar sufijo `Chart` para gráficos completos: `PieChart`, `LineChart`
- Usar sufijo `Graph` para representaciones matemáticas: `BarGraph`
- Usar sufijo `Indicator` para elementos visuales simples: `ProgressIndicator`

## 📚 Recursos Adicionales

- [Material Design - Data Visualization](https://material.io/design/communication/data-visualization.html)
- [Flutter Charts Package](https://pub.dev/packages/fl_chart)
- [Responsive Design Guide](https://flutter.dev/docs/development/ui/layout/responsive)

## 🐛 Troubleshooting

### El gráfico no se muestra
- Verificar que `data` no esté vacía
- Asegurar que al menos un item tenga `percentage >= minPercentageToShow`

### Los porcentajes no suman 100%
- Normalizar los datos antes de pasarlos al componente
- Usar método helper para calcular porcentajes automáticamente

### Texto desbordado
- El componente usa `FittedBox` automáticamente
- Si persiste, reducir `barHeight` o usar segmentos más grandes

---

**Última actualización**: 16 de octubre de 2025  
**Versión**: 1.0.0
