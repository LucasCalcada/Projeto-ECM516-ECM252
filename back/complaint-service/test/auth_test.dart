import 'package:complaint_service/src/auth.dart';
import 'package:complaint_service/src/config.dart';
import 'package:complaint_service/src/errors.dart';
import 'package:complaint_service/src/models.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:test/test.dart';

const _secret = 'complaints-test-secret';
const _user = '11111111-1111-4111-8111-111111111111';
const _building = '22222222-2222-4222-8222-222222222222';
const _residency = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';

Map<String, Object?> _claims() => {
  'tokenKind': 'user',
  'userId': _user,
  'buildingId': _building,
  'residencyId': _residency,
  'permissions': <String>[],
  'exp':
      DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/
      1000,
};

String _sign(
  Map<String, Object?> claims, {
  String secret = _secret,
  JWTAlgorithm algorithm = JWTAlgorithm.HS256,
}) => JWT(claims).sign(SecretKey(secret), algorithm: algorithm);

final _unauthorized = throwsA(
  isA<ApiException>().having((e) => e.statusCode, 'statusCode', 401),
);

void main() {
  group('authentication', () {
    test('accepts Core raw JWT and Bearer JWT', () {
      final token = _sign(_claims());
      for (final header in [token, 'Bearer $token', 'bearer $token']) {
        final actor = authenticate(header, _secret);
        expect(actor.userId, _user);
        expect(actor.buildingId, _building);
        expect(actor.residencyId, _residency);
        expect(actor.canManage, isFalse);
      }
    });

    test('recognizes management permission and canonicalizes UUIDs', () {
      final claims = _claims()
        ..['residencyId'] = _residency.toUpperCase()
        ..['permissions'] = [manageComplaintsPermission];
      final actor = authenticate(_sign(claims), _secret);
      expect(actor.canManage, isTrue);
      expect(actor.residencyId, _residency);
    });

    test('permits an administrator without a residency claim', () {
      final claims = _claims()..remove('residencyId');
      expect(authenticate(_sign(claims), _secret).residencyId, isNull);
    });

    test('rejects missing, malformed and incorrectly signed tokens', () {
      for (final token in [
        null,
        '',
        'abc',
        'Bearer ',
        'a.b.c',
        _sign(_claims(), secret: 'incorrect-secret'),
      ]) {
        expect(() => authenticate(token, _secret), _unauthorized);
      }
    });

    test('accepts only HS256 even when another HMAC signature is valid', () {
      final token = _sign(_claims(), algorithm: JWTAlgorithm.HS384);
      expect(() => authenticate(token, _secret), _unauthorized);
    });

    test('requires user token kind and valid UUID claims', () {
      for (final entry in <MapEntry<String, Object?>>[
        const MapEntry('tokenKind', 'account'),
        const MapEntry('tokenKind', null),
        const MapEntry('userId', 'bad-id'),
        const MapEntry('buildingId', null),
        const MapEntry('residencyId', 'bad-id'),
      ]) {
        final claims = _claims()..[entry.key] = entry.value;
        expect(() => authenticate(_sign(claims), _secret), _unauthorized);
      }
    });

    test('requires a string list of permissions', () {
      for (final permissions in [
        null,
        'admin',
        [1],
      ]) {
        final claims = _claims()..['permissions'] = permissions;
        expect(() => authenticate(_sign(claims), _secret), _unauthorized);
      }
    });

    test(
      'requires expiration and rejects expired or not-yet-active tokens',
      () {
        final missingExpiry = _claims()..remove('exp');
        final expired = _claims()..['exp'] = 1;
        final future = _claims()
          ..['nbf'] =
              DateTime.now()
                  .add(const Duration(hours: 1))
                  .millisecondsSinceEpoch ~/
              1000;
        for (final claims in [missingExpiry, expired, future]) {
          expect(() => authenticate(_sign(claims), _secret), _unauthorized);
        }
      },
    );
  });

  group('environment configuration', () {
    test('provides repository-compatible local defaults', () {
      final config = AppConfig.fromEnvironment({});
      expect(config.port, 8007);
      expect(config.host, '0.0.0.0');
      expect(
        config.databaseUrl,
        'postgresql://admin:adminPasswd@localhost:5432/complaintDb',
      );
      expect(config.jwtSecret, 'test-token');
      expect(config.databaseSslMode, 'disable');
    });

    test('loads explicit database, port and TLS settings', () {
      final config = AppConfig.fromEnvironment({
        'PORT': '8010',
        'HOST': '127.0.0.1',
        'DATABASE_URL': 'postgresql://user:pass@db:5432/complaints',
        'JWT_SECRET': _secret,
        'DATABASE_SSL_MODE': 'verifyFull',
      });
      expect(config.port, 8010);
      expect(config.host, '127.0.0.1');
      expect(config.jwtSecret, _secret);
      expect(config.databaseSslMode, 'verifyFull');
    });

    test('rejects invalid configuration without exposing credentials', () {
      for (final environment in [
        {'PORT': 'zero'},
        {'PORT': '0'},
        {'PORT': '65536'},
        {'HOST': ''},
        {'JWT_SECRET': ''},
        {'DATABASE_URL': 'http://db/complaints'},
        {'DATABASE_SSL_MODE': 'invalid'},
      ]) {
        expect(
          () => AppConfig.fromEnvironment(environment),
          throwsFormatException,
        );
      }
    });
  });
}
