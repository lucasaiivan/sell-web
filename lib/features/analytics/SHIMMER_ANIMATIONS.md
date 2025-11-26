# Analytics - Animaciones de Carga

## Funcionalidad Implementada

### Shimmer Effect en MetricCards

Cuando cambias de filtro en Analytics, ahora verás una **animación shimmer elegante** mientras se cargan los nuevos datos.

## Componentes Creados

### 1. ShimmerWidget (`shimmer_widget.dart`)
Widget reutilizable que renderiza un efecto shimmer (brillo desplazándose):

```dart
ShimmerWidget(
  child: Container(
    width: 100,
    height: 20,
    color: Colors.white,
  ),
)
```

**Características:**
- Animación suave de gradiente lineal
- Duración configurable (default: 1.5 segundos)
- Se repite infinitamente
- Usa `SingleTickerProviderStateMixin` para performance

### 2. SkeletonLoader (`shimmer_widget.dart`)
Widget de conveniencia para crear esqueletos de carga rápidamente:

```dart
SkeletonLoader(
  width: 120,
  height: 28,
  borderRadius: BorderRadius.circular(6),
)
```

### 3. MetricCard Actualizada
Ahora acepta parámetro `isLoading`:

```dart
MetricCard(
  title: 'Transacciones',
  value: '150',
  icon: Icons.receipt_long,
  color: Colors.orange,
  isLoading: true, // <-- Muestra shimmer
)
```

## Comportamiento

### Estados Visuales

1. **Cargando (`isLoading: true`)**:
   - Muestra `SkeletonLoader` con shimmer
   - Rectángulo gris animado en lugar del valor
   - Icono y título permanecen visibles

2. **Cargado (`isLoading: false`)**:
   - Muestra el valor real
   - Transición suave con `AnimatedSwitcher`
   - Fade in de 300ms

### Flujo de Usuario

1. Usuario selecciona nuevo filtro (ej: "Este año")
2. `provider.isLoading` se pone en `true`
3. **Se muestra shimmer** en todas las MetricCards
4. Stream emite nuevos datos
5. `provider.isLoading` se pone en `false`
6. **Fade in** con los nuevos valores

## Animaciones Utilizadas

### AnimatedSwitcher
Transición entre widget de carga y widget de valor:

```dart
AnimatedSwitcher(
  duration: const Duration(milliseconds: 300),
  transitionBuilder: (child, animation) {
    return FadeTransition(
      opacity: animation,
      child: child,
    );
  },
  child: isLoading
      ? _buildLoadingValue(theme) // Shimmer
      : _buildValue(theme),       // Valor real
)
```

### Gradient Animation (dentro de ShimmerWidget)
```dart
_animation = Tween<double>(begin: -2.0, end: 2.0).animate(
  CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
);
```

Los stops del gradiente se mueven de -2.0 a 2.0, creando el efecto de "ola" que se desplaza.

## Performance

- **SingleTickerProviderStateMixin**: Optimiza las animaciones
- **AnimationController.repeat()**: Loop infinito eficiente
- **ShaderMask con LinearGradient**: Renderizado nativo, muy performante
- **AnimatedSwitcher**: Transición ligera con FadeTransition

## Personalización Futura

### Cambiar duración del shimmer:
```dart
ShimmerWidget(
  duration: Duration(milliseconds: 1000), // Más rápido
  child: ...
)
```

### Cambiar colores del shimmer:
En `shimmer_widget.dart`, modifica los `colors` del `LinearGradient`:
```dart
colors: const [
  Color(0xFFYOURCOLOR1),
  Color(0xFFYOURCOLOR2),
  Color(0xFFYOURCOLOR3),
],
```

### Cambiar duración del fade:
En `metric_card.dart`:
```dart
AnimatedSwitcher(
  duration: const Duration(milliseconds: 500), // Más lento
  ...
)
```

## Ejemplo Visual

```
[Filtro: Hoy]
┌─────────────────┐
│ 🟠 Icono       │
│ ███████        │  <- Shimmer animado
│ Transacciones  │
└─────────────────┘

↓ (300ms fade)

[Datos cargados]
┌─────────────────┐
│ 🟠 Icono       │
│ 1,234          │  <- Valor real
│ Transacciones  │
└─────────────────┘
```

## Beneficios

✅ **UX mejorada**: Usuario sabe que se están cargando datos  
✅ **Feedback visual**: No hay "congelamiento" aparente  
✅ **Profesional**: Mismo patrón que apps populares (Facebook, LinkedIn)  
✅ **Performance**: Animación nativa, sin impacto en FPS  
✅ **Reutilizable**: `ShimmerWidget` se puede usar en otros features
