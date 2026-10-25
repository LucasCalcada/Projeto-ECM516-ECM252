import 'dart:io';

class AppConfig {
  const AppConfig({
    required this.port,
    required this.host,
    required this.databaseUrl,
    required this.jwtSecret,
    required this.databaseSslMode,
  });

  factory AppConfig.fromEnvironment([Map<String, String>? environment]) {
    final values = environment ?? Platform.environment;
    final port = int.tryParse(values['PORT'] ?? '8007');
    if (port == null || port < 1 || port > 65535) {
      throw const FormatException('PORT deve estar entre 1 e 65535.');
    }
    final host = values['HOST'] ?? '0.0.0.0';
    final databaseUrl =
        values['DATABASE_URL'] ??
        'postgresql://admin:adminPasswd@localhost:5432/complaintDb';
    final jwtSecret = values['JWT_SECRET'] ?? 'test-token';
    final sslMode = values['DATABASE_SSL_MODE'] ?? 'disable';
    final databaseUri = Uri.tryParse(databaseUrl);
    if (host.trim().isEmpty || jwtSecret.trim().isEmpty) {
      throw const FormatException('HOST e JWT_SECRET não podem ser vazios.');
    }
    if (databaseUri == null ||
        !{'postgres', 'postgresql'}.contains(databaseUri.scheme) ||
        databaseUri.host.isEmpty ||
        databaseUri.path.length <= 1) {
      throw const FormatException('DATABASE_URL deve apontar para PostgreSQL.');
    }
    if (!{'disable', 'require', 'verifyFull'}.contains(sslMode)) {
      throw const FormatException(
        'DATABASE_SSL_MODE deve ser disable, require ou verifyFull.',
      );
    }
    return AppConfig(
      port: port,
      host: host,
      databaseUrl: databaseUrl,
      jwtSecret: jwtSecret,
      databaseSslMode: sslMode,
    );
  }

  final int port;
  final String host;
  final String databaseUrl;
  final String jwtSecret;
  final String databaseSslMode;
}
