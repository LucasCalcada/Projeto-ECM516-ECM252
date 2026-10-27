import 'dart:io';

import 'package:postgres/postgres.dart';

import 'package:complaint_service/src/config.dart';
import 'package:complaint_service/src/database.dart';
import 'package:complaint_service/src/migration_diagnostics.dart';

Future<void> main() async {
  Pool<dynamic>? pool;
  try {
    pool = createDatabasePool(AppConfig.fromEnvironment());
    final migration = await File.fromUri(
      Platform.script.resolve('../migrations/001_initial.sql'),
    ).readAsString();
    await pool.runTx((session) async {
      // Serialize concurrent startup migrations of this service.
      await session.execute('SELECT pg_advisory_xact_lock(8007001)');
      // Simple query protocol accepts the complete migration in one execution.
      await session.execute(migration, queryMode: QueryMode.simple);
    });
    stdout.writeln('Complaint service migration applied.');
  } on ServerException catch (error) {
    stderr.writeln(describeMigrationDatabaseFailure(error.code));
    exitCode = 1;
  } on Object catch (error) {
    // Avoid printing credentials from a malformed DATABASE_URL.
    stderr.writeln('Migration failed (${error.runtimeType}).');
    exitCode = 1;
  } finally {
    await pool?.close();
  }
}
