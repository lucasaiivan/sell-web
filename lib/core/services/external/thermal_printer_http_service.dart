import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:sellweb/core/services/storage/app_data_persistence_service.dart';
import 'package:http/http.dart' as http;
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

// ────────────────────────────────────────────────────────────────────────────
// ENUMS Y TIPOS
// ────────────────────────────────────────────────────────────────────────────

/// Protocolo de comunicación con el servidor de impresión.
enum PrinterProtocol { http, https }

extension PrinterProtocolExt on PrinterProtocol {
  String get scheme => name; // 'http' | 'https'

  static PrinterProtocol fromString(String? s) =>
      s == 'http' ? PrinterProtocol.http : PrinterProtocol.https;
}

/// Tipo de error de conexión con el servidor de impresión.
///
/// Permite a la UI mostrar mensajes, íconos y acciones específicas
/// para cada escenario sin múltiples peticiones de reintento.
enum PrinterErrorType {
  /// Servidor no está corriendo / no hay red
  serverUnavailable,

  /// Certificado auto-firmado no fue aceptado en el navegador
  certificateNotAccepted,

  /// Token de autenticación inválido (HTTP 401)
  invalidToken,

  /// No hay impresora configurada en el servidor (HTTP 400)
  printerNotConfigured,

  /// Servidor activo pero sistema de impresión no inicializado (HTTP 503)
  printSystemNotReady,

  /// La petición tardó más de 5 segundos
  timeout,

  /// Respuesta inesperada del servidor
  serverError,

  /// No hay configuración previa (estado inicial limpio)
  notConfigured,
}

// ────────────────────────────────────────────────────────────────────────────
// RESULTADO DE SONDEO ATÓMICO
// ────────────────────────────────────────────────────────────────────────────

/// Resultado de sondear una URL concreta (protocolo + host + puerto).
class _ProbeResult {
  final bool ok;
  final String url;
  final PrinterProtocol protocol;
  final String host;
  final int port;
  final Map<String, dynamic>? body;
  final bool isCertError;

  const _ProbeResult({
    required this.ok,
    required this.url,
    required this.protocol,
    required this.host,
    required this.port,
    this.body,
    this.isCertError = false,
  });
}

// ────────────────────────────────────────────────────────────────────────────
// RESULTADO PÚBLICO DE CONEXIÓN
// ────────────────────────────────────────────────────────────────────────────

/// Resultado rico de una operación con el servidor de impresión.
class PrinterConnectionResult {
  final bool success;
  final PrinterErrorType? errorType;
  final String? message;
  final String? printerName;
  final String? actionUrl;
  final Map<String, dynamic>? serverData;

  /// Protocolo efectivo con el que se logró conexión.
  final PrinterProtocol? resolvedProtocol;

  /// URL completa que respondió exitosamente.
  final String? resolvedUrl;

  const PrinterConnectionResult({
    required this.success,
    this.errorType,
    this.message,
    this.printerName,
    this.actionUrl,
    this.serverData,
    this.resolvedProtocol,
    this.resolvedUrl,
  });

  bool get isCertificateError =>
      errorType == PrinterErrorType.certificateNotAccepted;
  bool get isServerUnavailable =>
      errorType == PrinterErrorType.serverUnavailable;
  bool get isTimeout => errorType == PrinterErrorType.timeout;
  bool get isPrinterNotConfigured =>
      errorType == PrinterErrorType.printerNotConfigured;
  bool get isInvalidToken => errorType == PrinterErrorType.invalidToken;
  bool get isPrintSystemNotReady =>
      errorType == PrinterErrorType.printSystemNotReady;
  bool get isNotConfigured => errorType == PrinterErrorType.notConfigured;

  // ── Factories semánticas ─────────────────────────────────────────────────

  factory PrinterConnectionResult.connected(
    Map<String, dynamic> data, {
    PrinterProtocol? protocol,
    String? resolvedUrl,
  }) {
    return PrinterConnectionResult(
      success: true,
      printerName: data['printer'] as String?,
      message: data['message'] as String?,
      serverData: data,
      resolvedProtocol: protocol,
      resolvedUrl: resolvedUrl,
    );
  }

  factory PrinterConnectionResult.notConfigured() {
    return const PrinterConnectionResult(
      success: false,
      errorType: PrinterErrorType.notConfigured,
      message: 'No hay configuración de impresora guardada.',
    );
  }

  factory PrinterConnectionResult.certificateNotAccepted(String serverUrl) {
    return PrinterConnectionResult(
      success: false,
      errorType: PrinterErrorType.certificateNotAccepted,
      // Mensaje cubre 2 causas: cert no aceptado O servidor apagado.
      // En Flutter Web no se puede distinguir entre ambas desde fetch().
      message: 'No se pudo conectar al servidor de impresión. '
          'Si la app SellPOS está activa, es necesario aceptar el certificado HTTPS '
          'en el navegador antes de poder conectarse.',
      actionUrl: serverUrl,
    );
  }

  factory PrinterConnectionResult.serverUnavailable() {
    return const PrinterConnectionResult(
      success: false,
      errorType: PrinterErrorType.serverUnavailable,
      message:
          'No se puede conectar con el servidor de impresión. '
          'Verificá que la app SellPOS esté ejecutándose en tu PC.',
    );
  }

  factory PrinterConnectionResult.timeout() {
    return const PrinterConnectionResult(
      success: false,
      errorType: PrinterErrorType.timeout,
      message:
          'El servidor tardó demasiado en responder. '
          'Puede estar iniciando — esperá unos segundos y reintentá.',
    );
  }

  factory PrinterConnectionResult.serverError(String msg) {
    return PrinterConnectionResult(
      success: false,
      errorType: PrinterErrorType.serverError,
      message: msg,
    );
  }

  factory PrinterConnectionResult.printerNotConfigured(String msg) {
    return PrinterConnectionResult(
      success: false,
      errorType: PrinterErrorType.printerNotConfigured,
      message: msg,
    );
  }

  factory PrinterConnectionResult.invalidToken() {
    return const PrinterConnectionResult(
      success: false,
      errorType: PrinterErrorType.invalidToken,
      message:
          'Token de autenticación inválido. '
          'Verificá el token en la configuración del servidor.',
    );
  }

  factory PrinterConnectionResult.printSystemNotReady() {
    return const PrinterConnectionResult(
      success: false,
      errorType: PrinterErrorType.printSystemNotReady,
      message:
          'El sistema de impresión no está listo. '
          'Reiniciá la aplicación SellPOS.',
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// PASO DE DESCUBRIMIENTO (para UI con progreso)
// ────────────────────────────────────────────────────────────────────────────

/// Estado de un paso del auto-discovery mostrado en la UI.
enum DiscoveryStepStatus { pending, running, success, failed }

class DiscoveryStep {
  final String label;
  final DiscoveryStepStatus status;

  const DiscoveryStep({required this.label, required this.status});

  DiscoveryStep copyWith({DiscoveryStepStatus? status}) =>
      DiscoveryStep(label: label, status: status ?? this.status);
}

// ────────────────────────────────────────────────────────────────────────────
// SERVICIO PRINCIPAL
// ────────────────────────────────────────────────────────────────────────────

/// Servicio de conexión con el servidor de impresión local (SellPOS Desktop).
///
/// ## Auto-Discovery
/// Cuando el usuario pulsa "Detectar", el servicio prueba en paralelo
/// múltiples combinaciones de protocolo+puerto hasta encontrar una que
/// responda con `{"status":"ok"}`.
///
/// ## Estrategias (en orden de prioridad):
/// 1. HTTPS → puerto ingresado
/// 2. HTTP  → puerto ingresado
/// 3. HTTPS → 8080 (default)
/// 4. HTTP  → 8080 (default)
/// 5. HTTPS → 3000 (legacy)
/// 6. HTTP  → 3000 (legacy)
///
/// La primera que responda gana; el resultado se persiste.
@lazySingleton
class ThermalPrinterHttpService {
  final AppDataPersistenceService _persistence;

  ThermalPrinterHttpService(this._persistence);

  // ── Estado interno ─────────────────────────────────────────────────────

  bool _isConnected = false;
  bool _certificateAccepted = false;
  String? _lastError;
  PrinterErrorType? _lastErrorType;
  String? _configuredPrinterName;
  String _serverHost = 'localhost';
  int _serverPort = 8080;
  PrinterProtocol _protocol = PrinterProtocol.https;
  Timer? _heartbeatTimer;

  /// Callback que notifica avance durante auto-discovery.
  /// El argumento es la lista actualizada de pasos.
  void Function(List<DiscoveryStep>)? onDiscoveryProgress;

  // ── Getters ─────────────────────────────────────────────────────────────

  bool get isConnected => _isConnected;
  bool get certificateAccepted => _certificateAccepted;
  String? get configuredPrinterName => _configuredPrinterName;
  String? get lastError => _lastError;
  PrinterErrorType? get lastErrorType => _lastErrorType;
  String get serverHost => _serverHost;
  int get serverPort => _serverPort;
  PrinterProtocol get protocol => _protocol;

  /// URL activa basada en protocolo/host/puerto resueltos.
  String get serverUrl => '${_protocol.scheme}://$_serverHost:$_serverPort';

  Map<String, dynamic> get detailedConnectionInfo => {
        'isConnected': _isConnected,
        'certificateAccepted': _certificateAccepted,
        'printerName': _configuredPrinterName,
        'serverUrl': serverUrl,
        'protocol': _protocol.scheme,
        'serverHost': _serverHost,
        'serverPort': _serverPort,
        'lastError': _lastError,
        'lastErrorType': _lastErrorType?.name,
      };

  // ── INICIALIZACIÓN ──────────────────────────────────────────────────────

  /// Carga la configuración persistida y verifica silenciosamente la conexión.
  Future<void> initialize() async {
    try {
      _serverPort = await _persistence.getPrinterServerPort() ?? 8080;
      _serverHost = await _persistence.getPrinterServerHost() ?? 'localhost';
      _configuredPrinterName = await _persistence.getPrinterName();

      final savedProtocol = await _persistence.getPrinterProtocol();
      _protocol = PrinterProtocolExt.fromString(savedProtocol);

      // Solo verifica si hay host/puerto guardados explícitamente
      final savedHost = await _persistence.getPrinterServerHost();
      final savedPort = await _persistence.getPrinterServerPort();

      if (savedHost == null || savedPort == null) {
        _isConnected = false;
        _certificateAccepted = false;
        if (kDebugMode) debugPrint('🖨️ Sin configuración previa de impresora.');
        return;
      }

      // Hay config previa → verificar conexión silenciosamente
      final result = await checkConnection();
      _isConnected = result.success;
      _certificateAccepted = !result.isCertificateError;

      if (result.success && result.printerName != null) {
        _configuredPrinterName = result.printerName;
      }

      if (kDebugMode) {
        debugPrint('🖨️ ThermalPrinterHttpService – init completo');
        debugPrint('   Protocolo: ${_protocol.scheme}');
        debugPrint('   Servidor : $serverUrl');
        debugPrint('   Impresora: ${_configuredPrinterName ?? "Sin configurar"}');
        debugPrint('   Conectado: $_isConnected');
      }
    } catch (e) {
      _lastError = 'Error al inicializar: $e';
      if (kDebugMode) debugPrint('❌ $_lastError');
    }
  }

  // ── AUTO-DISCOVERY ──────────────────────────────────────────────────────

  /// Detecta automáticamente el servidor de impresión probando múltiples
  /// combinaciones protocolo+puerto en paralelo.
  ///
  /// [host]    → dirección ingresada por el usuario (ej: "localhost")
  /// [port]    → puerto ingresado por el usuario (ej: 8080)
  ///
  /// Actualiza `onDiscoveryProgress` con el avance en tiempo real.
  /// Retorna [PrinterConnectionResult] con el resultado y URL resuelta.
  Future<PrinterConnectionResult> autoDiscover({
    required String host,
    required int port,
  }) async {
    _lastError = null;
    _lastErrorType = null;

    // Construir estrategias únicas
    final candidates = _buildCandidates(host, port);

    // Inicializar pasos de UI
    final steps = candidates
        .map((c) => DiscoveryStep(
              label: '${c.protocol.scheme.toUpperCase()}://$host:${c.port}',
              status: DiscoveryStepStatus.pending,
            ))
        .toList();

    _notifyProgress(steps);

    // ── Sondeo en paralelo con race ──────────────────────────────────────
    final Completer<_ProbeResult> completer = Completer();
    int remaining = candidates.length;
    bool anyTimeout = false;
    // Flag: alguna probe HTTPS falló con error de red/cert.
    // En Flutter Web es imposible distinguir cert error de servidor apagado,
    // por eso lo consideramos posible cert error y mostramos las instrucciones.
    bool httpsHadCertError = false;

    for (int i = 0; i < candidates.length; i++) {
      final c = candidates[i];
      final idx = i;

      // Marcar como "probando"
      steps[idx] = steps[idx].copyWith(status: DiscoveryStepStatus.running);
      _notifyProgress(List.from(steps));

      _probeUrl(c).then((probe) {
        // Contar cert errors de probes HTTPS (HTTP no tiene SSL)
        if (probe.isCertError && probe.protocol == PrinterProtocol.https) {
          httpsHadCertError = true;
        }
        if (probe.ok && !completer.isCompleted) {
          // ¡Ganador!
          steps[idx] =
              steps[idx].copyWith(status: DiscoveryStepStatus.success);
          _notifyProgress(List.from(steps));
          completer.complete(probe);
        } else {
          steps[idx] = steps[idx].copyWith(status: DiscoveryStepStatus.failed);
          _notifyProgress(List.from(steps));
        }
        remaining--;

        if (remaining == 0 && !completer.isCompleted) {
          // Todas fallaron
          completer.complete(_ProbeResult(
            ok: false,
            url: 'https://$host:$port',
            protocol: PrinterProtocol.https,
            host: host,
            port: port,
            isCertError: httpsHadCertError,
          ));
        }
      }).catchError((_) {
        remaining--;
        steps[idx] = steps[idx].copyWith(status: DiscoveryStepStatus.failed);
        _notifyProgress(List.from(steps));
        if (remaining == 0 && !completer.isCompleted) {
          completer.complete(_ProbeResult(
            ok: false,
            url: 'https://$host:$port',
            protocol: PrinterProtocol.https,
            host: host,
            port: port,
          ));
        }
      });
    }

    // Esperar hasta 6 segundos máximo
    _ProbeResult winner;
    try {
      winner = await completer.future.timeout(const Duration(seconds: 6));
    } on TimeoutException {
      anyTimeout = true;
      winner = _ProbeResult(
        ok: false,
        url: 'https://$host:$port',
        protocol: PrinterProtocol.https,
        host: host,
        port: port,
      );
    }

    if (!winner.ok) {
      if (anyTimeout) return _setError(PrinterConnectionResult.timeout());

      // En Flutter Web NO se puede distinguir entre:
      //   a) Certificado no aceptado (fetch falla con XmlHttpRequestError genérico)
      //   b) Servidor apagado     (fetch falla con el MISMO XmlHttpRequestError)
      //
      // Estrategia: si alguna probe HTTPS marcó posible cert error,
      // mostrar el flujo de "aceptar certificado" que también incluye
      // la instrucción de verificar que SellPOS esté corriendo.
      // Esto cubre ambos casos y guía correctamente al usuario.
      //
      // Solo forzar "servidor no disponible" si NINGUNA probe HTTPS
      // marcó cert error (p.ej. todas dieron timeout).
      if (httpsHadCertError) {
        return _setError(
            PrinterConnectionResult.certificateNotAccepted(
                'https://$host:$port'));
      }

      return _setError(PrinterConnectionResult.serverUnavailable());
    }

    // ── Actualizar estado con el ganador ──────────────────────────────────
    _serverHost = winner.host;
    _serverPort = winner.port;
    _protocol = winner.protocol;
    _certificateAccepted = true;

    // 2. Enviar /configure-printer con la URL resuelta
    final configResult = await _configurePrinterOnServer(winner);
    return configResult;
  }

  /// Envía POST /configure-printer al servidor ganador y guarda config.
  Future<PrinterConnectionResult> _configurePrinterOnServer(
      _ProbeResult winner) async {
    try {
      final response =
          await _makeHttpRequest('POST', '/configure-printer', {}, winner.url);

      if (response == null) {
        return _setError(PrinterConnectionResult.serverUnavailable());
      }

      // Interpretar status codes embebidos
      if (response['errorType'] == 'printerNotConfigured') {
        return _setError(PrinterConnectionResult.printerNotConfigured(
            response['message'] ?? 'Sin impresora en el servidor.'));
      }
      if (response['errorType'] == 'invalidToken') {
        return _setError(PrinterConnectionResult.invalidToken());
      }
      if (response['errorType'] == 'printSystemNotReady') {
        return _setError(PrinterConnectionResult.printSystemNotReady());
      }

      if (response['status'] == 'ok') {
        _isConnected = true;
        _configuredPrinterName =
            _extractPrinterName(response['printer'] as String?);
        await _saveConfiguration();

        if (kDebugMode) {
          debugPrint('✅ Conectado: ${winner.protocol.scheme}://'
              '${winner.host}:${winner.port}');
          debugPrint('   Impresora: $_configuredPrinterName');
        }

        return PrinterConnectionResult.connected(
          {...response, 'printer': _configuredPrinterName ?? response['printer']},
          protocol: winner.protocol,
          resolvedUrl: winner.url,
        );
      }

      final msg = response['message'] as String?;
      return _setError(
          PrinterConnectionResult.serverError(msg ?? 'Error al configurar.'));
    } catch (e) {
      return _setError(PrinterConnectionResult.serverUnavailable());
    }
  }

  // ── VERIFICACIÓN DE CONEXIÓN ────────────────────────────────────────────

  /// Verifica la conexión con la URL actualmente configurada.
  Future<PrinterConnectionResult> checkConnection() async {
    try {
      _lastError = null;
      _lastErrorType = null;

      final response =
          await _makeHttpRequest('GET', '/status', null, serverUrl);

      if (response == null) {
        return _setError(PrinterConnectionResult.serverUnavailable());
      }

      if (response['status'] == 'ok') {
        _isConnected = true;
        _certificateAccepted = true;
        _lastErrorType = null;
        _configuredPrinterName =
            _extractPrinterName(response['printer'] as String?);
        return PrinterConnectionResult.connected(response,
            protocol: _protocol, resolvedUrl: serverUrl);
      }

      final msg = response['message'] as String?;
      return _setError(PrinterConnectionResult.serverError(
          msg ?? 'Respuesta inesperada del servidor.'));
    } on _CertificateException catch (e) {
      _certificateAccepted = false;
      return _setError(
          PrinterConnectionResult.certificateNotAccepted(e.serverUrl));
    } on TimeoutException {
      return _setError(PrinterConnectionResult.timeout());
    } catch (e) {
      return _setError(PrinterConnectionResult.serverUnavailable());
    }
  }

  // ── CONFIGURAR (API legada mantenida) ──────────────────────────────────

  /// Configura usando host/puerto explícitos sin auto-discovery.
  /// Mantiene compatibilidad con código que llame directamente a este método.
  Future<PrinterConnectionResult> configurePrinter({
    String? serverHost,
    int? serverPort,
  }) async {
    return autoDiscover(
      host: serverHost ?? _serverHost,
      port: serverPort ?? _serverPort,
    );
  }

  // ── DESCONEXIÓN ─────────────────────────────────────────────────────────

  Future<void> disconnectPrinter() async {
    stopHeartbeat();
    _isConnected = false;
    _configuredPrinterName = null;
    _lastError = null;
    _lastErrorType = null;
    await _clearConfiguration();
  }

  // ── IMPRESIÓN ───────────────────────────────────────────────────────────

  /// Imprime un ticket de venta. Requiere conexión activa.
  Future<PrinterConnectionResult> printTicket({
    required String businessName,
    required List<Map<String, dynamic>> products,
    required double total,
    required String paymentMethod,
    double? cashReceived,
    double? change,
  }) async {
    if (!_isConnected) {
      return _setError(PrinterConnectionResult.serverUnavailable());
    }

    try {
      final payload = {
        'businessName': businessName,
        'products': products,
        'total': total,
        'paymentMethod': paymentMethod,
        if (cashReceived != null) 'cashReceived': cashReceived,
        if (change != null) 'change': change,
      };

      final response =
          await _makeHttpRequest('POST', '/print-ticket', payload, serverUrl);

      if (response == null) {
        _isConnected = false;
        return _setError(PrinterConnectionResult.serverUnavailable());
      }

      if (response['status'] == 'ok') {
        _isConnected = true;
        return PrinterConnectionResult.connected(response,
            protocol: _protocol, resolvedUrl: serverUrl);
      }

      return _setError(PrinterConnectionResult.serverError(
          response['message'] ?? 'Error al imprimir.'));
    } on TimeoutException {
      return _setError(PrinterConnectionResult.timeout());
    } catch (e) {
      _isConnected = false;
      return _setError(PrinterConnectionResult.serverUnavailable());
    }
  }

  /// Envía un ticket de prueba al servidor.
  Future<PrinterConnectionResult> printTestTicket() async {
    if (!_isConnected) {
      return _setError(PrinterConnectionResult.serverUnavailable());
    }

    try {
      final response =
          await _makeHttpRequest('POST', '/test-printer', {}, serverUrl);

      if (response == null) {
        return _setError(PrinterConnectionResult.serverUnavailable());
      }

      if (response['status'] == 'ok') {
        return PrinterConnectionResult.connected(response,
            protocol: _protocol, resolvedUrl: serverUrl);
      }

      return _setError(PrinterConnectionResult.serverError(
          response['message'] ?? 'Error al imprimir ticket de prueba.'));
    } on TimeoutException {
      return _setError(PrinterConnectionResult.timeout());
    } catch (e) {
      return _setError(PrinterConnectionResult.serverUnavailable());
    }
  }

  // ── CERTIFICADO ─────────────────────────────────────────────────────────

  /// Abre el servidor en nueva pestaña para aceptar el certificado HTTPS.
  void openCertificateAcceptPage({String? url}) {
    html.window.open(url ?? serverUrl, '_blank');
  }

  // ── HEARTBEAT ───────────────────────────────────────────────────────────

  void startHeartbeat({int intervalMs = 30000}) {
    stopHeartbeat();
    _heartbeatTimer =
        Timer.periodic(Duration(milliseconds: intervalMs), (_) async {
      final result = await checkConnection();
      _isConnected = result.success;
      _certificateAccepted = !result.isCertificateError;
    });
    if (kDebugMode) debugPrint('💓 Heartbeat iniciado (${intervalMs / 1000}s)');
  }

  void stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  // ── CONSTRUCCIÓN DE CANDIDATOS ─────────────────────────────────────────

  /// Genera la lista de URLs a probar en paralelo durante auto-discovery.
  ///
  /// Prioridad (orden de preferencia si todas responden rápido):
  /// 1. HTTPS:puerto ingresado  2. HTTP:puerto ingresado
  /// 3. HTTPS:8080              4. HTTP:8080
  /// 5. HTTPS:3000              6. HTTP:3000
  List<_ProbeRecord> _buildCandidates(String host, int port) {
    final ports = <int>{port, 8080, 3000};
    final result = <_ProbeRecord>[];

    for (final p in ports) {
      result
        ..add(_ProbeRecord(
          protocol: PrinterProtocol.https,
          host: host,
          port: p,
          url: 'https://$host:$p',
        ))
        ..add(_ProbeRecord(
          protocol: PrinterProtocol.http,
          host: host,
          port: p,
          url: 'http://$host:$p',
        ));
    }
    return result;
  }

  // ── SONDEO ATÓMICO ──────────────────────────────────────────────────────

  /// Prueba una URL concreta con GET /status.
  /// Timeout 3 s. No lanza excepciones — siempre retorna [_ProbeResult].
  Future<_ProbeResult> _probeUrl(_ProbeRecord record) async {
    try {
      final url = Uri.parse('${record.url}/status');
      final response = await http
          .get(url, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 3));

      if (kDebugMode) {
        debugPrint('🔍 ${record.url} → ${response.statusCode}');
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        Map<String, dynamic>? body;
        try {
          body = jsonDecode(response.body) as Map<String, dynamic>;
        } catch (_) {}

        final isOk = body?['status'] == 'ok';
        return _ProbeResult(
          ok: isOk,
          url: record.url,
          protocol: record.protocol,
          host: record.host,
          port: record.port,
          body: body,
        );
      }

      // HTTP 4xx/5xx → servidor existe pero con error
      // p.ej. 401 = token incorrecto → igual es "alcanzable"
      if (response.statusCode == 401 ||
          response.statusCode == 400 ||
          response.statusCode == 503) {
        Map<String, dynamic>? body;
        try {
          body = jsonDecode(response.body) as Map<String, dynamic>;
        } catch (_) {}
        // Lo reportamos como ok=false pero el servidor SÍ existe
        return _ProbeResult(
          ok: false,
          url: record.url,
          protocol: record.protocol,
          host: record.host,
          port: record.port,
          body: body,
        );
      }

      return _ProbeResult(
        ok: false,
        url: record.url,
        protocol: record.protocol,
        host: record.host,
        port: record.port,
      );
    } on TimeoutException {
      return _ProbeResult(
        ok: false,
        url: record.url,
        protocol: record.protocol,
        host: record.host,
        port: record.port,
      );
    } catch (e) {
      // En Flutter Web, fetch() falla con XmlHttpRequestError genérico
      // tanto para cert no aceptado como para servidor apagado.
      // Marcamos isCertError=true SOLO en probes HTTPS porque:
      //   - El servidor puede ser solo-HTTPS (no escucha HTTP).
      //   - Si HTTPS falla genéricamente, el cert es el candidato más plausible.
      //   - La UI mostrará instrucciones que cubren ambos casos.
      final isHttpsProbe = record.protocol == PrinterProtocol.https;
      final isCert = isHttpsProbe && _isPossibleCertOrNetworkError(e.toString());
      if (kDebugMode) {
        debugPrint('❌ Probe ${record.url} → ${e.runtimeType}: ${e.toString().substring(0, e.toString().length.clamp(0, 80))}');
        if (isCert) debugPrint('🔒 Marcado como posible cert error (HTTPS)');
      }
      return _ProbeResult(
        ok: false,
        url: record.url,
        protocol: record.protocol,
        host: record.host,
        port: record.port,
        isCertError: isCert,
      );
    }
  }

  // ── HTTP INTERNO ────────────────────────────────────────────────────────

  Map<String, String> _getHeaders() {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  /// Ejecuta una petición HTTP/S y normaliza la respuesta.
  Future<Map<String, dynamic>?> _makeHttpRequest(
    String method,
    String endpoint,
    Map<String, dynamic>? data,
    String baseUrl,
  ) async {
    final url = Uri.parse('$baseUrl$endpoint');
    if (kDebugMode) debugPrint('🌐 $method → $url');

    http.Response response;
    try {
      final headers = _getHeaders();
      switch (method.toUpperCase()) {
        case 'GET':
          response = await http
              .get(url, headers: headers)
              .timeout(const Duration(seconds: 5));
          break;
        case 'POST':
          response = await http
              .post(url, headers: headers, body: jsonEncode(data ?? {}))
              .timeout(const Duration(seconds: 5));
          break;
        default:
          throw ArgumentError('Método HTTP no soportado: $method');
      }
    } on TimeoutException {
      rethrow;
    } catch (e) {
      final msg = e.toString();
      // Para checkConnection() (URL ya configurada = siempre HTTPS)
      // cualquier error genérico de red puede ser cert no aceptado.
      if (_isPossibleCertOrNetworkError(msg)) throw _CertificateException(baseUrl);
      rethrow;
    }

    if (kDebugMode) debugPrint('   ← ${response.statusCode}');

    Map<String, dynamic>? body;
    if (response.body.isNotEmpty) {
      try {
        body = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (_) {
        body = {'status': 'error', 'message': response.body};
      }
    }

    switch (response.statusCode) {
      case >= 200 when response.statusCode < 300:
        return body ?? {'status': 'ok'};
      case 400:
        return {
          'status': 'error',
          'errorType': 'printerNotConfigured',
          'message':
              body?['message'] ?? 'No hay impresora configurada en el servidor.',
        };
      case 401:
        return {
          'status': 'error',
          'errorType': 'invalidToken',
          'message': 'Token de autenticación inválido.',
        };
      case 503:
        return {
          'status': 'error',
          'errorType': 'printSystemNotReady',
          'message': 'El sistema de impresión no está listo. '
              'Reiniciá la aplicación de escritorio.',
        };
      default:
        return {
          'status': 'error',
          'message':
              'Error HTTP ${response.statusCode}: ${body?['message'] ?? response.body}',
        };
    }
  }

  // ── UTILIDADES ──────────────────────────────────────────────────────────

  /// Detecta si un mensaje de error es un posible error de certificado SSL
  /// o error de red (que en Flutter Web son indistinguibles).
  ///
  /// ## Por qué incluir errores genéricos de red:
  /// En **Flutter Web**, `fetch()` falla con `XmlHttpRequestError` genérico
  /// tanto cuando el certificado no está aceptado como cuando el servidor
  /// está apagado. Es **imposible** distinguir ambos casos desde Dart/JS.
  ///
  /// La estrategia es marcar el error como "posible cert" en probes HTTPS
  /// y mostrar al usuario instrucciones que cubren ambos escenarios.
  bool _isPossibleCertOrNetworkError(String msg) {
    final s = msg.toLowerCase();
    // Errores SSL/TLS específicos (Dart nativo / mobile / algunos browsers):
    if (s.contains('err_cert') ||
        s.contains('certificate') ||
        s.contains('handshake') ||
        s.contains('ssl_error') ||
        s.contains('cert_authority') ||
        s.contains('sec_error')) {
      return true;
    }
    // Errores genéricos de red en Flutter Web (fetch() / XmlHttpRequest):
    // Estos aparecen tanto para cert no aceptado como para servidor apagado.
    if (s.contains('xmlhttprequest') ||
        s.contains('failed to fetch') ||
        s.contains('networkerror') ||
        s.contains('network error') ||
        s.contains('typeerror') ||
        s.contains('err_connection') ||
        s.contains('net::err')) {
      return true;
    }
    return false;
  }

  String? _extractPrinterName(String? s) {
    if (s == null) return null;
    return s.contains(':') ? s.split(':').last.trim() : s;
  }

  PrinterConnectionResult _setError(PrinterConnectionResult result) {
    _isConnected = false;
    _lastError = result.message;
    _lastErrorType = result.errorType;
    return result;
  }

  void _notifyProgress(List<DiscoveryStep> steps) {
    onDiscoveryProgress?.call(steps);
  }

  Future<void> _saveConfiguration() async {
    try {
      if (_configuredPrinterName != null) {
        await _persistence.savePrinterName(_configuredPrinterName!);
      }
      await _persistence.savePrinterServerPort(_serverPort);
      await _persistence.savePrinterServerHost(_serverHost);
      await _persistence.savePrinterProtocol(_protocol.scheme);
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Error al guardar config: $e');
    }
  }

  Future<void> _clearConfiguration() async {
    try {
      await _persistence.clearPrinterSettings();
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Error al limpiar config: $e');
    }
  }
}

// ────────────────────────────────────────────────────────────────────────────
// TIPOS INTERNOS
// ────────────────────────────────────────────────────────────────────────────

/// Registro de un candidato de conexión durante auto-discovery.
class _ProbeRecord {
  final PrinterProtocol protocol;
  final String host;
  final int port;
  final String url;

  const _ProbeRecord({
    required this.protocol,
    required this.host,
    required this.port,
    required this.url,
  });
}

/// Excepción interna para errores de certificado SSL.
class _CertificateException implements Exception {
  final String serverUrl;
  const _CertificateException(this.serverUrl);
}
