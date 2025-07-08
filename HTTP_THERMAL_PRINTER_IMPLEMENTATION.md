# 🖥️ Implementación de Servidor HTTP Local para Impresoras Térmicas

## 📋 Resumen de Cambios

### ✅ Cambios Implementados

1. **Eliminación de `usb_thermal_printer_web_pro`**
   - Dependencia removida del `pubspec.yaml`
   - Servicio anterior movido a `thermal_printer_service_old.dart` como referencia

2. **Nuevo Servicio HTTP: `ThermalPrinterHttpService`**
   - Ubicación: `lib/core/services/thermal_printer_http_service.dart`
   - Maneja la comunicación con servidor HTTP local
   - Compatible con Flutter Web

3. **Dependencias Agregadas**
   ```yaml
   dependencies:
     shelf: ^1.4.0
     shelf_router: ^1.1.4
     shelf_cors_headers: ^0.1.5
   ```

4. **Diálogo de Configuración Actualizado**
   - `PrinterConfigDialog` completamente rediseñado
   - Configuración de servidor HTTP (host/puerto)
   - Interfaz Material 3 mejorada

## 🏗️ Arquitectura del Nuevo Sistema

### Componentes

```
┌─────────────────┐    HTTP POST     ┌──────────────────────┐
│   Flutter Web   │ ───────────────> │  Flutter Desktop     │
│   (sell-web)    │                  │  (Servidor HTTP)     │
└─────────────────┘                  └──────────────────────┘
         │                                      │
         │                                      │
         ▼                                      ▼
┌─────────────────┐                  ┌──────────────────────┐
│ WebApp Cliente  │                  │ Impresora Térmica    │
│ (Navegador)     │                  │ (USB Local)          │
└─────────────────┘                  └──────────────────────┘
```

### Flujo de Impresión

1. **WebApp** → Configura conexión con servidor en `localhost:8080`
2. **WebApp** → Envía datos de ticket via HTTP POST a `/print-ticket`
3. **Servidor Desktop** → Recibe datos y procesa impresión en impresora USB local
4. **Servidor Desktop** → Responde con `{"status": "ok"}` o error

## 📡 API del Servidor HTTP

### Endpoints Disponibles

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| `POST` | `/print-ticket` | Envía datos de ticket para imprimir |
| `GET`  | `/status` | Verifica estado del servidor |
| `POST` | `/configure-printer` | Configura impresora en el servidor |
| `POST` | `/test-printer` | Envía comando de prueba |

### Ejemplo de Request

```bash
curl -X POST http://localhost:8080/print-ticket \
  -H "Content-Type: application/json" \
  -d '{
    "businessName": "Mi Negocio",
    "products": [
      {"quantity": 2, "description": "Producto A", "price": 10.50}
    ],
    "total": 21.00,
    "paymentMethod": "Efectivo",
    "customerName": "Cliente Ejemplo"
  }'
```

### Ejemplo de Response

```json
{
  "status": "ok",
  "message": "Ticket impreso correctamente"
}
```

## ⚙️ Configuración en Flutter Web

### 1. Configurar Servidor

```dart
final printerService = ThermalPrinterHttpService();

await printerService.configurePrinter(
  printerName: "Impresora Principal",
  serverHost: "localhost",
  serverPort: 8080,
);
```

### 2. Imprimir Ticket

```dart
final success = await printerService.printTicket(
  businessName: "Mi Negocio",
  products: [
    {"quantity": 1, "description": "Producto", "price": 10.00}
  ],
  total: 10.00,
  paymentMethod: "Efectivo",
);
```

## 🛡️ Configuración de Seguridad

### CORS (Cross-Origin Resource Sharing)

El servidor incluye configuración CORS para permitir requests desde la WebApp:

```dart
final handler = Pipeline()
    .addMiddleware(corsHeaders())
    .addMiddleware(logRequests())
    .addHandler(router.call);
```

### Recomendaciones

1. **Red Local**: Configurar servidor en `0.0.0.0:8080` para acceso desde red local
2. **Firewall**: Abrir puerto 8080 en Windows/macOS si es necesario
3. **Token API** (opcional): Implementar validación de headers para mayor seguridad

## 📱 Compatibilidad

### Plataformas Soportadas

| Plataforma | WebApp (Cliente) | Servidor HTTP |
|------------|------------------|---------------|
| **Windows** | ✅ Chrome/Edge | ✅ Flutter Desktop |
| **macOS** | ✅ Chrome/Edge | ✅ Flutter Desktop |
| **Linux** | ✅ Chrome/Edge | ✅ Flutter Desktop |
| **Android** | ✅ Chrome | ❌ No soportado |
| **iOS** | ❌ Safari sin WebUSB | ❌ No soportado |

### Navegadores

- ✅ **Chrome 61+**: Soporte completo
- ✅ **Edge 79+**: Soporte completo  
- ✅ **Opera 48+**: Soporte completo
- ❌ **Firefox**: Sin soporte (limitación de WebUSB)
- ❌ **Safari**: Sin soporte (limitación de WebUSB)

## 🔧 Archivos Modificados

### Nuevos Archivos
- `lib/core/services/thermal_printer_http_service.dart`

### Archivos Actualizados
- `pubspec.yaml` - Dependencias de shelf
- `lib/core/widgets/dialogs/printer_config_dialog.dart` - Nueva UI
- `lib/presentation/pages/sell_page.dart` - Import actualizado
- `lib/core/widgets/dialogs/ticket_options_dialog.dart` - Servicio actualizado

### Archivos Movidos
- `lib/core/services/thermal_printer_service.dart` → `thermal_printer_service_old.dart`

## 🚀 Próximos Pasos

### Para Desarrollo Flutter Desktop

1. **Crear Aplicación Desktop**
   ```bash
   flutter create thermal_printer_server --platforms=windows,macos,linux
   ```

2. **Implementar Servidor HTTP**
   ```dart
   // main.dart
   import 'package:shelf/shelf_io.dart' as io;
   
   void main() async {
     final server = await io.serve(handler, 'localhost', 8080);
     print('Servidor ejecutándose en ${server.address.host}:${server.port}');
   }
   ```

3. **Integrar Biblioteca de Impresión**
   - Para Windows: `win32_registry`, `ffi`
   - Para macOS: `native_pdf_renderer`
   - Para Linux: `process`, `cups`

### Para Testing Inmediato

1. **Servidor de Prueba**
   ```bash
   # Crear servidor simple con Node.js para testing
   npm install express cors
   ```

2. **Mock Response**
   ```javascript
   app.post('/print-ticket', (req, res) => {
     console.log('Ticket recibido:', req.body);
     res.json({ status: 'ok', message: 'Ticket procesado' });
   });
   ```

## 📊 Beneficios del Nuevo Enfoque

| Aspecto | Enfoque Anterior | Nuevo Enfoque HTTP |
|---------|------------------|---------------------|
| **Compatibilidad** | Solo navegadores con WebUSB | Cualquier navegador + Desktop |
| **Confiabilidad** | Dependiente de WebUSB API | HTTP estándar |
| **Configuración** | IDs de dispositivo complejos | IP/Puerto simple |
| **Debugging** | Limitado a herramientas web | Logs de servidor completos |
| **Escalabilidad** | Una impresora por navegador | Múltiples impresoras por servidor |
| **Mantenimiento** | Dependiente de terceros | Control total del código |

## ⚠️ Limitaciones Conocidas

1. **Requiere Aplicación Desktop**: El servidor HTTP debe ejecutarse por separado
2. **Configuración Inicial**: Los usuarios deben instalar la aplicación Desktop
3. **Red Local**: La WebApp y Desktop deben estar en la misma red
4. **Puerto Disponible**: El puerto 8080 debe estar libre

## 📝 Notas de Implementación

- **Estado Actual**: Implementación base completa con simulación
- **Métodos Compatibles**: `generateTicketPdf()` y `printTicketWithBrowser()` mantienen compatibilidad
- **Configuración**: Se guarda en SharedPreferences para persistencia
- **Error Handling**: Manejo robusto de errores de red y configuración

---

**Fecha de Implementación**: 7 de enero de 2025  
**Versión**: 1.0.0  
**Desarrollador**: GitHub Copilot con guías de Clean Architecture y Material 3
