import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:sellweb/core/services/thermal_printer_http_service.dart';

/// Diálogo para configurar el servidor HTTP de impresora térmica
class PrinterConfigDialog extends StatefulWidget {
  const PrinterConfigDialog({super.key});

  @override
  State<PrinterConfigDialog> createState() => _PrinterConfigDialogState();
}

class _PrinterConfigDialogState extends State<PrinterConfigDialog> {
  final _printerService = ThermalPrinterHttpService();
  final _serverHostController = TextEditingController();
  final _serverPortController = TextEditingController();
  final _devicePathController = TextEditingController();

  bool _isConnecting = false;
  String? _statusMessage;
  bool _isSuccess = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentStatus();
    _initializeControllers();
  }

  void _initializeControllers() {
    // Inicializar con valores por defecto
    _serverHostController.text = _printerService.serverHost;
    _serverPortController.text = _printerService.serverPort.toString();
  }

  void _loadCurrentStatus() {
    if (_printerService.isConnected) {
      final connectionDetails = _printerService.detailedConnectionInfo;
      final printerName =
          connectionDetails['printerName'] ?? 'Servidor HTTP Local';
      final serverUrl = connectionDetails['serverUrl'] ?? 'No configurado';
      final connectionType =
          connectionDetails['connectionType'] ?? 'Desconocido';

      String statusText = '✅ Servidor conectado: $printerName\n';
      statusText += '🌐 URL: $serverUrl\n';
      statusText += '� Tipo: $connectionType\n';
      statusText += '🟢 Estado: Operativo';

      _statusMessage = statusText;
      _isSuccess = true;
    }
  }

  @override
  void dispose() {
    _serverHostController.dispose();
    _serverPortController.dispose();
    _devicePathController.dispose();
    super.dispose();
  }

  /// Maneja errores específicos del servidor Desktop
  String _parseDesktopServerError(String error) {
    if (error.contains('no se puede conectar')) {
      return '❌ Error de conexión física con la impresora\n\n'
          'Posibles soluciones:\n'
          '• Verificar que la impresora esté encendida\n'
          '• Comprobar conexión USB/Bluetooth\n'
          '• Reinstalar controladores de impresora\n'
          '• Probar con otro nombre de impresora\n'
          '• Usar "Buscar Impresoras" en el servidor Desktop primero';
    }

    if (error.contains('no encontrada')) {
      return '❌ El servidor no pudo encontrar impresoras disponibles\n\n'
          'Sugerencias:\n'
          '• Verificar que haya impresoras instaladas en el sistema\n'
          '• Ejecutar "Buscar Impresoras" en el servidor Desktop\n'
          '• El servidor manejará automáticamente la selección\n'
          '• Comprobar logs del servidor Desktop para más información';
    }

    if (error.contains('400')) {
      return '❌ Error de configuración del servidor\n\n'
          'Recomendaciones:\n'
          '• Verificar que el servidor Desktop esté funcionando correctamente\n'
          '• Comprobar logs del servidor para más detalles\n'
          '• El servidor maneja automáticamente la selección de impresoras\n'
          '• Asegurar que la configuración del servidor sea válida';
    }

    return error;
  }

  /// Prueba conexión con servidor antes de configurar impresora
  Future<bool> _testServerConnection() async {
    try {
      setState(() {
        _statusMessage = 'Verificando conexión con servidor...';
      });

      final testUrl =
          'http://${_serverHostController.text.trim()}:${_serverPortController.text}/status';
      final response = await http.get(
        Uri.parse(testUrl),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'ok') {
          return true;
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<void> _connectPrinter() async {
    setState(() {
      _isConnecting = true;
      _statusMessage = 'Configurando conexión con servidor HTTP...';
      _isSuccess = false;
    });

    try {
      setState(() {
        _statusMessage = 'Verificando conexión con servidor...';
      });

      // Parsear puerto si se especificó
      int? serverPort;
      if (_serverPortController.text.isNotEmpty) {
        serverPort = int.tryParse(_serverPortController.text);
        if (serverPort == null || serverPort < 1 || serverPort > 65535) {
          setState(() {
            _statusMessage =
                '❌ Puerto debe ser un número válido entre 1 y 65535';
            _isSuccess = false;
            _isConnecting = false;
          });
          return;
        }
      }

      // Probar conexión con el servidor antes de configurar la impresora
      final serverExists = await _testServerConnection();
      if (!serverExists) {
        setState(() {
          _statusMessage = '❌ No se pudo conectar con el servidor HTTP\n'
              '• Verifique que el servidor esté en ejecución\n'
              '• Asegúrese de que la dirección y el puerto sean correctos';
          _isSuccess = false;
          _isConnecting = false;
        });
        return;
      }

      final success = await _printerService.configurePrinter(
        serverHost: _serverHostController.text.trim().isNotEmpty
            ? _serverHostController.text.trim()
            : null,
        serverPort: serverPort,
        devicePath: _devicePathController.text.trim().isNotEmpty
            ? _devicePathController.text.trim()
            : null,
      );

      setState(() {
        if (success) {
          // Recargar el estado con información actualizada
          _loadCurrentStatus();
        } else {
          String errorDetails =
              _printerService.lastError ?? 'Error desconocido';

          // Usar función auxiliar para parsear errores específicos del servidor Desktop
          _statusMessage = _parseDesktopServerError(errorDetails);
          _isSuccess = false;
        }
      });
    } catch (e) {
      setState(() {
        _statusMessage = '❌ Error inesperado: $e';
        _isSuccess = false;
      });
    } finally {
      setState(() {
        _isConnecting = false;
      });
    }
  }

  Future<void> _disconnectPrinter() async {
    setState(() {
      _isConnecting = true;
      _statusMessage = 'Desconectando del servidor...';
    });

    await _printerService.disconnectPrinter();

    setState(() {
      _isConnecting = false;
      _statusMessage = '🔌 Desconectado del servidor HTTP\n'
          'Puede configurar una nueva conexión cuando guste';
      _isSuccess = false;
    });
  }

  Future<void> _testPrint() async {
    setState(() {
      _isConnecting = true;
      _statusMessage = 'Enviando comando de prueba al servidor...';
    });

    final success = await _printerService.printTestTicket();

    setState(() {
      _isConnecting = false;
      if (success) {
        _statusMessage = '✅ Comando de prueba enviado correctamente\n'
            '🖨️ Verifique que la impresora haya impreso el ticket de prueba';
        _isSuccess = true;
      } else {
        String errorDetails =
            _printerService.lastError ?? 'Error al enviar comando';

        if (errorDetails.contains('conexión')) {
          _statusMessage = '❌ Conexión perdida con el servidor\n'
              '🔌 Verifique que el servidor esté funcionando';
        } else {
          _statusMessage = '❌ Error en prueba: $errorDetails\n'
              '• Verificar que el servidor esté funcionando\n'
              '• Comprobar que la impresora esté configurada en el servidor';
        }
        _isSuccess = false;
      }
    });
  }

  /// Genera mensaje de ayuda específico para problemas comunes
  Widget _buildTroubleshootingHelp() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.tertiaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colorScheme.tertiary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.help_outline,
                size: 16,
                color: colorScheme.tertiary,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'Problemas Comunes',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.tertiary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildTroubleshootingItem(
            '🔍 Servidor no encuentra impresoras',
            '• Verificar que haya impresoras instaladas en el sistema\n'
                '• Ejecutar "Buscar Impresoras" en servidor Desktop\n'
                '• El servidor selecciona automáticamente la primera disponible',
          ),
          _buildTroubleshootingItem(
            '🔌 Error de conexión con servidor',
            '• Verificar que el servidor Desktop esté en ejecución\n'
                '• Comprobar que el puerto esté disponible\n'
                '• Asegurar que no haya firewall bloqueando la conexión',
          ),
          _buildTroubleshootingItem(
            '🌐 Error HTTP 400/500',
            '• Verificar que el servidor Desktop esté funcionando\n'
                '• Comprobar que la configuración del servidor sea correcta\n'
                '• Revisar logs del servidor Desktop para más detalles',
          ),
        ],
      ),
    );
  }

  Widget _buildTroubleshootingItem(String title, String description) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            description,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 11,
              height: 1.3,
            ),
            softWrap: true,
            overflow: TextOverflow.visible,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final screenSize = MediaQuery.of(context).size;
    final maxWidth = screenSize.width * 0.9;
    final maxHeight = screenSize.height * 0.85;

    return Dialog(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth.clamp(400.0, 550.0),
          maxHeight: maxHeight,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header fijo
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceVariant.withValues(alpha: 0.3),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.http,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Configurar Impresora HTTP',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  // Indicador de estado de conexión
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _printerService.isConnected
                          ? Colors.green.withValues(alpha: 0.2)
                          : Colors.grey.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _printerService.isConnected
                            ? Colors.green.withValues(alpha: 0.5)
                            : Colors.grey.withValues(alpha: 0.5),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _printerService.isConnected
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          size: 14,
                          color: _printerService.isConnected
                              ? Colors.green.shade700
                              : Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            _printerService.isConnected ? 'Conectado' : 'Desconectado',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: _printerService.isConnected
                                  ? Colors.green.shade700
                                  : Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Contenido scrolleable
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Información sobre el nuevo enfoque
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: colorScheme.primary.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 16,
                                color: colorScheme.primary,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  'Servidor HTTP Local',
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '• Conecta con aplicación Flutter Desktop (Windows/macOS/Linux)\n'
                            '• El servidor maneja automáticamente todas las impresoras conectadas\n'
                            '• Puerto por defecto: 8080\n'
                            '• La WebApp solo envía datos del ticket via HTTP POST\n'
                            '• No requiere configuración específica de impresoras\n'
                            '• Asegúrese que el servidor Desktop esté ejecutándose',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurface.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Estado actual
                    if (_statusMessage != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _isSuccess
                              ? Colors.green.withValues(alpha: 0.1)
                              : Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _isSuccess
                                ? Colors.green.withValues(alpha: 0.3)
                                : Colors.orange.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              _isSuccess ? Icons.check_circle : Icons.warning,
                              color: _isSuccess ? Colors.green : Colors.orange,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _statusMessage!,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: _isSuccess
                                      ? Colors.green.shade700
                                      : Colors.orange.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 16),

                    // Configuración del servidor HTTP
                    Text(
                      'Configuración del Servidor HTTP',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Layout responsivo para campos de servidor
                    LayoutBuilder(
                      builder: (context, constraints) {
                        if (constraints.maxWidth > 400) {
                          // Layout horizontal para pantallas más grandes
                          return Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: TextField(
                                  controller: _serverHostController,
                                  decoration: const InputDecoration(
                                    labelText: 'Host/IP',
                                    hintText: 'localhost',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.computer),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: _serverPortController,
                                  decoration: const InputDecoration(
                                    labelText: 'Puerto',
                                    hintText: '8080',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.settings_ethernet),
                                  ),
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                ),
                              ),
                            ],
                          );
                        } else {
                          // Layout vertical para pantallas pequeñas
                          return Column(
                            children: [
                              TextField(
                                controller: _serverHostController,
                                decoration: const InputDecoration(
                                  labelText: 'Host/IP',
                                  hintText: 'localhost',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.computer),
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _serverPortController,
                                decoration: const InputDecoration(
                                  labelText: 'Puerto',
                                  hintText: '8080',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.settings_ethernet),
                                ),
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                              ),
                            ],
                          );
                        }
                      },
                    ),

                    const SizedBox(height: 16),

                    // Configuración avanzada (opcional)
                    ExpansionTile(
                      title: const Text('Configuración Avanzada'),
                      subtitle: const Text(
                          'Configuración específica del dispositivo (opcional)'),
                      children: [
                        const SizedBox(height: 8),
                        TextField(
                          controller: _devicePathController,
                          decoration: const InputDecoration(
                            labelText: 'Ruta del Dispositivo (opcional)',
                            hintText: 'Ej: /dev/ttyUSB0, COM3, etc.',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.device_hub),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'La ruta del dispositivo se usa en el servidor para identificar la impresora específica',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),

                    // Información técnica de conexión (solo si está conectado)
                    if (_printerService.isConnected) ...[
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainer.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: colorScheme.outline.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.settings,
                                  size: 16,
                                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    'Información de Conexión',
                                    style: theme.textTheme.labelMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.onSurface.withValues(alpha: 0.8),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Builder(
                              builder: (context) {
                                final connectionDetails =
                                    _printerService.detailedConnectionInfo;
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildInfoRow(
                                      '🖨️ Impresora:',
                                      connectionDetails['printerName'] ?? 'Sin nombre',
                                      theme,
                                    ),
                                    _buildInfoRow(
                                      '🌐 URL Servidor:',
                                      connectionDetails['serverUrl'] ??
                                          'No configurado',
                                      theme,
                                    ),
                                    _buildInfoRow(
                                      '📋 Tipo:',
                                      connectionDetails['connectionType'] ??
                                          'Desconocido',
                                      theme,
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Ayuda para problemas comunes
                    if (_statusMessage != null && !_isSuccess)
                      _buildTroubleshootingHelp(),
                  ],
                ),
              ),
            ),
            
            // Botones de acción fijos en la parte inferior
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceVariant.withValues(alpha: 0.2),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  // Botón de cancelar
                  TextButton(
                    onPressed: _isConnecting ? null : () => Navigator.of(context).pop(),
                    child: const Text('Cancelar'),
                  ),

                  const Spacer(),

                  // Botón de desconectar (solo si está conectado)
                  if (_printerService.isConnected && !_isConnecting) ...[
                    TextButton(
                      onPressed: _disconnectPrinter,
                      child: Text(
                        'Desconectar',
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],

                  // Botón de prueba (solo si está conectado)
                  if (_printerService.isConnected && !_isConnecting) ...[
                    TextButton(
                      onPressed: _testPrint,
                      child: const Text('Probar'),
                    ),
                    const SizedBox(width: 8),
                  ],

                  // Botón de conectar
                  FilledButton(
                    onPressed: _isConnecting ? null : _connectPrinter,
                    child: _isConnecting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(_printerService.isConnected ? 'Reconectar' : 'Conectar'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Construye una fila de información con etiqueta y valor
  Widget _buildInfoRow(String label, String value, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 300) {
            // Layout horizontal para pantallas más grandes
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 100,
                  child: Text(
                    label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    value,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.9),
                    ),
                    softWrap: true,
                    overflow: TextOverflow.visible,
                  ),
                ),
              ],
            );
          } else {
            // Layout vertical para pantallas pequeñas
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.9),
                  ),
                  softWrap: true,
                  overflow: TextOverflow.visible,
                ),
                const SizedBox(height: 4),
              ],
            );
          }
        },
      ),
    );
  }
}

/// Función helper para mostrar el diálogo de configuración
Future<void> showPrinterConfigDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      return const PrinterConfigDialog();
    },
  );
}
