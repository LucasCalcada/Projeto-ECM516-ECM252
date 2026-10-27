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
  }) async {
    if (token.isEmpty) {
      throw const ApiException(ApiFailure.unauthorized);
    }
    try {
      final uri = Uri.parse('$baseUrl$path').replace(queryParameters: query);
      final response = await client
          .get(
            uri,
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
            },
          )
          .timeout(timeout);
      if (response.statusCode == 401) {
        throw const ApiException(ApiFailure.unauthorized);
      }
      if (response.statusCode == 403) {
        throw const ApiException(ApiFailure.forbidden);
      }
      if (response.statusCode >= 500) {
        throw const ApiException(ApiFailure.server);
      }
      if (response.statusCode != 200) {
        throw const ApiException(ApiFailure.invalidResponse);
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
