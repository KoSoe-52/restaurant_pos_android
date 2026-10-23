class ApiException implements Exception {
  final String message;
  final int statusCode;

  const ApiException(this.message, this.statusCode);

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

class NetworkException implements Exception {
  final String message;

  const NetworkException(
      [this.message = 'No internet connection. Please check your network.']);

  @override
  String toString() => 'NetworkException: $message';
}
