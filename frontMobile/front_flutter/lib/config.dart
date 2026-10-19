import 'package:flutter/foundation.dart';

abstract final class AppConfig {
  static const language = String.fromEnvironment(
    'APP_LANGUAGE',
    defaultValue: 'pt',
  );

  static String get authUrl {
    const configured = String.fromEnvironment('AUTH_URL');
    if (configured.isNotEmpty) return configured;
    final host = !kIsWeb && defaultTargetPlatform == TargetPlatform.android
        ? '10.0.2.2'
        : 'localhost';
    return 'http://$host:8001';
  }
}
