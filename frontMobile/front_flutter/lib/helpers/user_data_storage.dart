import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Local presentation data. Reading it does not authenticate a session.
abstract interface class UserDataStorage {
  Future<Map<String, dynamic>?> readUserData();
  Future<void> saveUserData(Map<String, dynamic> data);
  Future<void> clearUserData();
}

class LocalUserDataStorage implements UserDataStorage {
  LocalUserDataStorage({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const key = 'hive.userData';
  final SharedPreferencesAsync _preferences;

  @override
  Future<Map<String, dynamic>?> readUserData() async {
    final value = await _preferences.getString(key);
    if (value == null) return null;
    final data = jsonDecode(value);
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Invalid stored user data');
    }
    return data;
  }

  @override
  Future<void> saveUserData(Map<String, dynamic> data) =>
      _preferences.setString(key, jsonEncode(data));

  @override
  Future<void> clearUserData() => _preferences.remove(key);
}
