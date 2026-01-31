### [2026-01-31 01:23] Mejora UI Botón Combos y Click en Items
- **Tareas:** Se actualizó el botón de acción en sección Combos para mostrar 'Editar' (Icono Edit) si hay items. Se hicieron clickeables los items del listado resumen para abrir el modal de gestión.
- **Resumen:** Se mejoró la intuitividad de la interfaz de combos permitiendo editar directamente al hacer click en los items y reflejando el estado de edición en el botón principal.

### [2026-01-30 21:30] Simplificación Textos Dialog Creación Rápida
- **Tareas:** Se simplificaron los textos en `_showQuickCreateDialog` ("Nuevo Item", "Nombre", "Crear") y se eliminó la descripción larga para una interfaz más directa.
- **Resumen:** Se hizo más conciso el diálogo de creación rápida de items en combos para mejorar la velocidad de interacción.

### [2026-01-30 21:20] Ui clean: Vista Previa Producto
- **Tareas:** Se eliminó el contenedor `_buildSectionContainer` en `_buildPreviewProductCard`. Se ajustó el layout a `Center` con `Row` (MainAxisSize.min) y mayor espaciado.
- **Resumen:** Se limpió la sección de "Vista previa" eliminando el marco contenedor para una presentación más ligera y centrada del producto.

### [2026-01-30 18:55] Reubicación Campo Expiración
- **Tareas:** Se movió el campo "Válido hasta" (fecha de expiración) de la sección de Combos a la sección de Inventario y Stock en `ProductEditCatalogueView`.
- **Resumen:** Se reorganizó la UI para unificar la gestión temporal del producto (expiración) junto con el control de inventario/stock.

### [2026-01-30 18:25] Corrección Navegación Eliminar Producto
- **Tareas:** Se actualizó `_deleteProduct` en `ProductEditCatalogueView` incrementando `popCount` a 3.
- **Resumen:** Se corrigió el flujo de navegación al eliminar un producto para asegurar el retorno al catálogo y evitar la vista de detalle obsoleta.

### [2026-01-30 14:45] Items de Combo Locales (Ad-Hoc)
- **Tareas:** Se modificó `_createQuickProduct` para generar items locales con ID temporal (`temp_...`) en lugar de persistirlos en el catálogo global.
- **Resumen:** Ahora los productos creados desde "Creación Rápida" son exclusivos del combo actual, evitando contaminar el catálogo principal con items temporales.

### [2026-01-30 14:15] Convertir Card de Resumen en Botón de Acción
- **Tareas:** Se eliminó el botón explícito "Gestionar productos". Se actualizó la tarjeta de Resumen Financiero para comportarse y lucir como un botón cuando no hay datos financieros, y como una tarjeta sutil cuando los tiene.
- **Resumen:** Se unificó la acción de gestión en un solo elemento de UI (la tarjeta), mejorando la estética y reduciendo redundancia visual.

### [2026-01-30 13:58] Corregir espaciado visual en Resumen de Combos
- **Tareas:** Se ajustó la lógica en `_buildComboSection` para que el `Divider` y el espaciado inferior solo se rendericen si existe al menos un valor financiero > 0.
- **Resumen:** Se solucionó un problema visual donde se mostraba una línea divisora y espacio vacío innecesario cuando el combo no tenía costos ni precio asignado.

### [2026-01-30 13:50] Mejorar Resumen Financiero en Combos
- **Tareas:** Se actualizó `_buildComboSection` para ocultar automáticamente las filas de "Valor Real", "Costo Total" y "Precio Final" si sus valores son 0.
- **Resumen:** Se limpió la interfaz del resumen financiero, mostrando solo la información relevante y ocultando valores en cero para una visualización más concisa.

### [2026-01-30 13:35] Mejorar UX de creación rápida en Combos
- **Tareas:** Se implementó un estado de carga (`_isCreating`) con indicador visual durante la creación de productos. Se rediseñó la vista vacía de búsqueda con textos más claros y un botón de creación más prominente.
- **Resumen:** Se optimizó el flujo de creación de productos rápidos para que sea más intuitivo y fluido, proporcionando feedback inmediato al usuario.

### [2026-01-30 13:15] Restaurar botón de gestión en Combos
- **Tareas:** Se reincorporó el botón `AppButton.outlined` "Gestionar productos" debajo del resumen financiero en `_buildComboSection`.
- **Resumen:** A petición del usuario, se mantuvo el botón explícito para gestionar productos además de la interacción en la tarjeta de resumen.

### [2026-01-30 13:00] Refactorización UI de Combos
- **Tareas:** `_buildComboSection` ahora muestra un resumen financiero en lugar de la lista completa. `_buildProductCard` oculta el precio si es 0 en búsqueda y listado.
- **Resumen:** Se simplificó la vista principal de combos con un card de resumen y se mejoró la visualización de items gratuitos u opcionales ocultando su precio cero.

### [2026-01-30 12:35] Implementar creación rápida de items en Combo
- **Tareas:** Implementado `_createQuickProduct` y `_showQuickCreateDialog` en `_ComboManagementSheet`. Agregado botón de creación en la vista de búsqueda vacía.
- **Resumen:** Se añadió la funcionalidad de crear productos rápidos (solo nombre) directamente desde el modal de gestión de combos para facilitar el flujo de trabajo.

### [2026-01-30 12:05] Mejorar UX de Combo Section
- **Tareas:** Actualizado `_buildComboSection` para mejorar UI de items y hacerlos clickeables. Actualizado `_showComboItemsModal` para agregar título grande.
- **Resumen:** Se mejoró la experiencia de usuario en la gestión de combos, haciendo los items interactivos y agregando un título claro en el modal de gestión.

### [2026-01-29 20:50] Despliegue a Producción
- **Tareas:** Ejecución de pipeline de despliegue (Clean, Build Web Release, Firebase Deploy).
- **Resumen:** Actualización exitosa del entorno de producción en Firebase Hosting.

### [2026-01-29 20:30] Refinamiento Chips Combo
- **Tareas:** Actualización de `_buildComboSubtitle` para mostrar Valor Real (tachado si aplica) y Precio Final en vista colapsada.
- **Resumen:** Mejora en la visualización de resumen financiero en la sección de combos.

### [2026-01-29 16:30] Mejora UI Sección Combos
- **Tareas:** Refactor `_buildComboSection` usando `ListTileAppExpanded`, creación de `_ComboManagementSheet` optimizado, mejora en `BaseBottomSheet` para auto-focus.
- **Resumen:** Se estandarizó la UI de combos igualando el estilo de la calculadora de márgenes y mejorando la UX de selección de productos.
