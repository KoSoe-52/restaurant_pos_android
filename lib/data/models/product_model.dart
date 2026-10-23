import 'category_model.dart';

class Product {
  final int id;
  final String name;
  final int sellPrice;
  final String? description;
  final String printerTarget;
  final bool isAvailable;
  final String? imageUrl;
  final ProductCategory? category;

  const Product({
    required this.id,
    required this.name,
    required this.sellPrice,
    this.description,
    required this.printerTarget,
    required this.isAvailable,
    this.imageUrl,
    this.category,
  });

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        id: json['id'],
        name: json['name'],
        sellPrice: json['sell_price'] is int
            ? json['sell_price']
            : (json['sell_price'] as num).toInt(),
        description: json['description'],
        printerTarget: json['printer_target'] ?? 'kitchen',
        isAvailable: json['is_available'] ?? true,
        imageUrl: json['image_url'],
        category: json['category'] != null
            ? ProductCategory.fromJson(json['category'])
            : null,
      );
}

class PaginatedProducts {
  final List<Product> data;
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  const PaginatedProducts({
    required this.data,
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });

  bool get hasNextPage => currentPage < lastPage;

  factory PaginatedProducts.fromJson(Map<String, dynamic> json) {
    final p = json['products'] as Map<String, dynamic>;
    return PaginatedProducts(
      data: (p['data'] as List).map((e) => Product.fromJson(e)).toList(),
      currentPage: p['current_page'],
      lastPage: p['last_page'],
      perPage: p['per_page'],
      total: p['total'],
    );
  }
}

// Cart item model (local state only)
class CartItem {
  final Product product;
  int quantity;
  String note;

  CartItem({
    required this.product,
    this.quantity = 1,
    this.note = '',
  });

  int get subtotal => product.sellPrice * quantity;

  Map<String, dynamic> toOrderItem() => {
        'product_id': product.id,
        'quantity': quantity,
        'note': note.isNotEmpty ? note : null,
      };
}
