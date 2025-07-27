import '../../domain/entities/catalogue.dart';

/// Algoritmo eficiente de búsqueda de productos que permite buscar sin importar
/// el orden de las palabras y con tolerancia a errores de escritura.
class CatalogueProductFilterAlgorithm {
  /// Busca productos usando un algoritmo eficiente que permite:
  /// - Búsqueda por palabras sin importar el orden
  /// - Búsqueda en múltiples campos (descripción, marca, código)
  /// - Normalización de texto (sin tildes, minúsculas)
  /// - Tolerancia a espacios extra
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
      final limitedResults = results.take(maxResults).toList();
      return limitedResults;
    }

    return results;
  }

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

    // Nueva lógica de bonificación más flexible
    if (matchedWords == queryWords.length) {
      // Bonificación completa si coinciden todas las palabras
      totalScore *= 1.5;
    } else if (matchedWords >= queryWords.length * 0.7) {
      // Bonificación parcial si coinciden al menos el 70% de las palabras
      totalScore *= 1.3;
    } else if (matchedWords >= queryWords.length * 0.5) {
      // Bonificación menor si coinciden al menos el 50% de las palabras
      totalScore *= 1.1;
    }

    // Aplicar factor de coincidencia para que productos con más palabras coincidentes aparezcan primero
    final matchFactor = matchedWords / queryWords.length;
    totalScore *= matchFactor;

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

  /// Búsqueda difusa mejorada para encontrar coincidencias similares
  static bool _fuzzyMatch(String text, String word) {
    if (word.length < 2) return false; // Muy corta para búsqueda difusa

    // Caso 1: Buscar subcadenas de la palabra en el texto (método original)
    for (int i = 0; i <= word.length - 2; i++) {
      final substring = word.substring(i, i + 2);
      if (text.contains(substring)) {
        return true;
      }
    }

    // Caso 2: Verificar si las primeras letras de la palabra coinciden con alguna palabra del texto
    final firstThreeChars = word.length >= 3 ? word.substring(0, 3) : word;
    final textWords = text.split(' ');
    for (final textWord in textWords) {
      if (textWord.startsWith(firstThreeChars)) {
        return true;
      }
    }

    // Caso 3: Tolerancia a errores de tipeo (una letra diferente)
    if (word.length >= 4) {
      final textWords = text.split(' ');
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
    int minLength = word1.length < word2.length ? word1.length : word2.length;

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

    final result = suggestions.take(maxSuggestions).toList();
    return result;
  }

  /// Filtra productos marcados como favoritos
  ///
  /// [products] Lista de productos a filtrar
  /// Retorna una lista con solo los productos marcados como favoritos
  static List<ProductCatalogue> getFavoriteProducts({
    required List<ProductCatalogue> products,
  }) {
    return products.where((product) => product.favorite).toList();
  }

  /// Obtiene productos ordenados por cantidad de ventas con prioridad para favoritos
  ///
  /// [products] Lista de productos a filtrar
  /// [limit] Número máximo de productos a retornar (opcional)
  /// [minimumSales] Número mínimo de ventas para incluir el producto (por defecto 1)
  /// Retorna una lista ordenada donde aparecen primero los productos favoritos 
  /// ordenados por ventas (descendente), seguidos de los no favoritos también ordenados por ventas
  static List<ProductCatalogue> getTopSellingProducts({
    required List<ProductCatalogue> products,
    int? limit,
    int minimumSales = 1,
  }) {
    // Filtrar productos que tienen ventas >= minimumSales
    final filteredProducts = products
        .where((product) => product.sales >= minimumSales)
        .toList();

    // Separar productos favoritos y no favoritos
    final favoriteProducts = filteredProducts
        .where((product) => product.favorite)
        .toList()
      ..sort((a, b) => b.sales.compareTo(a.sales)); // Ordenar favoritos por ventas descendente

    final nonFavoriteProducts = filteredProducts
        .where((product) => !product.favorite)
        .toList()
      ..sort((a, b) => b.sales.compareTo(a.sales)); // Ordenar no favoritos por ventas descendente

    // Combinar listas: favoritos primero, luego no favoritos
    final topProducts = [...favoriteProducts, ...nonFavoriteProducts];

    // Aplicar límite si se especifica
    if (limit != null && limit > 0) {
      return topProducts.take(limit).toList();
    }

    return topProducts;
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
