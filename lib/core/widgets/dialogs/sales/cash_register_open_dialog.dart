import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sellweb/core/widgets/inputs/inputs.dart';
import '../../../../presentation/providers/cash_register_provider.dart';
import '../../../../presentation/providers/sell_provider.dart';
import '../../buttons/app_button.dart';

/// Diálogo para abrir una nueva caja registradora
class CashRegisterOpenDialog extends StatefulWidget {
  const CashRegisterOpenDialog({super.key});

  @override
  State<CashRegisterOpenDialog> createState() => _CashRegisterOpenDialogState();
}

class _CashRegisterOpenDialogState extends State<CashRegisterOpenDialog> {
  List<String> _localFixedDescriptions = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFixedDescriptions();
    });
  }

  void _loadFixedDescriptions() async {
    final cashRegisterProvider = context.read<CashRegisterProvider>();
    final sellProvider = context.read<SellProvider>();
    final accountId = sellProvider.profileAccountSelected.id;
    
    if (accountId.isNotEmpty) {
      await cashRegisterProvider.loadCashRegisterFixedDescriptions(accountId);
      setState(() {
        _localFixedDescriptions = List.from(cashRegisterProvider.fixedDescriptions);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cashRegisterProvider = context.watch<CashRegisterProvider>();

    return AlertDialog(
      title: Row(
        children: [
          const Text('Apertura de Caja'),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InputTextField(
              controller: cashRegisterProvider.openDescriptionController,
              labelText: 'Descripción',
              hintText: 'Ej: Caja Principal',
            ), 
            const SizedBox(height: 16),
            // input : Campo para monto inicial
            MoneyInputTextField(
              controller: cashRegisterProvider.initialCashController,
              labelText: 'Monto Inicial', 
              
            ), 
            
            // view : items fixers con nombres frecuentes de caja
            const SizedBox(height: 16),
            _buildFrequentNamesSection(context, cashRegisterProvider),

            if (cashRegisterProvider.errorMessage != null) ...[
              const SizedBox(height: 16),
              Text(
                cashRegisterProvider.errorMessage!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        Consumer<SellProvider>(
          builder: (context, sellProvider, child) {
            return AppButton.primary(
              onPressed: cashRegisterProvider.isProcessing
                  ? null
                  : () => _handleOpenCashRegister(
                        context,
                        cashRegisterProvider,
                        sellProvider,
                      ),
              isLoading: cashRegisterProvider.isProcessing,
              text: 'Abrir Caja',
            );
          },
        ),
      ],
    );
  }

  /// Construye la sección de nombres frecuentes de caja registradora
  Widget _buildFrequentNamesSection(
    BuildContext context,
    CashRegisterProvider cashRegisterProvider,
  ) {
    // Usar la lista local en lugar de la del provider para mejor UX
    if (_localFixedDescriptions.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Nombres frecuentes:',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const Spacer(),
            IconButton(
              onPressed: () => _showAddDescriptionDialog(context, cashRegisterProvider),
              icon: Icon(
                Icons.add_circle_outline,
                size: 18,
                color: theme.colorScheme.primary,
              ),
              tooltip: 'Agregar nombre frecuente',
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _localFixedDescriptions.map((description) {
            return Stack(
              children: [
                ActionChip(
                  label: Padding(
                    padding: const EdgeInsets.only(right: 18), // Espacio para el botón X
                    child: Text(description),
                  ),
                  onPressed: () {
                    cashRegisterProvider.openDescriptionController.text = description;
                  },
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  labelStyle: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
                Positioned(
                  right: 4,
                  top: 4,
                  bottom: 4,
                  child: InkWell(
                    onTap: () => _deleteFixedDescription(context, cashRegisterProvider, description),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      child: Icon(
                        Icons.close,
                        size: 12,
                        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  Future<void> _handleOpenCashRegister(
    BuildContext context,
    CashRegisterProvider cashRegisterProvider,
    SellProvider sellProvider,
  ) async {
    final accountId = sellProvider.profileAccountSelected.id;
    final userId = sellProvider.profileAccountSelected.id;

    final success = await cashRegisterProvider.openCashRegister(
      accountId,
      userId,
    );

    if (success && context.mounted) {
      Navigator.of(context).pop();
    }
  }

  /// Muestra diálogo para agregar nueva descripción frecuente
  void _showAddDescriptionDialog(
    BuildContext context,
    CashRegisterProvider cashRegisterProvider,
  ) {
    final textController = TextEditingController();
    final sellProvider = context.read<SellProvider>();
    
    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Agregar Nombre Frecuente'),
          content: SizedBox(
            width: 300,
            child: InputTextField(
              controller: textController,
              labelText: 'Descripción',
              hintText: 'Ej: Caja Secundaria',
              autofocus: true,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                final description = textController.text.trim();
                if (description.isNotEmpty) {
                  // 1. Agregar inmediatamente a la lista local para mejor UX
                  setState(() {
                    _localFixedDescriptions.add(description);
                  });
                  
                  if (dialogContext.mounted) {
                    Navigator.of(dialogContext).pop();
                  }
                  
                  // 2. Guardar en el backend en segundo plano
                  try {
                    final accountId = sellProvider.profileAccountSelected.id;
                    final success = await cashRegisterProvider.createCashRegisterFixedDescription(
                      accountId,
                      description,
                    );
                    
                    if (!success && mounted) {
                    // Si falló, remover de la lista local
                    setState(() {
                      _localFixedDescriptions.remove(description);
                    });
                    if (context.mounted) {
                      final theme = Theme.of(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Error al guardar el nombre frecuente'),
                          backgroundColor: theme.colorScheme.error,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  }
                  } catch (e) {
                    // Si falló, remover de la lista local
                    if (mounted) {
                      setState(() {
                        _localFixedDescriptions.remove(description);
                      });
                      if (context.mounted) {
                        final theme = Theme.of(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error al guardar: $e'),
                            backgroundColor: theme.colorScheme.error,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    }
                  }
                }
              },
              child: const Text('Agregar'),
            ),
          ],
        );
      },
    );
  }

  // Helper para mostrar mensajes sin problemas de contexto
  void _showErrorMessage(String message) {
    if (mounted && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showSuccessMessage(String message) {
    if (mounted && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Theme.of(context).colorScheme.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Elimina una descripción frecuente
  Future<void> _deleteFixedDescription(
    BuildContext context,
    CashRegisterProvider cashRegisterProvider,
    String description,
  ) async {
    final sellProvider = context.read<SellProvider>();
    final accountId = sellProvider.profileAccountSelected.id;
    
    // Mostrar diálogo de confirmación
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Eliminar Nombre Frecuente'),
          content: Text('¿Estás seguro de que deseas eliminar "$description"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(
                'Eliminar',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ],
        );
      },
    );

    // Si se confirmó la eliminación, proceder
    if (confirmed == true) {
      // 1. Actualizar inmediatamente la vista local para mejor UX
      setState(() {
        _localFixedDescriptions.remove(description);
      });

      // 2. Eliminar del backend en segundo plano
      try {
        final success = await cashRegisterProvider.deleteCashRegisterFixedDescription(
          accountId,
          description,
        );
        
        if (context.mounted) {
          if (success) {
            _showSuccessMessage('Nombre frecuente "$description" eliminado');
          } else {
            // Si falló, restaurar el elemento en la lista local
            setState(() {
              _localFixedDescriptions.add(description);
            });
            _showErrorMessage('Error al eliminar el nombre frecuente');
          }
        }
      } catch (e) {
        // Si falló, restaurar el elemento en la lista local
        if (mounted) {
          setState(() {
            _localFixedDescriptions.add(description);
          });
          _showErrorMessage('Error al eliminar: ${e.toString().replaceAll('Exception: ', '')}');
        }
      }
    }
  }
}
