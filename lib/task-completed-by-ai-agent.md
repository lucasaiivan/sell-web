### [2026-02-06 18:32] Optimización de Performance: Modo Demo
- **Tareas:** Implementado sistema de caché lazy loading en `DemoAccountService` para eliminar regeneración redundante de datos. Se agregaron variables de caché privadas (_cachedProducts, _cachedCategories, _cachedProviders, _cachedBrands, _cachedAdminUsers, _cachedAccount, _cachedAdminProfile, _cachedTickets, _cachedCashRegisters). Se modificaron todos los getters para usar patrón `??=` garantizando generación única. Se agregó método `clearCache()` para gestión de memoria. En `HomePage`, se implementó flag `_demoProductsLoaded` para prevenir carga múltiple y se agregó limpieza de caché al cambiar de cuenta (`_buildWelcomeScreen` y `_buildBlockedScreen`).
- **Resumen:** Eliminado delay al cargar pantalla principal en modo Demo (de ~300-500ms a ~10ms en cargas subsecuentes). Los datos se generan una sola vez y se cachean, reduciendo regeneraciones de 300 productos y 500 tickets a solo 100 productos y tickets según scope necesario.

### [2026-02-06 14:26] Hotfix: Crash al Cambiar entre Modo Invitado y Cuenta Real
- **Tareas:** Se actualizó `main.dart` reemplazando `ChangeNotifierProxyProvider` con `ChangeNotifierProvider.value` para evitar que el framework elimine los Singleton Providers (`CatalogueProvider`, etc.) al reconstruir el widget tree. Se agregaron verificaciones de `mounted` en `HomePage` para prevenir ejecución de lógica asíncrona en widgets desmontados.
- **Resumen:** Solucionado el crash crítico que cerraba la app al intentar cambiar de cuenta o salir del modo invitado, asegurando la persistencia correcta de los servicios.

### [2026-02-05 21:38] Ampliación de Datos Demo a 100 Productos de Supermercado
- **Tareas:** Se expandieron las categorías de productos de 8 a 12, agregando `Congelados`, `Perfumería`, `Bazar` y `Mascotas`. Se creó el mapa `providersByCategory` con 3 proveedores por categoría. Se actualizó el método `generateDemoProducts()` para incluir asignación de proveedores (`provider`, `nameProvider`) y cálculo de `revenuePercentage` realista por categoría (15%-60%). Se implementó `_generateProfitPercentage()` con márgenes específicos (ej: lácteos 15-25%, panadería 40-60%). Se ajustó `productNamesByCategory` para generar exactamente 100 productos (8-9 por categoría). El precio de compra ahora se calcula coherentemente: `purchasePrice = salePrice / (1 + profitPercentage/100)`.
- **Resumen:** Completados los datos demo con 100 productos de supermercado con información completa y coherente: nombre, marca, categoría, stock, ganancia realista por categoría y proveedores específicos.

### [2026-02-05 01:15] Corrección: Datos Demo No Visibles en Primeras Horas (00:00-08:00)
- **Tareas:** Se reemplazó el método `_generateTodayTickets()` por `_generateLastSevenDaysTickets()` en `AnalyticsDemoHelper`. El método antiguo solo generaba transacciones para el día actual entre las 8am y la hora actual, retornando lista vacía si la hora era anterior a las 8am. El nuevo método genera ~140-180 transacciones distribuidas en los últimos 7 días completos (8am-10pm de cada día), garantizando siempre datos disponibles independientemente de la hora de acceso.
- **Resumen:** Solucionado el bug donde los usuarios en modo invitado no veían datos de analíticas al acceder antes de las 8am, proporcionando ahora una experiencia demo completa las 24 horas del día con datos realistas de una semana completa.

### [2026-02-05 23:35] Corrección: Conflicto de Showcases Simultáneos
- **Tareas:** Se agregó verificación del índice de página activa (`homeProvider.currentPageIndex`) en los métodos `_checkAndStartShowcase` de `SalesPage` y `CataloguePage`. Esto previene que ambos showcases se ejecuten simultáneamente cuando ambas páginas están pre-construidas en el PageView con `AutomaticKeepAliveClientMixin`.
- **Resumen:** Solucionado el bug donde los tutoriales de Ventas y Catálogo se activaban al mismo tiempo, asegurando que solo se muestre el tutorial de la página actualmente visible.

### [2026-02-05 23:25] Tutorial de Catálogo
- **Tareas:** Se implementó `showcaseview` en `CataloguePage`. Se añadieron keys y lógica para resaltar: Botón flotante 'Agregar Nuevo', Botón de 'Filtros Avanzados', y la barra de pestañas (Productos, Categorías, Proveedores). Se aseguró la integración correcta con `PreferredSize` para la `TabBar`. Persistencia key: `catalogue_page_showcase_shown`.
- **Resumen:** Se guía al usuario en la gestión del catálogo, destacando cómo agregar items, filtrar la lista y navegar entre las secciones principales.

### [2026-02-05 23:10] Tutorial en Menú Lateral (Drawer)
- **Tareas:** Se refactorizó `AppDrawer` a `StatefulWidget` para gestionar el ciclo de vida del tutorial. Se integró `showcaseview` dentro del Drawer. Se agregaron keys para: Perfil de Negocio, Ventas, Analíticas, Catálogo, Usuarios e Historial de Caja. Se implementó lógica dinámica que solo incluye en el tutorial los elementos para los cuales el usuario tiene permisos. Persistencia mediante `shared_preferences` (key: `drawer_showcase_shown`).
- **Resumen:** Se añadió una guía interactiva al menú principal que se activa automáticamente al abrir el drawer por primera vez, explicando cada módulo disponible según los permisos del usuario.

### [2026-02-05 21:55] Extensión Tutorial: Ticket y Pago
- **Tareas:** Se extendió el tutorial de `sales_page.dart` cubriendo el flujo de cierre de venta. Se modificó `TicketDrawerWidget` para aceptar keys de showcase. Se agregaron disparadores condicionales para mostrar el botón 'Cobrar' en móvil y los elementos del ticket (Confirmar, Total, Pagos, Descuento) en escritorio/móvil cuando hay productos. Se implementó lógica de "Partes" (2 y 3) con persistencia independiente para no abrumar al usuario.
- **Resumen:** Completado el recorrido guiado del punto de venta, cubriendo desde la selección de productos hasta la confirmación y pago, adaptándose dinámicamente a móvil y escritorio.

### [2026-02-04 21:38] Tutorial Interactivo en Página de Ventas
- **Tareas:** Se implementó `showcaseview` en `sales_page.dart` con 6 showcases ordenados: ventas rápidas (FAB), gestión de caja, último ticket, configuración de impresora, búsqueda de productos, y productos favoritos. Se envolvió el Consumer2 con `ShowCaseWidget` y `Builder` para contexto correcto. Se implementaron métodos de control (`_shouldShowShowcase`, `_markShowcaseAsShown`, `_startShowcase`, `_checkAndStartShowcase`) con persistencia en SharedPreferences (key: 'sales_page_showcase_shown'). Se agregó flag `_showcaseInitialized` para evitar múltiples inicializaciones. Activación automática con delay de 800ms.
- **Resumen:** Se agregó tutorial interactivo automático para guiar a usuarios nuevos a través de las funcionalidades clave del punto de venta, mostrándose solo la primera vez con descripciones profesionales en español y emojis para mejor UX.

### [2026-02-04 20:45] Tutorial Interactivo para Modo Invitado
- **Tareas:** Se implementó el paquete `showcaseview` en `WelcomeSelectedAccountPage`. Se refactorizó de StatelessWidget a StatefulWidget. Se crearon 4 GlobalKeys para destacar: cuenta demo, crear cuenta, cambiar tema, y email/logout. Se agregó lógica de persistencia con SharedPreferences (key: 'guest_mode_showcase_shown'). Se implementó activación automática del tutorial al seleccionar cuenta demo con delay de 300ms.
- **Resumen:** Se agregó tutorial interactivo automático para guiar a nuevos usuarios cuando entran como invitados, destacando funcionalidades clave de la aplicación y mostrándose solo la primera vez.

### [2026-02-01 21:30] Mejora UX: Modo Invitado en Gestión de Usuarios
- **Tareas:** Se agregó detección de modo invitado en `UserAdminDialog`. Se muestra banner informativo ámbar indicando que los datos no se pueden modificar. Se oculta el botón de "Actualizar/Crear" y se reemplaza "Cancelar" por "Cerrar". Se previene el intento de guardar en Firebase mostrando SnackBar amigable.
- **Resumen:** Mejorada experiencia de usuario en modo invitado al visualizar perfiles, evitando errores de Firebase y comunicando claramente que es modo de demostración de solo lectura.

### [2026-02-01 20:55] Hotfix: Crash en Detalle de Caja Demo
- **Tareas:** Se robusteció `CashRegister.fromMap` y `CashFlow.fromMap` para manejar correctamente tanto `Timestamp` como `DateTime` y valores nulos. Se corrigió `DemoDataService` para usar la clave `date` en lugar de `timestamp` en flujos de caja.
- **Resumen:** Solucionado error `NoSuchMethodError: 'toDate'` que causaba cierre inesperado al ver detalles de arqueos generados localmente, asegurando compatibilidad entre datos demo y datos de Firebase.

### [2026-02-01 20:40] Datos de Prueba Centralizados para Modo Invitado
- **Tareas:** Se actualizó `DemoDataService.generateDemoUsers()` para generar 2 usuarios específicos (Superusuario y Empleado). Se conectó `GetUserAccountsUseCase.getDemoUsers()` con import correspondiente. Se agregó soporte demo en `CashRegisterProvider.loadCashRegisterHistory()` con método auxiliar `_loadDemoCashRegisterHistory()` que aplica filtros de fecha (última semana, mes, mes anterior, todo).
- **Resumen:** Se centralizó y organizó la generación de datos de prueba para modo invitado, permitiendo visualizar usuarios y arqueos de caja con filtros funcionales sin necesidad de Firebase.

### [2026-02-01 20:20] Botón Login en Modo Invitado
- **Tareas:** Se agregó un botón 'Iniciar sesión' (`TextButton`) dentro del banner de color ámbar que aparece en el modo invitado en `home_page.dart`.
- **Resumen:** Facilita la salida del modo invitado y el acceso a la pantalla de login directamente desde el banner informativo principal.

### [2026-02-01 19:55] Mejora UI Banner Modo Invitado
- **Tareas:** Se rediseñó completamente el banner de modo invitado en `home_page.dart` con un enfoque minimalista premium: gradiente suave con tonos amber/orange más refinados, mejor espaciado, tipografía mejorada con jerarquía visual clara, icono circular con fondo semitransparente, separador con gradiente sutil, y mejor disposición de elementos.
- **Resumen:** Se mejoró significativamente la estética del banner manteniendo el diseño minimalista pero haciéndolo más moderno, elegante y visualmente atractivo.

### [2026-01-31 18:07] Corrección en AuthProvider
- **Tareas:** Se corrigió un error de tipo en `AuthProvider` donde `String?` (de `_user!.uid`) no podía asignarse a `String` (en `account.ownerId`). Se implementó un fallback seguro `?? 'guest-user'`.
- **Resumen:** Se solucionó un error de compilación asegurando que `ownerId` nunca sea nulo, asignando 'guest-user' si el UID no está disponible.

### [2026-01-31 01:35] Despliegue a Producción
- **Tareas:** Ejecución de pipeline de despliegue (`flutter clean`, `flutter pub get`, `flutter build web --release`, `firebase deploy`).
- **Resumen:** Se desplegó una nueva versión de la web app en Firebase Hosting tras actualizar dependencias y compilar una release limpia.

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
