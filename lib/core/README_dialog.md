# Diálogo Agregar Producto Público - Documentación

## Descripción
El método `showDialogAgregarProductoPublico` ha sido mejorado para manejar dos casos de uso principales:

1. **Agregar producto existente**: Cuando se encuentra un producto en la base de datos pública
2. **Crear producto nuevo**: Cuando no se encuentra el producto y se necesita crear uno nuevo

## Parámetros

```dart
Future<void> showDialogAgregarProductoPublico(
  BuildContext context, {
  required ProductCatalogue product, 
  String? errorMessage,
  bool isNew = false, // Parámetro clave para determinar el modo
})
```

### Parámetros:
- `context`: BuildContext requerido para mostrar el diálogo
- `product`: Producto base que se va a procesar
- `errorMessage`: Mensaje de error opcional para mostrar
- `isNew`: **NUEVO** - Define el comportamiento del diálogo:
  - `false` (por defecto): Modo "agregar existente"
  - `true`: Modo "crear nuevo"

## Modos de Funcionamiento

### Modo 1: Agregar Producto Existente (`isNew = false`)
- **UI**: Muestra información del producto como solo lectura
- **Título**: "Producto encontrado"
- **Icono**: Descarga de nube (verde)
- **Opciones**:
  - ✅ Agregar al catálogo local
  - 💰 Establecer precio de venta
- **Acciones**:
  - Siempre agrega al ticket actual
  - Opcionalmente guarda en catálogo local

### Modo 2: Crear Producto Nuevo (`isNew = true`)
- **UI**: Campos editables para descripción y código
- **Título**: "Crear nuevo producto"
- **Icono**: Círculo con plus (azul)
- **Opciones**:
  - ✅ Agregar al catálogo local
  - 🌐 Crear en base de datos pública
  - 💰 Establecer precio de venta
  - ✏️ Editar descripción
  - 🏷️ Editar código de barras
- **Acciones**:
  - Siempre agrega al ticket actual
  - Opcionalmente crea en base pública
  - Opcionalmente guarda en catálogo local

## Flujo de Trabajo

### Para Producto Existente:
1. Usuario escanea código
2. Sistema encuentra producto en base pública
3. Llama `showDialogAgregarProductoPublico(context, product: found, isNew: false)`
4. Usuario establece precio y confirma
5. Producto se agrega al ticket
6. Opcionalmente se guarda en catálogo local

### Para Producto Nuevo:
1. Usuario escanea código
2. Sistema no encuentra producto
3. Llama `showDialogAgregarProductoPublico(context, product: empty, isNew: true)`
4. Usuario completa descripción, código y precio
5. Usuario decide si crear en base pública
6. Producto se agrega al ticket
7. Opcionalmente se crea en base pública
8. Opcionalmente se guarda en catálogo local

## Ejemplos de Uso

### Caso 1: Producto Encontrado
```dart
// Producto encontrado en base pública
await showDialogAgregarProductoPublico(
  context,
  product: productFoundInPublic,
  isNew: false,
);
```

### Caso 2: Producto Nuevo
```dart
// Crear producto desde código escaneado
await showDialogAgregarProductoPublico(
  context,
  product: ProductCatalogue(
    id: '',
    code: scannedCode,
    description: '',
    // ... otros campos
  ),
  isNew: true,
);
```

### Caso 3: Con Mensaje de Error
```dart
// Mostrar error previo
await showDialogAgregarProductoPublico(
  context,
  product: product,
  errorMessage: 'Error al conectar con servidor',
  isNew: false,
);
```

## Validaciones Implementadas

### Comunes:
- ✅ Precio debe ser mayor a 0
- ✅ Manejo de errores de conexión
- ✅ Validación de campos requeridos

### Específicas para Producto Nuevo:
- ✅ Descripción no puede estar vacía
- ✅ Código no puede estar vacío
- ✅ Generación automática de ID si está vacío

## Características de UX

### Diseño Adaptativo:
- 🎨 Colores dinámicos según el modo
- 📱 ScrollView para contenido largo
- 🌙 Soporte para tema claro/oscuro
- ♿ Controles accesibles

### Feedback Visual:
- 🟢 Verde para productos existentes
- 🔵 Azul para productos nuevos
- 🔴 Rojo para errores
- ✨ Animaciones suaves en checkboxes

### Gestión de Estados:
- 🔄 Actualización reactiva de UI
- 💾 Preservación de datos entre errores
- ⚡ Cierre inmediato tras confirmación
- 🔙 Reapertura automática en caso de error

## Integración con Arquitectura

El diálogo está completamente integrado con:
- 📦 **Providers**: CatalogueProvider, SellProvider
- 🏗️ **Clean Architecture**: Casos de uso separados
- 🗄️ **Firebase**: Base pública y catálogos privados
- 🎯 **Material 3**: Diseño consistente
- 🌐 **Provider Pattern**: Gestión de estado

## Notas de Desarrollo

- ✅ Código sigue convenciones del proyecto
- ✅ Comentarios en español para secciones complejas
- ✅ Manejo robusto de errores
- ✅ Validaciones de entrada
- ✅ UI responsiva y accesible
