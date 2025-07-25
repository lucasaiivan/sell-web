import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../presentation/providers/catalogue_provider.dart';

/// Widget mejorado para búsqueda de productos con sugerencias inteligentes
class ProductSearchField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final bool autofocus;

  const ProductSearchField({
    super.key,
    required this.controller,
    required this.focusNode,
    this.hintText = 'Buscar productos...',
    this.onChanged,
    this.onClear,
    this.autofocus = false,
  });

  @override
  State<ProductSearchField> createState() => _ProductSearchFieldState();
}

class _ProductSearchFieldState extends State<ProductSearchField> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  List<String> _suggestions = [];

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
    widget.focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    widget.focusNode.removeListener(_onFocusChanged);
    _removeOverlay();
    super.dispose();
  }

  void _onTextChanged() {
    final query = widget.controller.text.trim();
    
    if (query.isNotEmpty && query.length >= 2) {
      try {
        // Obtener sugerencias del provider
        final catalogueProvider = Provider.of<CatalogueProvider>(context, listen: false);
        _suggestions = catalogueProvider.getSearchSuggestions(query: query);
        
        if (_suggestions.isNotEmpty && widget.focusNode.hasFocus) {
          _showSuggestionsOverlay();
        } else {
          _hideSuggestions();
        }
      } catch (e) {
        _hideSuggestions();
      }
    } else {
      _hideSuggestions();
    }

    // Llamar al callback de cambio
    widget.onChanged?.call(query);
  }

  void _onFocusChanged() {
    if (!widget.focusNode.hasFocus) {
      // Delay para permitir selección de sugerencias
      Future.delayed(const Duration(milliseconds: 150), () {
        _hideSuggestions();
      });
    } else if (_suggestions.isNotEmpty && widget.controller.text.trim().length >= 2) {
      _showSuggestionsOverlay();
    }
  }

  void _showSuggestionsOverlay() {
    _removeOverlay();
    
    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: _getSearchFieldWidth(),
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0.0, 65.0),
          child: Material(
            elevation: 8.0,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: _suggestions.length,
                itemBuilder: (context, index) {
                  final suggestion = _suggestions[index];
                  return ListTile(
                    dense: true,
                    leading: Icon(
                      Icons.search_rounded,
                      size: 18,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    title: Text(
                      suggestion,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    onTap: () {
                      widget.controller.text = suggestion;
                      widget.controller.selection = TextSelection.fromPosition(
                        TextPosition(offset: suggestion.length),
                      );
                      _hideSuggestions();
                      widget.onChanged?.call(suggestion);
                    },
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideSuggestions() {
    _removeOverlay();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  double _getSearchFieldWidth() {
    // Intentar obtener el ancho del campo de búsqueda
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    return renderBox?.size.width ?? 300;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return CompositedTransformTarget(
      link: _layerLink,
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: widget.focusNode.hasFocus 
                ? colorScheme.primary 
                : colorScheme.outline.withValues(alpha: 0.3),
            width: widget.focusNode.hasFocus ? 2 : 1,
          ),
        ),
        child: TextField(
          controller: widget.controller,
          focusNode: widget.focusNode,
          autofocus: widget.autofocus,
          style: theme.textTheme.bodyLarge,
          decoration: InputDecoration(
            hintText: widget.hintText,
            hintStyle: theme.textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            prefixIcon: Icon(
              Icons.search_rounded,
              color: colorScheme.primary,
              size: 24,
            ),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Botón de limpiar
                if (widget.controller.text.isNotEmpty)
                  IconButton(
                    icon: Icon(
                      Icons.clear_rounded,
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    onPressed: () {
                      widget.controller.clear();
                      _hideSuggestions();
                      widget.onClear?.call();
                    },
                  ),
              ],
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ),
    );
  }
}
