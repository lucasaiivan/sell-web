import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../../core/core.dart';
import 'package:sellweb/core/presentation/widgets/ui/quantity_selector.dart';
import 'package:sellweb/features/sales/presentation/providers/sales_provider.dart';

/// Diálogo modernizado para venta rápida siguiendo Material Design 3
///
/// En pantallas pequeñas (< 600px) con fullView=true, se muestra en pantalla completa.
/// En pantallas grandes, siempre se muestra como diálogo modal.
class QuickSaleDialog extends StatefulWidget {
  const QuickSaleDialog({
    super.key,
    required this.provider,
    this.fullView = false,
  });

  final SalesProvider provider;
  final bool fullView;

  @override
  State<QuickSaleDialog> createState() => _QuickSaleDialogState();
}

class _QuickSaleDialogState extends State<QuickSaleDialog> {
  final _formKey = GlobalKey<FormState>();
  final _priceController = AppMoneyTextEditingController();
  final _descriptionController = TextEditingController();
  double _quantity = 1;

  // FocusNodes para navegación por teclado
  final _priceFocusNode = FocusNode();
  final _descriptionFocusNode = FocusNode();

  // Unidades disponibles
  final List<String> _units = UnitHelper.allUnits;
  String _selectedUnit = UnitConstants.unit;

  bool _isProcessing = false;
  bool _showPriceError = false;

  /// Devuelve la etiqueta dinámica del monto según la unidad seleccionada
  String _getMountLabel() {
    return 'Monto por ${UnitHelper.getUnitDisplayName(_selectedUnit)}';
  }


  @override
  void dispose() {
    _priceController.dispose();
    _descriptionController.dispose();
    _priceFocusNode.dispose();
    _descriptionFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BaseDialog(
      title: 'Venta Rápida',
      icon: Icons.bolt_rounded,
      fullView: widget.fullView,
      content: _buildContent(context),
      actions: [
        DialogComponents.secondaryActionButton(
          context: context,
          text: 'Cancelar',
          onPressed: () => Navigator.of(context).pop(),
        ),
        DialogComponents.primaryActionButton(
          context: context,
          text: 'AGREGAR', 
          onPressed: _hasValidAmount && !_isProcessing ? _processQuickSale : null,
          isLoading: _isProcessing,
        ),
      ],
    );
  }

  bool get _hasValidAmount =>
      _priceController.text.isNotEmpty && _priceController.doubleValue > 0;

  Widget _buildContent(BuildContext context) {
    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),

            // CAMPO DE MONTO (GRANDE Y CENTRAL)
            _buildPremiumMoneyField(context),

            const SizedBox(height: 32),

            // SELECTOR DE UNIDAD 
            _buildModernUnitSelector(context),

            const SizedBox(height: 24),

            // CAMPO DE CANTIDAD CON CONTROLES INTEGRADOS
            _buildModernQuantityField(context),

            const SizedBox(height: 24),

            // CAMPO DE DESCRIPCIÓN (MINIMALISTA)
            DialogComponents.textField(
              context: context,
              controller: _descriptionController,
              focusNode: _descriptionFocusNode,
              textInputAction: TextInputAction.done,
              label: '¿Qué estás vendiendo?',
              hint: 'Ej: Bebida, Snack, Artículo...',
             
              onEditingComplete: () {
                _processQuickSale();
              },
            ),

            const SizedBox(height: 32),

            // VISTA PREVIA DEL TOTAL (GLASSMORPHISM STYLE)
            _buildPremiumTotalPreview(context),

            const SizedBox(height: 16),
          ],
        ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0, curve: Curves.easeOutCubic),
      ),
    );
  }

  /// Campo de monto con diseño premium y minimalista
  Widget _buildPremiumMoneyField(BuildContext context) {
    return Column(
      children: [
        Text(
          _getMountLabel().toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            letterSpacing: 1.2,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 8),
        DialogComponents.moneyField(
          autofocus: true,
          context: context,
          controller: _priceController,
          focusNode: _priceFocusNode,
          // nextFocusNode: _descriptionFocusNode, // Removed specific passing to quantity since QuantitySelector manages its own focus
          textInputAction: TextInputAction.next,
          fontSize: 42,
          center: true,
          label: '', // Label vacío para un look más limpio
          hint: r'$0',
          showCurrencyIcon: false,
          errorText: _showPriceError &&
                  (_priceController.text.isEmpty ||
                      _priceController.doubleValue <= 0)
              ? 'El precio es obligatorio'
              : null,
          onChanged: (value) {
            setState(() {
              if (_showPriceError && value > 0) {
                _showPriceError = false;
              }
            });
          },
        ),
      ],
    );
  }

  /// Selector de unidades moderno y minimalista con soporte para scroll con mouse
  Widget _buildModernUnitSelector(BuildContext context) {
    final scrollController = ScrollController();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'UNIDAD DE MEDIDA',
            style: TextStyle(
              fontSize: 10,
              letterSpacing: 1.0,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Listener(
          onPointerSignal: (pointerSignal) {
            if (pointerSignal is PointerScrollEvent) {
              // Convertir scroll vertical del mouse en scroll horizontal
              final newOffset = scrollController.offset + pointerSignal.scrollDelta.dy;
              scrollController.jumpTo(
                newOffset.clamp(0.0, scrollController.position.maxScrollExtent),
              );
            }
          },
          child: ScrollConfiguration(
            // Habilitar drag en todas las plataformas
            behavior: ScrollConfiguration.of(context).copyWith(
              dragDevices: {
                PointerDeviceKind.touch,
                PointerDeviceKind.mouse,
              },
              scrollbars: false,
            ),
            child: SingleChildScrollView(
              controller: scrollController,
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              child: Row(
                children: _units.map((unit) {
                  final isSelected = _selectedUnit == unit;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _selectedUnit = unit;
                          _quantity = 1;
                        });
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: AnimatedContainer(
                        duration: 250.ms,
                        curve: Curves.easeInOut,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
                          ), 
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isSelected) ...[
                              const Icon(Icons.check_circle_rounded, size: 16, color: Colors.white),
                              const SizedBox(width: 6),
                            ],
                            Text(
                              UnitHelper.getUnitDisplayName(unit),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                color: isSelected
                                    ? Colors.white
                                    : Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Campo de cantidad modernizado
  Widget _buildModernQuantityField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'CANTIDAD (${UnitHelper.getUnitSymbol(_selectedUnit)})',
            style: TextStyle(
              fontSize: 10,
              letterSpacing: 0.8,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
        ),
        Center(
          child: QuantitySelector(
            initialQuantity: _quantity,
            unit: _selectedUnit,
            onQuantityChanged: (val) {
              setState(() {
                _quantity = val;
              });
            },
            buttonSize: 48,
          ),
        ),
      ],
    );
  }



  /// Vista previa del total con estilo premium (Glassmorphism inspired)
  Widget _buildPremiumTotalPreview(BuildContext context) {
    return AnimatedBuilder(
      animation: _priceController,
      builder: (context, _) {
        final price = _priceController.doubleValue;
        final total = price * _quantity;

        if (price <= 0 || _quantity <= 0) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TOTAL ESTIMADO',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Theme.of(context).colorScheme.primary,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${UnitHelper.formatQuantityAdaptive(_quantity, _selectedUnit)} x ${CurrencyFormatter.formatPrice(value: price)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
              Text(
                CurrencyFormatter.formatPrice(value: total),
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Theme.of(context).colorScheme.primary,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ).animate(target: total > 0 ? 1 : 0).fadeIn().scale(begin: const Offset(0.95, 0.95), curve: Curves.easeOutBack);
      },
    );
  }



  Future<void> _processQuickSale() async {
    // Validar que el precio no esté vacío y sea mayor a 0
    if (_priceController.text.isEmpty || _priceController.doubleValue <= 0) {
      setState(() {
        _showPriceError = true;
      });
      return;
    }

    // Validar formulario antes de proceder
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final price = _priceController.doubleValue;
      var description = _descriptionController.text.trim();
      
      // Si la descripción está vacía, usar un valor por defecto descriptivo
      if (description.isEmpty) {
        description = 'Venta Rápida';
      }
      
      final quantity = _quantity;

      // Agregar el producto de venta rápida con cantidad
      await widget.provider.addQuickProduct(
        description: description,
        salePrice: price,
        unit: _selectedUnit,
        quantity: quantity,
      );

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        showErrorDialog(
          context: context,
          title: 'Error',
          message: 'No se pudo agregar el producto de venta rápida.',
          details: e.toString(),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }


}

/// Helper function para mostrar el diálogo de venta rápida
///
/// **Parámetros:**
/// - `context`: BuildContext necesario para mostrar el diálogo
/// - `provider`: SalesProvider para agregar el producto de venta rápida
/// - `fullView`: Si es true, se muestra en pantalla completa en dispositivos pequeños (default: true)
///
/// **Ejemplo:**
/// ```dart
/// await showQuickSaleDialog(
///   context,
///   provider: salesProvider,
///   fullView: true,
/// );
/// ```
Future<void> showQuickSaleDialog(
  BuildContext context, {
  required SalesProvider provider,
  bool fullView = true,
}) {
  final isSmallScreen = MediaQuery.of(context).size.width < 600;

  // Si es vista completa Y pantalla pequeña, usar Navigator.push
  if (fullView && isSmallScreen) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => QuickSaleDialog(
          provider: provider,
          fullView: fullView,
        ),
      ),
    );
  }

  // Vista normal como diálogo
  return showDialog(
    barrierDismissible: false,
    context: context,
    builder: (context) => QuickSaleDialog(
      provider: provider,
      fullView: fullView,
    ),
  );
}
