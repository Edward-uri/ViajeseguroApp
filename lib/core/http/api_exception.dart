class ApiException implements Exception {
  ApiException(this.message, {this.statusCode, this.details});

  final String message;

  final int? statusCode;

  final Object? details;

  @override
  String toString() =>
      'ApiException(status: $statusCode, message: $message, details: $details)';
}

class NetworkException extends ApiException {
  NetworkException(super.message);
}

class UnauthorizedException extends ApiException {
  UnauthorizedException(super.message) : super(statusCode: 401);
}

class ValidationException extends ApiException {
  ValidationException(super.message, {super.details})
      : super(statusCode: 400);
}
