import 'package:flutter/foundation.dart';
import '../models/category_model.dart';
import '../models/product_model.dart';
import '../services/api_service.dart';

class MenuProvider extends ChangeNotifier {
  List<ProductCategory> _categories = [];
  List<Product> _products = [];
  bool _isLoadingCategories = false;
  bool _isLoadingProducts = false;
  String? _error;
  int? _selectedCategoryId;
  String _searchQuery = '';

  // Cart state
  final Map<int, CartItem> _cartItems = {};

  List<ProductCategory> get categories => _categories;
  List<Product> get products => _products;
  bool get isLoadingCategories => _isLoadingCategories;
  bool get isLoadingProducts => _isLoadingProducts;
  bool get isLoading => _isLoadingCategories || _isLoadingProducts;
  String? get error => _error;
  int? get selectedCategoryId => _selectedCategoryId;
  String get searchQuery => _searchQuery;

  // Cart getters
  List<CartItem> get cartItems => _cartItems.values.toList();
  int get cartItemCount =>
      _cartItems.values.fold(0, (sum, item) => sum + item.quantity);
  int get cartTotal =>
      _cartItems.values.fold(0, (sum, item) => sum + item.subtotal);
  bool get hasCartItems => _cartItems.isNotEmpty;

  Future<void> loadCategories() async {
    _isLoadingCategories = true;
    _error = null;
    notifyListeners();
    try {
      _categories = await ApiService.getCategories();
    } catch (e) {
      _error = _extractMessage(e);
    } finally {
      _isLoadingCategories = false;
      notifyListeners();
    }
  }

  Future<void> loadProducts({bool refresh = false}) async {
    if (refresh) {
      _products = [];
    }
    _isLoadingProducts = true;
    _error = null;
    notifyListeners();
    try {
      final result = await ApiService.getProducts(
        categoryId: _selectedCategoryId,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
      );
      _products = result.data;
    } catch (e) {
      _error = _extractMessage(e);
    } finally {
      _isLoadingProducts = false;
      notifyListeners();
    }
  }

  void selectCategory(int? categoryId) {
    if (_selectedCategoryId == categoryId) return;
    _selectedCategoryId = categoryId;
    loadProducts(refresh: true);
  }

  void setSearch(String query) {
    _searchQuery = query;
    loadProducts(refresh: true);
  }

  void clearSearch() {
    _searchQuery = '';
    loadProducts(refresh: true);
  }

  // Cart operations
  void addToCart(Product product) {
    if (_cartItems.containsKey(product.id)) {
      _cartItems[product.id]!.quantity++;
    } else {
      _cartItems[product.id] = CartItem(product: product);
    }
    notifyListeners();
  }

  void removeFromCart(int productId) {
    if (_cartItems.containsKey(productId)) {
      if (_cartItems[productId]!.quantity > 1) {
        _cartItems[productId]!.quantity--;
      } else {
        _cartItems.remove(productId);
      }
      notifyListeners();
    }
  }

  void removeItemCompletely(int productId) {
    _cartItems.remove(productId);
    notifyListeners();
  }

  void updateItemNote(int productId, String note) {
    if (_cartItems.containsKey(productId)) {
      _cartItems[productId]!.note = note;
      notifyListeners();
    }
  }

  void clearCart() {
    _cartItems.clear();
    notifyListeners();
  }

  int getQuantityInCart(int productId) {
    return _cartItems[productId]?.quantity ?? 0;
  }

  List<Map<String, dynamic>> getCartAsOrderItems() {
    return _cartItems.values.map((item) => item.toOrderItem()).toList();
  }

  String _extractMessage(dynamic e) {
    final s = e.toString();
    if (s.contains('NetworkException')) return 'No internet connection.';
    if (s.contains('UnauthorizedException')) return 'Session expired.';
    return s
        .replaceAll('Exception: ', '')
        .replaceAll('ApiException(', '')
        .split('):')
        .last
        .trim();
  }
}
