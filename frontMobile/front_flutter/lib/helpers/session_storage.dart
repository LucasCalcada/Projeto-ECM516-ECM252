import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract interface class SessionStorage {
  Future<void> saveAccountToken(String token);
  Future<String?> readAccountToken();
  Future<void> saveUserToken(String token);
  Future<String?> readUserToken();
  Future<void> clearSession();
}

class SecureSessionStorage implements SessionStorage {
  const SecureSessionStorage();

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  static const _accountTokenKey = 'accountToken';
  static const _userTokenKey = 'userToken';

  @override
  Future<void> saveAccountToken(String token) async {
    await _storage.delete(key: _userTokenKey);
    await _storage.write(key: _accountTokenKey, value: token);
  }

  @override
  Future<String?> readAccountToken() => _storage.read(key: _accountTokenKey);

  @override
  Future<void> saveUserToken(String token) =>
      _storage.write(key: _userTokenKey, value: token);

  @override
  Future<String?> readUserToken() => _storage.read(key: _userTokenKey);

  @override
  Future<void> clearSession() async {
    await _storage.delete(key: _userTokenKey);
    await _storage.delete(key: _accountTokenKey);
  }
}
