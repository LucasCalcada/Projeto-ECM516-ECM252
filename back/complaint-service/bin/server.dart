import 'dart:async';
import 'dart:io';

import 'package:complaint_service/src/app.dart';
import 'package:complaint_service/src/config.dart';
import 'package:complaint_service/src/database.dart';
import 'package:complaint_service/src/postgres_repository.dart';
import 'package:complaint_service/src/service.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

Future<void> main() async {
  final config = AppConfig.fromEnvironment();
  final repository = PostgresComplaintRepository(createDatabasePool(config));
  HttpServer? server;
  try {
    await repository.health();
    server = await shelf_io.serve(
      createApp(
        service: ComplaintService(repository),
        repository: repository,
        jwtSecret: config.jwtSecret,
      ),
      config.host,
      config.port,
    );
    server.autoCompress = true;
  } catch (_) {
    stderr.writeln(
      'Falha ao iniciar complaint-service. Verifique o banco e as migrações.',
    );
    await repository.close();
    exitCode = 1;
    return;
  }
  stdout.writeln('Complaint-service iniciado em ${config.host}:${server.port}');

  var stopping = false;
  Future<void> shutdown() async {
    if (stopping) return;
    stopping = true;
    await server!.close();
    await repository.close();
    exit(0);
  }

  ProcessSignal.sigint.watch().listen((_) => unawaited(shutdown()));
  if (!Platform.isWindows) {
    ProcessSignal.sigterm.watch().listen((_) => unawaited(shutdown()));
  }
}
