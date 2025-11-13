import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sellweb/core/core.dart';
import 'package:sellweb/domain/entities/catalogue.dart' hide Provider;
import '../providers/catalogue_provider.dart';
import '../providers/sell_provider.dart';
import '../widgets/navigation/drawer.dart';

/// Página dedicada para gestionar el catálogo de productos
/// Separada de la lógica de ventas para mejor organización
class CataloguePage extends StatefulWidget {
  const CataloguePage({super.key});

  @override
  State<CataloguePage> createState() => _CataloguePageState();
}

class _CataloguePageState extends State<CataloguePage> {
  bool _isGridView = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      drawer: const AppDrawer(),
      body: _buildBody(context),
      floatingActionButton: _buildFloatingActionButton(context),
    );
  }

  /// Construye el AppBar de la página de catálogo
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final catalogueProvider = Provider.of<CatalogueProvider>(context);
    final sellProvider = Provider.of<SellProvider>(context, listen: false);

    return AppBar(
      toolbarHeight: 70,
      titleSpacing: 0,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: Container(),
      flexibleSpace: SafeArea(
        child: Container(
          padding: const EdgeInsets.only(
            top: 20.0,
            bottom: 12,
            left: 12,
            right: 12,
          ),
          child: Row(
            children: [
              // Avatar y botón de drawer
              Builder(
                builder: (context) => GestureDetector(
                  onTap: () => Scaffold.of(context).openDrawer(),
                  child: UserAvatar(
                    imageUrl: sellProvider.profileAccountSelected.image,
                    text: sellProvider.profileAccountSelected.name,
                    radius: 18,
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Título de la página
              Text(
                'Catálogo',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(width:12),
              SearchButton(
                label: 'Buscar',
                 onPressed: () {  }
                 ,
                
              ),

              const Spacer(),
              // Contador de productos
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${catalogueProvider.products.length} productos',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                ),
              ),
              const SizedBox(width: 8),
              // Botón para alternar vista
              IconButton(
                onPressed: () => setState(() => _isGridView = !_isGridView),
                icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view),
                tooltip: _isGridView ? 'Vista de lista' : 'Vista de grilla',
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Construye el cuerpo de la página con la lista de productos
  Widget _buildBody(BuildContext context) {
    return Consumer<CatalogueProvider>(
      builder: (context, catalogueProvider, child) {
        // Estado de carga
        if (catalogueProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        // Sin productos
        if (catalogueProvider.products.isEmpty) {
          return _buildEmptyState(context);
        }

        // Lista de productos
        return _isGridView
            ? _buildGridView(catalogueProvider)
            : _buildListView(catalogueProvider);
      },
    );
  }

  /// Construye la vista en grilla
  Widget _buildGridView(CatalogueProvider catalogueProvider) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _getCrossAxisCount(context),
        crossAxisSpacing: 0,
        mainAxisSpacing: 0,
        childAspectRatio: 0.75,
      ),
      itemCount: catalogueProvider.products.length,
      itemBuilder: (context, index) {
        final product = catalogueProvider.products[index];
        return _ProductCatalogueCard(product: product);
      },
    );
  }

  /// Construye la vista en lista vertical
  Widget _buildListView(CatalogueProvider catalogueProvider) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: catalogueProvider.products.length,
      separatorBuilder: (context, index) => const Divider(height:0,thickness:0.4),
      itemBuilder: (context, index) {
        final product = catalogueProvider.products[index];
        return _ProductListTile(product: product);
      },
    );
  }

  /// Estado vacío cuando no hay productos
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 80,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'No hay productos en el catálogo',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Agrega tu primer producto',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }

  /// Botón flotante para agregar productos
  Widget _buildFloatingActionButton(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () {
        // TODO: Implementar diálogo para agregar producto
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Agregar producto - Por implementar')),
        );
      },
      icon: const Icon(Icons.add),
      label: const Text('Agregar producto'),
    );
  }

  /// Calcula el número de columnas según el ancho de la pantalla
  int _getCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 600) return 3;
    if (width < 900) return 4;
    if (width < 1200) return 6;
    return 7;
  }
}

/// Tarjeta para mostrar un producto en vista de lista
class _ProductListTile extends StatelessWidget {
  final ProductCatalogue product;

  const _ProductListTile({required this.product});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Editar: ${product.description}')),
        );
      },
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Imagen del producto
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: ProductImage(
                imageUrl: product.image,
                size: 80,
                fit: BoxFit.cover,
              ),
            ),
    
            const SizedBox(width: 16),
    
            // Información del producto
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Descripción
                  Text(
                    product.description,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
    
                  // Código
                  if (product.code.isNotEmpty)
                    Text(
                      product.code,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
    
                  const SizedBox(height: 8),
    
                  // Precio y stock
                  if (product.stock && product.quantityStock <= product.alertStock)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        product.quantityStock > 0
                            ? 'Stock bajo'
                            : 'Sin stock',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width:12),
            // text : Precio
            Text(
              CurrencyFormatter.formatPrice(value: product.salePrice),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
                fontSize: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tarjeta para mostrar un producto del catálogo
class _ProductCatalogueCard extends StatelessWidget {
  final ProductCatalogue product;

  const _ProductCatalogueCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          // TODO: Implementar edición de producto
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Editar: ${product.description}')),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen del producto
            Expanded(
              flex: 3,
              child: ProductImage(
                imageUrl: product.image,
                fit: BoxFit.cover,
              ),
            ),

            // Información del producto
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Descripción
                    Text(
                      product.description,
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    // Precio y código
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          CurrencyFormatter.formatPrice(
                              value: product.salePrice),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                        if (product.code.isNotEmpty)
                          Text(
                            product.code,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontSize: 10,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Indicador de stock bajo
            if (product.stock && product.quantityStock <= product.alertStock)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 4),
                color: Colors.red,
                child: Text(
                  product.quantityStock > 0 ? 'Stock bajo' : 'Sin stock',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
