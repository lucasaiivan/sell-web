import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sellweb/core/core.dart';
import 'package:sellweb/core/presentation/widgets/success/process_success_view.dart';
import 'package:sellweb/features/auth/presentation/providers/auth_provider.dart';
import 'package:sellweb/features/sales/presentation/providers/sales_provider.dart';
import 'package:sellweb/features/cash_register/presentation/providers/cash_register_provider.dart';

/// Diálogo para abrir una nueva caja registradora
class CashRegisterOpenDialog extends StatefulWidget {
  const CashRegisterOpenDialog({super.key, this.fullView = false});

  final bool fullView;

  @override
  State<CashRegisterOpenDialog> createState() => _CashRegisterOpenDialogState();
}

class _CashRegisterOpenDialogState extends State<CashRegisterOpenDialog> {
  List<String> _localFixedDescriptions = [];
  bool _rememberDescription = false; // Nueva variable para el checkbox
  String? _montoError; // Error para el campo de monto inicial

  @override
  void initState() {
    super.initState();
    // Resetear el checkbox
    _rememberDescription = false;
    
    // Limpiar errores previos al inicializar el diálogo
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final provider = context.read<CashRegisterProvider>();
        provider.clearError();

        // Limpiar los campos de texto para empezar con valores vacíos
        provider.openDescriptionController.clear();
        provider.initialCashController.clear();

        // Agregar listener para limpiar errores al escribir
        provider.openDescriptionController.addListener(() {
          if (mounted && provider.errorMessage != null) {
            provider.clearError();
          }
        });

        // Agregar listener para limpiar error de monto al escribir
        provider.initialCashController.addListener(() {
          if (mounted && _montoError != null) {
            setState(() {
              _montoError = null;
            });
          }
        });

        _loadFixedDescriptions();
      }
    });
  }

  void _loadFixedDescriptions() async {
    final cashRegisterProvider = context.read<CashRegisterProvider>();
    final sellProvider = context.read<SalesProvider>();
    final accountId = sellProvider.profileAccountSelected.id;

    debugPrint('🔄 Cargando nombres frecuentes para accountId: $accountId');
    
    if (accountId.isNotEmpty) {
      await cashRegisterProvider.loadCashRegisterFixedDescriptions(accountId);
      debugPrint('📋 Nombres frecuentes del provider: ${cashRegisterProvider.fixedDescriptions}');
      setState(() {
        _localFixedDescriptions =
            List.from(cashRegisterProvider.fixedDescriptions);
      });
      debugPrint('📋 Nombres frecuentes cargados en estado local: $_localFixedDescriptions');
    } else {
      debugPrint('⚠️ accountId está vacío, no se pueden cargar nombres frecuentes');
    }
  }

  @override
  Widget build(BuildContext context) {
    final cashRegisterProvider = context.watch<CashRegisterProvider>();
    final authProvider = context.watch<AuthProvider>();

    return BaseDialog(
      title: 'Apertura de Caja',
      subtitle: 'Inicia la apertura de una caja registradora contable',
      icon: Icons.point_of_sale,
      width: 500,
      fullView: widget.fullView,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [ 
          // view : fecha actual
          Opacity(opacity: 0.5, child: _buildDateHeader(context)),
          const SizedBox(height: 20),
          // view : cajero (email del usuario admin)
          _buildCashierField(context, authProvider),
          const SizedBox(height: 20), 
          // view : description
          DialogComponents.buildIconTitleLabel(icon: Icons.edit_outlined, label: 'Descripción'),
          InputTextField(
            maxLength: 20,
            controller: cashRegisterProvider.openDescriptionController, 
            hintText: 'Ej: Turno Mañana, caja principal',  
            errorText: (cashRegisterProvider.errorMessage != null) ? cashRegisterProvider.errorMessage : null,
          ), 
          // checkbox : Recordar descripción como frecuente
          _buildRememberCheckbox(context, cashRegisterProvider), 
          const SizedBox(height: 12), 
          _buildFrequentNamesSection(context, cashRegisterProvider),
          const SizedBox(height: 12),
          DialogComponents.buildIconTitleLabel(icon: Icons.monetization_on_outlined, label: 'Monto Inicial de la caja'),
          MoneyInputTextField(
            controller: cashRegisterProvider.initialCashController,  
            hintText: '0.0', 
            helperText: 'Dinero en efectivo disponible al iniciar',
            errorText: _montoError,
          ), 
          DialogComponents.sectionSpacing,
        ],
      ),
      actions: [
        // boton : cancelar
        DialogComponents.secondaryActionButton(
          context: context,
          text: 'Cancelar',
          onPressed: () => Navigator.pop(context),
        ),
        // boton : abrir caja
        Consumer<SalesProvider>(
          builder: (context, sellProvider, child) {
            return DialogComponents.primaryActionButton(
              context: context,
              text: 'Abrir Caja',
              icon: Icons.lock_open_rounded,
              onPressed: cashRegisterProvider.isProcessing
                  ? null
                  : () => _handleOpenCashRegister(
                        context,
                        cashRegisterProvider,
                        sellProvider,
                      ),
              isLoading: cashRegisterProvider.isProcessing,
            );
          },
        ),
      ],
    );
  } 
  /// Construye el encabezado con la fecha actual formateada
  Widget _buildDateHeader(BuildContext context) {
    final theme = Theme.of(context);
    final currentDate = DateTime.now();
    final formattedDate = DateFormatter.formatFullDateWithDay(dateTime: currentDate);

    return Text(
      formattedDate,
      style: theme.textTheme.labelLarge?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w400,
      ),
    );
  }

  /// Construye el campo de cajero (email del usuario admin) - solo lectura
  Widget _buildCashierField(BuildContext context, AuthProvider authProvider) {
    final userEmail = authProvider.user?.email ?? 'Sin email';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DialogComponents.buildIconTitleLabel(
          icon: Icons.person_outline_rounded, 
          label: 'Cajero'
        ),
        InputTextField(
          controller: TextEditingController(text: userEmail),
          enabled: false,
          hintText: 'Email del cajero',  
          fillColor: Colors.green.withValues(alpha: 0.05),
        ),
      ],
    );
  }

  /// Construye la sección de nombres frecuentes de caja registradora
  Widget _buildFrequentNamesSection(
      BuildContext context, CashRegisterProvider cashRegisterProvider) {
    // Si no hay nombres frecuentes, no mostrar nada
    if (_localFixedDescriptions.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);

    return SingleChildScrollView(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _localFixedDescriptions.map((description) {
                return Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
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
                              // Limpiar error al seleccionar un nombre frecuente
                              if (cashRegisterProvider.errorMessage != null) {
                                cashRegisterProvider.clearError();
                              }
                            },
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(20),
                              bottomLeft: Radius.circular(20),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 2,
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
                            padding: const EdgeInsets.all(6),
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

    // ⚠️ VALIDACIÓN: El monto inicial es obligatorio
    final montoText = cashRegisterProvider.initialCashController.text.trim();
    if (montoText.isEmpty) {
      // Establecer el error en el campo de monto
      setState(() {
        _montoError = 'Debe ingresar el monto inicial (o escribir 0)';
      });
      return;
    }

    // ⚠️ IMPORTANTE: Capturar valores ANTES de navegar a ProcessSuccessView
    // porque dentro del callback 'action' el contexto cambia y los valores pueden perderse
    final description = cashRegisterProvider.openDescriptionController.text.trim();
    // Si la descripción está vacía, usar "Caja" por defecto
    final finalDescription = description.isEmpty ? 'Caja' : description;
    final shouldRemember = _rememberDescription;
    
    debugPrint('📝 Valores capturados ANTES de ProcessSuccessView:');
    debugPrint('   - Descripción original: "$description"');
    debugPrint('   - Descripción final: "$finalDescription"');
    debugPrint('   - Recordar: $shouldRemember');

    // Mostrar ProcessSuccessView mientras se ejecuta la apertura
    if (!context.mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ProcessSuccessView(
          loadingText: 'Abriendo caja...',
          successTitle: '¡Caja abierta!',
          successSubtitle: finalDescription,
          finalText: null,
          popCount: 2, // Cerrar ProcessSuccessView + CashRegisterOpenDialog
          action: () async {
            // Establecer la descripción final en el controller para que el provider la use
            if (finalDescription != description) {
              cashRegisterProvider.openDescriptionController.text = finalDescription;
            }
            
            // 1. Abrir la caja registradora
            final success = await cashRegisterProvider.openCashRegister(
              accountId: accountId,
              cashierId: userId,
              cashierName: userName,
            );
            
            if (!success) {
              throw Exception(cashRegisterProvider.errorMessage ?? 'Error al abrir la caja');
            }

            // 2. Si está marcado "Recordar", guardar como nombre frecuente
            debugPrint('🔍 shouldRemember (variable capturada): $shouldRemember');
            if (shouldRemember) {
              debugPrint('🔍 Descripción a guardar (variable capturada): "$finalDescription"');
              debugPrint('🔍 Ya existe en lista local: ${_localFixedDescriptions.contains(finalDescription)}');
              debugPrint('🔍 Lista local actual: $_localFixedDescriptions');
              
              // Solo guardar si no es el nombre por defecto "Caja" y no existe ya
              if (finalDescription != 'Caja' && !_localFixedDescriptions.contains(finalDescription)) {
                try {
                  debugPrint('✅ Guardando nombre frecuente: "$finalDescription" en accountId: $accountId');
                  await cashRegisterProvider.createCashRegisterFixedDescription(
                    accountId,
                    finalDescription,
                  );
                  debugPrint('✅ Nombre frecuente guardado exitosamente');
                  // Nota: No actualizamos _localFixedDescriptions aquí porque el diálogo
                  // se cierra con popCount:2. La próxima vez que se abra el diálogo,
                  // se recargarán automáticamente los nombres desde Firestore en initState.
                } catch (e) {
                  // Error al guardar nombre frecuente, pero la caja ya se abrió exitosamente
                  debugPrint('❌ Error al guardar nombre frecuente: $e');
                }
              } else {
                debugPrint('⚠️ No se guarda: descripción vacía o ya existe');
              }
            }
          },
          onError: (error) {
            // Mostrar error con SnackBar
            if (context.mounted) {
              Navigator.of(context).pop(); // Cerrar ProcessSuccessView
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(error.toString().replaceAll('Exception: ', '')),
                  backgroundColor: Theme.of(context).colorScheme.error,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
        ),
      ),
    );
  }

  /// Construye el checkbox para recordar la descripción
  Widget _buildRememberCheckbox(BuildContext context, CashRegisterProvider cashRegisterProvider) {
    final theme = Theme.of(context);
    
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: cashRegisterProvider.openDescriptionController,
      builder: (context, value, child) {
        final description = value.text.trim();
        
        return InkWell(
          onTap: () {
            setState(() {
              _rememberDescription = !_rememberDescription;
            });
          },
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    value: _rememberDescription,
                    onChanged: (value) {
                      setState(() {
                        _rememberDescription = value ?? false;
                      });
                    },
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: description.isEmpty
                      ? Text(
                          'Recordar como frecuente',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface,
                          ),
                        )
                      : RichText(
                          text: TextSpan(
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface,
                            ),
                            children: [
                              const TextSpan(text: 'Recordar '),
                              TextSpan(
                                text: '\'$description\'',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const TextSpan(text: ' como frecuente'),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Helper para mostrar mensajes sin problemas de contexto
  void _showErrorMessage(String message) {
    if (mounted && context.mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
      final uniqueKey = UniqueKey();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          key: uniqueKey,
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
      final uniqueKey = UniqueKey();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          key: uniqueKey,
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
