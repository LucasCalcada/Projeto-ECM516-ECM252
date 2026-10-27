import 'dart:convert';

import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

import 'errors.dart';
import 'models.dart';

final _uuidPattern = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
  caseSensitive: false,
);

/// Accepts Core's raw Authorization JWT and the conventional Bearer form.
AuthContext authenticate(String? authorization, String jwtSecret) {
  if (authorization == null || authorization.length > 8192) {
    throw ApiException.unauthorized;
  }
  var token = authorization.trim();
  if (token.toLowerCase().startsWith('bearer ')) {
    token = token.substring(7).trim();
  }

  try {
    final parts = token.split('.');
    if (parts.length != 3) throw ApiException.unauthorized;
    final header = jsonDecode(
      utf8.decode(base64Url.decode(base64Url.normalize(parts.first))),
    );
    // An explicit allowlist prevents algorithm substitution.
    if (header is! Map || header['alg'] != 'HS256') {
      throw ApiException.unauthorized;
    }
    final jwt = JWT.verify(token, SecretKey(jwtSecret));
    final payload = jwt.payload;
    if (payload is! Map || payload['tokenKind'] != 'user') {
      throw ApiException.unauthorized;
    }
    final expiresAt = payload['exp'];
    if (expiresAt is! num ||
        !expiresAt.isFinite ||
        expiresAt <= DateTime.now().millisecondsSinceEpoch / 1000) {
      throw ApiException.unauthorized;
    }
    final permissions = payload['permissions'];
    if (permissions is! List || permissions.any((p) => p is! String)) {
      throw ApiException.unauthorized;
    }
    final residencyId = payload['residencyId'];
    return AuthContext(
      userId: _uuidClaim(payload['userId']),
      buildingId: _uuidClaim(payload['buildingId']),
      residencyId: residencyId == null ? null : _uuidClaim(residencyId),
      permissions: List<String>.unmodifiable(permissions.cast<String>()),
    );
  } on ApiException {
    rethrow;
  } catch (_) {
    throw ApiException.unauthorized;
  }
}

String _uuidClaim(Object? value) {
  if (value is! String || !_uuidPattern.hasMatch(value)) {
    throw ApiException.unauthorized;
  }
  return value.toLowerCase();
}
