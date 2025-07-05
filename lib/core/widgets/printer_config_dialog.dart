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
      _statusMessage = 'Impresora conectada: ${_printerService.printerName}';
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
      }
      
      if (_productIdController.text.isNotEmpty) {
        productId = int.tryParse(_productIdController.text);
      }

      final success = await _printerService.connectPrinter(
        vendorId: vendorId,
        productId: productId,
      );

      setState(() {
        if (success) {
          _statusMessage = 'Impresora conectada correctamente';
          _isSuccess = true;
        } else {
          _statusMessage = _printerService.lastError ?? 'Error al conectar';
          _isSuccess = false;
        }
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error: $e';
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
      _statusMessage = 'Impresora desconectada';
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
        _statusMessage = 'Ticket de prueba impreso correctamente';
        _isSuccess = true;
      } else {
        _statusMessage = _printerService.lastError ?? 'Error al imprimir';
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
                        'Compatibilidad',
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
                    '• El navegador solicitará permisos USB',
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
