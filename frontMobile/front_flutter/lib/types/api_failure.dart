enum ApiFailure {
  unauthorized,
  forbidden,
  network,
  timeout,
  server,
  invalidResponse,
  storage,
  unexpected,
}

class ApiException implements Exception {
  const ApiException(this.failure, {this.statusCode, this.code});

  final ApiFailure failure;
  final int? statusCode;
  final String? code;
}
