import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:sellweb/core/widgets/dialogs/base/base_dialog.dart';
import 'package:sellweb/core/widgets/dialogs/base/standard_dialogs.dart';
import 'package:sellweb/core/widgets/dialogs/components/dialog_components.dart';
import 'package:web/web.dart' as html;
import 'package:sellweb/core/services/thermal_printer_http_service.dart';

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
        _connectionInfo = 'Conectado: ${details['printerName'] ?? 'Servidor HTTP Local'}';
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

            // Configuración para Windows
            _buildWindowsConfiguration(),

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
          onPressed: _isConnecting ? null : (_isConnected ? _disconnectPrinter : _cancel),
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
                    color: _isConnected ? Colors.green[700] : Colors.orange[700],
                  ),
                ),
                Text(
                  _connectionInfo ?? (_isConnected 
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
        
        Row(
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

  Widget _buildWindowsConfiguration() {
    final theme = Theme.of(context);
    
    return ExpansionTile(
      title: const Text('Configurar impresora en Windows'),
      subtitle: const Text('Descarga y configura el programa para Windows'),
      tilePadding: EdgeInsets.zero,
      leading: Icon(
        Icons.desktop_windows_rounded,
        color: theme.colorScheme.primary,
      ),
      children: [
        const SizedBox(height: 12),
        
        // Información explicativa
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Programa requerido para Windows',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Para usar impresoras térmicas en Windows, necesitas descargar e instalar el programa SellPOS Desktop que actúa como servidor local.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              
              // Lista de pasos
              ...['1. Descarga el programa SellPOS Desktop para Windows',
                  '2. Instala y ejecuta la aplicación',
                  '3. Configura tu impresora térmica en el programa',
                  '4. El servidor se iniciará automáticamente en puerto 8080',
                  '5. Regresa aquí y conecta usando localhost:8080'].map((step) => 
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.check_circle_outline_rounded,
                        color: theme.colorScheme.primary,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          step,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Botón de descarga
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Reemplazar con la URL real de descarga
                    const downloadUrl = 'https://github.com/lucasaiivan/sellpos/releases/latest';
                    
                    // Abrir URL en una nueva pestaña
                    if (kIsWeb) {
                      html.window.open(downloadUrl, '_blank');
                    }
                  },
                  icon: Icon(
                    Icons.download_rounded,
                    color: theme.colorScheme.onPrimary,
                  ),
                  label: Text(
                    'Descargar SellPOS Desktop',
                    style: TextStyle(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Enlace alternativo
              Center(
                child: TextButton.icon(
                  onPressed: () {
                    const repoUrl = 'https://github.com/lucasaiivan/sellpos';
                    if (kIsWeb) {
                      html.window.open(repoUrl, '_blank');
                    }
                  },
                  icon: Icon(
                    Icons.code_rounded,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                  label: Text(
                    'Ver código fuente en GitHub',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 8),
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
      final testUrl = 'http://${_serverHostController.text.trim()}:${_serverPortController.text.trim()}/status';
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
          _errorMessage = 'No se pudo conectar con el servidor HTTP. Verifique que esté ejecutándose y que la dirección y puerto sean correctos.';
          _isConnecting = false;
        });
        return;
      }

      // Configurar impresora
      final success = await _printerService.configurePrinter(
        serverHost: _serverHostController.text.trim(),
        serverPort: int.parse(_serverPortController.text.trim()),
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
          _errorMessage = _printerService.lastError ?? 'Error desconocido al configurar la impresora.';
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
