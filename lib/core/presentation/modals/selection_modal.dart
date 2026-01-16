import 'package:flutter/material.dart';
import 'package:sellweb/core/presentation/modals/base_bottom_sheet.dart';

/// Este widget presenta un modal que permite al usuario seleccionar un elemento
/// de una lista proporcionada, con la opción de buscar y filtrar los elementos.
///
/// [T] es el tipo de los elementos en la lista.
///
/// Propiedades:
/// - [title]: El título que se muestra en la parte superior del modal.
/// - [items]: La lista de elementos de la cual el usuario puede seleccionar.
/// - [labelBuilder]: Una función que convierte un elemento [T] en una cadena
///   para mostrar como etiqueta principal en la lista.
/// - [subtitleBuilder]: Una función opcional para obtener un subtítulo de un
///   elemento [T], mostrado debajo de la etiqueta principal.
/// - [idBuilder]: Una función opcional para obtener un identificador único de
///   un elemento [T].
/// - [imageUrlBuilder]: Una función opcional para obtener la URL de una imagen
///   asociada a un elemento [T], mostrada junto a la etiqueta.
/// - [selectedItem]: El elemento que está actualmente seleccionado en la lista.
///   Este se marcará visualmente.
/// - [searchHint]: El texto de sugerencia para el campo de búsqueda dentro del modal.

class SelectionModal<T> extends StatefulWidget {
  final String title;
  final List<T> items;
  final String Function(T) labelBuilder;
  final String Function(T)? subtitleBuilder;
  final String Function(T)? idBuilder;
  final String Function(T)? imageUrlBuilder;
  final T? selectedItem;
  final String searchHint;
  final Future<T?> Function()? onAdd;
  final String? labelButton;
  final void Function(T item)? onButton;

  const SelectionModal({
    super.key,
    required this.title,
    required this.items,
    required this.labelBuilder,
    this.subtitleBuilder,
    this.idBuilder,
    this.imageUrlBuilder,
    this.selectedItem,
    this.searchHint = 'Buscar',
    this.onAdd,
    this.labelButton,
    this.onButton,
  });

  @override
  State<SelectionModal<T>> createState() => _SelectionModalState<T>();
}


class _SelectionModalState<T> extends State<SelectionModal<T>> {
  late List<T> _filteredItems;
  // Controller removed as BaseBottomSheet handles the input field
  
  @override
  void initState() {
    super.initState();
    _filteredItems = widget.items;
  }

  void _onSearch(String query) {
    setState(() {
      if (query.trim().isEmpty) {
        _filteredItems = widget.items;
      } else {
        final lowerQuery = query.toLowerCase().trim();
        _filteredItems = widget.items.where((item) {
          final label = widget.labelBuilder(item).toLowerCase();
          final subtitle =
              widget.subtitleBuilder?.call(item).toLowerCase() ?? '';
          return label.contains(lowerQuery) || subtitle.contains(lowerQuery);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return BaseBottomSheet(
      title: widget.title,
      onSearch: _onSearch,
      searchHint: widget.searchHint,
      body: widget.items.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.local_shipping_outlined,
                    size: 64,
                    color: colorScheme.outline.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No tienes ningún${widget.title.toLowerCase().contains('categoría') ? 'a' : ''} ${widget.title.toLowerCase().replaceAll('seleccionar ', '')}${widget.title.toLowerCase().contains('categoría') ? 'a' : ''}',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : _filteredItems.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search_off_rounded,
                        size: 64,
                        color: colorScheme.outline.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No se encontraron resultados',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  // Add padding at the bottom to avoid content being hidden by footer actions
                  padding: EdgeInsets.only(
                    top: 8,
                    bottom: widget.onAdd != null ? 100 : 24,
                  ),
                  itemCount: _filteredItems.length,
                  itemBuilder: (context, index) {
                    final item = _filteredItems[index];
                    final label = widget.labelBuilder(item);
                    final subtitle = widget.subtitleBuilder?.call(item);
                    final id = widget.idBuilder?.call(item);
                    final imageUrl = widget.imageUrlBuilder?.call(item);

                    final isSelected = widget.selectedItem != null &&
                        (widget.idBuilder != null
                            ? id == widget.idBuilder!(widget.selectedItem!)
                            : item == widget.selectedItem);

                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => Navigator.of(context).pop(item),
                        onLongPress: widget.onButton != null
                            ? () {
                                Navigator.pop(context);
                                widget.onButton!(item);
                              }
                            : null,
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          child: Row(
                            children: [
                              // Leading - Avatar
                              imageUrl != null && imageUrl.isNotEmpty
                                  ? CircleAvatar(
                                      backgroundImage: NetworkImage(imageUrl),
                                      backgroundColor:
                                          colorScheme.surfaceContainerHighest,
                                      onBackgroundImageError: (_, __) {},
                                    )
                                  : CircleAvatar(
                                      backgroundColor:
                                          colorScheme.surfaceContainerHighest,
                                      child: Text(
                                        label.isNotEmpty
                                            ? label[0].toUpperCase()
                                            : '?',
                                        style: TextStyle(
                                          color: colorScheme.onSurfaceVariant,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                              const SizedBox(width: 16),
                              // Title and Subtitle
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      label,
                                      style: TextStyle(
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                        color: isSelected
                                            ? colorScheme.primary
                                            : null,
                                      ),
                                    ),
                                    if (subtitle != null) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        subtitle,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              // Trailing - Check icon
                              if (isSelected) ...[
                                const SizedBox(width: 8),
                                Icon(Icons.check_circle,
                                    color: colorScheme.primary),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
      actions: widget.onAdd != null
          ? [
              FilledButton.icon(
                onPressed: () async {
                  // Guardar referencia al Navigator ANTES del await
                  final navigator = Navigator.of(context);
                  // Ejecutar la acción de crear (muestra el diálogo de creación)
                  final newItem = await widget.onAdd!();
                  // Si se creó un item, cerrar el modal con el item seleccionado
                  if (newItem != null) {
                    navigator.pop(newItem);
                  }
                },
                icon: const Icon(Icons.add, size: 20),
                label: Text(widget.labelButton ?? 'Crear'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
            ]
          : null,
    );
  }
}
