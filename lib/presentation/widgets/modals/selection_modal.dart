import 'package:flutter/material.dart';

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

  const SelectionModal({
    super.key,
    required this.title,
    required this.items,
    required this.labelBuilder,
    this.subtitleBuilder,
    this.idBuilder,
    this.imageUrlBuilder,
    this.selectedItem,
    this.searchHint = 'Buscar...',
  });

  @override
  State<SelectionModal<T>> createState() => _SelectionModalState<T>();
}

class _SelectionModalState<T> extends State<SelectionModal<T>> {
  late List<T> _filteredItems;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filteredItems = widget.items;
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      if (query.isEmpty) {
        _filteredItems = widget.items;
      } else {
        _filteredItems = widget.items.where((item) {
          final label = widget.labelBuilder(item).toLowerCase();
          final subtitle =
              widget.subtitleBuilder?.call(item).toLowerCase() ?? '';
          return label.contains(query) || subtitle.contains(query);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 32,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                  style: IconButton.styleFrom(
                    backgroundColor: colorScheme.surfaceContainerHighest,
                  ),
                ),
              ],
            ),
          ),

          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: widget.searchHint,
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor:
                    colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),

          const SizedBox(height: 16),
          const Divider(height: 1),

          // List
          Expanded(
            child: _filteredItems.isEmpty
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
                    padding: const EdgeInsets.symmetric(vertical: 8),
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

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 4),
                        leading: imageUrl != null && imageUrl.isNotEmpty
                            ? CircleAvatar(
                                backgroundImage: NetworkImage(imageUrl),
                                backgroundColor:
                                    colorScheme.surfaceContainerHighest,
                              )
                            : null,
                        title: Text(
                          label,
                          style: TextStyle(
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected ? colorScheme.primary : null,
                          ),
                        ),
                        subtitle: subtitle != null ? Text(subtitle) : null,
                        trailing: isSelected
                            ? Icon(Icons.check_circle,
                                color: colorScheme.primary)
                            : null,
                        onTap: () => Navigator.of(context).pop(item),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
