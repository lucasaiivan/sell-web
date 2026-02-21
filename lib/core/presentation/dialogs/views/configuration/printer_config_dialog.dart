import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sellweb/core/di/injection_container.dart';
import 'package:sellweb/core/services/external/thermal_printer_http_service.dart';
import '../../../widgets/dialog/base/base_dialog.dart';
import '../../../widgets/dialog/base/standard_dialogs.dart';
import '../../../widgets/dialog/base/dialog_components.dart';
import 'package:sellweb/core/presentation/helpers/responsive_helper.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CONSTANTES DE DISEÑO
// ─────────────────────────────────────────────────────────────────────────────

const _kRadiusBanner = 14.0;
const _kPadBanner = EdgeInsets.all(16.0);

// ─────────────────────────────────────────────────────────────────────────────
// WIDGET PRINCIPAL
// ─────────────────────────────────────────────────────────────────────────────

/// Diálogo de configuración de impresora térmica.
///
/// Campos: solo **dirección** y **puerto**.
/// Auto-discovery prueba en paralelo HTTPS+HTTP × múltiples puertos.
/// La UI muestra pasos animados en tiempo real durante la detección.
class PrinterConfigDialog extends StatefulWidget {
  const PrinterConfigDialog({super.key});

  @override
  State<PrinterConfigDialog> createState() => _PrinterConfigDialogState();
}

class _PrinterConfigDialogState extends State<PrinterConfigDialog>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _service = getIt<ThermalPrinterHttpService>();
  final _hostCtrl = TextEditingController();
  final _portCtrl = TextEditingController();

  // Estado de la pantalla
  _DialogPhase _phase = _DialogPhase.idle;
  PrinterConnectionResult? _lastResult;
  List<DiscoveryStep> _steps = [];

  // Auto-polling: esperar a que el usuario acepte el certificado
  Timer? _certPollTimer;
  bool _isPollingCert = false;
  int _pollAttempts = 0;
  static const _maxPollAttempts = 20; // 20 × 3s = 60s máximo

  // Animación de pulso para el banner de carga
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    _loadConfig();
  }

  @override
  void dispose() {
    _service.onDiscoveryProgress = null;
    _stopCertPolling();
    _pulseCtrl.dispose();
    _hostCtrl.dispose();
    _portCtrl.dispose();
    super.dispose();
  }

  void _loadConfig() {
    _hostCtrl.text = _service.serverHost;
    _portCtrl.text = _service.serverPort.toString();

    if (_service.isConnected) {
      setState(() {
        _phase = _DialogPhase.success;
        _lastResult = PrinterConnectionResult.connected({
          'status': 'ok',
          'printer': _service.configuredPrinterName,
          'message': 'Impresora lista',
        }, protocol: _service.protocol);
      });
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isConnected = _phase == _DialogPhase.success;
    final isScanning = _phase == _DialogPhase.scanning;

    return BaseDialog(
      title: 'Configuración de Impresora',
      icon: Icons.print_rounded,
      width: 500,
      content: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner de estado (siempre visible)
            _buildStatusBanner(),
            const SizedBox(height: 16),

            // Campos de dirección + puerto
            _buildAddressRow(),
            const SizedBox(height: 12),

            // Pasos de discovery (solo durante escaneo o tras fallo)
            AnimatedSize(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeInOutCubic,
              alignment: Alignment.topCenter,
              child: _steps.isNotEmpty
                  ? _buildDiscoverySteps()
                  : const SizedBox.shrink(),
            ),

            // Card de error con acciones específicas
            AnimatedSize(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeInOutCubic,
              alignment: Alignment.topCenter,
              child: (_lastResult != null && !_lastResult!.success)
                  ? Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: _buildErrorCard(),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
      actions: [
        // Probar (solo conectado)
        if (isConnected && !isScanning)
          DialogComponents.secondaryActionButton(
            context: context,
            text: 'Probar',
            icon: Icons.receipt_long_rounded,
            onPressed: _testPrinter,
          ),

        // Desconectar / Cancelar
        DialogComponents.secondaryActionButton(
          context: context,
          text: isConnected ? 'Desconectar' : 'Cancelar',
          icon: isConnected ? Icons.link_off_rounded : Icons.cancel_outlined,
          onPressed: isScanning
              ? null
              : (isConnected ? _disconnect : () => Navigator.of(context).pop()),
        ),

        // Botón principal
        DialogComponents.primaryActionButton(
          context: context,
          text: isConnected ? 'Reconectar' : 'Detectar Impresora',
          icon: isConnected ? Icons.refresh_rounded : Icons.search_rounded,
          onPressed: isScanning ? null : _detect,
          isLoading: isScanning,
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BANNER DE ESTADO
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildStatusBanner() {
    final theme = Theme.of(context);
    final cfg = _statusConfig();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      padding: _kPadBanner,
      decoration: BoxDecoration(
        color: cfg.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(_kRadiusBanner),
        border: Border.all(color: cfg.color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          // Icono con pulso animado durante escaneo
          _phase == _DialogPhase.scanning
              ? AnimatedBuilder(
                  animation: _pulseAnim,
                  builder: (_, __) => Opacity(
                    opacity: _pulseAnim.value,
                    child: _iconContainer(cfg, 22),
                  ),
                )
              : _iconContainer(cfg, 22),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cfg.title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: cfg.color,
                  ),
                ),
                Text(
                  cfg.subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (_lastResult?.success == true &&
                    _lastResult?.printerName != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.print_rounded,
                          size: 13,
                          color: theme.colorScheme.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text(
                        _lastResult!.printerName!,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: cfg.color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
                if (_lastResult?.resolvedProtocol != null &&
                    _lastResult!.success) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        _lastResult!.resolvedProtocol == PrinterProtocol.https
                            ? Icons.https_rounded
                            : Icons.http_rounded,
                        size: 12,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _lastResult!.resolvedProtocol!.scheme.toUpperCase(),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconContainer(_StatusConfig cfg, double iconSize) {
    return Container(
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: cfg.color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(cfg.icon, color: cfg.color, size: iconSize),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // FILA DIRECCIÓN + PUERTO
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildAddressRow() {
    final mobile = isMobile(context);
    final enabled = _phase != _DialogPhase.scanning;

    final hostField = DialogComponents.textField(
      context: context,
      controller: _hostCtrl,
      label: 'Dirección del servidor',
      hint: 'localhost  o  192.168.1.10',
      prefixIcon: Icons.computer_rounded,
      readOnly: !enabled,
      validator: (v) =>
          v?.trim().isEmpty == true ? 'Requerido' : null,
    );

    final portField = DialogComponents.textField(
      context: context,
      controller: _portCtrl,
      label: 'Puerto',
      hint: '8080',
      prefixIcon: Icons.settings_ethernet_rounded,
      keyboardType: TextInputType.number,
      readOnly: !enabled,
      validator: (v) {
        if (v?.trim().isEmpty == true) return 'Requerido';
        final p = int.tryParse(v!.trim());
        if (p == null || p < 1 || p > 65535) return 'Inválido';
        return null;
      },
    );

    if (mobile) {
      return Column(
        children: [hostField, const SizedBox(height: 10), portField],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 3, child: hostField),
        const SizedBox(width: 10),
        Expanded(flex: 1, child: portField),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PASOS ANIMADOS DE DISCOVERY
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildDiscoverySteps() {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Estrategias de conexión',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),
          ..._steps.map((step) => _StepTile(step: step)),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // CARD DE ERROR
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildErrorCard() {
    final result = _lastResult!;
    final theme = Theme.of(context);
    final cfg = _statusConfig();

    Widget? actionWidget;

    if (result.isCertificateError) {
      // ── Flujo de fallback PNA / SSL ────────────────────
      actionWidget = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),

          SizedBox(
            width: double.infinity,
            child: FilledButton.tonal(
              onPressed: () {
                _service.openCertificateAcceptPage(url: result.actionUrl);
                // Iniciar auto-detección después de que el usuario vaya a aceptar
                _startCertPolling();
              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.open_in_new_rounded, size: 16),
                  SizedBox(width: 8),
                  Text('Solucionar Conexión Segura'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Status del auto-polling o reintentar
          if (_isPollingCert) ...[
            Row(
              children: [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Esperando confirmación automática... ($_pollAttempts/$_maxPollAttempts)',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ] else ...[
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _detect,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Reintentar conexión'),
              ),
            ),
          ],
        ],
      );
    } else if (result.isServerUnavailable) {
      actionWidget = _buildStepHints([
        '1. Abrí la app SellPOS en tu PC',
        '2. Esperá a que el servidor se inicie (ícono 🖨️ en la barra)',
        '3. Presioná "Detectar Impresora" de nuevo',
      ]);
    } else if (result.isPrinterNotConfigured) {
      actionWidget = _buildStepHints([
        '1. En SellPOS → Configuración → Impresora',
        '2. Seleccioná y conectá tu impresora física',
        '3. Volvé aquí y presioná "Detectar Impresora"',
      ]);
    } else if (result.isPrintSystemNotReady) {
      actionWidget = _buildStepHints([
        '1. Cerrá la app SellPOS en tu PC',
        '2. Volvé a abrirla y esperá 10 segundos',
        '3. Presioná "Detectar Impresora"',
      ]);
    } else if (result.isTimeout) {
      actionWidget = Padding(
        padding: const EdgeInsets.only(top: 4),
        child: SizedBox(
          width: double.infinity,
          child: FilledButton.tonal(
            onPressed: _detect,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.refresh_rounded, size: 16),
                SizedBox(width: 8),
                Text('Reintentar detección'),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cfg.color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: cfg.color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(cfg.icon, size: 15, color: cfg.color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  result.message ?? 'Error desconocido.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          if (actionWidget != null) ...[
            const SizedBox(height: 12),
            actionWidget,
          ],
        ],
      ),
    );
  }

  Widget _buildStepHints(List<String> steps) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: steps
          .map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(s,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.onSurface)),
              ))
          .toList(),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // CONFIG VISUAL POR ESTADO
  // ─────────────────────────────────────────────────────────────────────────

  _StatusConfig _statusConfig() {
    return switch (_phase) {
      _DialogPhase.idle => _StatusConfig(
          icon: Icons.print_disabled_rounded,
          color: Colors.grey,
          title: 'Sin configurar',
          subtitle:
              'Ingresá la dirección de tu PC y presioná "Detectar Impresora"',
        ),
      _DialogPhase.scanning => _StatusConfig(
          icon: Icons.radar_rounded,
          color: Colors.blue,
          title: 'Detectando servidor…',
          subtitle: 'Probando protocolos HTTP/HTTPS y puertos disponibles',
        ),
      _DialogPhase.success => _StatusConfig(
          icon: Icons.check_circle_rounded,
          color: Colors.green,
          title: 'Impresora conectada',
          subtitle: 'Lista para imprimir tickets',
        ),
      _DialogPhase.error => switch (_lastResult?.errorType) {
          PrinterErrorType.certificateNotAccepted => _StatusConfig(
              icon: Icons.lock_outline_rounded,
              color: Colors.amber,
              title: 'Certificado HTTPS pendiente',
              subtitle: 'Aceptá el certificado en el navegador para continuar',
            ),
          PrinterErrorType.serverUnavailable => _StatusConfig(
              icon: Icons.wifi_off_rounded,
              color: Colors.red,
              title: 'Servidor no disponible',
              subtitle: 'La app SellPOS no está ejecutándose',
            ),
          PrinterErrorType.timeout => _StatusConfig(
              icon: Icons.schedule_rounded,
              color: Colors.grey,
              title: 'Sin respuesta (timeout)',
              subtitle: 'El servidor tardó demasiado en responder',
            ),
          PrinterErrorType.printerNotConfigured => _StatusConfig(
              icon: Icons.print_disabled_rounded,
              color: Colors.orange,
              title: 'Sin impresora configurada',
              subtitle: 'El servidor está activo pero no tiene impresora',
            ),
          PrinterErrorType.printSystemNotReady => _StatusConfig(
              icon: Icons.warning_amber_rounded,
              color: Colors.orange,
              title: 'Sistema de impresión no listo',
              subtitle: 'Reiniciá la aplicación SellPOS',
            ),
          PrinterErrorType.invalidToken => _StatusConfig(
              icon: Icons.key_off_rounded,
              color: Colors.orange,
              title: 'Autenticación fallida',
              subtitle: 'El servidor requiere un token de acceso',
            ),
          _ => _StatusConfig(
              icon: Icons.error_outline_rounded,
              color: Colors.red,
              title: 'Error de conexión',
              subtitle: _lastResult?.message ?? 'No se pudo conectar',
            ),
        },
    };
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ACCIONES
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _detect() async {
    if (!_formKey.currentState!.validate()) return;
    _stopCertPolling(); // Cancelar polling automático si estaba activo

    final host = _hostCtrl.text.trim();
    final port = int.tryParse(_portCtrl.text.trim()) ?? 8080;

    setState(() {
      _phase = _DialogPhase.scanning;
      _lastResult = null;
      _steps = [];
    });

    // Registrar callback de progreso de discovery
    _service.onDiscoveryProgress = (steps) {
      if (mounted) setState(() => _steps = steps);
    };

    final result = await _service.autoDiscover(host: host, port: port);

    _service.onDiscoveryProgress = null;

    if (!mounted) return;

    setState(() {
      _lastResult = result;
      _phase = result.success ? _DialogPhase.success : _DialogPhase.error;
    });

    if (result.success) {
      // Cerrar tras breve pausa para que el usuario vea ✅
      Future.delayed(const Duration(milliseconds: 1800), () {
        if (mounted) Navigator.of(context).pop();
      });
    }
  }

  // ── AUTO-POLLING: esperar a que el usuario acepte el certificado ──────

  /// Inicia un timer que reintenta `checkConnection()` cada 3 segundos.
  /// Cuando el usuario acepta el cert en su navegador y vuelve,
  /// el siguiente reintento exitoso cierra el diálogo automáticamente.
  void _startCertPolling() {
    _stopCertPolling();
    _pollAttempts = 0;
    setState(() => _isPollingCert = true);

    _certPollTimer =
        Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }
      _pollAttempts++;

      if (_pollAttempts > _maxPollAttempts) {
        _stopCertPolling();
        return;
      }

      if (mounted) setState(() {}); // Actualizar contador en UI

      final result = await _service.checkConnection();
      if (!mounted) return;

      if (result.success) {
        _stopCertPolling();
        setState(() {
          _phase = _DialogPhase.success;
          _lastResult = result;
        });
        // Cerrar tras breve pausa
        Future.delayed(const Duration(milliseconds: 1800), () {
          if (mounted) Navigator.of(context).pop();
        });
      }
    });
  }

  void _stopCertPolling() {
    _certPollTimer?.cancel();
    _certPollTimer = null;
    if (mounted) setState(() => _isPollingCert = false);
  }

  Future<void> _testPrinter() async {
    final result = await _service.printTestTicket();
    if (!mounted) return;

    showInfoDialog(
      context: context,
      title: result.success ? 'Prueba Exitosa' : 'Error en Prueba',
      message: result.success
          ? 'El ticket de prueba fue enviado correctamente.'
          : result.message ?? 'No se pudo enviar el ticket de prueba.',
      icon: result.success
          ? Icons.check_circle_outline_rounded
          : Icons.error_outline_rounded,
    );
  }

  Future<void> _disconnect() async {
    final confirmed = await showConfirmationDialog(
      context: context,
      title: 'Desconectar Impresora',
      message: '¿Desconectar y eliminar la configuración guardada?',
      icon: Icons.link_off_rounded,
      confirmText: 'Desconectar',
      cancelText: 'Cancelar',
    );

    if (confirmed != true || !mounted) return;

    await _service.disconnectPrinter();
    setState(() {
      _phase = _DialogPhase.idle;
      _lastResult = null;
      _steps = [];
    });
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TILE DE PASO DE DISCOVERY
// ─────────────────────────────────────────────────────────────────────────────

class _StepTile extends StatelessWidget {
  final DiscoveryStep step;

  const _StepTile({required this.step});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final (color, icon, showSpin) = switch (step.status) {
      DiscoveryStepStatus.pending => (
          theme.colorScheme.onSurfaceVariant,
          Icons.radio_button_unchecked_rounded,
          false
        ),
      DiscoveryStepStatus.running => (Colors.blue, Icons.sync_rounded, true),
      DiscoveryStepStatus.success => (Colors.green, Icons.check_circle_rounded, false),
      DiscoveryStepStatus.failed => (
          theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
          Icons.cancel_outlined,
          false
        ),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: showSpin
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.blue,
                    ),
                  )
                : Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 10),
          Text(
            step.label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: step.status == DiscoveryStepStatus.success
                  ? Colors.green
                  : step.status == DiscoveryStepStatus.failed
                      ? theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4)
                      : theme.colorScheme.onSurface,
              fontWeight: step.status == DiscoveryStepStatus.success
                  ? FontWeight.w600
                  : FontWeight.normal,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TIPOS LOCALES
// ─────────────────────────────────────────────────────────────────────────────

enum _DialogPhase { idle, scanning, success, error }

class _StatusConfig {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  const _StatusConfig({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// HELPER GLOBAL
// ─────────────────────────────────────────────────────────────────────────────

/// Helper para mostrar el diálogo desde cualquier parte de la app.
Future<void> showPrinterConfigDialog(BuildContext context) {
  return showDialog(
    context: context,
    builder: (context) => const PrinterConfigDialog(),
  );
}
