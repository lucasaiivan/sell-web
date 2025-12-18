import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sellweb/features/catalogue/domain/entities/mark.dart';
import 'package:sellweb/features/catalogue/presentation/providers/catalogue_provider.dart';

/// Modal de búsqueda de marcas con consultas bajo demanda
///
/// Características:
/// - Búsqueda con debouncing (500ms) para optimizar consultas a Firestore
/// - No carga marcas al inicio (búsqueda bajo demanda)
/// - Buscador centrado en estado inicial
/// - Búsqueda por prefijo en tiempo real
/// - Opción para crear nueva marca (visible solo cuando no hay resultados)
/// - Indicadores visuales para marcas verificadas y seleccionadas
/// - Se presenta como BottomSheet con handle bar
class BrandSearchDialog extends StatefulWidget {
  final CatalogueProvider catalogueProvider;
  final String? currentBrandId;
  final String currentBrandName;
  final VoidCallback? onCreateNewBrand;
  final Function(Mark)? onEditBrand;

  const BrandSearchDialog({
    super.key,
    required this.catalogueProvider,
    this.currentBrandId,
    required this.currentBrandName,
    this.onCreateNewBrand,
    this.onEditBrand,
  });

  @override
  State<BrandSearchDialog> createState() => _BrandSearchDialogState();
}

class _BrandSearchDialogState extends State<BrandSearchDialog> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _debounceTimer;

  List<Mark> _brands = [];
  bool _isLoading = false;
  bool _hasSearched = false;
  bool _isTyping = false; // Indica si el usuario está escribiendo (periodo de debounce)
  String _lastSearchQuery = ''; 
  

  @override
  void initState() {
    super.initState(); 
    _lastSearchQuery = widget.currentBrandName.trim(); // Inicializar con el nombre actual de la marca
    _searchController.addListener(_onSearchChanged); 
    // No cargar marcas al inicio
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  /// Listener del campo de búsqueda con debouncing
  void _onSearchChanged() {
    _debounceTimer?.cancel();

    final query = _searchController.text.trim();

    // Solo procesar si el contenido realmente cambió (no solo selección de texto)
    if (query == _lastSearchQuery) {
      return;
    }

    _lastSearchQuery = query;

    // Actualizar el suffixIcon del TextField
    setState(() {});

    if (query.isEmpty) {
      setState(() {
        _brands = [];
        _hasSearched = false;
        _isLoading = false;
        _isTyping = false;
      });
      return;
    }

    if (query.length < 2) {
      setState(() {
        _brands = [];
        _hasSearched = false;
        _isLoading = false;
        _isTyping = false;
      });
      return;
    }

    // Activar estado de escritura para feedback visual
    setState(() {
      _isTyping = true;
    });

    // Debounce: espera 1100ms después de que el usuario deja de escribir
    _debounceTimer = Timer(const Duration(milliseconds: 1100), () {
      if (mounted && _searchController.text.trim() == query) {
        setState(() {
          _isTyping = false;
        });
        _searchBrands(query);
      }
    });
  }

  /// Busca marcas por nombre (búsqueda por prefijo)
  Future<void> _searchBrands(String query) async {
    // Almacenamos el query actual para validar consistencia al finalizar la consulta
    final searchStartedWith = query;

    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });

    try {
      final brands = await widget.catalogueProvider.searchBrands(
        query: query,
        limit: 30,
      );

      // Solo actualizamos el estado si:
      // 1. El widget sigue montado
      // 2. El query que buscamos sigue siendo el que está en el controlador
      // 3. El query que buscamos es el mismo que inició esta ejecución (evita race conditions)
      if (mounted && 
          _searchController.text.trim() == searchStartedWith &&
          query == searchStartedWith) {
        setState(() {
          _brands = brands;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted && _searchController.text.trim() == searchStartedWith) {
        setState(() {
          _isLoading = false;
          _brands = [];
        });
      }
    }
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
        children: [
          // Handle bar
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // AppBar con título
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
            child: Row(
              children: [
                Icon(
                  Icons.branding_watermark_outlined,
                  color: colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Buscar marca',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                  tooltip: 'Cerrar',
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Contenido
          Expanded(
            child: _brands.isEmpty && !_isLoading && !_hasSearched
                ? _buildCenteredSearch(theme, colorScheme)
                : _buildSearchWithResults(theme, colorScheme),
          ),
        ],
      ),
    );
  }

  /// Construye la vista con el buscador centrado (estado inicial)
  Widget _buildCenteredSearch(ThemeData theme, ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // icon : búsqueda 
            Icon(
              Icons.cloud_queue_sharp,
              size: 64,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              focusNode: _focusNode,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Escribe el nombre de la marca...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? _isTyping
                        ? const Padding(
                            padding: EdgeInsets.all(12.0),
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : IconButton(
                            icon: const Icon(Icons.backspace_outlined, size: 20),
                            onPressed: () {
                              _searchController.clear();
                            },
                          )
                    : null,
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Construye la vista con resultados de búsqueda
  Widget _buildSearchWithResults(ThemeData theme, ColorScheme colorScheme) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Campo de búsqueda en la parte superior
              Padding(
                padding: const EdgeInsets.only(top: 16, left: 24, right: 24),
                child: TextField(
                  controller: _searchController,
                  focusNode: _focusNode,
                  decoration: InputDecoration(
                    hintText: 'Buscar marca...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? _isTyping
                            ? const Padding(
                                padding: EdgeInsets.all(12.0),
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              )
                            : IconButton(
                                icon: const Icon(Icons.backspace_outlined, size: 20),
                                onPressed: () {
                                  _searchController.clear();
                                },
                              )
                        : null,
                    filled: true,
                    fillColor: colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Contador de resultados
              if (_brands.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${_brands.length} marcas encontradas',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
        // Lista de marcas con scroll
        _buildBrandsListSliver(theme, colorScheme),
      ],
    );
  }

  /// Construye la lista de marcas como Sliver con estados: loading, empty, data
  Widget _buildBrandsListSliver(ThemeData theme, ColorScheme colorScheme) {
    if (_isLoading && _brands.isEmpty) {
      return SliverFillRemaining(
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_brands.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off,
                size: 64,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'No se encontraron marcas',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Intenta con otro término',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              if (widget.onCreateNewBrand != null) ...[
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    widget.onCreateNewBrand?.call();
                  },
                  icon: const Icon(Icons.add, size: 20),
                  label: const Text('Crear nueva marca'),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final brand = _brands[index];
          final isSelected = widget.currentBrandId == brand.id; 

          // Capitalizar nombre para mostrar (sin modificar el valor real)
          final displayName = brand.name.isNotEmpty
              ? brand.name[0].toUpperCase() + brand.name.substring(1)
              : 'Sin nombre';

          final displayDescription = brand.description.isNotEmpty
              ? brand.description[0].toUpperCase() +
                  brand.description.substring(1)
              : '';

          return ListTile(
            leading: brand.image.isNotEmpty
                ? CircleAvatar(
                    backgroundImage: NetworkImage(brand.image),
                    radius: 20,
                    onBackgroundImageError: (_, __) {
                      // En caso de error al cargar la imagen, muestra el avatar con inicial
                    },
                  )
                : CircleAvatar(
                    backgroundColor: colorScheme.primaryContainer,
                    child: Text(
                      brand.name.isNotEmpty ? brand.name[0].toUpperCase() : '?',
                      style: TextStyle(
                        color: colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    displayName,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
                if (brand.verified)
                  const Icon(
                    Icons.verified,
                    size: 18,
                    color: Colors.blue,
                  ),
              ],
            ),
            subtitle: displayDescription.isNotEmpty
                ? Text(
                    displayDescription,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )
                : null,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                  IconButton(
                    icon: Icon(
                      Icons.edit_outlined,
                      size: 20,
                      color: colorScheme.primary,
                    ),
                    tooltip: 'Editar marca',
                    onPressed: () {
                      Navigator.pop(context);
                      widget.onEditBrand?.call(brand);
                    },
                  ),
                if (isSelected)
                  Icon(
                    Icons.check_circle,
                    color: colorScheme.primary,
                  ),
              ],
            ),
            selected: isSelected,
            selectedTileColor:
                colorScheme.primaryContainer.withValues(alpha: 0.3),
            onTap: () => Navigator.pop(context, brand),
          );
        },
        childCount: _brands.length,
      ),
    );
  }
}
