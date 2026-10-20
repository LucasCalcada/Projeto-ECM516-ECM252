import 'package:flutter/foundation.dart';

abstract final class AppConfig {
  static const language = String.fromEnvironment(
    'APP_LANGUAGE',
    defaultValue: 'pt',
  );

  static String get authUrl {
    const configured = String.fromEnvironment('AUTH_URL');
    if (configured.isNotEmpty) return configured;
    return 'http://$_host:8001';
  }

  static String get coreUrl {
    const configured = String.fromEnvironment('CORE_URL');
    return configured.isNotEmpty ? configured : 'http://$_host:8000';
  }

  static String get communicationUrl {
    const configured = String.fromEnvironment('COMMUNICATION_URL');
    return configured.isNotEmpty ? configured : 'http://$_host:8006';
  }

  static String get _host =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android
      ? '10.0.2.2'
      : 'localhost';
}
