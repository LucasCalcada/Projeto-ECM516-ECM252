import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:front_flutter/helpers/api_client.dart';
import 'package:front_flutter/helpers/packages_service.dart';
import 'package:front_flutter/types/api_failure.dart';
import 'package:front_flutter/types/delivery_package.dart';
import 'package:front_flutter/types/user_session.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

final session = UserSession(token: 'token', userId: 'u', buildingId: 'b', buildingName: 'B', residencyId: 'r', permissions: [], expiresAt: DateTime.utc(2100));
const package = {'id': 'p', 'buildingId': 'b', 'residencyId': 'r', 'description': 'Caixa', 'status': 'PENDING', 'createdAt': '2026-11-10T12:00:00Z', 'deliveredAt': null};

void main() {
  test('real routes, token, payload and optional residency names', () async {
    final requests = <http.Request>[];
    final client = MockClient((request) async {
      requests.add(request);
      final value = request.url.path.contains('/building/')
          ? {'residentData': [{'residencies': [{'id': 'r', 'name': '101'}]}]}
          : request.method == 'GET' ? [package] : package;
      return http.Response(jsonEncode(value), 200);
    });
    final service = HttpPackagesService(delivery: ApiClient(client: client, baseUrl: 'http://delivery'), core: ApiClient(client: client, baseUrl: 'http://core'));
    expect((await service.listPackages(session, PackageScope.residency)).single.residencyName, 'r');
    expect(requests.length, 1);
    expect((await service.listPackages(session, PackageScope.building)).single.residencyName, '101');
    await service.createPackage(session, residencyId: 'r', description: ' Caixa ');
    await service.confirmDelivery(session, 'p');
    expect(requests.every((r) => r.headers['Authorization'] == 'Bearer token'), isTrue);
    expect(requests[0].url.queryParameters, {'scope': 'residency'});
    expect(requests[1].url.queryParameters, {'scope': 'building'});
    expect(requests[2].url.path, '/building/b/details');
    expect(jsonDecode(requests[3].body), {'residencyId': 'r', 'description': 'Caixa'});
    expect(requests[4].method, 'PUT');
    expect(jsonDecode(requests[4].body), {'packageId': 'p'});
    client.close();
  });

  test('building list survives core failure and malformed delivery fails', () async {
    final client = MockClient((r) async => r.url.host == 'core' ? http.Response('{}', 403) : http.Response(jsonEncode([package]), 200));
    final service = HttpPackagesService(delivery: ApiClient(client: client, baseUrl: 'http://delivery'), core: ApiClient(client: client, baseUrl: 'http://core'));
    expect((await service.listPackages(session, PackageScope.building)).single.residencyName, 'r');
    client.close();
    final invalid = MockClient((_) async => http.Response('{}', 200));
    final badService = HttpPackagesService(delivery: ApiClient(client: invalid, baseUrl: 'http://delivery'), core: ApiClient(client: invalid, baseUrl: 'http://core'));
    await expectLater(badService.listPackages(session, PackageScope.residency), throwsA(isA<ApiException>().having((e) => e.failure, 'failure', ApiFailure.invalidResponse)));
    invalid.close();
  });
}
