class AuthResult {
  const AuthResult({required this.token});

  final String token;

  factory AuthResult.fromJson(Object? json) {
    if (json is Map<String, dynamic>) {
      final token = json['token'];
      if (token is String && token.trim().isNotEmpty) {
        return AuthResult(token: token);
      }
    }
    throw const AuthException(AuthFailure.invalidResponse);
  }
}

enum AuthFailure {
  invalidCredentials,
  invalidRequest,
  server,
  network,
  timeout,
  invalidResponse,
  storage,
  unexpected,
}

class AuthException implements Exception {
  const AuthException(this.failure);

  final AuthFailure failure;
}
