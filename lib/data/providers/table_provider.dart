import 'package:flutter/foundation.dart';
import 'dart:async';
import '../models/table_model.dart';
import '../services/api_service.dart';
import '../../core/constants/app_constants.dart';

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

  Future<void> loadTables() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _tables = await ApiService.getTables();
      _error = null;
    } catch (e) {
      _error = _extractMessage(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshTables() async {
    try {
      _tables = await ApiService.getTables();
      _error = null;
      notifyListeners();
    } catch (e) {
      // Silent refresh failure — keep existing data
    }
  }

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

  @override
  void dispose() {
    stopAutoRefresh();
    super.dispose();
  }

  String _extractMessage(dynamic e) {
    final s = e.toString();
    if (s.contains('NetworkException')) {
      return 'No internet connection. Check your network.';
    }
    if (s.contains('UnauthorizedException')) {
      return 'Session expired. Please login again.';
    }
    return s.replaceAll('Exception: ', '').replaceAll('ApiException(', '').split('):').last.trim();
  }
}
