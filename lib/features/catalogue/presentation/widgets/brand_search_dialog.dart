import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sellweb/features/catalogue/domain/entities/mark.dart';
import 'package:sellweb/features/catalogue/presentation/providers/catalogue_provider.dart';

/// Modal de búsqueda de marcas con consultas bajo demanda
///
/// Características:
/// - Búsqueda con debouncing (500ms) para optimizar consultas a Firestore
/// - Muestra marcas populares al inicio
/// - Búsqueda por prefijo en tiempo real
/// - Opción para crear nueva marca desde el modal
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
  bool _showPopular = true;

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.currentBrandName;
    _searchController.addListener(_onSearchChanged);
    _loadPopularBrands();
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

    // Forzar rebuild para actualizar el suffixIcon del TextField
    setState(() {});

    if (query.isEmpty) {
      _loadPopularBrands();
      return;
    }

    if (query.length < 2) {
      setState(() {
        _brands = [];
        _showPopular = false;
      });
      return;
    }

    // Debounce: espera 500ms después de que el usuario deja de escribir
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _searchBrands(query);
    });
  }

  /// Carga las marcas populares (verificadas y recientes)
  Future<void> _loadPopularBrands() async {
    setState(() {
      _isLoading = true;
      _showPopular = true;
    });

    try {
      final brands = await widget.catalogueProvider.getPopularBrands(limit: 20);

      // Debug: mostrar información de las marcas cargadas
      print('🔍 Marcas cargadas: ${brands.length}');
      for (var i = 0; i < brands.length && i < 3; i++) {
        print(
            '  Marca $i: id="${brands[i].id}", name="${brands[i].name}", desc="${brands[i].description}"');
      }

      if (mounted) {
        setState(() {
          _brands = brands;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error cargando marcas populares: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _brands = [];
        });
      }
    }
  }

  /// Busca marcas por nombre (búsqueda por prefijo)
  Future<void> _searchBrands(String query) async {
    setState(() {
      _isLoading = true;
      _showPopular = false;
    });

    try {
      final brands = await widget.catalogueProvider.searchBrands(
        query: query,
        limit: 30,
      );

      if (mounted) {
        setState(() {
          _brands = brands;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
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
          // Handle bar y Header FIJO
          Column(
            mainAxisSize: MainAxisSize.min,
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
              // Header
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
                        _showPopular ? 'Marcas populares' : 'Buscar marca',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
            ],
          ),
          // Contenido colapsable: búsqueda y contador
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 12),
                      // Campo de búsqueda
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: TextField(
                          controller: _searchController,
                          focusNode: _focusNode,
                          autofocus: true,
                          decoration: InputDecoration(
                            hintText: 'Buscar marca...',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      _searchController.clear();
                                      _loadPopularBrands();
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
                      // Contador o mensaje
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Row(
                          children: [
                            if (_isLoading)
                              const SizedBox(
                                width: 16,
                                height: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            else if (_brands.isNotEmpty)
                              Text(
                                '${_brands.length} marcas encontradas',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            const Spacer(),
                            if (widget.onCreateNewBrand != null)
                              TextButton.icon(
                                onPressed: () {
                                  Navigator.pop(context);
                                  widget.onCreateNewBrand?.call();
                                },
                                icon: const Icon(Icons.add, size: 18),
                                label: const Text('Nueva marca'),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
                // Lista de marcas con scroll
                _buildBrandsListSliver(theme, colorScheme),
              ],
            ),
          ),
        ],
      ),
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
                _searchController.text.isEmpty
                    ? 'Escribe para buscar marcas'
                    : 'No se encontraron marcas',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              if (_searchController.text.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Intenta con otro término',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
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
                if (widget.onEditBrand != null && !brand.verified)
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
