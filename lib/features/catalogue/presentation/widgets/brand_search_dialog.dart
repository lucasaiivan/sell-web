import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sellweb/core/core.dart';
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
  Timer? _debounceTimer;

  List<Mark> _brands = [];
  bool _isLoading = false;
  bool _hasSearched = false;
  String _lastSearchQuery = '';

  @override
  void initState() {
    super.initState();
    _lastSearchQuery = widget.currentBrandName
        .trim(); // Inicializar con el nombre actual de la marca
    _searchController.addListener(_onSearchChanged);
    // No cargar marcas al inicio
  }

  @override
  void dispose() {
    _searchController.dispose();
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
      });
      return;
    }

    if (query.length < 2) {
      setState(() {
        _brands = [];
        _hasSearched = false;
        _isLoading = false;
      });
      return;
    }

    // Debounce: espera 1100ms después de que el usuario deja de escribir
    _debounceTimer = Timer(const Duration(milliseconds: 1100), () {
      if (mounted && _searchController.text.trim() == query) {
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

    return BaseBottomSheet(
      title: 'Seleccionar Marca',
      onSearch: _handleSearchInput,
      searchHint: 'Buscar marca...',
      searchController: _searchController,
      body: _buildContent(theme, colorScheme),
    );
  }

  /// Wrapper para adaptar la firma de onSearch y manejar la lógica
  void _handleSearchInput(String query) {
    // La lógica de debounce ya está conectada al listener del controller en initState
    // pero BaseBottomSheet actualiza el controller, que dispara el listener.
    // También podemos implementar lógica directa aquí si preferimos no usar el listener.
    // Dado que ya tenemos _onSearchChanged conectado al controller, 
    // y BaseBottomSheet usa el MISMO controller, no necesitamos hacer nada extra aquí
    // EXCEPTO si BaseBottomSheet no notifica cambios al controller (lo hace por ser su controller).
    
    // Sin embargo, para mayor claridad y evitar dependencias cíclicas, 
    // BaseBottomSheet llama a onSearch cuando el texto cambia.
    // El controller también notifica listeners. 
    // Vamos a confiar en la implementación actual del controller listener _onSearchChanged
    // que ya tiene el debouncing.
  }

  // ... _buildContent y otros métodos se mantienen, pero ya no necesitamos _buildSuffixIcon
  // ni la estructura manual del modal.
  
  Widget _buildContent(ThemeData theme, ColorScheme colorScheme) {
    if (_isLoading && _brands.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_brands.isEmpty) {
      // Estado inicial o sin resultados
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _hasSearched ? Icons.search_off_rounded : Icons.search_sharp,
              size: 64,
              color: colorScheme.outline.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              _hasSearched ? 'No se encontraron marcas' : 'Busca una marca',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            if (_hasSearched && widget.onCreateNewBrand != null) ...[
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
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 24),
      itemCount: _brands.length,
      itemBuilder: (context, index) {
        final brand = _brands[index];
        final isSelected = widget.currentBrandId == brand.id;

        // Capitalizar
        final displayName = brand.name.isNotEmpty
            ? TextFormatter.capitalizeString(brand.name)
            : 'Sin nombre';

        final displayDescription = brand.description.isNotEmpty
            ? TextFormatter.capitalizeString(brand.description)
            : '';

        return ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
          leading: brand.image.isNotEmpty
              ? CircleAvatar(
                  backgroundImage: NetworkImage(brand.image),
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  onBackgroundImageError: (_, __) {},
                )
              : CircleAvatar(
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  child: Text(
                    brand.name.isNotEmpty ? brand.name[0].toUpperCase() : '?',
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
          title: Text(
            displayName,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? colorScheme.primary : null,
            ),
          ),
          subtitle: displayDescription.isNotEmpty
              ? Text(displayDescription,
                  maxLines: 1, overflow: TextOverflow.ellipsis)
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
                Icon(Icons.check_circle, color: colorScheme.primary),
            ],
          ),
          onTap: () => Navigator.pop(context, brand),
        );
      },
    );
  }
}
