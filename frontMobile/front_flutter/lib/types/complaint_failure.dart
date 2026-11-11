enum ComplaintFailure {
  validation,
  forbidden,
  notFound,
  conflict,
  network,
  server,
  invalidResponse,
}

class ComplaintException implements Exception {
  const ComplaintException(this.failure, {this.code});
  final ComplaintFailure failure;
  final String? code;
}

/// Raised by the host adapter when its authenticated session is no longer valid.
class ComplaintSessionExpired implements Exception {
  const ComplaintSessionExpired();
}
