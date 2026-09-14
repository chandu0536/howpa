class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  const ApiException({
    required this.message,
    this.statusCode,
    this.data,
  });

  @override
  String toString() => 'ApiException: $message (status: $statusCode)';
}

class NetworkException extends ApiException {
  const NetworkException({super.message = 'Please check your internet connection.'})
      : super(statusCode: 0);
}

class UnauthorizedException extends ApiException {
  const UnauthorizedException({super.message = 'Session expired. Please login again.'})
      : super(statusCode: 401);
}

class ServerException extends ApiException {
  const ServerException({super.message = 'Internal server error occurred.'})
      : super(statusCode: 500);
}
