import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sellweb/presentation/widgets/inputs/inputs.dart';
import 'package:sellweb/features/auth/presentation/providers/auth_provider.dart';
import 'package:sellweb/features/sales/presentation/providers/sales_provider.dart';
import '../../../../providers/cash_register_provider.dart';

import '../../../buttons/app_button.dart';

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
    // Limpiar errores previos al inicializar el diálogo
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final provider = context.read<CashRegisterProvider>();
        provider.clearError();

        // Limpiar los campos de texto para empezar con valores vacíos
        provider.openDescriptionController.clear();
        provider.initialCashController.clear();

        _loadFixedDescriptions();
      }
    });
  }

  void _loadFixedDescriptions() async {
    final cashRegisterProvider = context.read<CashRegisterProvider>();
    final sellProvider = context.read<SalesProvider>();
    final accountId = sellProvider.profileAccountSelected.id;

    if (accountId.isNotEmpty) {
      await cashRegisterProvider.loadCashRegisterFixedDescriptions(accountId);
      setState(() {
        _localFixedDescriptions =
            List.from(cashRegisterProvider.fixedDescriptions);
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
            // view : items fixers con nombres frecuentes de caja
            _buildFrequentNamesSection(context, cashRegisterProvider),
            const SizedBox(height: 16),
            // input : Campo para monto inicial
            MoneyInputTextField(
              controller: cashRegisterProvider.initialCashController,
              labelText: 'Monto Inicial',
            ),

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
        Consumer<SalesProvider>(
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
      BuildContext context, CashRegisterProvider cashRegisterProvider) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header con título y botón de agregar
        Row(
          children: [
            Text(
              'Nombres frecuentes',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 8),
            // button : Botón para agregar nuevo nombre frecuente
            InkWell(
              onTap: () =>
                  _showAddDescriptionDialog(context, cashRegisterProvider),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  Icons.add_circle_outline,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // view : Lista de nombres frecuentes con scroll
        Container(
          constraints: const BoxConstraints(
            maxHeight: 120, // Altura máxima para evitar desbordamiento
          ),
          child: _localFixedDescriptions.isEmpty
              ? Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: theme.colorScheme.onSurfaceVariant
                            .withValues(alpha: 0.5),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Aún no hay nombres frecuentes guardados',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.7),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _localFixedDescriptions.map((description) {
                      return Container(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: theme.colorScheme.outline
                                .withValues(alpha: 0.2),
                            width: 1,
                          ),
                        ),
                        child: IntrinsicWidth(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Área clickeable del chip
                              Expanded(
                                child: InkWell(
                                  onTap: () {
                                    cashRegisterProvider
                                        .openDescriptionController
                                        .text = description;
                                  },
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(20),
                                    bottomLeft: Radius.circular(20),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    child: Text(
                                      description,
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        color:
                                            theme.colorScheme.onSurfaceVariant,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ),
                              // Divisor vertical
                              Container(
                                width: 1,
                                height: 16,
                                color: theme.colorScheme.outline
                                    .withValues(alpha: 0.2),
                              ),
                              // Botón de eliminar
                              InkWell(
                                onTap: () => _deleteFixedDescription(
                                    context, cashRegisterProvider, description),
                                borderRadius: const BorderRadius.only(
                                  topRight: Radius.circular(20),
                                  bottomRight: Radius.circular(20),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Icon(
                                    Icons.close,
                                    size: 14,
                                    color: theme.colorScheme.onSurfaceVariant
                                        .withValues(alpha: 0.7),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
        ),
      ],
    );
  }

  Future<void> _handleOpenCashRegister(
    BuildContext context,
    CashRegisterProvider cashRegisterProvider,
    SalesProvider sellProvider,
  ) async {
    final accountId = sellProvider.profileAccountSelected.id;
    final authProvider = context.read<AuthProvider>();

    // Obtener datos del usuario actual
    final userId = authProvider.user?.email ?? authProvider.user?.uid ?? '';
    final userName =
        authProvider.user?.displayName ?? authProvider.user?.email ?? 'Usuario';

    final success = await cashRegisterProvider.openCashRegister(
      accountId: accountId,
      cashierId: userId,
      cashierName: userName,
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
    final sellProvider = context.read<SalesProvider>();

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
                    final success = await cashRegisterProvider
                        .createCashRegisterFixedDescription(
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
                        ScaffoldMessenger.of(context).clearSnackBars();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text(
                                'Error al guardar el nombre frecuente'),
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
                        ScaffoldMessenger.of(context).clearSnackBars();
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
      ScaffoldMessenger.of(context).clearSnackBars();
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
      ScaffoldMessenger.of(context).clearSnackBars();
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
    final sellProvider = context.read<SalesProvider>();
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
        final success =
            await cashRegisterProvider.deleteCashRegisterFixedDescription(
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
          _showErrorMessage(
              'Error al eliminar: ${e.toString().replaceAll('Exception: ', '')}');
        }
      }
    }
  }
}
