import 'package:complaint_service/src/migration_diagnostics.dart';
import 'package:test/test.dart';

void main() {
  group('migration startup diagnostics', () {
    test('explains missing database and points to root Compose bootstrap', () {
      final diagnostic = describeMigrationDatabaseFailure('3D000');
      expect(diagnostic, contains('SQLSTATE 3D000'));
      expect(diagnostic, contains('O banco configurado não existe'));
      expect(diagnostic, contains('Docker Compose da raiz'));
    });

    test('distinguishes authentication, permissions and schema failures', () {
      for (final code in ['28000', '28P01']) {
        expect(
          describeMigrationDatabaseFailure(code),
          contains('A autenticação no PostgreSQL falhou'),
        );
      }
      expect(
        describeMigrationDatabaseFailure('42501'),
        contains('não possui as permissões necessárias'),
      );
      for (final code in ['42601', '42P01', '42703']) {
        expect(
          describeMigrationDatabaseFailure(code),
          contains('incompatível com o esquema atual'),
        );
      }
      expect(
        describeMigrationDatabaseFailure('57P03'),
        contains('ainda não aceita conexões'),
      );
    });

    test('retains unknown SQLSTATE without inventing a specific cause', () {
      expect(
        describeMigrationDatabaseFailure('XX000'),
        'Migration failed (PostgreSQL SQLSTATE XX000). '
        'Verifique o estado do banco e os logs do PostgreSQL.',
      );
    });

    test('never echoes arbitrary diagnostic input or connection details', () {
      for (final code in [
        null,
        '',
        'postgresql://admin:secret@db/complaintDb',
        '3D000\npassword=secret',
        '3d000',
      ]) {
        final diagnostic = describeMigrationDatabaseFailure(code);
        expect(diagnostic, contains('SQLSTATE unknown'));
        expect(diagnostic, isNot(contains('secret')));
        expect(diagnostic, isNot(contains('postgresql://')));
        expect(diagnostic, isNot(contains('\n')));
      }
    });
  });
}
