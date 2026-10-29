import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

import '../../core/constants/app_constants.dart';
import '../../core/errors/exceptions.dart';
import '../models/settings_model.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  AuthStatus _status = AuthStatus.unknown;
  WaiterUser? _user;
  RestaurantSettings _settings = RestaurantSettings.defaultSettings;
  String? _errorMessage;
  bool _isLoading = false;

  AuthStatus get status => _status;
  WaiterUser? get user => _user;
  RestaurantSettings get settings => _settings;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  // ── Private helpers ────────────────────────────────────────────────────

  void _update({
    AuthStatus? status,
    WaiterUser? user,
    RestaurantSettings? settings,
    bool? loading,
    String? error,
    bool clearError = false,
  }) {
    if (status != null) _status = status;
    if (user != null) _user = user;
    if (settings != null) _settings = settings;
    if (loading != null) _isLoading = loading;
    if (clearError) _errorMessage = null;
    if (error != null) _errorMessage = error;
    notifyListeners();
  }

  // ── Auth operations ────────────────────────────────────────────────────

  Future<void> checkAuth() async {
    _update(loading: true);
    try {
      final token = await ApiService.getToken();
      if (token == null) {
        _update(status: AuthStatus.unauthenticated, loading: false);
        return;
      }
      final user = await ApiService.me();
      final settings = await ApiService.getSettings();
      _update(
        status: AuthStatus.authenticated,
        user: user,
        settings: settings,
        loading: false,
      );
    } catch (e) {
      await ApiService.clearToken();
      _update(status: AuthStatus.unauthenticated, loading: false);
    }
  }

  Future<bool> login(String email, String password) async {
    _update(loading: true, clearError: true);
    debugPrint('[AUTH] login attempt: $email');
    try {
      final deviceName = await _getDeviceName();
      final result = await ApiService.login(email, password, deviceName);
      final settings = await ApiService.getSettings();
      _update(
        status: AuthStatus.authenticated,
        user: result.user,
        settings: settings,
        loading: false,
      );
      debugPrint('[AUTH] login success: ${result.user.name} (${result.user.role})');
      return true;
    } catch (e) {
      debugPrint('[AUTH] login failed: $e');
      _update(loading: false, error: AppException.userMessage(e));
      return false;
    }
  }

  Future<void> logout() async {
    _update(loading: true);
    await ApiService.logout();
    _user = null;
    _settings = RestaurantSettings.defaultSettings;
    _update(status: AuthStatus.unauthenticated, loading: false);
  }

  // ── Device name ────────────────────────────────────────────────────────

  Future<String> _getDeviceName() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final info = await deviceInfo.androidInfo;
        return 'android-${info.model.replaceAll(' ', '-').toLowerCase()}';
      } else if (Platform.isIOS) {
        final info = await deviceInfo.iosInfo;
        return 'ios-${info.name.replaceAll(' ', '-').toLowerCase()}';
      }
    } catch (_) {}
    return AppConstants.defaultDeviceName;
  }
}
