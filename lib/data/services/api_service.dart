import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../../core/constants/app_constants.dart';
import '../../core/errors/exceptions.dart';
import '../models/category_model.dart';
import '../models/order_model.dart';
import '../models/product_model.dart';
import '../models/settings_model.dart';
import '../models/table_model.dart';
import '../models/user_model.dart';

class ApiService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static final _client = http.Client();

  // ── Token management ────────────────────────────────────────────────────

  static Future<String?> getToken() => _storage.read(key: AppConstants.tokenKey);

  static Future<void> saveToken(String token) =>
      _storage.write(key: AppConstants.tokenKey, value: token);

  static Future<void> clearToken() =>
      _storage.delete(key: AppConstants.tokenKey);

  // ── HTTP headers ────────────────────────────────────────────────────────

  static Future<Map<String, String>> _headers({bool auth = true}) async {
    final h = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (auth) {
      final token = await getToken();
      if (token != null) h['Authorization'] = 'Bearer $token';
    }
    return h;
  }

  // ── Response handler ────────────────────────────────────────────────────

  static dynamic _handleResponse(http.Response response) {
    dynamic body;
    try {
      body = jsonDecode(utf8.decode(response.bodyBytes));
    } catch (_) {
      throw ApiException('Invalid server response', response.statusCode);
    }

    final msg = body is Map ? body['message'] as String? : null;

    switch (response.statusCode) {
      case 200:
      case 201:
      case 204:
        return body;
      case 401:
        throw const UnauthorizedException();
      case 403:
        throw ForbiddenException(msg ?? 'Access denied');
      case 404:
        throw NotFoundException(msg ?? 'Not found');
      case 422:
        final errors = <String, List<String>>{};
        if (body is Map && body['errors'] != null) {
          (body['errors'] as Map).forEach((k, v) {
            errors[k.toString()] = List<String>.from(v as Iterable);
          });
        }
        throw ValidationException(msg ?? 'Validation failed', errors);
      default:
        throw ApiException(msg ?? 'Server error (${response.statusCode})', response.statusCode);
    }
  }

  // ── Base transport ──────────────────────────────────────────────────────

  static Future<dynamic> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
    bool auth = true,
  }) async {
    final url = '${AppConstants.baseUrl}$path';
    final sw = Stopwatch()..start();
    debugPrint('[API] → $method $url');
    try {
      final request = http.Request(method, Uri.parse(url))
        ..headers.addAll(await _headers(auth: auth));
      if (body != null) request.body = jsonEncode(body);

      final streamed = await _client
          .send(request)
          .timeout(AppConstants.requestTimeout);
      final response = await http.Response.fromStream(streamed);
      debugPrint(
          '[API] ← ${response.statusCode} $method $path (${sw.elapsedMilliseconds}ms)');
      return _handleResponse(response);
    } on SocketException catch (e) {
      debugPrint('[API] ✗ $method $path — socket: $e');
      throw const NetworkException();
    } on HttpException catch (e) {
      debugPrint('[API] ✗ $method $path — http: $e');
      throw const NetworkException('Connection failed. Please try again.');
    } on TimeoutException {
      debugPrint(
          '[API] ✗ $method $path — timed out after ${AppConstants.requestTimeout.inSeconds}s');
      throw const NetworkException('Request timed out. Please try again.');
    } on ApiException {
      rethrow;
    } on NetworkException {
      rethrow;
    } catch (e) {
      debugPrint('[API] ✗ $method $path — unexpected: $e');
      throw ApiException(e.toString(), 0);
    }
  }

  static Future<dynamic> get(String path) => _send('GET', path);

  static Future<dynamic> post(
    String path, {
    Map<String, dynamic>? body,
    bool auth = true,
  }) =>
      _send('POST', path, body: body, auth: auth);

  static Future<dynamic> patch(
    String path, {
    Map<String, dynamic>? body,
  }) =>
      _send('PATCH', path, body: body);

  static Future<dynamic> delete(
    String path, {
    Map<String, dynamic>? body,
  }) =>
      _send('DELETE', path, body: body);

  // ── Auth ─────────────────────────────────────────────────────────────────

  static Future<LoginResponse> login(
    String email,
    String password,
    String deviceName,
  ) async {
    final body = await post(
      '/auth/login',
      body: {'email': email, 'password': password, 'device_name': deviceName},
      auth: false,
    );
    final result = LoginResponse.fromJson(body);
    await saveToken(result.token);
    return result;
  }

  static Future<void> logout() async {
    try {
      await post('/auth/logout');
    } catch (_) {}
    await clearToken();
  }

  static Future<WaiterUser> me() async {
    final body = await get('/auth/me');
    return WaiterUser.fromJson(body['user']);
  }

  // ── Reference data ────────────────────────────────────────────────────────

  static Future<List<RestaurantTable>> getTables() async {
    final body = await get('/tables');
    return (body['tables'] as List)
        .map((e) => RestaurantTable.fromJson(e))
        .toList();
  }

  static Future<List<ProductCategory>> getCategories() async {
    final body = await get('/categories');
    return (body['categories'] as List)
        .map((e) => ProductCategory.fromJson(e))
        .toList();
  }

  static Future<PaginatedProducts> getProducts({
    int? categoryId,
    String? search,
    int page = 1,
    int perPage = AppConstants.defaultPerPage,
  }) async {
    final params = <String, String>{
      'page': '$page',
      'per_page': '$perPage',
    };
    if (categoryId != null) params['category_id'] = '$categoryId';
    if (search != null && search.isNotEmpty) params['search'] = search;
    final query = Uri(queryParameters: params).query;
    final body = await get('/products?$query');
    return PaginatedProducts.fromJson(body);
  }

  static Future<RestaurantSettings> getSettings() async {
    final body = await get('/settings/public');
    return RestaurantSettings.fromJson(body);
  }

  // ── Orders ────────────────────────────────────────────────────────────────

  static Future<PaginatedOrders> getOrders({
    String? status,
    bool myOrders = false,
    int? tableId,
    String? date,
    int page = 1,
    int perPage = AppConstants.ordersPerPage,
  }) async {
    final params = <String, String>{
      'page': '$page',
      'per_page': '$perPage',
    };
    if (status != null) params['status'] = status;
    if (myOrders) params['my'] = '1';
    if (tableId != null) params['table_id'] = '$tableId';
    if (date != null) params['date'] = date;
    final query = Uri(queryParameters: params).query;
    final body = await get('/orders?$query');
    return PaginatedOrders.fromJson(body);
  }

  static Future<Order> getOrder(int id) async {
    final body = await get('/orders/$id');
    return Order.fromJson(body);
  }

  static Future<Order> createOrder({
    int? tableId,
    String? customerName,
    String? customerPhone,
    String? note,
    required List<Map<String, dynamic>> items,
  }) async {
    final payload = <String, dynamic>{'items': items};
    if (tableId != null) payload['table_id'] = tableId;
    if (customerName != null && customerName.isNotEmpty) {
      payload['customer_name'] = customerName;
    }
    if (customerPhone != null && customerPhone.isNotEmpty) {
      payload['customer_phone'] = customerPhone;
    }
    if (note != null && note.isNotEmpty) payload['note'] = note;

    final body = await post('/orders', body: payload);
    return Order.fromJson(body);
  }

  static Future<Order> addItems(
    int orderId,
    List<Map<String, dynamic>> items,
  ) async {
    final body = await patch('/orders/$orderId', body: {'items': items});
    return Order.fromJson(body);
  }

  static Future<Order> serveOrder(int orderId) async {
    final body = await post('/orders/$orderId/serve');
    return Order.fromJson(body);
  }

  static Future<void> voidOrder(int orderId, String reason) async {
    await post('/orders/$orderId/void', body: {'void_reason': reason});
  }

  static Future<Order> voidItem(
    int orderId,
    int itemId,
    String reason,
  ) async {
    final body = await post(
      '/orders/$orderId/items/$itemId/void',
      body: {'void_reason': reason},
    );
    return Order.fromJson(body);
  }

  // ── Print jobs ────────────────────────────────────────────────────────────

  static Future<void> retryPrintJob(int jobId) async {
    await post('/print-jobs/$jobId/retry');
  }
}
