import 'package:flutter/material.dart';
import 'package:sellweb/core/services/external/thermal_printer_http_service.dart';

/// Provider para gestionar el estado de conexión de impresora térmica
///
/// **Responsabilidad:** Coordinar UI y servicio de impresora
/// - Delega toda la lógica de conexión a ThermalPrinterHttpService
/// - Expone estado de conexión y errores para la UI
/// - No contiene lógica de impresión, solo gestión de estado
///
/// **Uso:**
/// ```dart
/// final printerProvider = Provider.of<PrinterProvider>(context);
/// await printerProvider.initialize(); // Inicializar conexión
/// await printerProvider.connectPrinter(serverHost: '192.168.1.100');
/// ```
class PrinterProvider extends ChangeNotifier {
  final ThermalPrinterHttpService _printerService = ThermalPrinterHttpService();

  bool _isConnected = false;
  String? _lastError;

  bool get isConnected => _isConnected;
  String? get lastError => _lastError;

  Future<void> initialize() async {
    await _printerService.initialize();
    _isConnected = _printerService.isConnected;
    _lastError = _printerService.lastError;
    notifyListeners();
  }

  Future<bool> connectPrinter(
      {String? serverHost, int? serverPort, String? devicePath}) async {
    final success = await _printerService.configurePrinter(
      serverHost: serverHost,
      serverPort: serverPort,
      devicePath: devicePath,
    );
    _isConnected = _printerService.isConnected;
    _lastError = _printerService.lastError;
    notifyListeners();
    return success;
  }

  Future<void> disconnectPrinter() async {
    await _printerService.disconnectPrinter();
    _isConnected = false;
    notifyListeners();
  }

  Future<void> refreshStatus() async {
    await _printerService.initialize();
    _isConnected = _printerService.isConnected;
    _lastError = _printerService.lastError;
    notifyListeners();
  }
}
