# CreationSuccessView

Widget reutilizable para mostrar confirmación visual de procesos de creación con animación de éxito.

## 📍 Ubicación
`lib/core/presentation/widgets/success/creation_success_view.dart`

## ✨ Características

- ✅ **Pantalla completa** con dos estados:
  - Estado de carga con `CircularProgressIndicator`
  - Estado de éxito con animación Lottie (check)
- 🎨 **Completamente personalizable**: Textos, duraciones, sonido
- 🔊 **Sonido de éxito** opcional (configurable)
- ⏱️ **Duraciones configurables** para cada estado
- 📱 **Responsive** y adaptable a tema claro/oscuro
- 🎯 **Callback** al completar la animación

## 🎯 Parámetros

| Parámetro | Tipo | Requerido | Por Defecto | Descripción |
|-----------|------|-----------|-------------|-------------|
| `loadingText` | `String` | ❌ | `'Procesando...'` | Texto mostrado durante la carga |
| `successTitle` | `String` | ❌ | `'¡Completado!'` | Título del estado de éxito |
| `successSubtitle` | `String?` | ❌ | `null` | Subtítulo destacado (ej: nombre del elemento creado) |
| `finalText` | `String?` | ❌ | `'Redirigiendo...'` | Texto final debajo del subtítulo |
| `loadingDuration` | `int` | ❌ | `1500` | Duración del estado de carga en ms |
| `successDuration` | `int` | ❌ | `2000` | Duración del estado de éxito en ms |
| `playSound` | `bool` | ❌ | `true` | Si debe reproducir sonido de éxito |
| `soundAssetPath` | `String` | ❌ | `'sounds/sale_success.mp3'` | Ruta del archivo de sonido |
| `onComplete` | `VoidCallback?` | ❌ | `null` | Callback al completar la animación |

## 📖 Ejemplos de Uso

### Ejemplo 1: Creación de Cuenta (Uso actual)

```dart
Navigator.of(context).push(
  MaterialPageRoute(
    builder: (context) => CreationSuccessView(
      loadingText: 'Creando cuenta\nEspere un momento...',
      successTitle: '¡Cuenta creada!',
      successSubtitle: 'Mi Tienda Online',
      finalText: 'Redirigiendo...',
      onComplete: () {
        Navigator.of(context).pop();
      },
    ),
  ),
);
```

### Ejemplo 2: Creación de Producto

```dart
Navigator.of(context).push(
  MaterialPageRoute(
    builder: (context) => CreationSuccessView(
      loadingText: 'Agregando producto...',
      successTitle: '¡Producto agregado!',
      successSubtitle: 'Coca-Cola 500ml',
      finalText: null, // Sin texto final
      loadingDuration: 1000, // Más rápido
      successDuration: 1500,
      onComplete: () {
        Navigator.of(context).pop();
        // Lógica adicional...
      },
    ),
  ),
);
```

### Ejemplo 3: Proceso sin Sonido

```dart
Navigator.of(context).push(
  MaterialPageRoute(
    builder: (context) => CreationSuccessView(
      loadingText: 'Guardando cambios...',
      successTitle: '¡Guardado!',
      playSound: false, // Sin sonido
      onComplete: () {
        Navigator.of(context).pop();
      },
    ),
  ),
);
```

### Ejemplo 4: Confirmación Mínima

```dart
Navigator.of(context).push(
  MaterialPageRoute(
    builder: (context) => CreationSuccessView(
      successTitle: '¡Listo!',
      loadingDuration: 500,
      successDuration: 1000,
      finalText: null,
      successSubtitle: null,
      onComplete: () {
        Navigator.of(context).pop();
      },
    ),
  ),
);
```

## 🎬 Flujo de Animación

```
1. Vista se monta
   ↓
2. Muestra estado de carga (CircularProgressIndicator + loadingText)
   ↓ [loadingDuration ms]
3. Cambia a estado de éxito
   ↓
4. Reproduce sonido (si playSound = true)
   ↓
5. Anima el check con ScaleTransition (800ms)
   ↓
6. Muestra successTitle, successSubtitle (si existe), finalText (si existe)
   ↓ [successDuration ms]
7. Ejecuta onComplete()
```

## ⏱️ Tiempos Recomendados

| Acción | Loading | Success | Total |
|--------|---------|---------|-------|
| **Rápida** | 500ms | 1000ms | 1.5s |
| **Normal** (defecto) | 1500ms | 2000ms | 3.5s |
| **Lenta/Importante** | 2000ms | 3000ms | 5s |

## 🔧 Personalización Avanzada

Si necesitas personalizar aún más (colores, animaciones diferentes, etc.), puedes:

1. Copiar el widget a tu feature específico
2. Extender la clase y sobrescribir métodos específicos
3. Crear una variante del widget con diferentes assets

## 📝 Notas

- El widget usa `Lottie` para la animación de check (`assets/anim/success_check.json`)
- El sonido por defecto es `sounds/sale_success.mp3`
- Se adapta automáticamente a tema claro/oscuro
- Usa `ScaleTransition` con `Curves.elasticOut` para un efecto más dinámico

## 🎨 Diseño

El widget sigue los principios de Material Design 3 y se adapta al tema de la aplicación.
