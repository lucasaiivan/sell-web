import 'package:flutter/material.dart';
import 'package:sellweb/core/services/search_catalogue_service.dart';
import 'package:sellweb/domain/entities/catalogue.dart';

/// Widget mejorado para búsqueda de productos con sugerencias inteligentes
class ProductSearchField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final bool autofocus;
  final List<ProductCatalogue>
      products; // Lista obligatoria de productos para sugerencias
  final int? searchResultsCount; // Contador de resultados de búsqueda
  final bool
      showResultsCounter; // Mostrar contador de resultados (por defecto true)

  const ProductSearchField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.products, // Productos obligatorios
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
        // Obtener sugerencias únicamente desde la lista de productos proporcionada
        _suggestions = SearchCatalogueService.getSearchSuggestions(
          products: widget.products,
          query: query,
          maxSuggestions: 5,
        );

        // Mostrar overlay tanto si hay resultados como si no hay (para mostrar "Sin resultados")
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

    // Reconstruir para mostrar/ocultar el botón de limpiar
    if (mounted) {
      setState(() {});
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
                    ? Container(
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
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
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
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        itemCount: _suggestions.length,
                        itemBuilder: (context, index) {
                          final suggestion = _suggestions[index];
                          return InkWell(
                            onTap: () {
                              widget.controller.text = suggestion;
                              widget.controller.selection =
                                  TextSelection.fromPosition(
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
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
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
                      ),
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
          color: colorScheme.primaryContainer.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(10),
          border: widget.focusNode.hasFocus
              ? Border.all(
                  color: colorScheme.primary.withValues(alpha: 0.6),
                  width: 1.5,
                )
              : Border.all(
                  color: Colors.transparent,
                  width: 1.5,
                ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Ícono de búsqueda
            Padding(
              padding: const EdgeInsets.only(left: 12, right: 8),
              child: Icon(
                Icons.search_rounded,
                color: colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
                size: 20,
              ),
            ),
            // Campo de texto
            Expanded(
              child: TextField(
                controller: widget.controller,
                focusNode: widget.focusNode,
                autofocus: widget.autofocus,
                maxLines: 1,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w400,
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  hintStyle: theme.textTheme.bodyMedium?.copyWith(
                    color:
                        colorScheme.onPrimaryContainer.withValues(alpha: 0.5),
                    fontWeight: FontWeight.w400,
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 12,
                  ),
                ),
              ),
            ),
            // Contador de resultados
            if (widget.showResultsCounter &&
                widget.searchResultsCount != null &&
                widget.controller.text.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: widget.searchResultsCount == 0
                        ? colorScheme.errorContainer.withValues(alpha: 0.3)
                        : colorScheme.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: widget.searchResultsCount == 0
                          ? colorScheme.error.withValues(alpha: 0.3)
                          : colorScheme.primary.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    widget.searchResultsCount == 0
                        ? 'Sin resultados'
                        : '${widget.searchResultsCount}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: widget.searchResultsCount == 0
                          ? colorScheme.error
                          : colorScheme.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
            // Botón de limpiar
            if (widget.controller.text.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: IconButton(
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  icon: Icon(
                    Icons.clear_rounded,
                    color:
                        colorScheme.onPrimaryContainer.withValues(alpha: 0.6),
                    size: 18,
                  ),
                  onPressed: () {
                    widget.controller.clear();
                    _hideSuggestions();
                    widget.onClear?.call();
                  },
                ),
              )
            else
              const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }
}
