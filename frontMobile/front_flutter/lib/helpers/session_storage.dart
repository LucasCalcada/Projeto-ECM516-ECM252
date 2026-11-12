import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SessionSection {
  const SessionSection({
    required this.userId,
    required this.buildingId,
    required this.route,
  });
  final String userId;
  final String buildingId;
  final String route;
}

abstract interface class SessionStorage {
  Future<void> saveAccountToken(String token);
  Future<String?> readAccountToken();
  Future<void> saveUserToken(String token);
  Future<String?> readUserToken();
  Future<void> clearUserToken();
  Future<void> clearSession();
  Future<SessionSection?> readSection();
  Future<void> saveSection(SessionSection section);
  Future<void> clearSection();
}

class SecureSessionStorage implements SessionStorage {
  const SecureSessionStorage();

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  static const _accountTokenKey = 'accountToken';
  static const _userTokenKey = 'userToken';
  static const _sectionKey = 'sessionSection';
  static Future<void> _writes = Future<void>.value();

  // A cleanup always runs after writes already requested, even if one failed.
  Future<void> _write(Future<void> Function() action) {
    final result = _writes.then((_) => action());
    _writes = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }

  @override
  Future<void> saveAccountToken(String token) => _write(() async {
    await _storage.delete(key: _sectionKey);
    await _storage.delete(key: _userTokenKey);
    await _storage.write(key: _accountTokenKey, value: token);
  });

  @override
  Future<String?> readAccountToken() => _storage.read(key: _accountTokenKey);

  @override
  Future<void> saveUserToken(String token) => _write(() async {
    await _storage.delete(key: _sectionKey);
    await _storage.write(key: _userTokenKey, value: token);
  });

  @override
  Future<String?> readUserToken() => _storage.read(key: _userTokenKey);

  @override
  Future<void> clearUserToken() => _write(() async {
    await _storage.delete(key: _sectionKey);
    await _storage.delete(key: _userTokenKey);
  });

  @override
  Future<void> clearSession() => _write(() async {
    await _storage.delete(key: _sectionKey);
    await _storage.delete(key: _userTokenKey);
    await _storage.delete(key: _accountTokenKey);
  });

  @override
  Future<SessionSection?> readSection() async {
    final raw = await _storage.read(key: _sectionKey);
    if (raw == null) return null;
    try {
      final data = jsonDecode(raw);
      if (data is! Map<String, dynamic> ||
          data['userId'] is! String ||
          data['buildingId'] is! String ||
          data['route'] is! String) {
        return null;
      }
      return SessionSection(
        userId: data['userId'],
        buildingId: data['buildingId'],
        route: data['route'],
      );
    } on FormatException {
      return null;
    }
  }

  @override
  Future<void> saveSection(SessionSection section) => _write(
    () => _storage.write(
      key: _sectionKey,
      value: jsonEncode({
        'userId': section.userId,
        'buildingId': section.buildingId,
        'route': section.route,
      }),
    ),
  );

  @override
  Future<void> clearSection() =>
      _write(() => _storage.delete(key: _sectionKey));
}
