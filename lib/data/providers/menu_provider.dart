import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/errors/exceptions.dart';
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

  // Debounce timer for search — avoids hitting the API on every keystroke.
  Timer? _searchDebounce;

  // Cart state
  final Map<int, CartItem> _cartItems = {};

  // ── Getters ────────────────────────────────────────────────────────────

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

  // ── Data loading ───────────────────────────────────────────────────────

  Future<void> loadCategories() async {
    _isLoadingCategories = true;
    _error = null;
    notifyListeners();
    try {
      _categories = await ApiService.getCategories();
    } catch (e) {
      _error = AppException.userMessage(e);
    } finally {
      _isLoadingCategories = false;
      notifyListeners();
    }
  }

  Future<void> loadProducts({bool refresh = false}) async {
    if (refresh) _products = [];
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
      _error = AppException.userMessage(e);
    } finally {
      _isLoadingProducts = false;
      notifyListeners();
    }
  }

  /// Resets search query and category selection, then reloads products.
  /// Call this when entering the menu screen to clear stale singleton state.
  void resetFilters() {
    _searchDebounce?.cancel();
    _searchQuery = '';
    _selectedCategoryId = null;
    _error = null;
    notifyListeners();
  }

  void selectCategory(int? categoryId) {
    if (_selectedCategoryId == categoryId) return;
    _searchDebounce?.cancel();
    _selectedCategoryId = categoryId;
    loadProducts(refresh: true);
  }

  /// Updates the search query with a 400 ms debounce so the API is only
  /// called after the user stops typing.
  void setSearch(String query) {
    _searchQuery = query;
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      loadProducts(refresh: true);
    });
    notifyListeners(); // update clear-button visibility immediately
  }

  void clearSearch() {
    _searchDebounce?.cancel();
    _searchQuery = '';
    loadProducts(refresh: true);
  }

  // ── Cart operations ────────────────────────────────────────────────────

  void addToCart(Product product) {
    if (_cartItems.containsKey(product.id)) {
      _cartItems[product.id]!.quantity++;
    } else {
      _cartItems[product.id] = CartItem(product: product);
    }
    notifyListeners();
  }

  void removeFromCart(int productId) {
    final item = _cartItems[productId];
    if (item == null) return;
    if (item.quantity > 1) {
      item.quantity--;
    } else {
      _cartItems.remove(productId);
    }
    notifyListeners();
  }

  void removeItemCompletely(int productId) {
    _cartItems.remove(productId);
    notifyListeners();
  }

  void updateItemNote(int productId, String note) {
    _cartItems[productId]?.note = note;
    notifyListeners();
  }

  void clearCart() {
    _cartItems.clear();
    notifyListeners();
  }

  int getQuantityInCart(int productId) =>
      _cartItems[productId]?.quantity ?? 0;

  List<Map<String, dynamic>> getCartAsOrderItems() =>
      _cartItems.values.map((item) => item.toOrderItem()).toList();

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }
}
