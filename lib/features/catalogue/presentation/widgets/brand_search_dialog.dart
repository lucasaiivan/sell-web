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
  final _focusNode = FocusNode();
  Timer? _debounceTimer;

  List<Mark> _brands = [];
  bool _isLoading = false;
  bool _hasSearched = false;
  bool _isTyping =
      false; // Indica si el usuario está escribiendo (periodo de debounce)
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
                    'Seleccionar Marca',
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
              focusNode: _focusNode,
              decoration: InputDecoration(
                hintText: 'Buscar',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _buildSuffixIcon(),
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

          // List or Content
          Expanded(
            child: _buildContent(theme, colorScheme),
          ),
        ],
      ),
    );
  }

  Widget _buildSuffixIcon() {
    if (_searchController.text.isEmpty) return const SizedBox.shrink();
    if (_isTyping) {
      return const Padding(
        padding: EdgeInsets.all(12.0),
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    return IconButton(
      icon: const Icon(Icons.backspace_outlined, size: 20),
      onPressed: () {
        _searchController.clear();
        setState(() {
          _brands = [];
          _hasSearched = false;
        });
      },
    );
  }

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
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _brands.length,
      itemBuilder: (context, index) {
        final brand = _brands[index];
        final isSelected = widget.currentBrandId == brand.id;

        // Capitalizar (manteniendo lógica existente)
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
