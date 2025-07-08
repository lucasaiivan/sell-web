# 📋 Especificaciones de Implementación - Servidor HTTP Flutter Desktop (Windows)

**Proyecto**: Thermal Printer Server Desktop  
**Fecha**: 7 de enero de 2025  
**Target Platform**: Windows 10/11  
**Framework**: Flutter Desktop + Clean Architecture  

---

## 🎯 Objetivo

Implementar una aplicación Flutter Desktop para Windows que ejecute un servidor HTTP local compatible con el cliente `ThermalPrinterHttpService` ya implementado en la WebApp, permitiendo la impresión física en impresoras térmicas USB conectadas localmente.

---

## 🏗️ Arquitectura Objetivo

```
┌─────────────────────────────────────┐
│         FLUTTER WEB APP             │
│    (Ya implementado - Cliente)      │
│                                     │
│  ThermalPrinterHttpService          │
│  └── HTTP POST → localhost:8080     │
└─────────────────┬───────────────────┘
                  │ JSON Requests
                  │
┌─────────────────▼───────────────────┐
│     FLUTTER DESKTOP APP             │
│         (Por implementar)           │
│                                     │
│  ├── HTTP Server (shelf)            │
│  ├── Windows Printer Integration    │
│  ├── System Tray Interface          │
│  └── Configuration UI               │
│                                     │
└─────────────────┬───────────────────┘
                  │ Windows Print API
                  │ ESC/POS Commands
┌─────────────────▼───────────────────┐
│         THERMAL PRINTER             │
│        (Hardware USB/Serial)        │
└─────────────────────────────────────┘
```

---

## 📦 Estructura del Proyecto Desktop

```
thermal_printer_server/
├── lib/
│   ├── main.dart                      # Entry point + System Tray
│   ├── core/
│   │   ├── constants/
│   │   │   └── app_constants.dart     # Puertos, URLs, configs
│   │   ├── services/
│   │   │   ├── http_server_service.dart     # Servidor HTTP con shelf
│   │   │   ├── printer_service.dart         # Impresión Windows nativa
│   │   │   ├── system_tray_service.dart     # Windows System Tray
│   │   │   └── config_service.dart          # Configuración persistente
│   │   └── utils/
│   │       ├── logger.dart            # Logging centralizado
│   │       ├── printer_detector.dart  # Detección de impresoras USB
│   │       └── esc_pos_formatter.dart # Formateo ESC/POS
│   ├── data/
│   │   ├── models/
│   │   │   ├── ticket_model.dart      # Modelo de ticket (compatible con WebApp)
│   │   │   ├── printer_config_model.dart
│   │   │   └── server_response_model.dart
│   │   └── repositories/
│   │       └── printer_repository_impl.dart
│   ├── domain/
│   │   ├── entities/
│   │   │   ├── ticket.dart
│   │   │   └── printer_config.dart
│   │   ├── repositories/
│   │   │   └── printer_repository.dart
│   │   └── usecases/
│   │       ├── configure_printer_usecase.dart
│   │       ├── print_ticket_usecase.dart
│   │       └── detect_printers_usecase.dart
│   └── presentation/
│       ├── pages/
│       │   ├── main_page.dart         # UI principal (opcional)
│       │   └── settings_page.dart     # Configuración de servidor
│       ├── widgets/
│       │   ├── system_tray_menu.dart  # Menú contextual tray
│       │   ├── printer_status_widget.dart
│       │   └── server_status_widget.dart
│       └── providers/
│           ├── server_provider.dart   # Estado del servidor HTTP
│           └── printer_provider.dart  # Estado de impresoras
├── windows/
│   └── (configuración Windows runner)
├── pubspec.yaml
└── README.md
```

---

## 📋 Dependencias Required (pubspec.yaml)

```yaml
name: thermal_printer_server
description: Servidor HTTP local para impresión térmica en Windows
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: ">=3.3.0 <4.0.0"
  flutter: ">=3.19.0"

dependencies:
  flutter:
    sdk: flutter

  # HTTP Server (Same versions as WebApp)
  shelf: ^1.4.0
  shelf_router: ^1.1.4
  shelf_cors_headers: ^0.1.5

  # State Management
  provider: ^6.1.5

  # Windows Integration
  win32: ^5.0.0                    # Windows APIs
  ffi: ^2.1.0                      # Native function calls
  system_tray: ^2.0.0              # System tray integration
  
  # File System & Config
  path_provider: ^2.1.0            # App data directory
  shared_preferences: ^2.5.3       # Persistent configuration
  
  # Utilities
  freezed_annotation: ^2.4.1       # Immutable models
  json_annotation: ^4.8.1          # JSON serialization
  
  # Logging
  logger: ^2.0.0                   # Structured logging

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0
  
  # Code Generation
  build_runner: ^2.4.7
  freezed: ^2.4.6
  json_serializable: ^6.7.1

flutter:
  uses-material-design: true
  assets:
    - assets/icons/           # Iconos para system tray
    - assets/sounds/          # Sonidos de notificación (opcional)
```

---

## 🔌 API Endpoints Compatibility

**CRITICAL**: El servidor Desktop debe ser 100% compatible con estos endpoints ya implementados en `ThermalPrinterHttpService`:

### 1. GET `/status`
```dart
// Request: Ninguno
// Response esperada:
{
  "status": "ok",
  "message": "Servidor de impresión activo",
  "timestamp": "2025-01-07T...",
  "printer": "HP LaserJet Pro" | "No configurada"
}
```

### 2. POST `/configure-printer`
```dart
// Request body (desde WebApp):
{
  "printerName": "Mi Impresora Principal",
  "config": {
    "name": "Mi Impresora Principal",
    "devicePath": "/dev/usb001",  // Opcional
    "customConfig": {},           // Configuración adicional
    "configuredAt": "2025-01-07T..."
  }
}

// Response esperada:
{
  "status": "ok" | "error",
  "message": "Impresora configurada correctamente" | "Error message"
}
```

### 3. POST `/test-printer`
```dart
// Request body:
{
  "test": true,
  "timestamp": "2025-01-07T..."
}

// Response esperada:
{
  "status": "ok" | "error", 
  "message": "Ticket de prueba impreso" | "Error message"
}

// Acción: Imprimir ticket de prueba básico
```

### 4. POST `/print-ticket`
```dart
// Request body (desde WebApp):
{
  "businessName": "Mi Negocio",
  "products": [
    {
      "quantity": 2,
      "description": "Producto Ejemplo",
      "price": 10.50
    }
  ],
  "total": 21.00,
  "paymentMethod": "Efectivo",
  "customerName": "Cliente Ejemplo",      // Opcional
  "cashReceived": 25.00,                 // Opcional
  "change": 4.00,                        // Opcional
  "timestamp": "2025-01-07T..."
}

// Response esperada:
{
  "status": "ok" | "error",
  "message": "Ticket impreso correctamente" | "Error message"
}
```

---

## 🖨️ Implementación de Impresión Windows

### Estrategias de Impresión (Prioridad Descendente)

#### 1. **Windows Print Spooler API** (Recomendado)
```dart
// Usar win32 package para acceder a Windows Print API
import 'package:win32/win32.dart';

class WindowsPrinterService {
  // Detectar impresoras instaladas en Windows
  Future<List<String>> getAvailablePrinters() async {
    // Usar EnumPrinters() de win32
  }
  
  // Imprimir usando Windows Print Spooler
  Future<bool> printRawData(String printerName, List<int> data) async {
    // Usar OpenPrinter(), StartDocPrinter(), WritePrinter()
  }
}
```

#### 2. **ESC/POS directo via USB/Serial** (Fallback)
```dart
// Para impresoras que no aparecen en Windows Printers
import 'package:win32/win32.dart';

class DirectPrinterService {
  // Detectar dispositivos USB por VID/PID
  Future<List<UsbDevice>> detectThermalPrinters() async {
    // Usar SetupDiGetClassDevs() para enumerar dispositivos USB
  }
  
  // Enviar comandos ESC/POS directamente
  Future<bool> sendEscPosCommands(String devicePath, List<int> commands) async {
    // Usar CreateFile(), WriteFile() para comunicación directa
  }
}
```

### Formato de Ticket ESC/POS

```dart
class EscPosFormatter {
  static List<int> formatTicket({
    required String businessName,
    required List<Product> products,
    required double total,
    required String paymentMethod,
    String? customerName,
    double? cashReceived,
    double? change,
  }) {
    final commands = <int>[];
    
    // ESC @ - Initialize printer
    commands.addAll([0x1B, 0x40]);
    
    // Center alignment + Bold
    commands.addAll([0x1B, 0x61, 0x01]);  // Center
    commands.addAll([0x1B, 0x45, 0x01]);  // Bold on
    
    // Business name
    commands.addAll(businessName.codeUnits);
    commands.addAll([0x0A, 0x0A]);        // Line feeds
    
    // Bold off, left align
    commands.addAll([0x1B, 0x45, 0x00]);  // Bold off
    commands.addAll([0x1B, 0x61, 0x00]);  // Left align
    
    // Date/Time
    final now = DateTime.now();
    final dateStr = 'Fecha: ${now.day}/${now.month}/${now.year}';
    final timeStr = 'Hora: ${now.hour}:${now.minute.toString().padLeft(2, '0')}';
    commands.addAll(dateStr.codeUnits);
    commands.addAll([0x0A]);
    commands.addAll(timeStr.codeUnits);
    commands.addAll([0x0A, 0x0A]);
    
    // Separator line
    commands.addAll('--------------------------------'.codeUnits);
    commands.addAll([0x0A]);
    commands.addAll('CANT. DESCRIPCIÓN        PRECIO'.codeUnits);
    commands.addAll([0x0A]);
    commands.addAll('--------------------------------'.codeUnits);
    commands.addAll([0x0A]);
    
    // Products
    for (final product in products) {
      final line = '${product.quantity}     ${product.description.padRight(15)}  \$${product.price.toStringAsFixed(2)}';
      commands.addAll(line.codeUnits);
      commands.addAll([0x0A]);
    }
    
    // Separator
    commands.addAll('--------------------------------'.codeUnits);
    commands.addAll([0x0A]);
    
    // Total (Bold)
    commands.addAll([0x1B, 0x45, 0x01]);  // Bold on
    final totalStr = 'TOTAL: \$${total.toStringAsFixed(2)}';
    commands.addAll(totalStr.padLeft(32).codeUnits);
    commands.addAll([0x0A, 0x0A]);
    commands.addAll([0x1B, 0x45, 0x00]);  // Bold off
    
    // Payment method
    commands.addAll('Método de pago: $paymentMethod'.codeUnits);
    commands.addAll([0x0A]);
    
    if (cashReceived != null) {
      commands.addAll('Efectivo recibido: \$${cashReceived.toStringAsFixed(2)}'.codeUnits);
      commands.addAll([0x0A]);
      commands.addAll('Vuelto: \$${(change ?? 0).toStringAsFixed(2)}'.codeUnits);
      commands.addAll([0x0A]);
    }
    
    // Footer
    commands.addAll([0x0A]);
    commands.addAll([0x1B, 0x61, 0x01]);  // Center
    commands.addAll('Gracias por su compra'.codeUnits);
    commands.addAll([0x0A, 0x0A, 0x0A]);
    
    // Cut paper (if supported)
    commands.addAll([0x1D, 0x56, 0x42, 0x00]);
    
    return commands;
  }
}
```

---

## 🔧 Sistema Tray Implementation

```dart
// main.dart
import 'package:system_tray/system_tray.dart';

class ThermalPrinterServerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Thermal Printer Server',
      home: const ServerHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize system tray
  await SystemTrayService.initialize();
  
  // Start HTTP server
  await HttpServerService.startServer();
  
  runApp(ThermalPrinterServerApp());
}

// core/services/system_tray_service.dart
class SystemTrayService {
  static final SystemTray _systemTray = SystemTray();
  
  static Future<void> initialize() async {
    await _systemTray.initSystemTray(
      title: "Thermal Printer Server",
      iconPath: "assets/icons/printer_icon.ico",
    );
    
    await _setupTrayMenu();
  }
  
  static Future<void> _setupTrayMenu() async {
    final menu = Menu();
    
    await menu.buildFrom([
      MenuItemLabel(
        label: 'Servidor: Activo',
        enabled: false,
      ),
      MenuSeparator(),
      MenuItemLabel(
        label: 'Abrir Configuración',
        onClicked: (menuItem) => _openSettings(),
      ),
      MenuItemLabel(
        label: 'Ver Logs',
        onClicked: (menuItem) => _openLogs(),
      ),
      MenuSeparator(),
      MenuItemLabel(
        label: 'Salir',
        onClicked: (menuItem) => _exitApp(),
      ),
    ]);
    
    await _systemTray.setContextMenu(menu);
  }
  
  static void updateServerStatus(bool isRunning) {
    // Update tray icon and tooltip based on server status
  }
}
```

---

## ⚡ HTTP Server Implementation

```dart
// core/services/http_server_service.dart
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_cors_headers/shelf_cors_headers.dart';

class HttpServerService {
  static HttpServer? _server;
  static final Logger _logger = Logger('HttpServerService');
  
  static Future<void> startServer({int port = 8080}) async {
    try {
      final router = Router()
        ..get('/status', _handleStatus)
        ..post('/configure-printer', _handleConfigurePrinter)
        ..post('/test-printer', _handleTestPrinter)
        ..post('/print-ticket', _handlePrintTicket);
      
      final handler = Pipeline()
          .addMiddleware(corsHeaders())
          .addMiddleware(logRequests())
          .addHandler(router.call);
      
      _server = await shelf_io.serve(
        handler,
        InternetAddress.anyIPv4,
        port,
      );
      
      _logger.i('Servidor HTTP iniciado en puerto $port');
      SystemTrayService.updateServerStatus(true);
      
    } catch (e) {
      _logger.e('Error iniciando servidor: $e');
      throw Exception('No se pudo iniciar el servidor HTTP');
    }
  }
  
  static Future<Response> _handleStatus(Request request) async {
    final printerService = GetIt.instance<PrinterService>();
    
    return Response.ok(
      jsonEncode({
        'status': 'ok',
        'message': 'Servidor de impresión activo',
        'timestamp': DateTime.now().toIso8601String(),
        'printer': printerService.currentPrinterName ?? 'No configurada',
      }),
      headers: {'Content-Type': 'application/json'},
    );
  }
  
  static Future<Response> _handleConfigurePrinter(Request request) async {
    try {
      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;
      
      final printerName = data['printerName'] as String?;
      final config = data['config'] as Map<String, dynamic>?;
      
      if (printerName == null) {
        return Response.badRequest(
          body: jsonEncode({
            'status': 'error',
            'error': 'Nombre de impresora requerido'
          }),
          headers: {'Content-Type': 'application/json'},
        );
      }
      
      final printerService = GetIt.instance<PrinterService>();
      final success = await printerService.configurePrinter(
        printerName: printerName,
        config: config,
      );
      
      if (success) {
        return Response.ok(
          jsonEncode({
            'status': 'ok',
            'message': 'Impresora configurada correctamente'
          }),
          headers: {'Content-Type': 'application/json'},
        );
      } else {
        return Response.internalServerError(
          body: jsonEncode({
            'status': 'error',
            'error': 'Error configurando impresora'
          }),
          headers: {'Content-Type': 'application/json'},
        );
      }
      
    } catch (e) {
      _logger.e('Error en configure-printer: $e');
      return Response.internalServerError(
        body: jsonEncode({
          'status': 'error',
          'error': 'Error interno del servidor'
        }),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }
  
  static Future<Response> _handlePrintTicket(Request request) async {
    try {
      final body = await request.readAsString();
      final ticketData = jsonDecode(body) as Map<String, dynamic>;
      
      final ticket = TicketModel.fromJson(ticketData);
      
      final printerService = GetIt.instance<PrinterService>();
      final success = await printerService.printTicket(ticket);
      
      if (success) {
        return Response.ok(
          jsonEncode({
            'status': 'ok',
            'message': 'Ticket impreso correctamente'
          }),
          headers: {'Content-Type': 'application/json'},
        );
      } else {
        return Response.internalServerError(
          body: jsonEncode({
            'status': 'error',
            'error': 'Error imprimiendo ticket'
          }),
          headers: {'Content-Type': 'application/json'},
        );
      }
      
    } catch (e) {
      _logger.e('Error en print-ticket: $e');
      return Response.internalServerError(
        body: jsonEncode({
          'status': 'error', 
          'error': 'Error procesando ticket'
        }),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }
}
```

---

## 🎯 Modelos de Datos (Compatibilidad)

```dart
// data/models/ticket_model.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'ticket_model.freezed.dart';
part 'ticket_model.g.dart';

@freezed
class TicketModel with _$TicketModel {
  const factory TicketModel({
    required String businessName,
    required List<ProductModel> products,
    required double total,
    required String paymentMethod,
    String? customerName,
    double? cashReceived,
    double? change,
    String? timestamp,
  }) = _TicketModel;

  factory TicketModel.fromJson(Map<String, dynamic> json) =>
      _$TicketModelFromJson(json);
}

@freezed
class ProductModel with _$ProductModel {
  const factory ProductModel({
    required int quantity,
    required String description,
    required double price,
  }) = _ProductModel;

  factory ProductModel.fromJson(Map<String, dynamic> json) =>
      _$ProductModelFromJson(json);
}
```

---

## 🔧 Configuración y Setup

### Windows Runner Configuration

```cpp
// windows/runner/main.cpp - Modificar para hide window by default
#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>
#include "flutter_window.h"
#include "utils.h"

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  
  // Hide window by default (runs in system tray)
  show_command = SW_HIDE;
  
  // ... rest of the main function
}
```

### Build Configuration

```yaml
# windows/runner/Runner.rc - App metadata
#define VER_FILEVERSION             1,0,0,0
#define VER_FILEVERSION_STR         "1.0.0.0\0"
#define VER_PRODUCTVERSION          1,0,0,0
#define VER_PRODUCTVERSION_STR      "1.0.0\0"
#define VER_FILEDESCRIPTION_STR     "Thermal Printer Server\0"
#define VER_INTERNALNAME_STR        "thermal_printer_server\0"
#define VER_LEGALCOPYRIGHT_STR      "Copyright (C) 2025\0"
#define VER_ORIGINALFILENAME_STR    "thermal_printer_server.exe\0"
#define VER_PRODUCTNAME_STR         "Thermal Printer Server\0"
```

---

## 🧪 Testing Strategy

### Unit Tests
```dart
// test/services/printer_service_test.dart
void main() {
  group('PrinterService', () {
    test('should detect available printers', () async {
      final service = PrinterService();
      final printers = await service.getAvailablePrinters();
      expect(printers, isA<List<String>>());
    });
    
    test('should format ESC/POS commands correctly', () {
      final commands = EscPosFormatter.formatTicket(
        businessName: 'Test Business',
        products: [ProductModel(quantity: 1, description: 'Test', price: 10.0)],
        total: 10.0,
        paymentMethod: 'Cash',
      );
      
      expect(commands, isA<List<int>>());
      expect(commands, isNotEmpty);
    });
  });
}
```

### Integration Tests
```dart
// integration_test/http_server_test.dart
void main() {
  testWidgets('HTTP Server responds to status endpoint', (tester) async {
    await HttpServerService.startServer(port: 9999);
    
    final response = await http.get(Uri.parse('http://localhost:9999/status'));
    expect(response.statusCode, 200);
    
    final data = jsonDecode(response.body);
    expect(data['status'], 'ok');
  });
}
```

---

## 📋 Implementation Checklist

### Phase 1: Core Infrastructure
- [ ] Setup Flutter Desktop project with Windows support
- [ ] Implement basic HTTP server with shelf
- [ ] Create system tray integration
- [ ] Setup logging and error handling
- [ ] Implement configuration persistence

### Phase 2: Printer Integration  
- [ ] Windows printer detection via win32
- [ ] ESC/POS command formatting
- [ ] Raw printing via Windows Print Spooler
- [ ] USB direct communication (fallback)
- [ ] Test printer functionality

### Phase 3: API Compatibility
- [ ] Implement all 4 required endpoints
- [ ] Ensure 100% compatibility with WebApp client
- [ ] Add request/response validation
- [ ] Implement proper error responses
- [ ] Add CORS support

### Phase 4: User Experience
- [ ] System tray menu with status
- [ ] Configuration UI (optional window)
- [ ] Auto-start with Windows
- [ ] Installer creation
- [ ] Documentation for end users

### Phase 5: Testing & Distribution
- [ ] Unit tests for all services
- [ ] Integration tests with real printers
- [ ] Windows compatibility testing
- [ ] Performance optimization
- [ ] MSI installer package

---

## 🚀 Quick Start Commands

```bash
# Create Flutter Desktop project
flutter create thermal_printer_server --platforms=windows

# Add dependencies  
flutter pub add shelf shelf_router shelf_cors_headers win32 ffi system_tray provider shared_preferences logger

# Add dev dependencies
flutter pub add --dev build_runner freezed json_serializable

# Build for Windows
flutter build windows --release

# Run in debug mode
flutter run -d windows
```

---

## 🎯 Success Criteria

### Functional Requirements
- ✅ HTTP server responds on localhost:8080
- ✅ All 4 endpoints return expected JSON responses  
- ✅ Physical printing works on thermal printers
- ✅ System tray integration functional
- ✅ Configuration persists between restarts
- ✅ WebApp client connects successfully

### Non-Functional Requirements
- ✅ Server starts in <3 seconds
- ✅ Print job completes in <5 seconds
- ✅ Memory usage <50MB at idle
- ✅ CPU usage <5% at idle
- ✅ Works on Windows 10/11
- ✅ Graceful error handling

### Compatibility Requirements
- ✅ 100% API compatibility with `ThermalPrinterHttpService`
- ✅ Supports same ticket format/structure
- ✅ Same error response format
- ✅ Same configuration parameters

---

## 📝 Directrices de Desarrollo

### Clean Architecture (Obligatorio)
- **Domain Layer**: Entities, repositories interfaces, use cases
- **Data Layer**: Models, repository implementations
- **Presentation Layer**: UI widgets, providers, pages
- **Core Layer**: Services, utilities, constants

### Convenciones de Código
- **Nombres**: Inglés para archivos, clases, métodos, variables
- **Formato**: snake_case archivos, PascalCase clases, camelCase variables
- **Comentarios**: Español, solo para lógica compleja
- **Documentación**: Funciones complejas con 1-2 líneas máximo

### Material 3 (Obligatorio)
- Implementar componentes Material 3 consistentes
- Soporte tema claro/oscuro dinámico
- Widgets reutilizables en `core/widgets/`
- UX accesible y responsivo

### Provider Pattern (Obligatorio)
- `ServerProvider` para estado del servidor HTTP
- `PrinterProvider` para estado de impresoras
- Consumer granular para rebuilds optimizados
- Separar business logic de UI

### Herramientas de Calidad
- `flutter analyze` sin errores antes de commit
- `dart format .` para formateo automático
- Tests unitarios para servicios críticos
- Logging estructurado con `logger` package

---

**Esta especificación está lista para ser implementada siguiendo Clean Architecture, Material 3 y las mejores prácticas de Flutter Desktop. El resultado debe ser una aplicación completamente funcional que permita a la WebApp imprimir tickets físicos en impresoras térmicas Windows.**
