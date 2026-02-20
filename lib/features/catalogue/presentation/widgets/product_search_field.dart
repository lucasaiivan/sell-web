import 'package:flutter/material.dart';
import 'package:sellweb/features/catalogue/data/datasources/local_search_datasource.dart';
import 'package:sellweb/features/catalogue/domain/entities/product_catalogue.dart';
import 'package:sellweb/core/presentation/widgets/inputs/search_text_field.dart';

/// Widget especializado para búsqueda de productos con sugerencias inteligentes
/// 
/// Extiende la funcionalidad del SearchTextField base agregando:
/// - Sugerencias de autocompletado basadas en el catálogo de productos
/// - Overlay con lista de sugerencias
/// - Búsqueda inteligente por nombre, código, marca, etc.
class ProductSearchField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final bool autofocus;
  final List<ProductCatalogue> products;
  final int? searchResultsCount;
  final bool showResultsCounter;

  const ProductSearchField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.products,
    this.hintText = 'Buscar productos...',
    this.onChanged,
    this.onClear,
    this.autofocus = false,
    this.searchResultsCount,
    this.showResultsCounter = true,
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.controller.addListener(_onTextChanged);
      widget.focusNode.addListener(_onFocusChanged);
    });
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
        _suggestions = LocalSearchDataSource.getSearchSuggestions(
          products: widget.products,
          query: query,
          maxSuggestions: 5,
        );

        if (widget.focusNode.hasFocus) {
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

    if (mounted) {
      setState(() {});
    }

    widget.onChanged?.call(query);
  }

  void _onFocusChanged() {
    if (!widget.focusNode.hasFocus) {
      Future.delayed(const Duration(milliseconds: 150), () {
        _hideSuggestions();
      });
    } else if (widget.controller.text.trim().length >= 2) {
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
          offset: const Offset(0.0, 50.0),
          child: Material(
            elevation: 0,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 240),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .primaryContainer
                    .withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: _suggestions.isEmpty
                    ? _buildEmptySuggestions(context)
                    : _buildSuggestionsList(context),
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  Widget _buildEmptySuggestions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 16,
            color: Theme.of(context)
                .colorScheme
                .onPrimaryContainer
                .withValues(alpha: 0.6),
          ),
          const SizedBox(width: 12),
          Text(
            'Sin resultados',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onPrimaryContainer
                      .withValues(alpha: 0.6),
                  fontWeight: FontWeight.w400,
                  fontSize: 14,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionsList(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: _suggestions.length,
      itemBuilder: (context, index) {
        final suggestion = _suggestions[index];
        return InkWell(
          onTap: () {
            widget.controller.text = suggestion;
            widget.controller.selection = TextSelection.fromPosition(
              TextPosition(offset: suggestion.length),
            );
            _hideSuggestions();
            widget.onChanged?.call(suggestion);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.search_rounded,
                  size: 16,
                  color: Theme.of(context)
                      .colorScheme
                      .onPrimaryContainer
                      .withValues(alpha: 0.6),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    suggestion,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onPrimaryContainer,
                          fontWeight: FontWeight.w400,
                          fontSize: 14,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _hideSuggestions() {
    _removeOverlay();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  double _getSearchFieldWidth() {
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    return renderBox?.size.width ?? 300;
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: SearchTextField(
        controller: widget.controller,
        focusNode: widget.focusNode,
        hintText: widget.hintText,
        autofocus: widget.autofocus,
        searchResultsCount: widget.searchResultsCount,
        showResultsCounter: widget.showResultsCounter,
        onClear: () {
          _hideSuggestions();
          widget.onClear?.call();
        },
        // No necesitamos pasar onChanged porque usamos el listener del controlador
        // que ya está configurado en initState
      ),
    );
  }
}
