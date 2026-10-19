import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract interface class SessionStorage {
  Future<void> saveAccountToken(String token);
  Future<String?> readAccountToken();
  Future<void> clearSession();
}

class SecureSessionStorage implements SessionStorage {
  const SecureSessionStorage();

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  static const _accountTokenKey = 'accountToken';

  @override
  Future<void> saveAccountToken(String token) =>
      _storage.write(key: _accountTokenKey, value: token);

  @override
  Future<String?> readAccountToken() => _storage.read(key: _accountTokenKey);

  @override
  Future<void> clearSession() => _storage.delete(key: _accountTokenKey);
}
