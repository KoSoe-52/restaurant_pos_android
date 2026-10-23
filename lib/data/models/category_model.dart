class ProductCategory {
  final int id;
  final String name;
  final String? color;
  final int productCount;

  const ProductCategory({
    required this.id,
    required this.name,
    this.color,
    required this.productCount,
  });

  factory ProductCategory.fromJson(Map<String, dynamic> json) =>
      ProductCategory(
        id: json['id'],
        name: json['name'],
        color: json['color'],
        productCount: json['product_count'] ?? 0,
      );
}
