import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract interface class PreferencesStorage {
  Future<String?> readLanguage();
  Future<void> saveLanguage(String language);
}

class SecurePreferencesStorage implements PreferencesStorage {
  const SecurePreferencesStorage();

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  @override
  Future<String?> readLanguage() => _storage.read(key: 'language');

  @override
  Future<void> saveLanguage(String language) =>
      _storage.write(key: 'language', value: language);
}
