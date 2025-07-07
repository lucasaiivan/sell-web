import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sellweb/core/services/thermal_printer_service.dart';

/// Diálogo para configurar la impresora térmica
class PrinterConfigDialog extends StatefulWidget {
  const PrinterConfigDialog({super.key});

  @override
  State<PrinterConfigDialog> createState() => _PrinterConfigDialogState();
}

class _PrinterConfigDialogState extends State<PrinterConfigDialog> {
  final _printerService = ThermalPrinterService();
  final _vendorIdController = TextEditingController();
  final _productIdController = TextEditingController();
  
  bool _isConnecting = false;
  String? _statusMessage;
  bool _isSuccess = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentStatus();
  }

  void _loadCurrentStatus() {
    if (_printerService.isConnected) {
      final connectionDetails = _printerService.detailedConnectionInfo;
      final printerName = connectionDetails['printerName'] ?? 'Impresora USB';
      final connectionType = connectionDetails['connectionType'] ?? 'Desconocido';
      final interface = connectionDetails['interface'];
      final endpoint = connectionDetails['endpoint'];
      final vendorId = connectionDetails['vendorId'];
      final productId = connectionDetails['productId'];
      
      String statusText = '✅ Impresora conectada: $printerName\n';
      statusText += '📋 Tipo: $connectionType\n';
      
      if (interface != null && endpoint != null) {
        statusText += '🔌 Interface: $interface, Endpoint: $endpoint\n';
      }
      
      if (vendorId != null || productId != null) {
        statusText += '🆔 IDs: ${vendorId ?? 'Auto'}/${productId ?? 'Auto'}\n';
      }
      
      statusText += '🟢 Estado: Operativa';
      
      _statusMessage = statusText;
      _isSuccess = true;
    }
  }

  @override
  void dispose() {
    _vendorIdController.dispose();
    _productIdController.dispose();
    super.dispose();
  }

  Future<void> _connectPrinter() async {
    setState(() {
      _isConnecting = true;
      _statusMessage = 'Conectando con impresora...';
      _isSuccess = false;
    });

    try {
      // Parsear IDs si se proporcionaron
      int? vendorId;
      int? productId;
      
      if (_vendorIdController.text.isNotEmpty) {
        vendorId = int.tryParse(_vendorIdController.text);
        if (vendorId == null) {
          setState(() {
            _statusMessage = 'Vendor ID debe ser un número válido';
            _isSuccess = false;
            _isConnecting = false;
          });
          return;
        }
      }
      
      if (_productIdController.text.isNotEmpty) {
        productId = int.tryParse(_productIdController.text);
        if (productId == null) {
          setState(() {
            _statusMessage = 'Product ID debe ser un número válido';
            _isSuccess = false;
            _isConnecting = false;
          });
          return;
        }
      }

      final success = await _printerService.connectPrinter(
        vendorId: vendorId,
        productId: productId,
      );

      setState(() {
        if (success) {
          // Recargar el estado con información detallada
          _loadCurrentStatus();
        } else {
          String errorDetails = _printerService.lastError ?? 'Error desconocido';
          
          // Proporcionar mensajes más específicos basados en el error
          if (errorDetails.contains('transferOut')) {
            _statusMessage = '❌ Error de comunicación USB. Intente:\n'
                '• Desconectar y reconectar la impresora\n'
                '• Usar otro puerto USB\n'
                '• Reiniciar el navegador\n'
                '• Verificar que la impresora esté encendida';
          } else if (errorDetails.contains('NotFoundError')) {
            _statusMessage = '❌ Impresora no encontrada. Verifique:\n'
                '• Que esté conectada por USB\n'
                '• Que esté encendida\n'
                '• Los permisos del navegador\n'
                '• Compatibilidad con Chrome/Edge';
          } else if (errorDetails.contains('SecurityError')) {
            _statusMessage = '❌ Error de permisos. Intente:\n'
                '• Actualizar la página\n'
                '• Usar Chrome o Edge\n'
                '• Permitir acceso USB cuando se solicite';
          } else if (errorDetails.contains('conexión con ninguna configuración')) {
            _statusMessage = '❌ No se pudo configurar automáticamente.\n'
                'Intente especificar Vendor ID y Product ID\n'
                'en la configuración avanzada.';
          } else {
            _statusMessage = '❌ Error: $errorDetails\n\n'
                'Sugerencias:\n'
                '• Verificar conexión USB\n'
                '• Reiniciar impresora\n'
                '• Probar otro puerto USB';
          }
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
      _statusMessage = 'Desconectando impresora...';
    });

    await _printerService.disconnectPrinter();

    setState(() {
      _isConnecting = false;
      _statusMessage = '🔌 Impresora desconectada correctamente\n'
          'Puede conectar una nueva impresora cuando guste';
      _isSuccess = false;
    });
  }

  Future<void> _testPrint() async {
    setState(() {
      _isConnecting = true;
      _statusMessage = 'Imprimiendo ticket de prueba...';
    });

    final success = await _printerService.printTestTicket();

    setState(() {
      _isConnecting = false;
      if (success) {
        _statusMessage = '✅ Ticket de prueba impreso correctamente\n'
            '🖨️ La impresora está funcionando bien';
        _isSuccess = true;
      } else {
        String errorDetails = _printerService.lastError ?? 'Error al imprimir';
        
        if (errorDetails.contains('Conexión USB perdida')) {
          _statusMessage = '❌ Conexión perdida durante impresión\n'
              '🔌 Reconecte la impresora e intente nuevamente';
        } else if (errorDetails.contains('transferOut')) {
          _statusMessage = '❌ Error de comunicación durante impresión\n'
              '• Verificar que la impresora tenga papel\n'
              '• Revisar conexión USB\n'
              '• Reiniciar impresora';
        } else {
          _statusMessage = '❌ Error en prueba: $errorDetails\n'
              '• Verificar papel en impresora\n'
              '• Comprobar conexión USB';
        }
        _isSuccess = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.print,
            color: colorScheme.primary,
          ),
          const SizedBox(width: 8),
          const Text('Configurar Impresora'),
          const Spacer(),
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
                Text(
                  _printerService.isConnected ? 'Conectada' : 'Desconectada',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: _printerService.isConnected 
                      ? Colors.green.shade700 
                      : Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Información sobre compatibilidad
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
                      Text(
                        'Información Importante',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '• Compatible con Windows y macOS\n'
                    '• Requiere impresora térmica USB\n'
                    '• Solo funciona en Chrome/Edge\n'
                    '• El navegador solicitará permisos USB\n'
                    '• Si falla, intente reconectar la impresora',
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
                          color: _isSuccess ? Colors.green.shade700 : Colors.orange.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 16),

            // Información técnica de conexión (solo si está conectada)
            if (_printerService.isConnected)
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
                        Text(
                          'Información Técnica',
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Builder(
                      builder: (context) {
                        final connectionDetails = _printerService.detailedConnectionInfo;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildInfoRow(
                              '🖨️ Nombre:', 
                              connectionDetails['printerName'] ?? 'Sin nombre',
                              theme,
                            ),
                            _buildInfoRow(
                              '🔧 Configuración:', 
                              connectionDetails['connectionType'] ?? 'Automática',
                              theme,
                            ),
                            if (connectionDetails['interface'] != null)
                              _buildInfoRow(
                                '🔌 Interface USB:', 
                                connectionDetails['interface'].toString(),
                                theme,
                              ),
                            if (connectionDetails['endpoint'] != null)
                              _buildInfoRow(
                                '📡 Endpoint:', 
                                connectionDetails['endpoint'].toString(),
                                theme,
                              ),
                            if (connectionDetails['vendorId'] != null)
                              _buildInfoRow(
                                '🆔 Vendor ID:', 
                                connectionDetails['vendorId'].toString(),
                                theme,
                              ),
                            if (connectionDetails['productId'] != null)
                              _buildInfoRow(
                                '🏷️ Product ID:', 
                                connectionDetails['productId'].toString(),
                                theme,
                              ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 16),

            // Configuración avanzada (opcional)
            ExpansionTile(
              title: const Text('Configuración Avanzada'),
              subtitle: const Text('Especificar IDs de dispositivo (opcional)'),
              children: [
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _vendorIdController,
                        decoration: const InputDecoration(
                          labelText: 'Vendor ID',
                          hintText: 'Ej: 1234',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _productIdController,
                        decoration: const InputDecoration(
                          labelText: 'Product ID',
                          hintText: 'Ej: 5678',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Deja en blanco para detectar automáticamente',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        // Botón de cancelar
        TextButton(
          onPressed: _isConnecting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        
        // Botón de desconectar (solo si está conectado)
        if (_printerService.isConnected && !_isConnecting)
          TextButton(
            onPressed: _disconnectPrinter,
            child: Text(
              'Desconectar',
              style: TextStyle(color: Colors.red.shade700),
            ),
          ),
        
        // Botón de prueba (solo si está conectado)
        if (_printerService.isConnected && !_isConnecting)
          TextButton(
            onPressed: _testPrint,
            child: const Text('Probar'),
          ),
        
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
    );
  }

  /// Construye una fila de información con etiqueta y valor
  Widget _buildInfoRow(String label, String value, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
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
            ),
          ),
        ],
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
