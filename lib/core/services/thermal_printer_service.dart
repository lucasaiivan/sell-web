import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:usb_thermal_printer_web_pro/usb_thermal_printer_web_pro.dart';
import 'package:sellweb/core/utils/shared_prefs_keys.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:web/web.dart' as html;

/// Servicio para manejo de impresoras térmicas USB
/// Compatible con Windows y macOS a través de web
class ThermalPrinterService {
  static final ThermalPrinterService _instance =
      ThermalPrinterService._internal();
  factory ThermalPrinterService() => _instance;
  ThermalPrinterService._internal();

  final WebThermalPrinter _printer = WebThermalPrinter();
  bool _isConnected = false;
  String? _printerName;
  String? _lastError;

  // Configuración exitosa guardada para reconexiones
  int? _workingInterface;
  int? _workingEndpoint;
  int? _workingVendorId;
  int? _workingProductId;

  /// Estado actual de conexión con la impresora
  bool get isConnected => _isConnected;

  /// Nombre de la impresora configurada
  String? get printerName => _printerName;

  /// Último error registrado
  String? get lastError => _lastError;

  /// Configuración actual de conexión exitosa
  String get connectionInfo {
    if (_workingInterface != null && _workingEndpoint != null) {
      return 'Interface $_workingInterface, Endpoint $_workingEndpoint';
    }
    return 'Configuración automática';
  }

  /// Información detallada de la conexión actual
  Map<String, dynamic> get detailedConnectionInfo {
    return {
      'isConnected': _isConnected,
      'printerName': _printerName,
      'interface': _workingInterface,
      'endpoint': _workingEndpoint,
      'vendorId': _workingVendorId,
      'productId': _workingProductId,
      'connectionType': (_workingInterface != null && _workingEndpoint != null)
          ? 'Configuración específica'
          : 'Detección automática',
      'lastError': _lastError,
    };
  }

  /// Información de depuración de la configuración USB actual
  String get debugInfo {
    final info = StringBuffer();
    info.writeln('=== THERMAL PRINTER DEBUG INFO ===');
    info.writeln('Connected: $_isConnected');
    info.writeln('Printer Name: $_printerName');
    info.writeln('Working Interface: $_workingInterface');
    info.writeln('Working Endpoint: $_workingEndpoint');
    info.writeln('Working Vendor ID: $_workingVendorId');
    info.writeln('Working Product ID: $_workingProductId');
    info.writeln('Last Error: $_lastError');
    info.writeln('Connection Info: $connectionInfo');
    info.writeln('================================');
    return info.toString();
  }

  /// Inicializa el servicio cargando configuración previa
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _printerName = prefs.getString(SharedPrefsKeys.printerName);

      // Cargar configuración exitosa previa
      _workingInterface =
          prefs.getInt('${SharedPrefsKeys.printerName}_interface');
      _workingEndpoint =
          prefs.getInt('${SharedPrefsKeys.printerName}_endpoint');
      _workingVendorId =
          prefs.getInt('${SharedPrefsKeys.printerName}_vendorId');
      _workingProductId =
          prefs.getInt('${SharedPrefsKeys.printerName}_productId');

      _isConnected = _printerName != null;
    } catch (e) {
      _lastError = 'Error al inicializar servicio: $e';
      if (kDebugMode) print(_lastError);
    }
  }

  /// Conecta con una impresora térmica USB
  /// Permite especificar vendorId y productId opcionales
  Future<bool> connectPrinter({
    int? vendorId,
    int? productId,
    int? interfaceNumber,
    int? endpointNumber,
  }) async {
    if (!kIsWeb) {
      _lastError = 'Solo compatible con Flutter Web';
      return false;
    }

    try {
      _lastError = null;

      // Configuración básica de la impresora
      _printer.config(
        printWidth: 48, // Ancho estándar para tickets de 58mm
        leftPadding: 0, // Sin padding para maximizar espacio
        rightPadding: 0,
      );

      // Inicialización básica de la impresora
      await _printer.printText('\x1B\x40'); // Initialize printer
      await _printer
          .printText('\x1B\x74\x00'); // Select character code table (CP437)

      // Intentar múltiples configuraciones de conexión
      bool connected = false;

      // Primera tentativa: usar configuración que funcionó previamente
      if (!connected && _workingInterface != null && _workingEndpoint != null) {
        try {
          connected = await _attemptConnection(
            vendorId: _workingVendorId,
            productId: _workingProductId,
            interfaceNo: _workingInterface!,
            endpointNo: _workingEndpoint!,
          );
          if (connected && kDebugMode) {
            print(
                'Reconectado con configuración previa: interfaz $_workingInterface, endpoint $_workingEndpoint');
          }
        } catch (e) {
          if (kDebugMode) print('Configuración previa falló: $e');
        }
      }

      // Segunda tentativa: con parámetros específicos (si se proporcionan)
      if (!connected && vendorId != null && productId != null) {
        try {
          connected = await _attemptConnection(
            vendorId: vendorId,
            productId: productId,
            interfaceNo: interfaceNumber ?? 0,
            endpointNo: endpointNumber ?? 3,
          );
          if (connected) {
            // Guardar configuración exitosa
            _workingInterface = interfaceNumber ?? 0;
            _workingEndpoint = endpointNumber ?? 3;
            _workingVendorId = vendorId;
            _workingProductId = productId;
          }
        } catch (e) {
          if (kDebugMode) print('Conexión específica falló: $e');
        }
      }

      // Tercera tentativa: detección automática sin parámetros
      if (!connected) {
        try {
          await _printer.pairDevice();
          connected = true;
        } catch (e) {
          if (kDebugMode) print('Conexión automática falló: $e');
        }
      }

      // Cuarta tentativa: con configuraciones comunes conocidas
      // NOTA: Endpoint 3 es el más común en impresoras térmicas USB
      // Basado en análisis de hardware real de impresoras como:
      // - Impresoras genéricas 58mm/80mm
      // - POS-80 series
      // - Y muchas otras que usan endpoint OUT 3
      if (!connected) {
        final commonConfigs = [
          {
            'interface': 0,
            'endpoint': 3
          }, // Endpoint más común en impresoras térmicas - PRIORIDAD
          {'interface': 0, 'endpoint': 1},
          {'interface': 0, 'endpoint': 2},
          {'interface': 0, 'endpoint': 4},
          {'interface': 1, 'endpoint': 3},
          {'interface': 1, 'endpoint': 1},
          {'interface': 1, 'endpoint': 2},
          {'interface': 1, 'endpoint': 4},
        ];

        for (var config in commonConfigs) {
          try {
            connected = await _attemptConnection(
              vendorId: vendorId,
              productId: productId,
              interfaceNo: config['interface']!,
              endpointNo: config['endpoint']!,
            );

            if (connected) {
              // Guardar configuración exitosa para futuras conexiones
              _workingInterface = config['interface'];
              _workingEndpoint = config['endpoint'];
              _workingVendorId = vendorId;
              _workingProductId = productId;

              if (kDebugMode)
                print(
                    'Conectado con interfaz ${config['interface']}, endpoint ${config['endpoint']}');
              break;
            }
          } catch (e) {
            if (kDebugMode)
              print(
                  'Config interfaz ${config['interface']}, endpoint ${config['endpoint']} falló: $e');
            continue;
          }
        }
      }

      if (!connected) {
        throw Exception(
            'No se pudo establecer conexión con ninguna configuración');
      }

      _isConnected = true;
      _printerName = 'Impresora USB ${vendorId ?? 'Auto'}';

      // Guardar configuración
      await _saveConfiguration();

      return true;
    } catch (e) {
      _lastError = 'Error al conectar impresora: $e';
      _isConnected = false;
      if (kDebugMode) print(_lastError);
      return false;
    }
  }

  /// Intenta conectar con configuración específica. Solo documenta y prueba la conexión, asumiendo que el endpoint es OUT si está en la lista de intentos.
  Future<bool> _attemptConnection({
    int? vendorId,
    int? productId,
    required int interfaceNo,
    required int endpointNo,
  }) async {
    try {
      // Intentar conexión básica primero
      await _printer.pairDevice(
        vendorId: vendorId,
        productId: productId,
        interfaceNo: interfaceNo,
        endpointNo: endpointNo,
      );

      // Verificar que la conexión realmente funcione con una prueba de escritura.
      await _printer.printText(String.fromCharCode(0));

      if (kDebugMode)
        print(
            'Conexión exitosa: interfaz $interfaceNo, endpoint $endpointNo (asumido OUT)');
      return true;
    } catch (e) {
      if (kDebugMode)
        print('Falló conexión interfaz $interfaceNo, endpoint $endpointNo: $e');
      return false;
    }
  }

  /// Prueba básica de conexión verificando el estado de la impresora
  Future<bool> _testConnection() async {
    try {
      if (!_isConnected) {
        return false;
      }

      // Realizar una operación de bajo nivel para verificar la escritura.
      // Se envía un comando nulo (0x00) que la mayoría de las impresoras ignoran,
      // pero que sirve para confirmar que el endpoint de salida es funcional.
      await _printer.printText(String.fromCharCode(0));

      return true;
    } catch (e) {
      if (kDebugMode) print('Test de conexión con escritura falló: $e');
      return false;
    }
  }

  /// Desconecta la impresora actual
  Future<void> disconnectPrinter() async {
    try {
      _lastError = null;

      if (_isConnected) {
        // Intentar cerrar la conexión de la impresora
        try {
          await _printer.closePrinter();
          if (kDebugMode) print('Impresora cerrada correctamente');
        } catch (e) {
          if (kDebugMode) print('Error al cerrar impresora: $e');
        }

        // Esperar un momento para asegurar que la desconexión se complete
        await Future.delayed(const Duration(milliseconds: 500));
      }
    } catch (e) {
      _lastError = 'Error al desconectar: $e';
      if (kDebugMode) print(_lastError);
    } finally {
      // Asegurar que el estado se resetee independientemente de errores
      _isConnected = false;
      _printerName = null;

      // Limpiar configuración guardada
      await _clearConfiguration();

      if (kDebugMode) print('Estado de impresora reseteado');
    }
  }

  /// Imprime un ticket de venta completo
  Future<bool> printTicket({
    required String businessName,
    required List<Map<String, dynamic>> products,
    required double total,
    required String paymentMethod,
    String? customerName,
    double? cashReceived,
    double? change,
  }) async {
    if (!_isConnected) {
      _lastError = 'No hay impresora conectada';
      return false;
    }

    try {
      _lastError = null;

      // Encabezado del ticket
      await _printTextEnhanced(
        businessName.toUpperCase(),
        bold: true,
        align: 'center',
        title: true,
      );
      await _printer.printEmptyLine();

      await _printTextEnhanced(
        'TICKET DE VENTA',
        align: 'center',
        bold: true,
      );
      await _printer.printEmptyLine();

      // Fecha y hora
      final now = DateTime.now();
      await _printTextEnhanced(
        'Fecha: ${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}',
      );
      await _printTextEnhanced(
        'Hora: ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
      );

      if (customerName != null && customerName.isNotEmpty) {
        await _printTextEnhanced('Cliente: $customerName');
      }

      // Línea separadora simple
      await _printTextEnhanced('--------------------------------',
          align: 'center');

      // Encabezado de productos
      await _printTextEnhanced('CANT. DESCRIPCION        PRECIO', bold: true);
      await _printTextEnhanced('--------------------------------',
          align: 'center');

      // Productos
      for (var product in products) {
        final quantity = product['quantity']?.toString() ?? '1';
        final description = product['description']?.toString() ?? 'Producto';
        final price = product['price']?.toString() ?? '0.00';

        String shortDesc = description.length > 15
            ? '${description.substring(0, 15)}...'
            : description.padRight(18);

        await _printTextEnhanced('$quantity $shortDesc $price');
      }

      await _printTextEnhanced('--------------------------------',
          align: 'center');

      // Total
      await _printTextEnhanced(
        'TOTAL: \$${total.toStringAsFixed(2)}',
        bold: true,
        align: 'right',
      );

      await _printer.printEmptyLine();

      // Método de pago
      await _printTextEnhanced('Metodo de pago: $paymentMethod');

      // Efectivo recibido y vuelto
      if (cashReceived != null && cashReceived > 0) {
        await _printTextEnhanced(
          'Efectivo recibido: \$${cashReceived.toStringAsFixed(2)}',
        );

        if (change != null && change > 0) {
          await _printTextEnhanced(
            'Vuelto: \$${change.toStringAsFixed(2)}',
          );
        }
      }

      await _printer.printEmptyLine();
      await _printTextEnhanced(
        'Gracias por su compra',
        align: 'center',
        bold: true,
      );
      await _printer.printEmptyLine();
      await _printer.printEmptyLine();

      return true;
    } catch (e) {
      _lastError = 'Error al imprimir ticket: $e';
      if (kDebugMode) print(_lastError);
      return false;
    }
  }

  /// Imprime un ticket de prueba
  Future<bool> printTestTicket() async {
    if (!_isConnected) {
      _lastError = 'No hay impresora conectada';
      return false;
    }

    try {
      _lastError = null;

      // Verificar conexión antes de imprimir
      if (!await _testConnection()) {
        _lastError = 'Conexión con impresora perdida';
        _isConnected = false;
        return false;
      }

      // Imprimir línea de prueba básica con manejo de errores por línea
      try {
        await _printTextEnhanced(
          'PRUEBA DE CONEXION',
          bold: true,
          align: 'center',
          title: true,
        );

        await _printer.printEmptyLine();

        await _printTextEnhanced(
          'Impresora funcionando correctamente',
          align: 'center',
        );

        await _printer.printEmptyLine();

        // Fecha y hora simple
        final now = DateTime.now();
        await _printTextEnhanced(
          'Fecha: ${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}',
          align: 'center',
        );

        await _printTextEnhanced(
          'Hora: ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
          align: 'center',
        );

        await _printer.printEmptyLine();

        await _printTextEnhanced(
          '--------------------------------',
          align: 'center',
        );

        await _printTextEnhanced(
          'ESTADO: CONECTADA',
          align: 'center',
          bold: true,
        );

        if (_workingInterface != null && _workingEndpoint != null) {
          await _printTextEnhanced(
            'Interface: $_workingInterface',
            align: 'center',
          );
          await _printTextEnhanced(
            'Endpoint: $_workingEndpoint',
            align: 'center',
          );
        }

        await _printer.printEmptyLine();
        await _printer.printEmptyLine();

        return true;
      } catch (printError) {
        // Si hay error de impresión, verificar si la conexión se perdió
        if (printError.toString().contains('transferOut') ||
            printError.toString().contains('NotFoundError')) {
          _isConnected = false;
          _lastError =
              'Conexión USB perdida durante la impresión. Reconecte la impresora.';
        } else {
          _lastError = 'Error durante impresión: $printError';
        }
        throw printError;
      }
    } catch (e) {
      if (_lastError == null) {
        _lastError = 'Error en ticket de prueba: $e';
      }
      if (kDebugMode) print(_lastError);
      return false;
    }
  }

  /// Guarda la configuración de la impresora
  Future<void> _saveConfiguration() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_printerName != null) {
        await prefs.setString(SharedPrefsKeys.printerName, _printerName!);

        // Guardar configuración exitosa de conexión
        if (_workingInterface != null) {
          await prefs.setInt(
              '${SharedPrefsKeys.printerName}_interface', _workingInterface!);
        }
        if (_workingEndpoint != null) {
          await prefs.setInt(
              '${SharedPrefsKeys.printerName}_endpoint', _workingEndpoint!);
        }
        if (_workingVendorId != null) {
          await prefs.setInt(
              '${SharedPrefsKeys.printerName}_vendorId', _workingVendorId!);
        }
        if (_workingProductId != null) {
          await prefs.setInt(
              '${SharedPrefsKeys.printerName}_productId', _workingProductId!);
        }
      }
    } catch (e) {
      if (kDebugMode) print('Error guardando configuración: $e');
    }
  }

  /// Elimina la configuración guardada
  Future<void> _clearConfiguration() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(SharedPrefsKeys.printerName);

      // Limpiar configuración de conexión
      await prefs.remove('${SharedPrefsKeys.printerName}_interface');
      await prefs.remove('${SharedPrefsKeys.printerName}_endpoint');
      await prefs.remove('${SharedPrefsKeys.printerName}_vendorId');
      await prefs.remove('${SharedPrefsKeys.printerName}_productId');

      // Limpiar variables en memoria
      _workingInterface = null;
      _workingEndpoint = null;
      _workingVendorId = null;
      _workingProductId = null;
    } catch (e) {
      if (kDebugMode) print('Error eliminando configuración: $e');
    }
  }

  /// Imprime texto con mejor manejo de caracteres especiales
  Future<void> _printTextEnhanced(
    String text, {
    bool bold = false,
    String align = 'left',
    bool title = false,
  }) async {
    try {
      // Comandos de formato
      String command = '';

      // Alineación
      switch (align.toLowerCase()) {
        case 'center':
          command += '\x1B\x61\x01';
          break;
        case 'right':
          command += '\x1B\x61\x02';
          break;
        default:
          command += '\x1B\x61\x00'; // left
      }

      // Negrita
      if (bold) {
        command += '\x1B\x45\x01';
      }

      // Tamaño
      if (title) {
        command += '\x1B\x21\x30'; // Double height & width
      }

      // Imprimir comando de formato + texto
      await _printer.printText(command + text);

      // Restaurar formato normal
      await _printer.printText('\x1B\x45\x00\x1B\x21\x00\x1B\x61\x00');
    } catch (e) {
      if (kDebugMode) print('Error en impresión mejorada: $e');
      throw e;
    }
  }

  /// Genera un PDF del ticket como alternativa a la impresión
  /// Útil cuando no hay impresora conectada pero se quiere conservar el ticket
  Future<bool> generateTicketPdf({
    required String businessName,
    required List<Map<String, dynamic>> products,
    required double total,
    required String paymentMethod,
    String? customerName,
    double? cashReceived,
    double? change,
    String? ticketId,
  }) async {
    try {
      final pdf = pw.Document();
      final now = DateTime.now();

      // Crear el contenido del ticket en PDF
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(20),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Encabezado
                pw.Center(
                  child: pw.Column(
                    children: [
                      pw.Text(
                        businessName.toUpperCase(),
                        style: pw.TextStyle(
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 10),
                      pw.Text(
                        'TICKET DE VENTA',
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 20),
                    ],
                  ),
                ),

                // Información de fecha y cliente
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                        'Fecha: ${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}'),
                    pw.Text(
                        'Hora: ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}'),
                  ],
                ),

                if (customerName != null && customerName.isNotEmpty)
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 10),
                    child: pw.Text('Cliente: $customerName'),
                  ),

                pw.SizedBox(height: 20),

                // Línea separadora
                pw.Divider(),

                // Encabezado de productos
                pw.Row(
                  children: [
                    pw.Expanded(
                        flex: 1,
                        child: pw.Text('Cant.',
                            style:
                                pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                    pw.Expanded(
                        flex: 3,
                        child: pw.Text('Descripción',
                            style:
                                pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                    pw.Expanded(
                        flex: 1,
                        child: pw.Text('Precio',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                            textAlign: pw.TextAlign.right)),
                  ],
                ),

                pw.Divider(),

                // Lista de productos
                ...products.map((product) {
                  final quantity = product['quantity']?.toString() ?? '1';
                  final description =
                      product['description']?.toString() ?? 'Producto';
                  final price = product['price']?.toString() ?? '0.00';

                  return pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 2),
                    child: pw.Row(
                      children: [
                        pw.Expanded(flex: 1, child: pw.Text(quantity)),
                        pw.Expanded(flex: 3, child: pw.Text(description)),
                        pw.Expanded(
                            flex: 1,
                            child:
                                pw.Text(price, textAlign: pw.TextAlign.right)),
                      ],
                    ),
                  );
                }).toList(),

                pw.Divider(),

                // Total
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  children: [
                    pw.Text(
                      'TOTAL: \$${total.toStringAsFixed(2)}',
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                pw.SizedBox(height: 20),

                // Método de pago
                pw.Text('Método de pago: $paymentMethod'),

                // Efectivo recibido y vuelto
                if (cashReceived != null && cashReceived > 0) ...[
                  pw.Text(
                      'Efectivo recibido: \$${cashReceived.toStringAsFixed(2)}'),
                  if (change != null && change > 0)
                    pw.Text('Vuelto: \$${change.toStringAsFixed(2)}'),
                ],

                pw.SizedBox(height: 30),

                // Mensaje de agradecimiento
                pw.Center(
                  child: pw.Text(
                    'Gracias por su compra',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      );

      // Generar bytes del PDF
      final output = await pdf.save();

      if (kIsWeb) {
        // Para web: usar el método que ya funciona en el proyecto
        final base64pdf = base64Encode(output);
        final url = 'data:application/pdf;base64,$base64pdf';

        // Crear enlace de descarga usando el enfoque del proyecto existente
        final anchor =
            html.document.createElement('a') as html.HTMLAnchorElement;
        anchor.href = url;
        anchor.target = '_blank';
        anchor.download =
            '${ticketId ?? DateTime.now().millisecondsSinceEpoch}_ticket.pdf';
        html.document.body!.append(anchor);
        anchor.click();
        anchor.remove();
      }

      return true;
    } catch (e) {
      _lastError = 'Error al generar PDF: $e';
      if (kDebugMode) print(_lastError);
      return false;
    }
  }

  /// Genera un PDF del ticket y lo abre en el administrador de impresión del navegador
  /// Útil para imprimir con impresoras del sistema (no térmicas)
  Future<bool> printTicketWithBrowser({
    required String businessName,
    required List<Map<String, dynamic>> products,
    required double total,
    required String paymentMethod,
    String? customerName,
    double? cashReceived,
    double? change,
    String? ticketId,
  }) async {
    try {
      final pdf = pw.Document();
      final now = DateTime.now();

      // Crear el contenido del ticket en PDF optimizado para impresión
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(20),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Encabezado
                pw.Center(
                  child: pw.Column(
                    children: [
                      pw.Text(
                        businessName.toUpperCase(),
                        style: pw.TextStyle(
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 10),
                      pw.Text(
                        'TICKET DE VENTA',
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 20),
                    ],
                  ),
                ),

                // Información de fecha y cliente
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                        'Fecha: ${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}'),
                    pw.Text(
                        'Hora: ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}'),
                  ],
                ),

                if (customerName != null && customerName.isNotEmpty)
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 10),
                    child: pw.Text('Cliente: $customerName'),
                  ),

                pw.SizedBox(height: 20),

                // Línea separadora
                pw.Divider(),

                // Encabezado de productos
                pw.Row(
                  children: [
                    pw.Expanded(
                        flex: 1,
                        child: pw.Text('CANT.',
                            style:
                                pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                    pw.Expanded(
                        flex: 3,
                        child: pw.Text('DESCRIPCIÓN',
                            style:
                                pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                    pw.Expanded(
                        flex: 1,
                        child: pw.Text('PRECIO',
                            textAlign: pw.TextAlign.right,
                            style:
                                pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                  ],
                ),

                pw.Divider(),

                // Lista de productos
                ...products.map((product) {
                  final quantity = product['quantity']?.toString() ?? '1';
                  final description =
                      product['description']?.toString() ?? 'Producto';
                  final price = product['price']?.toString() ?? '\$0.00';

                  return pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 2),
                    child: pw.Row(
                      children: [
                        pw.Expanded(flex: 1, child: pw.Text(quantity)),
                        pw.Expanded(flex: 3, child: pw.Text(description)),
                        pw.Expanded(
                            flex: 1,
                            child:
                                pw.Text(price, textAlign: pw.TextAlign.right)),
                      ],
                    ),
                  );
                }).toList(),

                pw.Divider(),

                // Total
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  children: [
                    pw.Text(
                      'TOTAL: \$${total.toStringAsFixed(2)}',
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                pw.SizedBox(height: 20),

                // Método de pago
                pw.Text('Método de pago: $paymentMethod'),

                // Efectivo recibido y vuelto
                if (cashReceived != null && cashReceived > 0) ...[
                  pw.Text(
                      'Efectivo recibido: \$${cashReceived.toStringAsFixed(2)}'),
                  if (change != null && change > 0)
                    pw.Text('Vuelto: \$${change.toStringAsFixed(2)}'),
                ],

                pw.SizedBox(height: 30),

                // Mensaje de agradecimiento
                pw.Center(
                  child: pw.Text(
                    'Gracias por su compra',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      );

      // Generar bytes del PDF
      final output = await pdf.save();

      if (kIsWeb) {
        // Crear un data URL con el PDF para abrir en nueva ventana
        final base64pdf = base64Encode(output);
        final dataUrl = 'data:application/pdf;base64,$base64pdf';

        // Abrir el PDF en una nueva ventana con intención de impresión
        final printWindow = html.window.open(dataUrl, '_blank');

        // Intentar ejecutar print después de que se cargue el PDF
        if (printWindow != null) {
          // Usar un timer para esperar a que cargue el PDF y luego ejecutar print
          Timer(const Duration(milliseconds: 1500), () {
            try {
              printWindow.print();
            } catch (e) {
              if (kDebugMode)
                print('No se pudo ejecutar print automáticamente: $e');
              // Si falla el print automático, el usuario puede usar Ctrl+P manualmente
            }
          });
        }
      }

      return true;
    } catch (e) {
      _lastError = 'Error al abrir administrador de impresión: $e';
      if (kDebugMode) print(_lastError);
      return false;
    }
  }
}
