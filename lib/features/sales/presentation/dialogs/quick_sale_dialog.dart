import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../../core/core.dart';
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
  final _quantityController = TextEditingController(text: '1');

  // FocusNodes para navegación por teclado
  final _priceFocusNode = FocusNode();
  final _descriptionFocusNode = FocusNode();
  final _quantityFocusNode = FocusNode();

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
    _quantityController.dispose();
    _priceFocusNode.dispose();
    _descriptionFocusNode.dispose();
    _quantityFocusNode.dispose();
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

            // SELECTOR DE UNIDAD (MODERNIZADO)
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
          nextFocusNode: _quantityFocusNode,
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

  /// Selector de unidades moderno y minimalista
  Widget _buildModernUnitSelector(BuildContext context) {
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
        SingleChildScrollView(
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
                      _quantityController.text = '1';
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
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              )
                            ]
                          : [],
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
      ],
    );
  }

  /// Campo de cantidad modernizado
  Widget _buildModernQuantityField(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CANTIDAD (${UnitHelper.getUnitSymbol(_selectedUnit)})',
            style: TextStyle(
              fontSize: 10,
              letterSpacing: 0.8,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildModernQuantityBtn(
                Icons.remove_rounded,
                onTap: _decreaseQuantity,
              ),
              Expanded(
                child: TextFormField(
                  controller: _quantityController,
                  focusNode: _quantityFocusNode,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    hintText: '1',
                    hintStyle: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: (value) => setState(() {}),
                  validator: (value) {
                    if (value == null || value.isEmpty) return null;
                    final quantity = UnitHelper.parseQuantity(value, defaultValue: -1);
                    if (quantity <= 0) return 'Dato inválido';
                    return UnitHelper.validateQuantity(quantity, _selectedUnit);
                  },
                ),
              ),
              _buildModernQuantityBtn(
                Icons.add_rounded,
                onTap: _increaseQuantity,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModernQuantityBtn(IconData icon, {required VoidCallback onTap}) {
    return Material(
      color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        ),
      ),
    );
  }

  /// Vista previa del total con estilo premium (Glassmorphism inspired)
  Widget _buildPremiumTotalPreview(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_priceController, _quantityController]),
      builder: (context, _) {
        final price = _priceController.doubleValue;
        final quantity = UnitHelper.parseQuantity(_quantityController.text);
        final total = price * quantity;

        if (price <= 0 || quantity <= 0) return const SizedBox.shrink();

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
                    '${UnitHelper.formatQuantityAdaptive(quantity, _selectedUnit)} x ${CurrencyFormatter.formatPrice(value: price)}',
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
      
      final quantity = UnitHelper.parseQuantity(_quantityController.text);

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

  // MÉTODOS DE UI Y LÓGICA DE CANTIDAD

  void _increaseQuantity() {
    final step = UnitHelper.getQuantityStep(_selectedUnit);
    final current = UnitHelper.parseQuantity(_quantityController.text, defaultValue: 0);
    _updateQuantity(current + step);
  }

  void _decreaseQuantity() {
    final step = UnitHelper.getQuantityStep(_selectedUnit);
    final minVal = UnitHelper.minQuantity; 
    final current = UnitHelper.parseQuantity(_quantityController.text, defaultValue: 0);
    
    if (current > minVal) {
      _updateQuantity(current - step);
    }
  }

  void _updateQuantity(double newValue) {
    if (newValue <= 0) return;

    // Redondeo inteligente para evitar errores flotantes y respetar unidad
    final smartValue = UnitHelper.roundSmartly(newValue);
    
    // Formatear usando el helper que limpia ceros innecesarios
    _quantityController.text = UnitHelper.formatQuantity(smartValue, _selectedUnit);
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
