import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../types/auth_result.dart';

class AuthService {
  AuthService({
    required this.client,
    required String baseUrl,
    this.timeout = const Duration(seconds: 15),
  }) : loginUri = Uri.parse(
         '${baseUrl.replaceFirst(RegExp(r'/+$'), '')}/auth/login',
       );

  final http.Client client;
  final Uri loginUri;
  final Duration timeout;

  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await client
          .post(
            loginUri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(timeout);

      if (response.statusCode == 401) {
        throw const AuthException(AuthFailure.invalidCredentials);
      }
      if (response.statusCode == 400) {
        throw const AuthException(AuthFailure.invalidRequest);
      }
      if (response.statusCode >= 500) {
        throw const AuthException(AuthFailure.server);
      }
      if (response.statusCode != 200) {
        throw const AuthException(AuthFailure.invalidResponse);
      }

      return AuthResult.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
    } on TimeoutException {
      throw const AuthException(AuthFailure.timeout);
    } on http.ClientException {
      throw const AuthException(AuthFailure.network);
    } on FormatException {
      throw const AuthException(AuthFailure.invalidResponse);
    }
  }
}
