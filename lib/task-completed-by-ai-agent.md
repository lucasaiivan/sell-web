### [2026-02-19 21:07] Fix: Detección de Certificado SSL en Flutter Web (Impresora Local)
- **Tareas:** Reemplazado `_isCertificateError()` por `_isPossibleCertOrNetworkError()` en `thermal_printer_http_service.dart` para detectar `XmlHttpRequestError` genérico de Flutter Web. Actualizado `_probeUrl()` para marcar probes HTTPS como `isCertError:true` cuando el error es de red genérico. Simplificada condición en `autoDiscover()` para activar flujo de cert si cualquier probe HTTPS falla. Mejorado `printer_config_dialog.dart` con flujo de 3 pasos claro (Verificar app → Abrir servidor → Reintentar) y auto-polling (`Timer` cada 3s) que detecta automáticamente cuando el usuario acepta el cert.
- **Resumen:** Solucionado el bug donde la webapp siempre mostraba "Servidor no disponible" en vez de "Certificado HTTPS pendiente", porque `fetch()` en Flutter Web no expone strings de certificado en el error.

### [2026-02-19 14:15] UX: Mejorada Compartición de Ticket (Descarga PDF Web)
- **Tareas:** Implementado helper de descarga `downloadFile` usando imports condicionales (`dart:html` para Web, stub para móvil) para garantizar descarga nativa de PDF en navegador. Actualizado `ShareTicketDialog`: en Web muestra botón "Descargar PDF" (icono `download`), en móvil "Compartir PDF" (icono `share`).
- **Resumen:** Solucionado problema de descarga de PDF en Web y mejorada la claridad de la UI según plataforma.

### [2026-02-19 11:32] Despliegue a Producción (Web)
- **Tareas:** Ejecución de pipeline de despliegue (`flutter clean`, `flutter pub get`, `flutter build web --release` sin WASM, `firebase deploy --only hosting`).
- **Resumen:** Despliegue exitoso de nueva versión en Firebase Hosting con la funcionalidad de Compartir Ticket.

### [2026-02-19 11:05] Feature: Compartir Ticket Multiplataforma (Web + Móvil)
- **Tareas:** Creado `ticket_share_service.dart` (`@lazySingleton`) con métodos `generateTicketText()`, `shareAsText()`, `copyToClipboard()`, `shareAsPdf()`, `shareViaWhatsApp()` usando `SharePlus.instance.share(ShareParams(...))` y `url_launcher`. Creado `share_ticket_dialog.dart` (MD3, vista previa + grid 2x2 con feedback y auto-dismiss). Actualizado `ticket_options_dialog.dart` (opción habilitada, conectada con nuevo diálogo). Registrado `TicketShareService` en `injection_container.config.dart`. `flutter analyze`: No issues found.
- **Resumen:** Implementada la función "Compartir Ticket" con soporte para Texto, PDF, portapapeles y WhatsApp tanto en Web como en móvil, cumpliendo Clean Architecture y MD3.

### [2026-02-19 10:38] Refactor: Auto-Discovery Multi-Protocolo de Impresora + UI Simplificada
- **Tareas:** Reescrito `thermal_printer_http_service.dart` con auto-discovery en paralelo (6 estrategias: HTTPS+HTTP × {puerto ingresado, 8080, 3000}), callback `onDiscoveryProgress` para UI en tiempo real, protocolo resuelto persistido. Reescrito `printer_config_dialog.dart`: solo host+puerto, pasos animados de detección, 4 fases (idle/scanning/success/error). Eliminado campo API Token de la UI. Actualizado `printer_provider.dart`, `shared_prefs_keys.dart`, `app_data_persistence_service.dart`.
- **Resumen:** Conexión con impresora ahora detecta automáticamente HTTP/HTTPS y puerto correcto sin intervención del usuario.

### [2026-02-18 22:30] Fix: Corrección Errores Impresora + 7 Estados Visuales
- **Tareas:** Bug 1 corregido: `response['error']` → `response['message']` en `checkConnection()`. Bug 2: `initialize()` solo conecta si hay config previa. Bug 3: `configurePrinter()` retorna `PrinterConnectionResult` (no doble petición). Agregado `PrinterErrorType` enum (7 categorías). Reescrito `printer_config_dialog.dart` con banner animado y card de error con pasos específicos por error. Adaptados `sales_provider.dart` y `ticket_options_dialog.dart`.
- **Resumen:** Eliminado el error genérico "Servidor no responde correctamente" con diagnóstico preciso y UX visual diferenciada para cada tipo de fallo.

### [2026-02-18 21:37] Migración Servicio de Impresora: HTTP → HTTPS
- **Tareas:** Reescrito `thermal_printer_http_service.dart` (HTTPS, API token Bearer, heartbeat, certificado auto-firmado, `PrinterConnectionResult`). Actualizado `printer_provider.dart`, `printer_config_dialog.dart` (guía certificado, API token, puerto 8080), `ticket_options_dialog.dart` (eliminados métodos stub). Agregado `printerApiToken` en `shared_prefs_keys.dart` y `app_data_persistence_service.dart`.
- **Resumen:** Migrado servicio de impresora de HTTP a HTTPS para compatibilidad con webapp HTTPS, evitando Mixed Content. Soporte para certificado auto-firmado con guía visual al usuario.

### [2026-02-14 02:00] Despliegue a Producción (Web)
- **Tareas:** Ejecución de pipeline de despliegue (`flutter clean`, `flutter pub get`, `flutter build web --release`, `firebase deploy --only hosting`). Se omitió `--web-renderer canvaskit` debido a su ausencia en las opciones actuales.
- **Resumen:** Despliegue exitoso de nueva versión en Firebase Hosting con configuración por defecto.

### [2026-02-14 01:35] Mejora UX: Toggle Grid/List
- **Tareas:** Se movió el botón de alternar vista (Grid/List) de la `AppBar` a la parte superior de la lista de productos. Se reemplazó el `IconButton` por un `TextButton.icon` alineado a la derecha para mayor claridad y accesibilidad, visible solo en móvil.
- **Resumen:** El control para cambiar la visualización de productos es ahora más accesible y explícito, ubicado contextualmente sobre el listado.

### [2026-02-14 01:30] Diseño Grid Transparente en Catálogo
- **Tareas:** Se modificó `_ProductCatalogueCard` en `catalogue_page.dart` para tener fondo `transparent`, `elevation: 0` y un borde sutil (`BorderSide` con `outline`). Se eliminó variable `isDark` no utilizada.
- **Resumen:** Las tarjetas de producto en vista de cuadrícula ahora siguen un diseño lineal (bordes) sin fondo, integrándose mejor con el estilo visual solicitado.

### [2026-02-14 01:25] Mejora UI: Margen en Item de Lista de Producto
- **Tareas:** Se actualizó `ProductListTile` en `product_list_tile.dart` agregando un margen (`SizedBox(width: 12)`) entre la información del producto y la columna de precio/ganancia en la vista móvil.
- **Resumen:** Se mejoró la legibilidad de la lista de productos añadiendo separación visual entre el contenido descriptivo y los datos numéricos.

### [2026-02-12 07:35] Tarjetas Expandibles en Vista de Producto
- **Tareas:** Se refactorizó `_buildInfoCard` en `product_catalogue_view.dart` para ser expandible/contraíble con fondo transparente y borde. Se agregó `_expandedCards` Set con índice 0 expandido por defecto. Se usó `AnimatedCrossFade` y `AnimatedRotation` para animaciones suaves.
- **Resumen:** Las tarjetas de información del producto ahora son expandibles/contraíbles con diseño limpio (borde + fondo transparente), la primera "Precios y margen" abierta por defecto.

### [2026-02-11 22:57] Mejora UI: Margen Inferior en Lista de Productos
- **Tareas:** Se actualizó `CataloguePage` agregando padding inferior en `_buildGridView` y `_buildListView` para asegurar un margen de 50dp al final del scroll.
- **Resumen:** Se añadió un margen de 50dp al final de las listas de productos para mejorar la visualización.

### [2026-02-11 22:55] Fix: Scroll con Mouse en Lista de Marcas
- **Tareas:** Se actualizó `brand_stories_list.dart` envolviendo el `ListView` con `ScrollConfiguration` y agregando `PointerDeviceKind.mouse` a `dragDevices`. Se importó `flutter/gestures.dart`.
- **Resumen:** Habilitado el scroll mediante arrastre con mouse en la lista horizontal de marcas del catálogo.

### [2026-02-11 00:57] Despliegue a Producción (Web)
- **Tareas:** Ejecución de pipeline de despliegue (`flutter clean`, `flutter pub get`, `flutter build web --release`, `firebase deploy --only hosting`). Se omitió `--web-renderer canvaskit` por deprecación en Flutter 3.35.7+.
- **Resumen:** Despliegue exitoso de nueva versión en Firebase Hosting con configuración optimizada por defecto.

### [2026-02-11 00:35] Fix: Error de Compilación en Catálogo
- **Tareas:** Se creó el archivo `brand_stories_list.dart` faltante en `lib/features/catalogue/presentation/widgets/`. Se implementó el widget `BrandStoriesList` para mostrar historias de marcas horizontalmente usando `AvatarItem`. Se verificó la corrección mediante `flutter analyze`.
- **Resumen:** Solucionado el error de compilación que impedía ejecutar la app debido a la referencia a un archivo inexistente en `CataloguePage`.

### [2026-02-08 11:15] Mejora UX: Menú Contextual en Listas de Catálogo
- **Tareas:** Se agregaron `PopupMenuButton` en `CategoriesListView` y `ProvidersListView` dentro de `CataloguePage`. Se implementó lógica de confirmación de eliminación (`_showDeleteConfirmation`) en los estados correspondientes.
- **Resumen:** Ahora es posible editar y eliminar categorías y proveedores directamente desde la vista de lista (móvil) mediante un menú contextual, igualando la funcionalidad de la vista de tabla (escritorio).

### [2026-02-07 01:56] Mejora Visual: Brillo de Tabs en Catálogo
- **Tareas:** Se actualizó `CataloguePage` para asignar un color de indicador específico (`Color(0xFF3E3E)`) en modo oscuro y `surface` (blanco) en modo claro.
- **Resumen:** Se mejoró la distinción visual de la pestaña seleccionada en ambos temas, asegurando un brillo adecuado para el modo oscuro.

### [2026-02-10 00:45] Unificar patrón de estilos de chips en vista web
- **Tareas:** Refactorizada sección `summaryWebContent` en `product_catalogue_view.dart` para usar `_buildMetaChip` y `_buildStatusChip` con el mismo patrón que mobile.
- **Resumen:** Se eliminó el chip personalizado de marca y se reorganizaron categoría/proveedor de metadatos a chips de estado, logrando consistencia visual entre mobile y web.

### [2026-02-10 00:25] Agregar parámetros a `_buildMetaChip`
- **Tareas:** Modificado `_buildMetaChip` en `product_catalogue_view.dart` para aceptar `accentColor` y `radius`.
- **Resumen:** Se añadieron parámetros opcionales para personalizar el color de acento y el radio del borde en el widget de chips de metadatos.

### [2026-02-09 06:40] Deploying Web App to Production
- **Tareas:** Ejecución de pipeline de despliegue (`flutter clean`, `flutter pub get`, `flutter build web --release`, `firebase deploy --only hosting`).
- **Resumen:** Se desplegó una nueva versión de la web app en Firebase Hosting tras construir una release limpia.

### [2026-02-07 01:35] Despliegue a Producción
- **Tareas:** Ejecución de pipeline de despliegue (`flutter clean`, `flutter pub get`, `flutter build web --release`, `firebase deploy --only hosting`).
- **Resumen:** Se desplegó una nueva versión de la web app en Firebase Hosting tras construir una release limpia.

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
