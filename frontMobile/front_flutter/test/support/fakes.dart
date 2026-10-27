import 'dart:async';
import 'dart:convert';

import 'package:front_flutter/helpers/preferences_storage.dart';
import 'package:front_flutter/helpers/session_storage.dart';

class FakeSessionStorage implements SessionStorage {
  String? token;
  String? userToken;
  int writes = 0;
  int userWrites = 0;
  bool failWrite = false;
  bool failUserWrite = false;
  bool failClear = false;
  Completer<void>? pendingWrite;
  Completer<void>? pendingUserWrite;

  @override
  Future<void> saveAccountToken(String value) async {
    writes++;
    if (failWrite) throw StateError('storage unavailable');
    if (pendingWrite != null) await pendingWrite!.future;
    userToken = null;
    token = value;
  }

  @override
  Future<String?> readAccountToken() async => token;

  @override
  Future<void> saveUserToken(String value) async {
    userWrites++;
    if (failUserWrite) throw StateError('storage unavailable');
    if (pendingUserWrite != null) await pendingUserWrite!.future;
    userToken = value;
  }

  @override
  Future<String?> readUserToken() async => userToken;

  @override
  Future<void> clearSession() async {
    if (failClear) throw StateError('storage unavailable');
    token = null;
    userToken = null;
  }
}

class FakePreferencesStorage implements PreferencesStorage {
  String? language;
  bool failWrite = false;

  @override
  Future<String?> readLanguage() async => language;

  @override
  Future<void> saveLanguage(String value) async {
    if (failWrite) throw StateError('storage unavailable');
    language = value;
  }
}

String userToken({
  List<String> permissions = const ['@reservation:create'],
  DateTime? expiresAt,
  String userId = 'user-1',
  String tokenKind = 'user',
}) {
  String encode(Object value) =>
      base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
  return '${encode({'alg': 'HS256'})}.${encode({'tokenKind': tokenKind, 'userId': userId, 'buildingId': 'building-1', 'buildingName': 'Residencial Jardim das Flores', 'residencyName': 'Apartamento 204', 'permissions': permissions, 'exp': (expiresAt ?? DateTime.now().add(const Duration(hours: 1))).millisecondsSinceEpoch ~/ 1000})}.test-signature';
}

const accountUsers = [
  {
    'userId': 'user-1',
    'userName': 'Maria Silva',
    'buildingId': 'building-1',
    'buildingName': 'Residencial Jardim das Flores',
  },
];

const posts = [
  {
    'id': 'notice-1',
    'title': 'Manutenção dos elevadores',
    'description':
        'A manutenção preventiva será realizada nesta quinta-feira, das 9h às 12h. '
        'Durante esse período, utilize o elevador de serviço. '
        'Nossa equipe estará disponível na portaria para ajudar os moradores.',
    'eventAt': null,
    'createdAt': '2026-10-20T12:00:00Z',
  },
  {
    'id': 'event-1',
    'title': 'Assembleia de moradores',
    'description': 'Encontro no salão de festas para conversar sobre as melhorias do condomínio.',
    'eventAt': '2026-10-25T21:00:00Z',
    'createdAt': '2026-10-19T12:00:00Z',
  },
];
