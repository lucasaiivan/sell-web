# Premium List Tile Components

Componentes reutilizables de ListTile con diseño premium y moderno, basados en el estilo de `_CashRegisterExpandableHeader`.

## 📦 Componentes

### 1. `PremiumListTile`
ListTile estático con diseño premium.

### 2. `ExpandablePremiumListTile`
ListTile expandible con animaciones suaves.

## 🎨 Características

- ✅ **Diseño Premium**: Bordes redondeados, sombras sutiles, colores vibrantes
- ✅ **Responsive**: Adapta tamaños para mobile/desktop
- ✅ **Animaciones**: Transiciones suaves en hover, tap y expansión
- ✅ **Personalizable**: Colores, iconos, badges, trailing customizables
- ✅ **Badges de Estado**: Indicadores visuales con punto animado
- ✅ **Contenido Expandible**: Lista de información detallada

## 📖 Uso

### Ejemplo 1: PremiumListTile básico

```dart
import 'package:sell_web/core/presentation/widgets/ui/ui.dart';

PremiumListTile(
  icon: Icons.point_of_sale_rounded,
  iconColor: theme.colorScheme.primary,
  title: 'Caja Principal',
  subtitle: Row(
    children: [
      Icon(Icons.schedule_rounded, size: 14),
      SizedBox(width: 6),
      Text('Abierta hace 2h 30min'),
    ],
  ),
  badge: PremiumListTileBadge(
    label: 'ACTIVA',
    color: Colors.green,
    showDot: true,
  ),
  onTap: () {
    // Acción al hacer tap
  },
  isMobile: false,
)
```

### Ejemplo 2: PremiumListTile con trailing customizado

```dart
PremiumListTile(
  icon: Icons.shopping_cart,
  iconColor: Colors.blue,
  title: 'Pedido #1234',
  subtitle: Text('3 productos'),
  badge: PremiumListTileBadge(
    label: 'PENDIENTE',
    color: Colors.orange,
  ),
  trailing: IconButton(
    icon: Icon(Icons.more_vert),
    onPressed: () {
      // Mostrar menú de opciones
    },
  ),
  isMobile: MediaQuery.of(context).size.width < 600,
)
```

### Ejemplo 3: ExpandablePremiumListTile

```dart
ExpandablePremiumListTile(
  icon: Icons.point_of_sale_rounded,
  iconColor: theme.colorScheme.primary,
  title: 'Caja Registradora Principal',
  subtitle: Row(
    children: [
      Icon(Icons.timelapse_rounded, size: 14),
      SizedBox(width: 6),
      Text('Activa desde hace 2h 30min'),
    ],
  ),
  badge: PremiumListTileBadge(
    label: 'ACTIVA',
    color: Colors.green.shade700,
    showDot: true,
  ),
  expandedInfo: [
    ExpandableInfoItem(
      icon: Icons.schedule_rounded,
      label: 'Apertura',
      value: '18 ene 2026, 14:30',
    ),
    ExpandableInfoItem(
      icon: Icons.timelapse_rounded,
      label: 'Tiempo activo',
      value: '2h 30min',
    ),
    ExpandableInfoItem(
      icon: Icons.person_rounded,
      label: 'Cajero',
      value: 'usuario@example.com',
    ),
    ExpandableInfoItem(
      icon: Icons.attach_money_rounded,
      label: 'Balance',
      valueWidget: Text(
        '\$12,500.00',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.green,
        ),
      ),
    ),
  ],
  initiallyExpanded: false,
  onExpansionChanged: (isExpanded) {
    print('Expandido: $isExpanded');
  },
  isMobile: false,
)
```

### Ejemplo 4: ExpandablePremiumListTile con colores personalizados

```dart
ExpandablePremiumListTile(
  icon: Icons.inventory_rounded,
  iconColor: Colors.purple,
  title: 'Stock bajo',
  subtitle: Text('5 productos con stock crítico'),
  badge: PremiumListTileBadge(
    label: 'ALERTA',
    color: Colors.red,
  ),
  backgroundColor: Colors.red.withOpacity(0.05),
  borderColor: Colors.red.withOpacity(0.2),
  expandedBorderColor: Colors.red.withOpacity(0.5),
  borderRadius: 12,
  expandedInfo: [
    ExpandableInfoItem(
      icon: Icons.inventory_2,
      label: 'Producto A',
      value: '2 unidades',
    ),
    ExpandableInfoItem(
      icon: Icons.inventory_2,
      label: 'Producto B',
      value: '1 unidad',
    ),
  ],
  isMobile: MediaQuery.of(context).size.width < 600,
)
```

### Ejemplo 5: Lista de PremiumListTile

```dart
ListView.separated(
  itemCount: items.length,
  separatorBuilder: (_, __) => SizedBox(height: 12),
  itemBuilder: (context, index) {
    final item = items[index];
    return PremiumListTile(
      icon: item.icon,
      iconColor: item.color,
      title: item.title,
      subtitle: Text(item.description),
      onTap: () => _navigateToItem(item),
      isMobile: isMobile,
    );
  },
)
```

## 🎨 Personalización

### Colores
- `iconColor`: Color del icono y elementos destacados
- `backgroundColor`: Color de fondo del contenedor
- `borderColor`: Color del borde (estado normal)
- `expandedBorderColor`: Color del borde (estado expandido)

### Dimensiones
- `borderRadius`: Radio de los bordes (default: 16.0)
- `padding`: Padding interno personalizado
- `isMobile`: Activa el modo responsive para móviles

### Badge
```dart
PremiumListTileBadge(
  label: 'TEXTO',
  color: Colors.green,
  showDot: true, // Mostrar punto de estado
)
```

### Información Expandible
```dart
ExpandableInfoItem(
  icon: Icons.info,
  label: 'Etiqueta',
  value: 'Valor',  // Texto simple
)

// O con widget personalizado
ExpandableInfoItem(
  icon: Icons.info,
  label: 'Etiqueta',
  valueWidget: CustomWidget(),  // Widget customizado
)
```

## 🔄 Migración desde _CashRegisterExpandableHeader

### Antes:
```dart
_CashRegisterExpandableHeader(
  cashRegister: currentCashRegister,
  theme: theme,
  isMobile: isMobile,
  timeInfo: timeInfo,
)
```

### Después:
```dart
ExpandablePremiumListTile(
  icon: Icons.point_of_sale_rounded,
  iconColor: theme.colorScheme.primary,
  title: currentCashRegister.description,
  subtitle: Row(
    children: [
      Icon(Icons.timelapse_rounded, size: 14),
      SizedBox(width: 6),
      Text(DateFormatter.getElapsedTime(
        fechaInicio: currentCashRegister.opening,
      )),
    ],
  ),
  badge: PremiumListTileBadge(
    label: 'ACTIVA',
    color: Colors.green.shade700,
  ),
  expandedInfo: timeInfo.map((info) => 
    ExpandableInfoItem(
      icon: info['icon'] as IconData,
      label: info['label'] as String,
      value: info['value'] as String,
    ),
  ).toList(),
  isMobile: isMobile,
)
```

## 🎯 Casos de Uso

1. **Listas de Cajas Registradoras**: Mostrar cajas activas/cerradas
2. **Catálogo de Productos**: Items de productos con detalles
3. **Historial de Ventas**: Tickets con información expandible
4. **Configuraciones**: Opciones con detalles adicionales
5. **Usuarios**: Lista de usuarios con roles y permisos
6. **Notificaciones**: Avisos con información detallada

## 📋 Notas

- Los widgets son **completamente responsive**
- Las animaciones tienen una duración de **300ms** (configurable internamente)
- El componente **no depende de providers** - es puramente presentacional
- Compatible con **Material Design 3**
- Optimizado para **performance** con `RepaintBoundary` implícito en animaciones
