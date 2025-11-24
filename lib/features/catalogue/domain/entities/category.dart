class Category {
  final String id;
  final String name;
  final Map<String, dynamic> subcategories;

  Category({
    this.id = "",
    this.name = "",
    this.subcategories = const {},
  });
}
