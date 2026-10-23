import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';

import '../models/user_model.dart';
import '../models/settings_model.dart';
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

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  Future<void> checkAuth() async {
    _setLoading(true);
    try {
      final token = await ApiService.getToken();
      if (token == null) {
        _status = AuthStatus.unauthenticated;
        _setLoading(false);
        return;
      }
      _user = await ApiService.me();
      _settings = await ApiService.getSettings();
      _status = AuthStatus.authenticated;
    } catch (_) {
      await ApiService.clearToken();
      _status = AuthStatus.unauthenticated;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _setError(null);
    try {
      final deviceName = await _getDeviceName();
      final result = await ApiService.login(email, password, deviceName);
      _user = result.user;
      _settings = await ApiService.getSettings();
      _status = AuthStatus.authenticated;
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString().replaceFirst('Exception: ', '').replaceFirst('ApiException(', '').split('):').last.trim());
      _setLoading(false);
      return false;
    }
  }

  Future<void> logout() async {
    _setLoading(true);
    await ApiService.logout();
    _user = null;
    _status = AuthStatus.unauthenticated;
    _setLoading(false);
  }

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
    return 'flutter-waiter-app';
  }
}
