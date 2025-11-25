import 'package:sellweb/features/catalogue/domain/entities/product_catalogue.dart';

/// Servicio unificado de búsqueda y filtrado de productos del catálogo.
///
/// Proporciona algoritmos eficientes para:
/// - Búsqueda textual avanzada con normalización y tolerancia a errores
/// - Filtrado por categorías, marcas y códigos
/// - Ordenamiento por relevancia y ventas
/// - Sugerencias de búsqueda inteligentes
class LocalSearchDataSource {
  // =================== BÚSQUEDA PRINCIPAL ===================

  /// Búsqueda principal de productos con algoritmo avanzado.
  ///
  /// Características:
  /// - Búsqueda por palabras sin importar el orden
  /// - Búsqueda en múltiples campos (descripción, marca, código)
  /// - Normalización de texto (sin tildes, minúsculas)
  /// - Tolerancia a espacios extra y errores de tipeo
  /// - Puntuación por relevancia
  ///
  /// [products] Lista de productos donde buscar
  /// [query] Término de búsqueda
  /// [maxResults] Máximo número de resultados (opcional)
  ///
  /// Retorna una lista ordenada por relevancia
  static List<ProductCatalogue> searchProducts({
    required List<ProductCatalogue> products,
    required String query,
    int? maxResults,
  }) {
    if (query.trim().isEmpty) {
      return products;
    }

    // Normalizar y dividir la consulta en palabras
    final normalizedQuery = _normalizeText(query);
    final queryWords =
        normalizedQuery.split(' ').where((word) => word.isNotEmpty).toList();

    if (queryWords.isEmpty) {
      return products;
    }

    // Buscar y puntuar productos
    final scoredResults = <_ScoredProduct>[];

    for (final product in products) {
      final score = _calculateProductScore(product, queryWords);
      if (score > 0) {
        scoredResults.add(_ScoredProduct(product: product, score: score));
      }
    }

    // Ordenar por puntuación (descendente) y luego por descripción
    scoredResults.sort((a, b) {
      final scoreComparison = b.score.compareTo(a.score);
      if (scoreComparison != 0) return scoreComparison;
      return a.product.description.compareTo(b.product.description);
    });

    // Aplicar límite si se especifica
    final results = scoredResults.map((scored) => scored.product).toList();
    if (maxResults != null && maxResults > 0) {
      return results.take(maxResults).toList();
    }

    return results;
  }

  // =================== BÚSQUEDAS ESPECÍFICAS ===================

  /// Busca productos que coincidan exactamente con el código
  static List<ProductCatalogue> searchByExactCode({
    required List<ProductCatalogue> products,
    required String code,
  }) {
    final normalizedCode = _normalizeText(code);
    return products.where((product) {
      return _normalizeText(product.code) == normalizedCode;
    }).toList();
  }

  /// Busca productos por categoría
  static List<ProductCatalogue> searchByCategory({
    required List<ProductCatalogue> products,
    required String category,
  }) {
    final normalizedCategory = _normalizeText(category);
    return products.where((product) {
      return _normalizeText(product.nameCategory)
              .contains(normalizedCategory) ||
          _normalizeText(product.category).contains(normalizedCategory);
    }).toList();
  }

  /// Busca productos por marca
  static List<ProductCatalogue> searchByBrand({
    required List<ProductCatalogue> products,
    required String brand,
  }) {
    final normalizedBrand = _normalizeText(brand);
    return products.where((product) {
      return _normalizeText(product.nameMark).contains(normalizedBrand);
    }).toList();
  }

  // =================== FILTROS Y ORDENAMIENTO ===================

  /// Obtiene productos más vendidos con prioridad para favoritos
  ///
  /// [products] Lista de productos a filtrar
  /// [limit] Número máximo de productos a retornar (opcional)
  /// [minimumSales] Número mínimo de ventas para incluir el producto (por defecto 1)
  ///
  /// Retorna una lista donde aparecen primero los productos favoritos
  /// ordenados por ventas (descendente), seguidos de los no favoritos
  static List<ProductCatalogue> getTopSellingProducts({
    required List<ProductCatalogue> products,
    int? limit,
    int minimumSales = 1,
  }) {
    // Filtrar productos que tienen ventas >= minimumSales
    final filteredProducts =
        products.where((product) => product.sales >= minimumSales).toList();

    // Separar productos favoritos y no favoritos
    final favoriteProducts = filteredProducts
        .where((product) => product.favorite)
        .toList()
      ..sort((a, b) => b.sales.compareTo(a.sales));

    final nonFavoriteProducts = filteredProducts
        .where((product) => !product.favorite)
        .toList()
      ..sort((a, b) => b.sales.compareTo(a.sales));

    // Combinar listas: favoritos primero, luego no favoritos
    final topProducts = [...favoriteProducts, ...nonFavoriteProducts];

    // Aplicar límite si se especifica
    if (limit != null && limit > 0) {
      return topProducts.take(limit).toList();
    }

    return topProducts;
  }

  /// Filtra productos marcados como favoritos
  static List<ProductCatalogue> getFavoriteProducts({
    required List<ProductCatalogue> products,
  }) {
    return products.where((product) => product.favorite).toList();
  }

  // =================== SUGERENCIAS ===================

  /// Obtiene sugerencias de búsqueda basadas en los productos disponibles
  static List<String> getSearchSuggestions({
    required List<ProductCatalogue> products,
    required String query,
    int maxSuggestions = 5,
  }) {
    if (query.trim().isEmpty) {
      return [];
    }

    final normalizedQuery = _normalizeText(query);
    final suggestions = <String>{};

    for (final product in products) {
      // Sugerencias de descripción
      final description = _normalizeText(product.description);
      if (description.contains(normalizedQuery) &&
          product.description.isNotEmpty) {
        suggestions.add(product.description);
      }

      // Sugerencias de marca
      final brand = _normalizeText(product.nameMark);
      if (brand.contains(normalizedQuery) && product.nameMark.isNotEmpty) {
        suggestions.add(product.nameMark);
      }

      // Sugerencias de categoría
      final category = _normalizeText(product.nameCategory);
      if (category.contains(normalizedQuery) &&
          product.nameCategory.isNotEmpty) {
        suggestions.add(product.nameCategory);
      }
    }

    return suggestions.take(maxSuggestions).toList();
  }

  // =================== MÉTODOS PRIVADOS ===================

  /// Normaliza texto eliminando tildes, convirtiendo a minúsculas y limpiando espacios
  static String _normalizeText(String text) {
    return text
        .toLowerCase()
        .trim()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ñ', 'n')
        .replaceAll(RegExp(r'\s+'), ' '); // Normalizar espacios múltiples
  }

  /// Calcula la puntuación de relevancia de un producto para una consulta
  static double _calculateProductScore(
      ProductCatalogue product, List<String> queryWords) {
    if (queryWords.isEmpty) return 0.0;

    // Textos normalizados del producto
    final description = _normalizeText(product.description);
    final code = _normalizeText(product.code);
    final brand = _normalizeText(product.nameMark);
    final category = _normalizeText(product.nameCategory);

    double totalScore = 0.0;
    int matchedWords = 0;

    for (final word in queryWords) {
      double wordScore = 0.0;

      // Coincidencia exacta en código (máxima puntuación)
      if (code == word) {
        wordScore = 100.0;
      }
      // Código contiene la palabra
      else if (code.contains(word)) {
        wordScore = 90.0;
      }
      // Coincidencia exacta en descripción (inicio de palabra)
      else if (description.startsWith(word)) {
        wordScore = 80.0;
      }
      // Descripción contiene la palabra al inicio de una palabra
      else if (_containsWordAtStart(description, word)) {
        wordScore = 70.0;
      }
      // Descripción contiene la palabra en cualquier lugar
      else if (description.contains(word)) {
        wordScore = 60.0;
      }
      // Coincidencia exacta en marca
      else if (brand == word) {
        wordScore = 50.0;
      }
      // Marca contiene la palabra
      else if (brand.contains(word)) {
        wordScore = 40.0;
      }
      // Categoría contiene la palabra
      else if (category.contains(word)) {
        wordScore = 30.0;
      }
      // Búsqueda difusa en descripción (similar)
      else if (_fuzzyMatch(description, word)) {
        wordScore = 20.0;
      }
      // Búsqueda difusa en marca
      else if (_fuzzyMatch(brand, word)) {
        wordScore = 15.0;
      }

      if (wordScore > 0) {
        matchedWords++;
        totalScore += wordScore;
      }
    }

    // Lógica de bonificación por coincidencias
    if (matchedWords < queryWords.length) {
      return 0.0;
    }

    // Bonificación adicional si hay coincidencias exactas o de alta puntuación
    if (totalScore / queryWords.length > 50) {
      totalScore *= 1.2;
    }

    return totalScore;
  }

  /// Verifica si el texto contiene la palabra al inicio de alguna palabra
  static bool _containsWordAtStart(String text, String word) {
    final words = text.split(' ');
    for (final textWord in words) {
      if (textWord.startsWith(word)) {
        return true;
      }
    }
    return false;
  }

  /// Búsqueda difusa para encontrar coincidencias similares
  static bool _fuzzyMatch(String text, String word) {
    if (word.length < 3) return false;

    final textWords = text.split(' ');

    // Caso: Tolerancia a errores de tipeo
    if (word.length >= 4) {
      for (final textWord in textWords) {
        if (_isTypoTolerant(textWord, word)) {
          return true;
        }
      }
    }

    return false;
  }

  /// Verifica si dos palabras son similares con tolerancia a un error de tipeo
  static bool _isTypoTolerant(String word1, String word2) {
    if ((word1.length - word2.length).abs() > 1) return false;

    int differences = 0;
    final minLength = word1.length < word2.length ? word1.length : word2.length;

    for (int i = 0; i < minLength; i++) {
      if (word1[i] != word2[i]) {
        differences++;
        if (differences > 1) return false;
      }
    }

    // Añadir diferencia por diferencia de longitud
    differences += (word1.length - word2.length).abs();

    return differences <= 1;
  }
}

/// Clase interna para manejar productos con puntuación
class _ScoredProduct {
  final ProductCatalogue product;
  final double score;

  const _ScoredProduct({
    required this.product,
    required this.score,
  });
}
