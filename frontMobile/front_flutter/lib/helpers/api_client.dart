import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../types/api_failure.dart';

class ApiClient {
  ApiClient({
    required this.client,
    required String baseUrl,
    this.timeout = const Duration(seconds: 15),
  }) : baseUrl = baseUrl.replaceFirst(RegExp(r'/+$'), '');

  final http.Client client;
  final String baseUrl;
  final Duration timeout;

  Future<Object?> get(
    String path, {
    required String token,
    Map<String, String>? query,
  }) => _send('GET', path, token: token, query: query);

  Future<Object?> post(
    String path, {
    required String token,
    required Object body,
  }) => _send('POST', path, token: token, body: body);

  Future<Object?> _send(
    String method,
    String path, {
    required String token,
    Map<String, String>? query,
    Object? body,
  }) async {
    if (token.isEmpty) {
      throw const ApiException(ApiFailure.unauthorized);
    }
    try {
      final uri = Uri.parse('$baseUrl$path').replace(queryParameters: query);
      final request = http.Request(method, uri)
        ..headers.addAll({
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        });
      if (body != null) {
        request.headers['Content-Type'] = 'application/json; charset=utf-8';
        request.body = jsonEncode(body);
      }
      final response = await http.Response.fromStream(
        await client.send(request).timeout(timeout),
      ).timeout(timeout);
      if (response.statusCode == 401) {
        throw const ApiException(ApiFailure.unauthorized);
      }
      if (response.statusCode == 403) {
        throw const ApiException(ApiFailure.forbidden);
      }
      if (response.statusCode >= 500) {
        throw const ApiException(ApiFailure.server);
      }
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw const ApiException(ApiFailure.invalidResponse);
      }
      if (response.bodyBytes.isEmpty) return null;
      return jsonDecode(utf8.decode(response.bodyBytes));
    } on TimeoutException {
      throw const ApiException(ApiFailure.timeout);
    } on http.ClientException {
      throw const ApiException(ApiFailure.network);
    } on FormatException {
      throw const ApiException(ApiFailure.invalidResponse);
    }
  }
}
