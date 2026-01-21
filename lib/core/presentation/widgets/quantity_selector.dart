import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sellweb/core/constants/ui_constants.dart';
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

  /// Si usar modo compacto (ancho mínimo) o expandir (ancho completo)
  /// Por defecto es false (ancho completo)
  final bool isCompact;

  const QuantitySelector({
    super.key,
    required this.initialQuantity,
    required this.unit,
    required this.onQuantityChanged,
    this.showInput = true,
    this.showUnit = true,
    this.buttonSize = 40,
    this.isCompact = false,
  });

  @override
  State<QuantitySelector> createState() => _QuantitySelectorState();
}

class _QuantitySelectorState extends State<QuantitySelector> {
  // ... existing state variables ...
  late double _quantity;
  late TextEditingController _controller;
  bool _isEditing = false;
  
  // ... existing methods ...
  
  @override
  void initState() {
    super.initState();
    _quantity = widget.initialQuantity;
    _controller = TextEditingController(
      text: UnitHelper.formatQuantityWithZeros(_quantity, widget.unit),
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
        _controller.text =
            UnitHelper.formatQuantityWithZeros(_quantity, widget.unit);
      });
    }

    // Si cambió la unidad, revalidar y reformatear
    if (oldWidget.unit != widget.unit) {
      final newQuantity = UnitHelper.normalizeQuantity(_quantity, widget.unit);
      
      setState(() {
        _quantity = newQuantity;
        _controller.text =
            UnitHelper.formatQuantityWithZeros(_quantity, widget.unit);
      });
      
      // Deferir la notificación para evitar setState durante build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onQuantityChanged(newQuantity);
      });
    }
  }

  void _increment() {
    final step = UnitHelper.getQuantityStep(widget.unit);
    final newQuantity = _quantity + step;

    // Validar máximo
    final maxQty = UnitHelper.getMaxQuantity(widget.unit);
    if (newQuantity <= maxQty) {
      _updateQuantity(newQuantity, fromButton: true);
    }
  }

  void _decrement() {
    final step = UnitHelper.getQuantityStep(widget.unit);
    final newQuantity = _quantity - step;

    // Validar mínimo
    if (newQuantity >= UnitHelper.minQuantity) {
      _updateQuantity(newQuantity, fromButton: true);
    }
  }

  void _updateQuantity(double newQuantity, {bool fromButton = false}) {
    // Normalizar según tipo de unidad
    final normalized = UnitHelper.normalizeQuantity(newQuantity, widget.unit);

    setState(() {
      _quantity = normalized;
      // Si no estamos editando O si el cambio viene de un botón explícito,
      // actualizamos el texto del controlador.
      if (!_isEditing || fromButton) {
        _controller.text =
            UnitHelper.formatQuantityWithZeros(normalized, widget.unit);
        
        // Si viene de un botón, mantenemos el cursor al final para evitar saltos extraños
        if (fromButton && _isEditing) {
           _controller.selection = TextSelection.fromPosition(
             TextPosition(offset: _controller.text.length)
           );
        }
      }
    });

    widget.onQuantityChanged(normalized);
  }

  void _onInputChanged(String value) {
    if (value.isEmpty) return;

    // Usar UnitHelper para parsear (maneja locale)
    final parsed = UnitHelper.parseQuantity(value, defaultValue: -1);

    if (parsed != -1) {
      // Validar
      final error = UnitHelper.validateQuantity(parsed, widget.unit);
      if (error == null) {
        // En el input manual NO pasamos fromButton, y ya estamos en _isEditing=true,
        // por lo que _updateQuantity NO tocará el texto, lo cual es correcto
        // para no interferir con lo que el usuario escribe.
        _updateQuantity(parsed);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isFractional = UnitHelper.isFractionalUnit(widget.unit);

    final inputWidget = widget.showInput
        ? _buildInput(theme, isFractional)
        : _buildDisplay(theme);

    return Row(
      mainAxisSize: widget.isCompact ? MainAxisSize.min : MainAxisSize.max,
      children: [
        // Botón decrementar
        _buildButton(
          icon: Icons.remove_rounded,
          onPressed: _quantity > UnitHelper.minQuantity ? _decrement : null,
          theme: theme,
        ),
    
        const SizedBox(width: 12),
    
        // Input de cantidad (si showInput es true) o solo display
        if (widget.isCompact)
          inputWidget
        else
          Expanded(child: inputWidget),
    
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
        borderRadius: BorderRadius.circular(UIConstants.defaultRadius),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(
          icon,
          size: 20,
          color:
              isEnabled ? theme.colorScheme.primary : theme.colorScheme.outline,
        ),
        padding: EdgeInsets.zero,
      ),
    );
  }

  // widget : input de cantidad
  Widget _buildInput(ThemeData theme, bool isFractional) {
    // Convertir a unidad de visualización si es fracción < 1
    final displayData = UnitHelper.convertToDisplayUnit(_quantity, widget.unit);
    final displayUnit = displayData['unit'] as String;
    final displaySymbol = UnitHelper.getUnitSymbol(displayUnit);

    // Formatear con ceros si es necesario
    final formattedText = _isEditing
        ? _controller.text
        : UnitHelper.formatQuantityWithZeros(_quantity, widget.unit);

    // Actualizar controller si no estamos editando
    if (!_isEditing && _controller.text != formattedText) {
      _controller.text = formattedText;
    }

    return Container(
      // Si es compacto, usar ancho fijo de 120, si no, que se expanda
      width: widget.isCompact ? 120 : null,
      height: widget.buttonSize, // Usar la misma altura del botón
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0), // Quitar padding vertical para que centre bien
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(UIConstants.defaultRadius),
        border: Border.all(
          color: _isEditing
              ? theme.colorScheme.primary
              : theme.colorScheme.outline.withValues(alpha: 0.2),
          width: _isEditing ? 2 : 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
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
                  // Permitir decimales (punto o coma) con hasta 3 dígitos
                  FilteringTextInputFormatter.allow(
                      RegExp(r'^\d*[\.,]?\d{0,3}'))
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
                _controller.text =
                    UnitHelper.formatQuantityWithZeros(_quantity, widget.unit);
              },
              onEditingComplete: () {
                setState(() {
                  _isEditing = false;
                });
                _controller.text =
                    UnitHelper.formatQuantityWithZeros(_quantity, widget.unit);
              },
            ),
          ),
          if (widget.showUnit) ...[
            const SizedBox(width: 4),
            Text(
              displaySymbol,
              style: theme.textTheme.bodySmall?.copyWith(
                color:
                    theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
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
        borderRadius: BorderRadius.circular(UIConstants.defaultRadius),
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
                color:
                    theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
