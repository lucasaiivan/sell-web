import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:sellweb/core/services/thermal_printer_http_service.dart';
import 'package:sellweb/core/utils/responsive.dart';
import 'package:sellweb/core/widgets/dialogs/base/base_dialog.dart';
import 'package:sellweb/core/widgets/dialogs/base/standard_dialogs.dart';
import 'package:sellweb/core/widgets/dialogs/components/dialog_components.dart';

/// Diálogo modernizado para configurar impresora térmica siguiendo Material Design 3
class PrinterConfigDialog extends StatefulWidget {
  const PrinterConfigDialog({super.key});

  @override
  State<PrinterConfigDialog> createState() => _PrinterConfigDialogState();
}

class _PrinterConfigDialogState extends State<PrinterConfigDialog> {
  final _formKey = GlobalKey<FormState>();
  final _printerService = ThermalPrinterHttpService();
  final _serverHostController = TextEditingController();
  final _serverPortController = TextEditingController();
  final _devicePathController = TextEditingController();

  bool _isConnecting = false;
  bool _isConnected = false;
  String? _connectionInfo;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCurrentConfiguration();
  }

  @override
  void dispose() {
    _serverHostController.dispose();
    _serverPortController.dispose();
    _devicePathController.dispose();
    super.dispose();
  }

  void _loadCurrentConfiguration() {
    // Cargar configuración actual
    _serverHostController.text = _printerService.serverHost;
    _serverPortController.text = _printerService.serverPort.toString();

    setState(() {
      _isConnected = _printerService.isConnected;
      if (_isConnected) {
        final details = _printerService.detailedConnectionInfo;
        _connectionInfo =
            'Conectado: ${details['printerName'] ?? 'Servidor HTTP Local'}';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BaseDialog(
      title: 'Configuración de Impresora',
      icon: Icons.print_rounded,
      width: 500,
      content: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Estado actual de la conexión
            _buildConnectionStatus(),

            DialogComponents.sectionSpacing,

            // Configuración del servidor
            _buildServerConfiguration(),

            DialogComponents.sectionSpacing,

            // Configuración avanzada (opcional)
            _buildAdvancedConfiguration(),

            // Mostrar error si existe
            if (_errorMessage != null) ...[
              DialogComponents.sectionSpacing,
              _buildErrorMessage(),
            ],
          ],
        ),
      ),
      actions: [
        DialogComponents.secondaryActionButton(
          context: context,
          text: _isConnected ? 'Desconectar' : 'Cancelar',
          icon: _isConnected ? Icons.link_off_rounded : Icons.cancel_outlined,
          onPressed: _isConnecting
              ? null
              : (_isConnected ? _disconnectPrinter : _cancel),
        ),
        DialogComponents.primaryActionButton(
          context: context,
          text: _isConnected ? 'Reconectar' : 'Conectar',
          icon: Icons.link_rounded,
          onPressed: _isConnecting ? null : _connectPrinter,
          isLoading: _isConnecting,
        ),
      ],
    );
  }

  Widget _buildConnectionStatus() {
    final theme = Theme.of(context);

    return DialogComponents.infoSection(
      context: context,
      title: 'Estado de la Impresora',
      icon: Icons.print_rounded,
      backgroundColor: _isConnected
          ? Colors.green.withValues(alpha: 0.1)
          : Colors.orange.withValues(alpha: 0.1),
      content: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _isConnected
                  ? Colors.green.withValues(alpha: 0.2)
                  : Colors.orange.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _isConnected ? Icons.check_circle_rounded : Icons.warning_rounded,
              color: _isConnected ? Colors.green[700] : Colors.orange[700],
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isConnected ? 'Impresora Conectada' : 'Sin Conexión',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color:
                        _isConnected ? Colors.green[700] : Colors.orange[700],
                  ),
                ),
                Text(
                  _connectionInfo ??
                      (_isConnected
                          ? 'Impresora lista para usar'
                          : 'Configure la conexión con el servidor'),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServerConfiguration() {
    final theme = Theme.of(context);
    final mobile = isMobile(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Configuración del Servidor',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        DialogComponents.itemSpacing,

        // Layout responsive: Column en móvil, Row en desktop
        mobile
            ? Column(
                children: [
                  DialogComponents.textField(
                    context: context,
                    controller: _serverHostController,
                    label: 'Dirección del Servidor',
                    hint: 'localhost',
                    prefixIcon: Icons.computer_rounded,
                    validator: (value) {
                      if (value?.trim().isEmpty == true) {
                        return 'La dirección es requerida';
                      }
                      return null;
                    },
                  ),
                  DialogComponents.itemSpacing,
                  DialogComponents.textField(
                    context: context,
                    controller: _serverPortController,
                    label: 'Puerto',
                    hint: '3000',
                    prefixIcon: Icons.settings_ethernet_rounded,
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value?.trim().isEmpty == true) {
                        return 'Puerto requerido';
                      }
                      final port = int.tryParse(value!);
                      if (port == null || port < 1 || port > 65535) {
                        return 'Puerto inválido';
                      }
                      return null;
                    },
                  ),
                ],
              )
            : Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: DialogComponents.textField(
                      context: context,
                      controller: _serverHostController,
                      label: 'Dirección del Servidor',
                      hint: 'localhost',
                      prefixIcon: Icons.computer_rounded,
                      validator: (value) {
                        if (value?.trim().isEmpty == true) {
                          return 'La dirección es requerida';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 1,
                    child: DialogComponents.textField(
                      context: context,
                      controller: _serverPortController,
                      label: 'Puerto',
                      hint: '3000',
                      prefixIcon: Icons.settings_ethernet_rounded,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value?.trim().isEmpty == true) {
                          return 'Puerto requerido';
                        }
                        final port = int.tryParse(value!);
                        if (port == null || port < 1 || port > 65535) {
                          return 'Puerto inválido';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
      ],
    );
  }

  Widget _buildAdvancedConfiguration() {
    return ExpansionTile(
      title: const Text('Configuración Avanzada'),
      subtitle: const Text('Configuración opcional del dispositivo'),
      tilePadding: EdgeInsets.zero,
      children: [
        const SizedBox(height: 8),
        DialogComponents.textField(
          context: context,
          controller: _devicePathController,
          label: 'Ruta del Dispositivo (Opcional)',
          hint: '/dev/usb/lp0',
          prefixIcon: Icons.usb_rounded,
        ),
        const SizedBox(height: 8),
        Text(
          'La ruta del dispositivo es opcional. Si no se especifica, el servidor detectará automáticamente la impresora disponible.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }

  Widget _buildErrorMessage() {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.error.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.error_outline_rounded,
                color: theme.colorScheme.onErrorContainer,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Error de Conexión',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.onErrorContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onErrorContainer,
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _testServerConnection() async {
    try {
      final testUrl =
          'http://${_serverHostController.text.trim()}:${_serverPortController.text.trim()}/status';
      final response = await http.get(
        Uri.parse(testUrl),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['status'] == 'ok';
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<void> _connectPrinter() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isConnecting = true;
      _errorMessage = null;
    });

    try {
      // Probar conexión con el servidor
      final serverAvailable = await _testServerConnection();
      if (!serverAvailable) {
        setState(() {
          _errorMessage =
              'No se pudo conectar con el servidor HTTP. Verifique que esté ejecutándose y que la dirección y puerto sean correctos.';
          _isConnecting = false;
        });
        return;
      }

      // Configurar impresora
      final success = await _printerService.configurePrinter(
        serverHost: _serverHostController.text.trim(),
        serverPort: int.parse(_serverPortController.text.trim()),
        devicePath: _devicePathController.text.trim().isNotEmpty
            ? _devicePathController.text.trim()
            : null,
      );

      if (success) {
        setState(() {
          _isConnected = true;
          _connectionInfo = 'Conectado correctamente al servidor';
        });

        if (mounted) {
          showInfoDialog(
            context: context,
            title: 'Conexión Exitosa',
            message: 'La impresora se ha configurado correctamente.',
            icon: Icons.check_circle_outline_rounded,
          );

          // Cerrar el diálogo después de un momento
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) Navigator.of(context).pop();
          });
        }
      } else {
        setState(() {
          _errorMessage = _printerService.lastError ??
              'Error desconocido al configurar la impresora.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error inesperado: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isConnecting = false;
      });
    }
  }

  Future<void> _disconnectPrinter() async {
    final confirmed = await showConfirmationDialog(
      context: context,
      title: 'Desconectar Impresora',
      message: '¿Estás seguro de que deseas desconectar la impresora?',
      icon: Icons.link_off_rounded,
      confirmText: 'Desconectar',
      cancelText: 'Cancelar',
    );

    if (confirmed == true) {
      // Reinicializar la configuración del servicio
      await _printerService.initialize();
      setState(() {
        _isConnected = false;
        _connectionInfo = null;
        _errorMessage = null;
      });

      if (mounted) {
        showInfoDialog(
          context: context,
          title: 'Configuración Reiniciada',
          message: 'La configuración de impresora se ha reiniciado.',
          icon: Icons.info_outline_rounded,
        );
      }
    }
  }

  void _cancel() {
    Navigator.of(context).pop();
  }
}

/// Helper function para mostrar el diálogo de configuración de impresora
Future<void> showPrinterConfigDialog(BuildContext context) {
  return showDialog(
    context: context,
    builder: (context) => const PrinterConfigDialog(),
  );
}
