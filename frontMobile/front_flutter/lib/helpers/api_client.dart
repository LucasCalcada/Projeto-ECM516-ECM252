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
  }) => _request('GET', path, token: token, query: query);

  Future<Object?> post(
    String path, {
    required String token,
    required Map<String, Object?> body,
  }) => _request('POST', path, token: token, body: body);

  Future<Object?> patch(
    String path, {
    required String token,
    required Map<String, Object?> body,
  }) => _request('PATCH', path, token: token, body: body);

  Future<Object?> put(
    String path, {
    required String token,
    required Map<String, Object?> body,
  }) => _request('PUT', path, token: token, body: body);

  Future<Object?> _request(
    String method,
    String path, {
    required String token,
    Map<String, String>? query,
    Map<String, Object?>? body,
  }) async {
    if (token.isEmpty) {
      throw const ApiException(ApiFailure.unauthorized);
    }
    try {
      final uri = Uri.parse('$baseUrl$path').replace(queryParameters: query);
      final headers = {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        if (body != null) 'Content-Type': 'application/json',
      };
      final response = await (switch (method) {
        'POST' => client.post(uri, headers: headers, body: jsonEncode(body)),
        'PATCH' => client.patch(uri, headers: headers, body: jsonEncode(body)),
        'PUT' => client.put(uri, headers: headers, body: jsonEncode(body)),
        _ => client.get(uri, headers: headers),
      }).timeout(timeout);
      String? code;
      if (response.statusCode >= 400) {
        try {
          final value = jsonDecode(utf8.decode(response.bodyBytes));
          if (value is Map && value['error'] is Map) {
            final rawCode = (value['error'] as Map)['code'];
            if (rawCode is String) code = rawCode;
          }
        } on FormatException {
          /* Status still determines the failure. */
        }
      }
      Never fail(ApiFailure failure) => throw ApiException(
        failure,
        statusCode: response.statusCode,
        code: code,
      );
      if (response.statusCode == 401) {
        fail(ApiFailure.unauthorized);
      }
      if (response.statusCode == 403) {
        fail(ApiFailure.forbidden);
      }
      if (response.statusCode >= 500) {
        fail(ApiFailure.server);
      }
      if (response.statusCode != 200 &&
          !(method == 'POST' && response.statusCode == 201)) {
        fail(ApiFailure.invalidResponse);
      }
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
