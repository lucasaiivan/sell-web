import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:sellweb/core/services/storage/app_data_persistence_service.dart';
import 'package:http/http.dart' as http;

/// Servicio para manejo de impresoras térmicas vía HTTP local
/// Este servicio configura y gestiona la conexión con un servidor HTTP local
/// que se ejecuta en la aplicación Flutter Desktop (Windows/macOS/Linux)
@lazySingleton
class ThermalPrinterHttpService {
  final AppDataPersistenceService _persistence;
  
  ThermalPrinterHttpService(this._persistence);

  bool _isConnected = false;
  String? _lastError;
  String? _configuredPrinterName;
  String _serverHost = 'localhost';
  int _serverPort = 8080;
  Map<String, dynamic>? _printerConfig;

  /// Estado de conexión con el servidor HTTP
  bool get isConnected => _isConnected;

  /// Nombre de la impresora configurada
  String? get configuredPrinterName => _configuredPrinterName;

  /// Último error registrado
  String? get lastError => _lastError;

  /// URL del servidor HTTP local
  String get serverUrl => 'http://$_serverHost:$_serverPort';

  /// Puerto del servidor
  int get serverPort => _serverPort;

  /// Host del servidor
  String get serverHost => _serverHost;

  /// Información detallada de la configuración
  Map<String, dynamic> get detailedConnectionInfo {
    return {
      'isConnected': _isConnected,
      'printerName': _configuredPrinterName,
      'serverUrl': serverUrl,
      'serverHost': _serverHost,
      'serverPort': _serverPort,
      'printerConfig': _printerConfig,
      'connectionType': _isConnected ? 'Servidor HTTP Local' : 'Desconectado',
      'lastError': _lastError,
    };
  }

  /// Inicializa el servicio cargando configuración previa
  Future<void> initialize() async {
    try {
      _configuredPrinterName = await _persistence.getPrinterName();
      // TODO: Agregar métodos para serverPort y serverHost en AppDataPersistenceService
      _serverPort = 8080; // Temporal: usar valor por defecto
      _serverHost = 'localhost'; // Temporal: usar valor por defecto

      // Cargar configuración de impresora
      // TODO: Agregar método getPrinterConfig en AppDataPersistenceService
      final configString = null as String?; // Temporal
      if (configString != null) {
        _printerConfig = jsonDecode(configString);
      }

      // Si hay configuración previa, verificar conexión
      if (_configuredPrinterName != null) {
        await _testConnection();
      }

      if (kDebugMode) {
        print('ThermalPrinterHttpService initialized');
        print('Server configured: $_serverHost:$_serverPort');
        print('Printer configured: $_configuredPrinterName');
      }
    } catch (e) {
      _lastError = 'Error al inicializar servicio HTTP: $e';
      if (kDebugMode) print(_lastError);
    }
  }

  /// Configura la conexión con el servidor HTTP local
  Future<bool> configurePrinter({
    String? printerName,
    String? serverHost,
    int? serverPort,
    String? devicePath,
    Map<String, dynamic>? customConfig,
  }) async {
    try {
      _lastError = null;

      // Actualizar configuración del servidor si se proporciona
      if (serverHost != null) _serverHost = serverHost;
      if (serverPort != null) _serverPort = serverPort;

      // El nombre de impresora es opcional, el servidor decide automáticamente
      final finalPrinterName = printerName ?? 'Auto-Selected-Printer';
      _configuredPrinterName = finalPrinterName;
      _printerConfig = {
        'name': finalPrinterName,
        'devicePath': devicePath,
        'customConfig': customConfig ?? {},
        'configuredAt': DateTime.now().toIso8601String(),
      };

      // Probar conexión con el servidor
      final connected = await _testConnection();

      if (connected) {
        // Enviar configuración al servidor
        final configSuccess = await _sendPrinterConfig();
        if (configSuccess) {
          _isConnected = true;
          await _saveConfiguration();

          if (kDebugMode) {
            print('Impresora configurada exitosamente: $printerName');
            print('Servidor: $serverUrl');
          }
          return true;
        }
      }

      return false;
    } catch (e) {
      _lastError = 'Error al configurar impresora: $e';
      if (kDebugMode) print(_lastError);
      return false;
    }
  }

  /// Desconecta la impresora y limpia la configuración
  Future<void> disconnectPrinter() async {
    try {
      _isConnected = false;
      _configuredPrinterName = null;
      _printerConfig = null;

      await _clearConfiguration();

      if (kDebugMode) print('Impresora desconectada y configuración eliminada');
    } catch (e) {
      _lastError = 'Error al desconectar impresora: $e';
      if (kDebugMode) print(_lastError);
    }
  }

  /// Imprime un ticket enviando los datos al servidor HTTP
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
      _lastError = 'No hay conexión con el servidor de impresión';
      return false;
    }

    try {
      _lastError = null;

      final ticketData = {
        'businessName': businessName,
        'products': products,
        'total': total,
        'paymentMethod': paymentMethod,
        'customerName': customerName,
        'cashReceived': cashReceived,
        'change': change,
        'timestamp': DateTime.now().toIso8601String(),
      };

      if (kDebugMode) {
        print('=== THERMAL PRINTER SERVICE DEBUG ===');
        print('Enviando ticket a: $serverUrl/print-ticket');
        print('Datos del ticket: ${jsonEncode(ticketData)}');
        print('=====================================');
      }

      final success = await _sendPrintRequest('/print-ticket', ticketData);

      if (success) {
        if (kDebugMode) print('✅ Ticket enviado para impresión exitosamente');
        return true;
      } else {
        if (kDebugMode) print('❌ Error al enviar ticket: $_lastError');
        return false;
      }
    } catch (e) {
      _lastError = 'Error al imprimir ticket: $e';
      if (kDebugMode) print('❌ Excepción en printTicket: $_lastError');
      return false;
    }
  }

  /// Envía un comando de impresión de prueba
  Future<bool> printTestTicket() async {
    if (!_isConnected) {
      _lastError = 'No hay conexión con el servidor de impresión';
      return false;
    }

    try {
      _lastError = null;

      final testData = {
        'test': true,
        'timestamp': DateTime.now().toIso8601String(),
      };

      final success = await _sendPrintRequest('/test-printer', testData);

      if (success) {
        if (kDebugMode) print('Comando de prueba enviado exitosamente');
        return true;
      } else {
        return false;
      }
    } catch (e) {
      _lastError = 'Error en impresión de prueba: $e';
      if (kDebugMode) print(_lastError);
      return false;
    }
  }

  /// Genera un PDF del ticket como alternativa (mantiene compatibilidad con API anterior)
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
      // Importar las dependencias necesarias para PDF
      // (este método mantiene compatibilidad con la API anterior pero no envía al servidor)

      if (kDebugMode) {
        print('=== GENERANDO PDF LOCALMENTE ===');
        print('Negocio: $businessName');
        print('Total: \$$total');
        print('Productos: ${products.length}');
        print('ID Ticket: $ticketId');
        print('================================');
      }

      // Por ahora simular éxito
      // En implementación real se usaría el código de PDF del servicio anterior
      await Future.delayed(const Duration(milliseconds: 300));
      return true;
    } catch (e) {
      _lastError = 'Error al generar PDF: $e';
      if (kDebugMode) print(_lastError);
      return false;
    }
  }

  /// Abre el PDF en el administrador de impresión del navegador (mantiene compatibilidad)
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
      if (kDebugMode) {
        print('=== ABRIENDO EN ADMINISTRADOR DE IMPRESIÓN ===');
        print('Negocio: $businessName');
        print('Total: \$$total');
        print('Productos: ${products.length}');
        print('==============================================');
      }

      // Por ahora simular éxito
      // En implementación real se generaría el PDF y se abriría en nueva ventana
      await Future.delayed(const Duration(milliseconds: 400));
      return true;
    } catch (e) {
      _lastError = 'Error al abrir administrador de impresión: $e';
      if (kDebugMode) print(_lastError);
      return false;
    }
  }

  /// Verifica la conexión con el servidor HTTP
  Future<bool> _testConnection() async {
    try {
      // En Flutter Web, usaremos fetch API
      if (kIsWeb) {
        return await _testConnectionWeb();
      } else {
        // Para aplicaciones desktop (futuro)
        return await _testConnectionDesktop();
      }
    } catch (e) {
      _lastError = 'Error al probar conexión: $e';
      if (kDebugMode) print(_lastError);
      return false;
    }
  }

  /// Prueba conexión en Flutter Web usando fetch
  Future<bool> _testConnectionWeb() async {
    try {
      if (kDebugMode) {
        print('Verificando conexión con $serverUrl/status');
      }

      // Importar dart:html para usar fetch en web
      // ignore: avoid_web_libraries_in_flutter
      final response = await _makeHttpRequest('GET', '/status', null);

      if (response != null && response['status'] == 'ok') {
        if (kDebugMode) print('Servidor HTTP respondió correctamente');
        return true;
      } else {
        _lastError = 'Servidor no disponible o respuesta inválida';
        return false;
      }
    } catch (e) {
      _lastError = 'Error de conexión: $e';
      if (kDebugMode) print(_lastError);
      return false;
    }
  }

  /// Prueba conexión en aplicación desktop
  Future<bool> _testConnectionDesktop() async {
    try {
      // Para implementación futura en desktop
      if (kDebugMode) {
        print('Verificando conexión desktop con $serverUrl/status');
      }

      return true;
    } catch (e) {
      _lastError = 'Error de conexión desktop: $e';
      return false;
    }
  }

  /// Envía la configuración de impresora al servidor
  Future<bool> _sendPrinterConfig() async {
    try {
      if (_printerConfig == null) return false;

      final configData = {
        'printerName': _configuredPrinterName,
        'config': _printerConfig,
      };

      return await _sendPrintRequest('/configure-printer', configData);
    } catch (e) {
      _lastError = 'Error al enviar configuración: $e';
      if (kDebugMode) print(_lastError);
      return false;
    }
  }

  /// Envía una solicitud al servidor de impresión
  Future<bool> _sendPrintRequest(
      String endpoint, Map<String, dynamic> data) async {
    try {
      if (kIsWeb) {
        return await _sendPrintRequestWeb(endpoint, data);
      } else {
        return await _sendPrintRequestDesktop(endpoint, data);
      }
    } catch (e) {
      _lastError = 'Error al enviar solicitud: $e';
      if (kDebugMode) print(_lastError);
      return false;
    }
  }

  /// Envía solicitud usando fetch API en web
  Future<bool> _sendPrintRequestWeb(
      String endpoint, Map<String, dynamic> data) async {
    try {
      final response = await _makeHttpRequest('POST', endpoint, data);

      if (response != null && response['status'] == 'ok') {
        if (kDebugMode) {
          print('Request exitoso a: $serverUrl$endpoint');
          print('Respuesta: ${response['message'] ?? 'Sin mensaje'}');
        }
        return true;
      } else {
        _lastError = response?['error'] ?? 'Error desconocido del servidor';
        return false;
      }
    } catch (e) {
      _lastError = 'Error en request web: $e';
      return false;
    }
  }

  /// Realiza una solicitud HTTP usando fetch API (solo web)
  Future<Map<String, dynamic>?> _makeHttpRequest(
      String method, String endpoint, Map<String, dynamic>? data) async {
    try {
      final url = Uri.parse('$serverUrl$endpoint');
      http.Response response;

      if (kDebugMode) {
        print('HTTP $method a: $url');
        if (data != null) print('Datos: ${jsonEncode(data)}');
      }

      // Configurar headers
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      // Realizar request según el método
      switch (method.toUpperCase()) {
        case 'GET':
          response = await http
              .get(url, headers: headers)
              .timeout(const Duration(seconds: 5));
          break;
        case 'POST':
          final body = data != null ? jsonEncode(data) : '';
          response = await http
              .post(url, headers: headers, body: body)
              .timeout(const Duration(seconds: 5));
          break;
        default:
          throw Exception('Método HTTP no soportado: $method');
      }

      if (kDebugMode) {
        print('HTTP Response Status: ${response.statusCode}');
        print('HTTP Response Body: ${response.body}');
      }

      // Procesar respuesta
      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (response.body.isNotEmpty) {
          return jsonDecode(response.body);
        } else {
          return {'status': 'ok', 'message': 'Respuesta vacía'};
        }
      } else {
        final errorBody =
            response.body.isNotEmpty ? response.body : 'Sin mensaje de error';
        return {
          'status': 'error',
          'error': 'Error HTTP ${response.statusCode}: $errorBody'
        };
      }
    } on TimeoutException {
      return {
        'status': 'error',
        'error': 'Timeout: Servidor no responde en 5 segundos'
      };
    } catch (e) {
      if (kDebugMode) print('Error en HTTP request: $e');
      return {'status': 'error', 'error': 'Error de comunicación: $e'};
    }
  }

  /// Envía solicitud usando HttpClient en desktop
  Future<bool> _sendPrintRequestDesktop(
      String endpoint, Map<String, dynamic> data) async {
    try {
      // Para implementación futura en desktop
      if (kDebugMode) {
        print('Enviando request desktop a: $serverUrl$endpoint');
        print('Datos: ${jsonEncode(data)}');
      }

      return true;
    } catch (e) {
      _lastError = 'Error en request desktop: $e';
      return false;
    }
  }

  /// Guarda la configuración
  Future<void> _saveConfiguration() async {
    try {
      if (_configuredPrinterName != null) {
        await _persistence.savePrinterName(_configuredPrinterName!);
      }

      // TODO: Agregar métodos para guardar serverPort y serverHost en AppDataPersistenceService
      // await _persistence.savePrinterServerPort(_serverPort);
      // await _persistence.savePrinterServerHost(_serverHost);

      // TODO: Agregar método savePrinterConfig en AppDataPersistenceService
      // if (_printerConfig != null) {
      //   await _persistence.savePrinterConfig(jsonEncode(_printerConfig));
      // }
    } catch (e) {
      if (kDebugMode) print('Error al guardar configuración: $e');
    }
  }

  /// Limpia la configuración guardada
  Future<void> _clearConfiguration() async {
    try {
      await _persistence.clearPrinterSettings();
      // TODO: Agregar métodos para limpiar serverPort, serverHost y config en AppDataPersistenceService
    } catch (e) {
      if (kDebugMode) print('Error al limpiar configuración: $e');
    }
  }

  /// Información de debug del servicio
  String get debugInfo {
    final info = StringBuffer();
    info.writeln('=== THERMAL PRINTER HTTP SERVICE DEBUG ===');
    info.writeln('Connected: $_isConnected');
    info.writeln('Server URL: $serverUrl');
    info.writeln('Printer Name: $_configuredPrinterName');
    info.writeln('Printer Config: $_printerConfig');
    info.writeln('Last Error: $_lastError');
    info.writeln('==========================================');
    return info.toString();
  }
}
