import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sellweb/core/utils/helpers/unit_helper.dart';

/// Widget reutilizable para seleccionar cantidad de productos
/// 
/// Soporta:
/// - Unidades discretas (unidad, caja, paquete, docena): solo enteros
/// - Unidades fraccionarias (kilogramo, litro, metro): decimales
/// - Botones +/- con incrementos adaptativos según tipo de unidad
/// - Input manual con validaciones
/// - Formateo visual según tipo de unidad
class QuantitySelector extends StatefulWidget {
  /// Cantidad inicial
  final double initialQuantity;
  
  /// Tipo de unidad del producto
  final String unit;
  
  /// Callback cuando cambia la cantidad
  final ValueChanged<double> onQuantityChanged;
  
  /// Si mostrar el input manual de cantidad (por defecto true)
  final bool showInput;
  
  /// Si mostrar la unidad junto a la cantidad (por defecto true)
  final bool showUnit;
  
  /// Tamaño de los botones (por defecto 40)
  final double buttonSize;
  
  const QuantitySelector({
    super.key,
    required this.initialQuantity,
    required this.unit,
    required this.onQuantityChanged,
    this.showInput = true,
    this.showUnit = true,
    this.buttonSize = 40,
  });

  @override
  State<QuantitySelector> createState() => _QuantitySelectorState();
}

class _QuantitySelectorState extends State<QuantitySelector> {
  late double _quantity;
  late TextEditingController _controller;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _quantity = widget.initialQuantity;
    _controller = TextEditingController(
      text: UnitHelper.formatQuantity(_quantity, widget.unit),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(QuantitySelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Si cambió la cantidad externa y no estamos editando, actualizar
    if (oldWidget.initialQuantity != widget.initialQuantity && !_isEditing) {
      setState(() {
        _quantity = widget.initialQuantity;
        _controller.text = UnitHelper.formatQuantity(_quantity, widget.unit);
      });
    }
    
    // Si cambió la unidad, revalidar y reformatear
    if (oldWidget.unit != widget.unit) {
      setState(() {
        _quantity = UnitHelper.normalizeQuantity(_quantity, widget.unit);
        _controller.text = UnitHelper.formatQuantity(_quantity, widget.unit);
      });
      widget.onQuantityChanged(_quantity);
    }
  }

  void _increment() {
    final step = UnitHelper.getQuantityStep(widget.unit);
    final newQuantity = _quantity + step;
    
    // Validar máximo
    final maxQty = UnitHelper.getMaxQuantity(widget.unit);
    if (newQuantity <= maxQty) {
      _updateQuantity(newQuantity);
    }
  }

  void _decrement() {
    final step = UnitHelper.getQuantityStep(widget.unit);
    final newQuantity = _quantity - step;
    
    // Validar mínimo
    if (newQuantity >= UnitHelper.minQuantity) {
      _updateQuantity(newQuantity);
    }
  }

  void _updateQuantity(double newQuantity) {
    // Normalizar según tipo de unidad
    final normalized = UnitHelper.normalizeQuantity(newQuantity, widget.unit);
    
    setState(() {
      _quantity = normalized;
      if (!_isEditing) {
        _controller.text = UnitHelper.formatQuantity(normalized, widget.unit);
      }
    });
    
    widget.onQuantityChanged(normalized);
  }

  void _onInputChanged(String value) {
    if (value.isEmpty) return;
    
    final parsed = double.tryParse(value);
    if (parsed != null) {
      // Validar
      final error = UnitHelper.validateQuantity(parsed, widget.unit);
      if (error == null) {
        _updateQuantity(parsed);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isFractional = UnitHelper.isFractionalUnit(widget.unit);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Botón decrementar
        _buildButton(
          icon: Icons.remove_rounded,
          onPressed: _quantity > UnitHelper.minQuantity ? _decrement : null,
          theme: theme,
        ),

        const SizedBox(width: 12),

        // Input de cantidad (si showInput es true) o solo display
        if (widget.showInput)
          _buildInput(theme, isFractional)
        else
          _buildDisplay(theme),

        const SizedBox(width: 12),

        // Botón incrementar
        _buildButton(
          icon: Icons.add_rounded,
          onPressed: _quantity < UnitHelper.getMaxQuantity(widget.unit)
              ? _increment
              : null,
          theme: theme,
        ),
      ],
    );
  }

  Widget _buildButton({
    required IconData icon,
    required VoidCallback? onPressed,
    required ThemeData theme,
  }) {
    final isEnabled = onPressed != null;

    return Container(
      width: widget.buttonSize,
      height: widget.buttonSize,
      decoration: BoxDecoration(
        color: isEnabled
            ? theme.colorScheme.primary.withValues(alpha: 0.12)
            : theme.colorScheme.outline.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(
          icon,
          size: 20,
          color: isEnabled
              ? theme.colorScheme.primary
              : theme.colorScheme.outline,
        ),
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildInput(ThemeData theme, bool isFractional) {
    return Container(
      width: 120,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _isEditing
              ? theme.colorScheme.primary
              : theme.colorScheme.outline.withValues(alpha: 0.2),
          width: _isEditing ? 2 : 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onPrimaryContainer,
              ),
              keyboardType: TextInputType.numberWithOptions(
                decimal: isFractional,
              ),
              inputFormatters: [
                if (isFractional)
                  // Permitir decimales con hasta 3 dígitos después del punto
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,3}'))
                else
                  // Solo números enteros
                  FilteringTextInputFormatter.digitsOnly,
              ],
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              onTap: () {
                setState(() {
                  _isEditing = true;
                });
                _controller.selection = TextSelection(
                  baseOffset: 0,
                  extentOffset: _controller.text.length,
                );
              },
              onChanged: _onInputChanged,
              onSubmitted: (value) {
                setState(() {
                  _isEditing = false;
                });
                _controller.text = UnitHelper.formatQuantity(_quantity, widget.unit);
              },
              onEditingComplete: () {
                setState(() {
                  _isEditing = false;
                });
                _controller.text = UnitHelper.formatQuantity(_quantity, widget.unit);
              },
            ),
          ),
          if (widget.showUnit) ...[
            const SizedBox(width: 4),
            Text(
              UnitHelper.getUnitSymbol(widget.unit),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDisplay(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            UnitHelper.formatQuantity(_quantity, widget.unit),
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (widget.showUnit) ...[
            const SizedBox(width: 4),
            Text(
              UnitHelper.getUnitSymbol(widget.unit),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
