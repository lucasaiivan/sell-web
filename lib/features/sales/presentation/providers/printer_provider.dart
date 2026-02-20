import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';
import 'package:sellweb/core/services/external/thermal_printer_http_service.dart';

/// Provider de estado para la impresora térmica.
///
/// Coordina la UI con [ThermalPrinterHttpService] exponiendo
/// el estado actual y delegando toda la lógica HTTP al servicio.
@injectable
class PrinterProvider extends ChangeNotifier {
  final ThermalPrinterHttpService _printerService;

  bool _isConnected = false;
  bool _certificateAccepted = true;
  String? _lastError;
  PrinterErrorType? _lastErrorType;
  String? _printerName;

  PrinterProvider(this._printerService);

  bool get isConnected => _isConnected;
  bool get certificateAccepted => _certificateAccepted;
  String? get lastError => _lastError;
  PrinterErrorType? get lastErrorType => _lastErrorType;
  String? get printerName => _printerName;
  String get serverUrl => _printerService.serverUrl;

  /// Inicializa el servicio (carga config, verifica conexión si había config).
  Future<void> initialize() async {
    await _printerService.initialize();
    _syncState();
    notifyListeners();
  }

  /// Conecta y configura la impresora via auto-discovery.
  ///
  /// Delega en [configurePrinter] que internamente llama a [autoDiscover].
  Future<PrinterConnectionResult> connectPrinter({
    String? serverHost,
    int? serverPort,
  }) async {
    final result = await _printerService.configurePrinter(
      serverHost: serverHost,
      serverPort: serverPort,
    );
    _syncState();
    notifyListeners();
    return result;
  }

  /// Verifica el estado de la conexión.
  Future<PrinterConnectionResult> checkConnection() async {
    final result = await _printerService.checkConnection();
    _syncState();
    notifyListeners();
    return result;
  }

  /// Desconecta y limpia la configuración.
  Future<void> disconnectPrinter() async {
    await _printerService.disconnectPrinter();
    _isConnected = false;
    _printerName = null;
    _certificateAccepted = true;
    _lastError = null;
    _lastErrorType = null;
    notifyListeners();
  }

  /// Abre la URL del servidor para aceptar el certificado auto-firmado.
  void openCertificateAcceptPage() {
    _printerService.openCertificateAcceptPage();
  }

  /// Envía un ticket de prueba a la impresora.
  Future<PrinterConnectionResult> printTestTicket() async {
    return _printerService.printTestTicket();
  }

  Future<void> refreshStatus() async {
    await _printerService.initialize();
    _syncState();
    notifyListeners();
  }

  void startHeartbeat({int intervalMs = 30000}) {
    _printerService.startHeartbeat(intervalMs: intervalMs);
  }

  void stopHeartbeat() {
    _printerService.stopHeartbeat();
  }

  void _syncState() {
    _isConnected = _printerService.isConnected;
    _certificateAccepted = _printerService.certificateAccepted;
    _lastError = _printerService.lastError;
    _lastErrorType = _printerService.lastErrorType;
    _printerName = _printerService.configuredPrinterName;
  }

  @override
  void dispose() {
    _printerService.stopHeartbeat();
    super.dispose();
  }
}
