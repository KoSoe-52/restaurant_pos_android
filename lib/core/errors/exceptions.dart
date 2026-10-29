class AppException implements Exception {
  final String message;
  const AppException(this.message);

  @override
  String toString() => message;

  /// Returns a clean, user-friendly message from any thrown value.
  static String userMessage(dynamic error) {
    if (error is NetworkException) return error.message;
    if (error is UnauthorizedException) return error.message;
    if (error is ValidationException) return error.firstError;
    if (error is ApiException) return error.message;
    if (error is AppException) return error.message;
    final s = error.toString();
    // Strip internal exception class prefixes if they leaked through
    for (final prefix in [
      'Exception: ',
      'ApiException(',
      'NetworkException: ',
      'UnauthorizedException: ',
    ]) {
      if (s.startsWith(prefix)) return s.substring(prefix.length).trim();
    }
    // Remove "nnn): " suffix pattern left by ApiException.toString
    final parenIdx = s.indexOf('):');
    if (parenIdx >= 0 && parenIdx < s.length - 2) {
      return s.substring(parenIdx + 2).trim();
    }
    return s.isNotEmpty ? s : 'An unexpected error occurred.';
  }
}

class ApiException extends AppException {
  final int statusCode;

  const ApiException(super.message, this.statusCode);

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class UnauthorizedException extends ApiException {
  const UnauthorizedException()
      : super('Session expired. Please login again.', 401);
}

class ForbiddenException extends ApiException {
  const ForbiddenException(String message) : super(message, 403);
}

class NotFoundException extends ApiException {
  const NotFoundException([String message = 'Resource not found'])
      : super(message, 404);
}

class ValidationException extends ApiException {
  final Map<String, List<String>> errors;

  const ValidationException(String message, this.errors)
      : super(message, 422);

  String get firstError {
    if (errors.isEmpty) return message;
    return errors.values.first.firstOrNull ?? message;
  }
}

class ServerException extends ApiException {
  const ServerException([String message = 'Server error. Please try again.'])
      : super(message, 500);
}

class NetworkException extends AppException {
  const NetworkException(
      [super.message = 'No internet connection. Please check your network.']);

  @override
  String toString() => 'NetworkException: $message';
}
