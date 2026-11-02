import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_mobile/core/errors/exceptions.dart';
import 'package:restaurant_mobile/data/providers/auth_provider.dart';
import 'package:restaurant_mobile/data/services/api_service.dart';

void main() {
  test('login with wrong password surfaces the server message', () async {
    try {
      await ApiService.login('waiter@gmail.com', 'definitely-wrong', 'test-device');
      fail('expected an exception');
    } catch (e) {
      // ignore: avoid_print
      print('THROWN: ${e.runtimeType} -> $e');
      // ignore: avoid_print
      print('USER MESSAGE: ${AppException.userMessage(e)}');
      expect(e, isA<UnauthorizedException>());
      expect(AppException.userMessage(e), 'Invalid email or password.');
    }
  });

  test('login with wrong email surfaces the server message', () async {
    try {
      await ApiService.login('nobody@x.com', 'x', 'test-device');
      fail('expected an exception');
    } catch (e) {
      // ignore: avoid_print
      print('THROWN: ${e.runtimeType} -> $e');
      expect(AppException.userMessage(e), isNotEmpty);
    }
  });

  test('AuthProvider sets errorMessage on wrong password', () async {
    final auth = AuthProvider();
    final ok = await auth.login('waiter@gmail.com', 'definitely-wrong');
    // ignore: avoid_print
    print('OK: $ok  errorMessage: ${auth.errorMessage}');
    expect(ok, isFalse);
    expect(auth.errorMessage, isNotNull);
    expect(auth.errorMessage, isNotEmpty);
  });
}
