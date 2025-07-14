import 'package:flutter/material.dart';
import 'package:sellweb/core/services/thermal_printer_http_service.dart';

/// Provider para manejar el estado de la impresora térmica
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
