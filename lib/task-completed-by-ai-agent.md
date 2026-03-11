### [2026-03-11 12:20] Mejora UI/UX: Cloud Print Queue Dialog + ClearQueue Feature
- **Tareas:** Agregado `clearPrintQueue` en `ICloudPrintRepository`, `CloudPrintRepositoryImpl` (WriteBatch atómico), `ClearPrintQueueUseCase`, y `CloudPrintProvider.clearQueue()`. Reescrito `cloud_print_queue_dialog.dart` con items enriquecidos: badge semántico de estado (`_PrintStatusChip`: waiting/printed/failed), avatar dinámico (`_StatusAvatar`), monto total formateado, cantidad de artículos, fecha/hora, color del medio de pago. Botón "Limpiar todo" (con confirmación) en las acciones del dialog. Subtítulo dinámico con contador de documentos en cola.
- **Resumen:** Se mejoró sustancialmente la UI/UX del diálogo de cola de impresión, aportando información clave al usuario y la capacidad de limpiar toda la cola en una operación atómica.

### [2026-03-08 00:07] Migración de Cola de Impresión a TicketModel
- **Tareas:** Se eliminaron las clases `PrintJob` y `PrintItem`. Se actualizó `TicketModel` agregando la propiedad `printStatus` ('waiting', 'printed', 'failed'). Se refactorizaron `ICloudPrintRepository`, `CloudPrintRepositoryImpl`, `CloudPrintProvider`, casos de uso y diálogos de UI para operar nativamente sobre `TicketModel`.
- **Resumen:** Se optimizó la arquitectura eliminando la redundancia de modelos, unificando el flujo de ventas e impresión bajo una misma entidad de dominio con control de estado de impresión.

### [2026-03-06 01:15] Refactorización Cloud Print a Clean Architecture
- **Tareas:** Creación de entidades `PrintJob`/`PrintItem`, repositorio `ICloudPrintRepository`, implementación en Data, y UseCases. Refactorización de `CloudPrintProvider`, `DrawerTicket`, `SalesProvider` y diálogos para usar datos tipados.
- **Resumen:** Se desacopló la lógica de impresión de la UI y Firestore, implementando Clean Architecture para mejorar la mantenibilidad y robustez del sistema de impresión.

### [2026-03-05 20:55] Orden descendente en Cola de Impresión
- **Tareas:** Se modificó `cloud_printer_service.dart` cambiando `descending: false` a `descending: true` en la consulta `getTicketQueue`.
- **Resumen:** Se optimizó la visualización de la cola de impresión para que los tickets más recientes aparezcan al principio de la lista.

### [2026-02-28 07:29] Mejora UX: Feedback Inmediato en Botón Recibo
- **Tareas:** Se agregó el estado de carga `_isProcessingReceipt` al widget `_TicketConfirmedPurchase`. Al presionar el botón "Recibo" se muestra un `CircularProgressIndicator` y el texto cambia a "Procesando..." de manera instantánea, bloqueando peticiones duplicadas durante las llamadas de red.
- **Resumen:** Se mejoró sustancialmente la UX del flujo post-venta añadiendo respuesta visual instantánea y estado de carga mientras se evalúa/envía el ticket, eliminando la latencia visual percibida.

### [2026-02-28 07:14] Mejora Flujo Post-Venta: Preferencia de Ticket Persistente
- **Tareas:** Modificado `ticket_options_dialog.dart` para guardar y cargar preferencia de opción de ticket en `SharedPreferences` (clave `ticket_option_preference`: `'print'`/`'share'`). Modificado `drawer_ticket.dart` en `_TicketConfirmedPurchaseState`: botón Recibo ejecuta directamente según preferencia (imprimir/compartir sin dialog), botón `IconButton` (⚙️) añadido al lado del Recibo que siempre abre el dialog de opciones, todas las acciones post-ticket limpian el estado con `onAnimationComplete`.
- **Resumen:** El flujo post-venta recuerda la elección del usuario para opciones de ticket, ejecutando directamente la acción preferida (imprimir o compartir) y permitiendo cambiarlo con el botón de configuración.

### [2026-02-27 00:52] Despliegue rápido a Producción
- **Tareas:** Ejecución de pipeline de despliegue (`flutter clean`, `flutter pub get`, `flutter build web --release`, `firebase deploy --only hosting`). Se omitió `--web-renderer canvaskit` (deprecado en Flutter actual). Desplegados 56 archivos en Firebase Hosting.
- **Resumen:** Despliegue exitoso a `https://commer-ef151-b5fde.web.app` con la versión más reciente de la webapp.

### [2026-02-24 00:50] Generación de Prompt Maestro para SellWeb PrintNode (Windows)
- **Tareas:** Análisis exhaustivo de rutas Firestore reales (`FirestorePaths`), entidades (`AccountProfile`, `AdminProfile`, `TicketModel`), `CloudPrinterService` (`ACCOUNTS/{id}/printing_receipts`), y arquitectura del proyecto. Generado prompt maestro mejorado (`prompt_maestro_sellweb_printnode.md`) con datos 100% reales del proyecto.
- **Resumen:** Se actualizó y mejoró el prompt de arquitectura para el nuevo proyecto satélite Flutter Windows "SellWeb PrintNode", alineándolo con la estructura Firestore, entidades de dominio y convenciones reales de `sell-web`.

### [2026-02-23 00:05] WebApp a Nodo de Impresión Firestore
- **Tareas:** Eliminado proveedor viejo y `ThermalPrinterHttpService`. Creados `CloudPrinterService` y `CloudPrintProvider` para inyectar un Documento con `businessId` en Firestore. UI migrada suprimiendo PNA/CORS bugs desde su raíz y acoplamiento removido del State principal.
- **Resumen:** Se refactorizó la WebApp exitosamente aislando el módulo de impresión y convirtiendo su lógica a cola nativa con Firebase.

### [2026-02-22 19:51] Arquitectura y Refactor: Windows Print Node
- **Tareas:** Creación del documento de diseño arquitectónico `windows_print_node_architecture.md` detallando la migración de app servidor HTTP a un Nodo de Impresión reactivo. Creado el esquema Clean Architecture, lógica Google Sign-In para Windows y suscripción atómica a Firestore.
- **Resumen:** Se estructuró y documentó exhaustivamente la refactorización para Windows Desktop resolviendo el problema de comunicación bloqueada por PNA y CORS.

### [2026-02-22 18:43] Despliegue rápido a Producción
- **Tareas:** Ejecución de pipeline de despliegue (`flutter clean`, `flutter pub get`, `flutter build web --release`, `firebase deploy --only hosting`). Se omitió el flag `--web-renderer canvaskit` debido a su ausencia en la versión 3.35.7.
- **Resumen:** Se desplegó exitosamente la versión más reciente en Firebase Hosting, asegurando que los cambios de `localhost` para PNA estén online.

### [2026-02-22 18:05] Fix PNA: localhost en lugar de 127.0.0.1
- **Tareas:** Se modificó `thermal_printer_http_service.dart` reemplazando `127.0.0.1` por `localhost` como host por defecto para evitar bloqueos PNA en Chrome. Se desplegó la webapp a Producción.
- **Resumen:** Se solucionó el bloqueo estricto de Chrome hacia IPs numéricas locales, habilitando la conexión al servidor de impresión local.

### [2026-02-22 02:50] Diagnóstico definitivo de CORS PNA (Chrome Producción)
- **Tareas:** Investigación intensiva de políticas PNA (Private Network Access) Chrome 130+. Comprobación de que el error HTTPS -> HTTP Localhost (`net::ERR_FAILED`) no depende del Frontend Dart, sino de la falta estricta de headers `OPTIONS` en el backend. Creación del manual `pna_shelf_fix.md` con middleware Shelf requerido (`Access-Control-Allow-Private-Network`).
- **Resumen:** Se diagnosticó y redactó el fix final para el Backend de Escritorio que bloqueaba por pre-vuelo PNA las peticiones CORS hechas desde la WebApp en producción.

### [2026-02-21 21:58] Simplificación PNA y Remoción SSL (Impresora Local)

### [2026-02-21 01:35] Despliegue rápido a Producción
- **Tareas:** Ejecución de `flutter build web --release` y `firebase deploy --only hosting`.
- **Resumen:** Se realizó un despliegue rápido de la aplicación web a Firebase Hosting.

### [2026-02-21 01:22] Deploy de WebApp al entorno de Producción
- **Tareas:** Despliegue de la web app con `flutter build web --release` y `firebase deploy --only hosting` tras compilar la versión de PNA SSL fallbacks en la impresora local.
- **Resumen:** Actualizado sell-web con las mejoras de comunicación al servidor de impresora de escritorio usando interop nativo de fetch para resolver el CORS.

### [2026-02-20 23:48] Refactor: Conexión de Impresora Nativa (PNA y SSL)
- **Tareas:** Migrado el uso del paquete HTTP en `ThermalPrinterHttpService` por un `fetch` nativo (`html.window.fetch`) con `mode: 'cors'`, resolviendo incompatibilidades con "Private Network Access" (PNA). Simplificada la UI de fallback en `PrinterConfigDialog` con el diseño y copy deseado para admitir certificados SSL locales.
- **Resumen:** Se solucionan bloqueos de CORS y PNA en producción, y se mejora significativamente el flujo al fallar el SSL con un botón visible "Solucionar Conexión Segura".

### [2026-02-19 22:31] Despliegue a Producción (Web)
- **Tareas:** Ejecución de pipeline de despliegue (`flutter clean`, `flutter pub get`, `flutter build web --release`, `firebase deploy --only hosting`).
- **Resumen:** Despliegue exitoso de nueva versión en Firebase Hosting aplicando refactor y simetría minimalista en la UI de opciones de ticket.

### [2026-02-19 22:30] Mejora UI: Botones Simétricos y Minimalistas en Compartir Ticket
- **Tareas:** Se refactorizó la UI de `_buildActionCard` en `share_ticket_dialog.dart`. Se eliminaron los gradientes y se introdujo un contenedor de proporciones cuadradas perfectas `AspectRatio(aspectRatio: 1)` para lograr simetría absoluta. Se mejoró el minimalismo utilizando colores base (`surfaceContainerLow` y `.onSurface`) junto con bordes sutiles transparentes en lugar de backgrounds pesados.
- **Resumen:** Se rediseñaron los botones de acción para compartir ticket y sean completamente simétricos (cuadrados) minimizando su ruido visual al máximo según normativas Material Design 3.

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
