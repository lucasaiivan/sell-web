# 🚀 Plan de Optimización de Rendimiento - Listados

## 📋 Resumen Ejecutivo

**Problema:** La aplicación carga **todos los productos** del catálogo en memoria, causando:
- Lentitud con 1000+ productos
- Alto consumo de memoria
- Lecturas excesivas de Firestore (💰 costos)
- UX degradada (scroll lag, búsquedas lentas)

**Solución:** Implementar **paginación lazy** + **optimizaciones de rendering**.

---

## 🎯 Mejoras Prioritarias

### **1. Paginación con Firestore (CRÍTICO)**

#### **Cambios en Repository**

```dart
// catalogue_repository.dart
abstract class CatalogueRepository {
  // ✅ NUEVO: Stream paginado
  Stream<QuerySnapshot> getCatalogueStreamPaginated({
    required String accountId,
    int limit = 50,
    DocumentSnapshot? startAfter,
  });
  
  // ✅ NUEVO: Cargar siguiente página
  Future<QuerySnapshot> getNextCataloguePage({
    required String accountId,
    required DocumentSnapshot lastDocument,
    int limit = 50,
  });
}
```

#### **Implementación**

```dart
// catalogue_repository_impl.dart
@override
Stream<QuerySnapshot> getCatalogueStreamPaginated({
  required String accountId,
  int limit = 50,
  DocumentSnapshot? startAfter,
}) {
  final path = FirestorePaths.accountCatalogue(accountId);
  final collection = _dataSource.collection(path);
  
  Query query = collection
    .orderBy('upgrade', descending: true) // Ordenar por última actualización
    .limit(limit);
  
  if (startAfter != null) {
    query = query.startAfterDocument(startAfter);
  }
  
  return query.snapshots();
}

@override
Future<QuerySnapshot> getNextCataloguePage({
  required String accountId,
  required DocumentSnapshot lastDocument,
  int limit = 50,
}) async {
  final path = FirestorePaths.accountCatalogue(accountId);
  final collection = _dataSource.collection(path);
  
  final query = collection
    .orderBy('upgrade', descending: true)
    .startAfterDocument(lastDocument)
    .limit(limit);
  
  return await _dataSource.getDocuments(query);
}
```

---

### **2. ListView con Infinite Scroll**

#### **Opción A: Usar `infinite_scroll_pagination` (Recomendado)**

```yaml
# pubspec.yaml
dependencies:
  infinite_scroll_pagination: ^4.0.0
```

```dart
// catalogue_page.dart
class _CataloguePageState extends State<CataloguePage> {
  final PagingController<DocumentSnapshot?, ProductCatalogue> _pagingController =
      PagingController(firstPageKey: null);
  
  static const _pageSize = 50;

  @override
  void initState() {
    super.initState();
    _pagingController.addPageRequestListener(_fetchPage);
  }

  Future<void> _fetchPage(DocumentSnapshot? pageKey) async {
    try {
      final catalogueProvider = context.read<CatalogueProvider>();
      final newItems = await catalogueProvider.loadNextPage(
        limit: _pageSize,
        startAfter: pageKey,
      );

      final isLastPage = newItems.length < _pageSize;
      if (isLastPage) {
        _pagingController.appendLastPage(newItems);
      } else {
        final nextPageKey = newItems.last.documentSnapshot; // Necesitas guardar esto
        _pagingController.appendPage(newItems, nextPageKey);
      }
    } catch (error) {
      _pagingController.error = error;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PagedListView<DocumentSnapshot?, ProductCatalogue>(
      pagingController: _pagingController,
      builderDelegate: PagedChildBuilderDelegate<ProductCatalogue>(
        itemBuilder: (context, product, index) => _ProductListTile(
          product: product,
          // ...
        ),
      ),
    );
  }
}
```

#### **Opción B: ScrollController Manual**

```dart
class _CataloguePageState extends State<CataloguePage> {
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_isLoadingMore) return;
    
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    
    // Cargar más cuando esté a 200px del final
    if (maxScroll - currentScroll <= 200) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    setState(() => _isLoadingMore = true);
    
    final catalogueProvider = context.read<CatalogueProvider>();
    await catalogueProvider.loadNextPage();
    
    setState(() => _isLoadingMore = false);
  }

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      controller: _scrollController, // ✅ Agregar controller
      // ...
    );
  }
}
```

---

### **3. Optimizar Provider con Selectores**

#### **Antes (❌ Malo)**
```dart
Consumer<CatalogueProvider>(
  builder: (context, catalogueProvider, _) {
    // Se reconstruye con CUALQUIER cambio
  },
)
```

#### **Después (✅ Bueno)**
```dart
Selector<CatalogueProvider, List<ProductCatalogue>>(
  selector: (_, provider) => provider.visibleProducts,
  builder: (context, products, _) {
    // Solo se reconstruye cuando visibleProducts cambia
  },
)
```

---

### **4. Cachear Contadores de Productos**

#### **En CatalogueProvider**

```dart
class CatalogueProvider extends ChangeNotifier {
  // ✅ Cache de contadores
  final Map<String, int> _categoryProductCounts = {};
  final Map<String, int> _providerProductCounts = {};

  void _updateProductCounts() {
    _categoryProductCounts.clear();
    _providerProductCounts.clear();
    
    for (final product in _state.products) {
      // Contar por categoría
      _categoryProductCounts[product.category] = 
        (_categoryProductCounts[product.category] ?? 0) + 1;
      
      // Contar por proveedor
      _providerProductCounts[product.provider] = 
        (_providerProductCounts[product.provider] ?? 0) + 1;
    }
  }

  int getProductCountByCategory(String categoryId) {
    return _categoryProductCounts[categoryId] ?? 0; // ✅ O(1)
  }

  int getProductCountByProvider(String providerId) {
    return _providerProductCounts[providerId] ?? 0; // ✅ O(1)
  }
}
```

---

### **5. Lazy Loading de Imágenes**

```dart
// Usar cached_network_image con placeholders
CachedNetworkImage(
  imageUrl: product.image,
  placeholder: (context, url) => Container(
    color: Colors.grey[300],
    child: Icon(Icons.image, size: 40),
  ),
  memCacheWidth: 200, // ✅ Limitar tamaño en cache
  maxWidthDiskCache: 400, // ✅ Limitar en disco
)
```

---

### **6. Virtualización de GridView**

```dart
// Usar GridView.builder en vez de MasonryGridView para mejor performance
GridView.builder(
  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: _getCrossAxisCount(context),
    childAspectRatio: 0.75,
  ),
  itemCount: products.length,
  itemBuilder: (context, index) {
    // Solo construye items visibles
  },
)
```

---

## 📊 Impacto Esperado

| Métrica | Antes | Después | Mejora |
|---------|-------|---------|--------|
| **Carga inicial** | 5-10s (1000 productos) | <1s (50 productos) | **90%** |
| **Memoria** | ~50MB | ~10MB | **80%** |
| **Lecturas Firestore** | 1000 docs | 50 docs | **95%** |
| **Scroll FPS** | 30-40 fps | 60 fps | **50%** |

---

## 🔄 Plan de Implementación

### **Fase 1: Paginación Backend (2-3 horas)**
1. ✅ Agregar métodos paginados en `CatalogueRepository`
2. ✅ Implementar en `CatalogueRepositoryImpl`
3. ✅ Crear UseCase `GetPaginatedCatalogueUseCase`

### **Fase 2: UI Infinite Scroll (2-3 horas)**
4. ✅ Instalar `infinite_scroll_pagination`
5. ✅ Refactorizar `_buildListView` con `PagedListView`
6. ✅ Agregar lógica de carga en `CatalogueProvider`

### **Fase 3: Optimizaciones (1-2 horas)**
7. ✅ Reemplazar `Consumer` con `Selector`
8. ✅ Implementar cache de contadores
9. ✅ Optimizar carga de imágenes

### **Fase 4: Testing (1 hora)**
10. ✅ Probar con dataset de 1000+ productos
11. ✅ Verificar scroll performance
12. ✅ Validar costos de Firestore

---

## 🎯 Métricas de Éxito

- [ ] Carga inicial < 2 segundos
- [ ] Scroll a 60 FPS constante
- [ ] Uso de memoria < 100MB con 1000+ productos
- [ ] Lecturas de Firestore reducidas en 90%

---

## 📚 Referencias

- [Firestore Pagination Best Practices](https://firebase.google.com/docs/firestore/query-data/query-cursors)
- [Flutter Performance Best Practices](https://docs.flutter.dev/perf/best-practices)
- [infinite_scroll_pagination Package](https://pub.dev/packages/infinite_scroll_pagination)
