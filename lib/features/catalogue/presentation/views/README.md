# Vistas de Catálogo

Este directorio contiene vistas de pantalla completa para funcionalidades específicas del catálogo.

## ProductSearchFullScreenView

Vista de pantalla completa para buscar y agregar productos al catálogo con **detección automática de entrada escaneada vs manual**.

### Funcionalidades

1. **Entrada de código de barras**: Campo de texto centrado para ingresar el código del producto.

2. **Detección automática de modo de entrada** 🆕:
   - **Escáner**: Detecta cuando el código se ingresa rápidamente (< 50ms entre caracteres)
   - **Manual**: Detecta cuando el usuario escribe normalmente
   - **Indicador visual**: Badge animado muestra el modo detectado
   - **Override manual**: Botón para forzar modo "escaneado" si es necesario

3. **Reglas de negocio**:
   - **Código escaneado** → `local: false` → Se guarda en BD global de la app
   - **Código manual** → `local: true` → Se guarda solo en catálogo del comercio
   - **Prevención de spam**: Evita códigos falsos en la BD global

4. **Búsqueda inteligente**: Al buscar un producto, el sistema:
   - Primero busca en el catálogo local del comercio
   - Si no existe localmente, busca en la base de datos global de productos
   - Si no existe en ningún lado, permite crear un producto nuevo

5. **Flujo de creación/edición**:
   - Si el producto existe localmente → Abre `ProductEditCatalogueView` en modo edición
   - Si existe en BD global pero no localmente → Crea referencia en catálogo con datos del producto global
   - Si no existe → Abre `ProductEditCatalogueView` en modo creación (respetando `local`)

6. **Controles flotantes**:
   - **FAB Teclado**: Siempre visible, permite enfocar el campo de texto
   - **FAB Buscar**: Animado, solo visible cuando hay texto ingresado

### Ejemplo de uso

```dart
final catalogueProvider = Provider.of<CatalogueProvider>(context, listen: false);
final salesProvider = Provider.of<SalesProvider>(context, listen: false);

Navigator.of(context).push(
  MaterialPageRoute(
    builder: (_) => ProductSearchFullScreenView(
      catalogueProvider: catalogueProvider,
      salesProvider: salesProvider,
    ),
  ),
);
```

### Integración

Esta vista se abre desde el FAB "Agregar" en `CataloguePage`.

### Consideraciones técnicas

- Utiliza `CatalogueProvider.searchByExactCode()` para búsqueda local
- Utiliza `CatalogueProvider.getPublicProductByCode()` para búsqueda global
- **Detección de escáner**: Mide tiempo entre pulsaciones (< 50ms = escaneado)
- **Productos escaneados** (`local: false`): Se guardan en BD global
- **Productos manuales** (`local: true`): Solo en catálogo del comercio
- Los productos de la BD global se marcan con `local=false`

### Algoritmo de Detección

```dart
// Umbral de tiempo entre caracteres
static const _scannerThresholdMs = 50;

// Lógica de detección
if (timeBetweenChars < 50ms && length > 3) {
  → Modo escaneado (local: false)
} else if (timeBetweenChars > 150ms) {
  → Modo manual (local: true)
}
```

### Indicadores Visuales

- 🟢 **Verde**: "Código escaneado" - Guardará en BD global
- 🔵 **Azul**: "Código manual" - Guardará solo en catálogo local
- Botón "Marcar como escaneado" disponible para override
