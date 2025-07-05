import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:usb_thermal_printer_web_pro/usb_thermal_printer_web_pro.dart';
import 'package:sellweb/core/utils/shared_prefs_keys.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Servicio para manejo de impresoras térmicas USB
/// Compatible con Windows y macOS a través de web
class ThermalPrinterService {
  static final ThermalPrinterService _instance = ThermalPrinterService._internal();
  factory ThermalPrinterService() => _instance;
  ThermalPrinterService._internal();

  final WebThermalPrinter _printer = WebThermalPrinter();
  bool _isConnected = false;
  String? _printerName;
  String? _lastError;

  /// Estado actual de conexión con la impresora
  bool get isConnected => _isConnected;
  
  /// Nombre de la impresora configurada
  String? get printerName => _printerName;
  
  /// Último error registrado
  String? get lastError => _lastError;

  /// Inicializa el servicio cargando configuración previa
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _printerName = prefs.getString(SharedPrefsKeys.printerName);
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
      
      // Configurar la impresora con parámetros optimizados para tickets
      _printer.config(
        printWidth: 48,    // Ancho típico para tickets térmicos
        leftPadding: 2,    // Padding mínimo
        rightPadding: 2,
      );

      // Intentar conectar con la impresora
      await _printer.pairDevice(
        vendorId: vendorId,
        productId: productId,
        interfaceNo: interfaceNumber,
        endpointNo: endpointNumber,
      );

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

  /// Desconecta la impresora actual
  Future<void> disconnectPrinter() async {
    try {
      if (_isConnected) {
        await _printer.closePrinter();
      }
    } catch (e) {
      _lastError = 'Error al desconectar: $e';
      if (kDebugMode) print(_lastError);
    } finally {
      _isConnected = false;
      _printerName = null;
      await _clearConfiguration();
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
      await _printer.printText(
        businessName.toUpperCase(),
        bold: true,
        align: 'center',
        title: true,
      );
      await _printer.printEmptyLine();
      
      await _printer.printText(
        'TICKET DE VENTA',
        align: 'center',
        bold: true,
      );
      await _printer.printEmptyLine();

      // Fecha y hora
      final now = DateTime.now();
      await _printer.printKeyValue(
        'Fecha:',
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}',
      );
      await _printer.printKeyValue(
        'Hora:',
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
      );
      
      if (customerName != null && customerName.isNotEmpty) {
        await _printer.printKeyValue('Cliente:', customerName);
      }
      
      await _printer.printDottedLine();

      // Productos
      await _printer.printFlex(
        ['CANT.', 'DESCRIPCIÓN', 'PRECIO'],
        [1, 3, 2],
        ['left', 'left', 'right'],
      );
      await _printer.printDottedLine();

      for (var product in products) {
        final quantity = product['quantity']?.toString() ?? '1';
        final description = product['description']?.toString() ?? 'Producto';
        final price = product['price']?.toString() ?? '0.00';
        
        await _printer.printFlex(
          [quantity, description, price],
          [1, 3, 2],
          ['left', 'left', 'right'],
        );
      }

      await _printer.printDottedLine();

      // Total
      await _printer.printKeyValue(
        'TOTAL:',
        '\$${total.toStringAsFixed(2)}',
      );

      // Método de pago
      await _printer.printKeyValue(
        'Método de pago:',
        paymentMethod,
      );

      // Efectivo recibido y vuelto (si aplica)
      if (cashReceived != null && cashReceived > 0) {
        await _printer.printKeyValue(
          'Efectivo recibido:',
          '\$${cashReceived.toStringAsFixed(2)}',
        );
        
        if (change != null && change > 0) {
          await _printer.printKeyValue(
            'Vuelto:',
            '\$${change.toStringAsFixed(2)}',
          );
        }
      }

      await _printer.printEmptyLine();
      await _printer.printText(
        'Gracias por su compra',
        align: 'center',
        bold: true,
      );
      await _printer.printEmptyLine();
      await _printer.printEmptyLine();

      // Código de barras del ticket (opcional)
      final ticketCode = '${now.millisecondsSinceEpoch}';
      await _printer.printBarcode(ticketCode);
      
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
      await _printer.printText(
        'TICKET DE PRUEBA',
        bold: true,
        align: 'center',
        title: true,
      );
      await _printer.printEmptyLine();
      
      await _printer.printText(
        'Impresora configurada correctamente',
        align: 'center',
      );
      await _printer.printEmptyLine();
      
      final now = DateTime.now();
      await _printer.printKeyValue(
        'Fecha:',
        '${now.day}/${now.month}/${now.year} ${now.hour}:${now.minute}',
      );
      
      await _printer.printDottedLine();
      await _printer.printText('Estado: CONECTADA', align: 'center', bold: true);
      await _printer.printEmptyLine();
      await _printer.printEmptyLine();
      
      return true;
    } catch (e) {
      _lastError = 'Error en ticket de prueba: $e';
      return false;
    }
  }

  /// Guarda la configuración de la impresora
  Future<void> _saveConfiguration() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_printerName != null) {
        await prefs.setString(SharedPrefsKeys.printerName, _printerName!);
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
    } catch (e) {
      if (kDebugMode) print('Error eliminando configuración: $e');
    }
  }
}
