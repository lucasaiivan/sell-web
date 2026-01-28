import '../../domain/entities/category.dart';

/// Modelo de datos para Category con lógica de serialización.
class CategoryModel extends Category {
  CategoryModel({
    super.id,
    super.name,
    super.subcategories,
  });

  /// Crea una instancia desde un Map
  factory CategoryModel.fromMap(Map<String, dynamic> data) {
    return CategoryModel(
      id: data['id'] ?? '',
      name: data.containsKey('name') ? data['name'] : data['nombre'] ?? '',
      subcategories: data.containsKey('subcategories')
          ? data['subcategories']
          : data['subcategorias'] ?? {},
    );
  }

  /// Convierte a Map para Firestore
  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "subcategories": subcategories,
      };

  /// Alias para toJson (compatibilidad)
  Map<String, dynamic> toMap() => toJson();

  /// Convierte a entidad de dominio
  Category toEntity() {
    return Category(
      id: id,
      name: name,
      subcategories: subcategories,
    );
  }
}
