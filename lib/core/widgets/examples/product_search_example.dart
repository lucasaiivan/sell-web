import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as provider_package;
import '../../../presentation/providers/catalogue_provider.dart';
import '../../../domain/entities/catalogue.dart' hide Provider;

/// Ejemplo de uso del algoritmo de búsqueda de productos
/// Este widget muestra cómo implementar y probar las funcionalidades de búsqueda
class ProductSearchExample extends StatefulWidget {
  const ProductSearchExample({super.key});

  @override
  State<ProductSearchExample> createState() => _ProductSearchExampleState();
}

class _ProductSearchExampleState extends State<ProductSearchExample> {
  final TextEditingController _searchController = TextEditingController();
  List<ProductCatalogue> _searchResults = [];
  List<String> _suggestions = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _suggestions = [];
      });
      return;
    }

    final catalogueProvider = provider_package.Provider.of<CatalogueProvider>(context, listen: false);
    
    // Realizar búsqueda con el algoritmo avanzado
    final results = catalogueProvider.searchProducts(
      query: query,
      maxResults: 10,
    );

    // Obtener sugerencias
    final suggestions = catalogueProvider.getSearchSuggestions(
      query: query,
      maxSuggestions: 5,
    );

    setState(() {
      _searchResults = results;
      _suggestions = suggestions;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prueba de Búsqueda de Productos'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Campo de búsqueda
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Buscar productos',
                hintText: 'Escribe cualquier palabra sin importar el orden',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                border: const OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            // Sugerencias
            if (_suggestions.isNotEmpty) ...[
              Text(
                'Sugerencias:',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _suggestions.map((suggestion) {
                  return ActionChip(
                    label: Text(suggestion),
                    onPressed: () {
                      _searchController.text = suggestion;
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],

            // Resultados de búsqueda
            Text(
              'Resultados: ${_searchResults.length}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),

            // Lista de productos encontrados
            Expanded(
              child: _searchResults.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_outlined,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchController.text.isEmpty
                                ? 'Escribe algo para buscar'
                                : 'No se encontraron productos',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final product = _searchResults[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              child: Text(
                                (index + 1).toString(),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            title: Text(
                              product.description,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (product.nameMark.isNotEmpty)
                                  Text('Marca: ${product.nameMark}'),
                                if (product.code.isNotEmpty)
                                  Text('Código: ${product.code}'),
                                if (product.nameCategory.isNotEmpty)
                                  Text('Categoría: ${product.nameCategory}'),
                              ],
                            ),
                            trailing: Text(
                              '\$${product.salePrice.toStringAsFixed(2)}',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      
      // FAB con ejemplos de búsqueda
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showSearchExamples,
        label: const Text('Ejemplos'),
        icon: const Icon(Icons.help_outline),
      ),
    );
  }

  void _showSearchExamples() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ejemplos de Búsqueda'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Prueba estos ejemplos de búsqueda:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildSearchExample('coca cola', 'Búsqueda simple por nombre'),
              _buildSearchExample('cola coca', 'Palabras en cualquier orden'),
              _buildSearchExample('500 ml bebida', 'Múltiples palabras'),
              _buildSearchExample('7790', 'Búsqueda por código parcial'),
              _buildSearchExample('pepsi lata', 'Marca + tipo de envase'),
              _buildSearchExample('bebida azucar', 'Sin tildes (búsqueda normalizada)'),
              _buildSearchExample('gal gall', 'Búsqueda difusa (galletas)'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchExample(String query, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.of(context).pop();
          _searchController.text = query;
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '"$query"',
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Función helper para mostrar la pantalla de ejemplo
void showProductSearchExample(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (context) => const ProductSearchExample(),
    ),
  );
}
