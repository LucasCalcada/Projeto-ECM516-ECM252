import 'package:postgres/postgres.dart';

import 'config.dart';

Pool<void> createDatabasePool(AppConfig config) {
  final uri = Uri.parse(config.databaseUrl);
  final sslMode = config.databaseSslMode == 'verifyFull'
      ? 'verify-full'
      : config.databaseSslMode;
  return Pool<void>.withUrl(
    uri
        .replace(
          queryParameters: {
            ...uri.queryParameters,
            'sslmode': sslMode,
            'connect_timeout': uri.queryParameters['connect_timeout'] ?? '10',
            'query_timeout': uri.queryParameters['query_timeout'] ?? '15',
            'max_connection_count':
                uri.queryParameters['max_connection_count'] ?? '10',
          },
        )
        .toString(),
  );
}
