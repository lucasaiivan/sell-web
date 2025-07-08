# 🖥️ Ejemplo de Servidor HTTP Local para Impresoras Térmicas

Este es un ejemplo de cómo implementar el servidor HTTP local en una aplicación Flutter Desktop que reciba los comandos de impresión desde la WebApp.

## 📁 Estructura del Proyecto Desktop

```
thermal_printer_server/
├── lib/
│   ├── main.dart                    # Punto de entrada
│   ├── services/
│   │   ├── http_server_service.dart # Servidor HTTP con shelf
│   │   └── printer_service.dart    # Manejo de impresora USB
│   └── models/
│       └── ticket_model.dart       # Modelo de datos del ticket
├── pubspec.yaml
└── README.md
```

## 📦 Dependencies (pubspec.yaml)

```yaml
name: thermal_printer_server
description: Servidor HTTP local para impresoras térmicas

environment:
  sdk: ">=3.3.0 <4.0.0"
  flutter: ">=3.3.0"

dependencies:
  flutter:
    sdk: flutter
  
  # HTTP Server
  shelf: ^1.4.0
  shelf_router: ^1.1.4
  shelf_cors_headers: ^0.1.5
  
  # Impresión térmica (para Desktop)
  # Nota: Estas son dependencias de ejemplo, buscar las más adecuadas
  ffi: ^2.1.0  # Para integración con bibliotecas nativas
  win32: ^5.0.0  # Para Windows (opcional)
  
  # Utilities
  dart_console: ^1.2.0  # Para logs en consola
  args: ^2.4.0  # Para argumentos de línea de comandos

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0

flutter:
  uses-material-design: true
```

## 🚀 Código Principal (main.dart)

```dart
import 'package:flutter/material.dart';
import 'package:dart_console/dart_console.dart';
import 'services/http_server_service.dart';
import 'services/printer_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final console = Console();
  console.writeLine('🖨️  Servidor de Impresoras Térmicas v1.0.0');
  console.writeLine('═══════════════════════════════════════════');
  
  // Inicializar servicios
  final printerService = PrinterService();
  final httpServer = HttpServerService(printerService);
  
  try {
    // Inicializar servicio de impresión
    await printerService.initialize();
    console.writeLine('✅ Servicio de impresión inicializado');
    
    // Iniciar servidor HTTP
    await httpServer.start(port: 8080);
    console.writeLine('🌐 Servidor HTTP iniciado en: http://localhost:8080');
    console.writeLine('');
    console.writeLine('📡 Endpoints disponibles:');
    console.writeLine('   POST /print-ticket     - Imprimir ticket');
    console.writeLine('   GET  /status          - Estado del servidor');
    console.writeLine('   POST /configure       - Configurar impresora');
    console.writeLine('   POST /test           - Prueba de impresión');
    console.writeLine('');
    console.writeLine('👆 Presione Ctrl+C para detener el servidor');
    
    // Mantener el servidor corriendo
    await httpServer.waitForShutdown();
    
  } catch (e) {
    console.writeLine('❌ Error al iniciar servidor: $e');
  } finally {
    await httpServer.stop();
    console.writeLine('🛑 Servidor detenido');
  }
}
```

## 🌐 Servicio HTTP (http_server_service.dart)

```dart
import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_cors_headers/shelf_cors_headers.dart';
import 'printer_service.dart';

class HttpServerService {
  final PrinterService _printerService;
  HttpServer? _server;
  
  HttpServerService(this._printerService);
  
  Future<void> start({int port = 8080}) async {
    final router = Router();
    
    // Configurar rutas
    router.post('/print-ticket', _handlePrintTicket);
    router.get('/status', _handleStatus);
    router.post('/configure', _handleConfigure);
    router.post('/test', _handleTest);
    
    // Configurar CORS y middleware
    final handler = Pipeline()
        .addMiddleware(corsHeaders(
          headers: {
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
            'Access-Control-Allow-Headers': 'Content-Type, Authorization',
          },
        ))
        .addMiddleware(logRequests())
        .addHandler(router.call);
    
    // Iniciar servidor
    _server = await io.serve(handler, 'localhost', port);
  }
  
  Future<void> stop() async {
    await _server?.close(force: true);
    _server = null;
  }
  
  Future<void> waitForShutdown() async {
    // Esperar señal de cierre (Ctrl+C)
    ProcessSignal.sigint.watch().listen((_) async {
      print('\n🛑 Señal de cierre recibida...');
      await stop();
      exit(0);
    });
    
    // Mantener vivo el proceso
    while (_server != null) {
      await Future.delayed(const Duration(seconds: 1));
    }
  }
  
  Future<Response> _handlePrintTicket(Request request) async {
    try {
      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;
      
      print('📄 Recibido ticket para imprimir:');
      print('   Negocio: ${data['businessName']}');
      print('   Total: \$${data['total']}');
      print('   Productos: ${(data['products'] as List).length}');
      
      // Enviar a impresora
      final success = await _printerService.printTicket(data);
      
      if (success) {
        print('✅ Ticket impreso correctamente');
        return Response.ok(
          jsonEncode({'status': 'ok', 'message': 'Ticket impreso correctamente'}),
          headers: {'Content-Type': 'application/json'},
        );
      } else {
        print('❌ Error al imprimir ticket');
        return Response(500,
          body: jsonEncode({'error': 'Error al imprimir ticket'}),
          headers: {'Content-Type': 'application/json'},
        );
      }
    } catch (e) {
      print('❌ Error procesando ticket: $e');
      return Response(500,
        body: jsonEncode({'error': 'Error interno del servidor: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }
  
  Future<Response> _handleStatus(Request request) async {
    final status = {
      'server_running': true,
      'printer_connected': _printerService.isConnected,
      'printer_name': _printerService.printerName,
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    return Response.ok(
      jsonEncode(status),
      headers: {'Content-Type': 'application/json'},
    );
  }
  
  Future<Response> _handleConfigure(Request request) async {
    try {
      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;
      
      final success = await _printerService.configure(
        printerName: data['printerName'],
        devicePath: data['devicePath'],
      );
      
      if (success) {
        return Response.ok(
          jsonEncode({'status': 'ok', 'message': 'Impresora configurada'}),
          headers: {'Content-Type': 'application/json'},
        );
      } else {
        return Response(500,
          body: jsonEncode({'error': 'Error al configurar impresora'}),
          headers: {'Content-Type': 'application/json'},
        );
      }
    } catch (e) {
      return Response(500,
        body: jsonEncode({'error': 'Error interno: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }
  
  Future<Response> _handleTest(Request request) async {
    final success = await _printerService.printTest();
    
    if (success) {
      return Response.ok(
        jsonEncode({'status': 'ok', 'message': 'Prueba de impresión exitosa'}),
        headers: {'Content-Type': 'application/json'},
      );
    } else {
      return Response(500,
        body: jsonEncode({'error': 'Error en prueba de impresión'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }
}
```

## 🖨️ Servicio de Impresión (printer_service.dart)

```dart
import 'dart:io';

class PrinterService {
  bool _isConnected = false;
  String? _printerName;
  String? _devicePath;
  
  bool get isConnected => _isConnected;
  String? get printerName => _printerName;
  
  Future<void> initialize() async {
    // Inicializar biblioteca de impresión según la plataforma
    if (Platform.isWindows) {
      await _initializeWindows();
    } else if (Platform.isMacOS) {
      await _initializeMacOS();
    } else if (Platform.isLinux) {
      await _initializeLinux();
    }
  }
  
  Future<bool> configure({required String printerName, String? devicePath}) async {
    _printerName = printerName;
    _devicePath = devicePath;
    
    // Intentar conectar con la impresora
    return await _connectToPrinter();
  }
  
  Future<bool> printTicket(Map<String, dynamic> ticketData) async {
    if (!_isConnected) return false;
    
    try {
      // Generar comandos ESC/POS
      final commands = _generateEscPosCommands(ticketData);
      
      // Enviar a impresora
      return await _sendToPrinter(commands);
    } catch (e) {
      print('Error al imprimir ticket: $e');
      return false;
    }
  }
  
  Future<bool> printTest() async {
    if (!_isConnected) return false;
    
    final testData = {
      'businessName': 'PRUEBA DE IMPRESIÓN',
      'products': [
        {'quantity': 1, 'description': 'Artículo de prueba', 'price': 1.00}
      ],
      'total': 1.00,
      'paymentMethod': 'Efectivo',
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    return await printTicket(testData);
  }
  
  // Métodos específicos por plataforma
  Future<void> _initializeWindows() async {
    // Implementar usando win32 o ffi para Windows
    print('Inicializando para Windows...');
  }
  
  Future<void> _initializeMacOS() async {
    // Implementar usando IOKit o CUPS para macOS
    print('Inicializando para macOS...');
  }
  
  Future<void> _initializeLinux() async {
    // Implementar usando CUPS para Linux
    print('Inicializando para Linux...');
  }
  
  Future<bool> _connectToPrinter() async {
    // Implementar conexión específica según plataforma
    print('Conectando a impresora: $_printerName');
    
    // Simulación para ejemplo
    await Future.delayed(const Duration(milliseconds: 500));
    _isConnected = true;
    return true;
  }
  
  List<int> _generateEscPosCommands(Map<String, dynamic> ticketData) {
    final commands = <int>[];
    
    // Comandos ESC/POS básicos
    // Initialize printer
    commands.addAll([0x1B, 0x40]);
    
    // Centrar y negrita para título
    commands.addAll([0x1B, 0x61, 0x01]); // Centro
    commands.addAll([0x1B, 0x45, 0x01]); // Negrita
    
    // Título del negocio
    final businessName = ticketData['businessName'] as String;
    commands.addAll(businessName.codeUnits);
    commands.addAll([0x0A, 0x0A]); // Nueva línea
    
    // Resetear formato
    commands.addAll([0x1B, 0x45, 0x00]); // Sin negrita
    commands.addAll([0x1B, 0x61, 0x00]); // Izquierda
    
    // Fecha y hora
    final now = DateTime.now();
    final dateStr = '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
    final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    
    commands.addAll('Fecha: $dateStr  Hora: $timeStr'.codeUnits);
    commands.addAll([0x0A, 0x0A]);
    
    // Línea separadora
    commands.addAll('--------------------------------'.codeUnits);
    commands.addAll([0x0A]);
    
    // Productos
    final products = ticketData['products'] as List;
    for (final product in products) {
      final qty = product['quantity'].toString();
      final desc = product['description'] as String;
      final price = '\$${product['price'].toStringAsFixed(2)}';
      
      final line = '$qty $desc $price';
      commands.addAll(line.codeUnits);
      commands.addAll([0x0A]);
    }
    
    // Línea separadora
    commands.addAll('--------------------------------'.codeUnits);
    commands.addAll([0x0A]);
    
    // Total
    final total = '\$${ticketData['total'].toStringAsFixed(2)}';
    commands.addAll([0x1B, 0x45, 0x01]); // Negrita
    commands.addAll('TOTAL: $total'.codeUnits);
    commands.addAll([0x1B, 0x45, 0x00]); // Sin negrita
    commands.addAll([0x0A, 0x0A]);
    
    // Método de pago
    final paymentMethod = ticketData['paymentMethod'] as String;
    commands.addAll('Método de pago: $paymentMethod'.codeUnits);
    commands.addAll([0x0A, 0x0A]);
    
    // Mensaje final
    commands.addAll([0x1B, 0x61, 0x01]); // Centro
    commands.addAll('Gracias por su compra'.codeUnits);
    commands.addAll([0x0A, 0x0A, 0x0A]);
    
    // Cortar papel (si es compatible)
    commands.addAll([0x1D, 0x56, 0x42, 0x00]);
    
    return commands;
  }
  
  Future<bool> _sendToPrinter(List<int> commands) async {
    try {
      if (Platform.isWindows) {
        return await _sendToWindowsPrinter(commands);
      } else if (Platform.isMacOS) {
        return await _sendToMacOSPrinter(commands);
      } else if (Platform.isLinux) {
        return await _sendToLinuxPrinter(commands);
      }
      return false;
    } catch (e) {
      print('Error enviando a impresora: $e');
      return false;
    }
  }
  
  Future<bool> _sendToWindowsPrinter(List<int> commands) async {
    // Implementar envío directo a puerto COM o USB en Windows
    print('Enviando ${commands.length} bytes a impresora Windows');
    await Future.delayed(const Duration(milliseconds: 200));
    return true;
  }
  
  Future<bool> _sendToMacOSPrinter(List<int> commands) async {
    // Implementar envío via CUPS o IOKit en macOS
    print('Enviando ${commands.length} bytes a impresora macOS');
    await Future.delayed(const Duration(milliseconds: 200));
    return true;
  }
  
  Future<bool> _sendToLinuxPrinter(List<int> commands) async {
    // Implementar envío via CUPS en Linux
    print('Enviando ${commands.length} bytes a impresora Linux');
    await Future.delayed(const Duration(milliseconds: 200));
    return true;
  }
}
```

## 🎯 Compilación y Ejecución

### Crear Proyecto
```bash
flutter create thermal_printer_server --platforms=windows,macos,linux
cd thermal_printer_server
# Copiar los archivos de arriba
flutter pub get
```

### Ejecutar en Desktop
```bash
# Windows
flutter run -d windows

# macOS  
flutter run -d macos

# Linux
flutter run -d linux
```

### Compilar Release
```bash
flutter build windows --release
flutter build macos --release
flutter build linux --release
```

## 🧪 Testing

### Probar con curl
```bash
# Verificar estado
curl http://localhost:8080/status

# Enviar ticket de prueba
curl -X POST http://localhost:8080/print-ticket \
  -H "Content-Type: application/json" \
  -d '{
    "businessName": "Mi Negocio Test",
    "products": [
      {"quantity": 2, "description": "Producto A", "price": 10.50},
      {"quantity": 1, "description": "Producto B", "price": 5.25}
    ],
    "total": 26.25,
    "paymentMethod": "Efectivo"
  }'
```

### Probar desde WebApp
```javascript
// En el navegador (consola de desarrollo)
fetch('http://localhost:8080/print-ticket', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
  },
  body: JSON.stringify({
    businessName: 'Test desde WebApp',
    products: [
      {quantity: 1, description: 'Producto Web', price: 15.00}
    ],
    total: 15.00,
    paymentMethod: 'Tarjeta'
  })
})
.then(response => response.json())
.then(data => console.log('Success:', data))
.catch(error => console.error('Error:', error));
```

## 📋 Lista de Tareas

### Implementación Básica ✅
- [x] Servidor HTTP con shelf
- [x] Endpoints básicos (print, status, configure, test)
- [x] Generación de comandos ESC/POS
- [x] Estructura de archivos
- [x] Manejo de CORS

### Implementación Avanzada 🚧
- [ ] Integración real con impresoras USB por plataforma
- [ ] Detección automática de impresoras
- [ ] Configuración persistente
- [ ] Interfaz gráfica opcional
- [ ] Sistema de logs
- [ ] Instalador automático

### Funcionalidades Extra 💡
- [ ] Soporte para múltiples impresoras
- [ ] Cola de impresión
- [ ] Reimpresión de tickets
- [ ] Configuración de plantillas
- [ ] Integración con gaveta de dinero
- [ ] Códigos de barras y QR

---

**Nota**: Este es un ejemplo funcional base. La implementación real de la comunicación con impresoras USB requiere bibliotecas nativas específicas por plataforma y puede variar según el modelo de impresora.
