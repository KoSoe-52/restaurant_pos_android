import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/constants/app_constants.dart';
import '../../core/errors/exceptions.dart';
import '../models/table_model.dart';
import '../services/api_service.dart';

class TableProvider extends ChangeNotifier {
  List<RestaurantTable> _tables = [];
  bool _isLoading = false;
  String? _error;
  Timer? _refreshTimer;

  List<RestaurantTable> get tables => _tables;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<RestaurantTable> get availableTables =>
      _tables.where((t) => t.isAvailable).toList();
  List<RestaurantTable> get occupiedTables =>
      _tables.where((t) => t.isOccupied).toList();
  List<RestaurantTable> get reservedTables =>
      _tables.where((t) => t.isReserved).toList();

  // ── Data loading ───────────────────────────────────────────────────────

  Future<void> loadTables() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _tables = await ApiService.getTables();
    } catch (e) {
      _error = AppException.userMessage(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Silent background refresh — keeps existing data on failure.
  Future<void> refreshTables() async {
    try {
      _tables = await ApiService.getTables();
      _error = null;
      notifyListeners();
    } catch (_) {}
  }

  // ── Auto-refresh ───────────────────────────────────────────────────────

  void startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(
      AppConstants.tableRefreshInterval,
      (_) => refreshTables(),
    );
  }

  void stopAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  /// Transfer an open order from the source table to [targetTableId].
  /// Returns an error message string on failure, null on success.
  Future<String?> transferTable(int orderId, int targetTableId) async {
    try {
      await ApiService.transferTable(orderId, targetTableId);
      await refreshTables(); // Sync table statuses after transfer
      return null;
    } catch (e) {
      return AppException.userMessage(e);
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    stopAutoRefresh();
    super.dispose();
  }
}
