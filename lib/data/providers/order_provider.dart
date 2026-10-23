import 'package:flutter/foundation.dart';
import '../models/order_model.dart';
import '../services/api_service.dart';

class OrderProvider extends ChangeNotifier {
  List<Order> _orders = [];
  Order? _currentOrder;
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _error;
  int _currentPage = 1;
  bool _hasMore = true;
  String? _statusFilter;

  List<Order> get orders => _orders;
  Order? get currentOrder => _currentOrder;
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get error => _error;
  bool get hasMore => _hasMore;

  void _setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }

  void _setSubmitting(bool v) {
    _isSubmitting = v;
    notifyListeners();
  }

  void _setError(String? v) {
    _error = v;
    notifyListeners();
  }

  Future<void> loadOrders({
    String? status,
    bool myOrders = false,
    bool refresh = false,
  }) async {
    if (refresh) {
      _orders = [];
      _currentPage = 1;
      _hasMore = true;
      _statusFilter = status;
    }
    if (!_hasMore) return;
    _setLoading(true);
    _error = null;
    try {
      final result = await ApiService.getOrders(
        status: status ?? _statusFilter,
        myOrders: myOrders,
        page: _currentPage,
      );
      if (refresh) {
        _orders = result.data;
      } else {
        _orders.addAll(result.data);
      }
      _hasMore = result.hasNextPage;
      if (_hasMore) _currentPage++;
    } catch (e) {
      _error = _extractMessage(e);
    } finally {
      _setLoading(false);
    }
  }

  Future<Order?> loadOrderDetail(int id) async {
    _setLoading(true);
    _error = null;
    try {
      _currentOrder = await ApiService.getOrder(id);
      _setLoading(false);
      return _currentOrder;
    } catch (e) {
      _error = _extractMessage(e);
      _setLoading(false);
      return null;
    }
  }

  Future<Order?> createOrder({
    int? tableId,
    String? customerName,
    String? customerPhone,
    String? note,
    required List<Map<String, dynamic>> items,
  }) async {
    _setSubmitting(true);
    _error = null;
    try {
      final order = await ApiService.createOrder(
        tableId: tableId,
        customerName: customerName,
        customerPhone: customerPhone,
        note: note,
        items: items,
      );
      _currentOrder = order;
      // Add/update in orders list
      final idx = _orders.indexWhere((o) => o.id == order.id);
      if (idx >= 0) {
        _orders[idx] = order;
      } else {
        _orders.insert(0, order);
      }
      _setSubmitting(false);
      return order;
    } catch (e) {
      _error = _extractMessage(e);
      _setSubmitting(false);
      return null;
    }
  }

  Future<Order?> addItems(
    int orderId,
    List<Map<String, dynamic>> items,
  ) async {
    _setSubmitting(true);
    _error = null;
    try {
      final order = await ApiService.addItems(orderId, items);
      _currentOrder = order;
      _updateOrderInList(order);
      _setSubmitting(false);
      return order;
    } catch (e) {
      _error = _extractMessage(e);
      _setSubmitting(false);
      return null;
    }
  }

  Future<bool> serveOrder(int orderId) async {
    _setSubmitting(true);
    _error = null;
    try {
      final order = await ApiService.serveOrder(orderId);
      _currentOrder = order;
      _updateOrderInList(order);
      _setSubmitting(false);
      return true;
    } catch (e) {
      _error = _extractMessage(e);
      _setSubmitting(false);
      return false;
    }
  }

  Future<bool> voidOrder(int orderId, String reason) async {
    _setSubmitting(true);
    _error = null;
    try {
      await ApiService.voidOrder(orderId, reason);
      // Remove from list
      _orders.removeWhere((o) => o.id == orderId);
      if (_currentOrder?.id == orderId) {
        _currentOrder = null;
      }
      _setSubmitting(false);
      return true;
    } catch (e) {
      _error = _extractMessage(e);
      _setSubmitting(false);
      return false;
    }
  }

  Future<Order?> voidItem(int orderId, int itemId, String reason) async {
    _setSubmitting(true);
    _error = null;
    try {
      final order = await ApiService.voidItem(orderId, itemId, reason);
      _currentOrder = order;
      _updateOrderInList(order);
      _setSubmitting(false);
      return order;
    } catch (e) {
      _error = _extractMessage(e);
      _setSubmitting(false);
      return null;
    }
  }

  Future<bool> retryPrintJob(int jobId) async {
    try {
      await ApiService.retryPrintJob(jobId);
      return true;
    } catch (_) {
      return false;
    }
  }

  void _updateOrderInList(Order order) {
    final idx = _orders.indexWhere((o) => o.id == order.id);
    if (idx >= 0) {
      _orders[idx] = order;
    }
    notifyListeners();
  }

  void clearError() => _setError(null);

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
