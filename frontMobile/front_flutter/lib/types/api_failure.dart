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
  const ApiException(this.failure);

  final ApiFailure failure;
}
