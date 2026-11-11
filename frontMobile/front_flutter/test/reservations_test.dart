import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:front_flutter/components/reservations/reservations_header.dart';
import 'package:front_flutter/helpers/api_client.dart';
import 'package:front_flutter/helpers/reservation_service.dart';
import 'package:front_flutter/types/api_failure.dart';
import 'package:front_flutter/types/reservation.dart';
import 'package:front_flutter/types/user_session.dart';
import 'package:front_flutter/views/reservations.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('reservation modes follow React capabilities', () {
    test('create and residence views require a residency', () {
      expect(reservationModes(session(['@reservation:create'])), [ReservationMode.create]);
      expect(reservationModes(session(['@reservation:create'], residency: null)), isEmpty);
      expect(reservationModes(session(['@reservation:view:residency'])), [ReservationMode.residency]);
      expect(reservationModes(session(['@reservation:view:residency'], residency: null)), isEmpty);
    });

    test('building mode does not require a residency', () {
      expect(reservationModes(session(['@reservation:view:building'], residency: null)), [ReservationMode.building]);
    });

    test('admin override preserves create, building, residence order', () {
      expect(reservationModes(session(['@core:admin'])), [ReservationMode.create, ReservationMode.building, ReservationMode.residency]);
      expect(reservationModes(session(['@core:admin'], residency: null)), [ReservationMode.building]);
      expect(reservationModes(session(['@reservation:view:residency', '@reservation:view:building', '@reservation:create'])),
        [ReservationMode.create, ReservationMode.building, ReservationMode.residency]);
    });

    test('unrelated permissions and expired sessions expose no mode', () {
      expect(reservationModes(session(['@visitor:create'])), isEmpty);
      expect(reservationModes(session([])), isEmpty);
      expect(reservationModes(session(['@core:admin'], expires: DateTime.utc(2000))), isEmpty);
    });
  });

  group('reservation calendar dates', () {
    test('civil date retains year, month and day without UTC conversion', () {
      final value = parseReservationDate('2026-11-08')!;
      expect(value.isUtc, isFalse);
      expect([value.year, value.month, value.day], [2026, 11, 8]);
      expect(reservationDateString(DateTime(2026, 11, 8, 23, 59)), '2026-11-08');
      expect(reservationDateString(parseReservationDate('2024-02-29')!), '2024-02-29');
    });

    test('rejects normalized, incomplete and timestamp values', () {
      for (final value in ['2026-02-29', '2026-04-31', '2026-00-08', '2026-13-08', '2026-11-00', '2026-1-08', '08/11/2026', '2026-11-08T00:00:00Z']) {
        expect(parseReservationDate(value), isNull, reason: value);
      }
    });

    test('model maps the actual API fields', () {
      final value = Reservation.fromJson(reservationJson);
      expect(value.commonAreaId, 'area-1');
      expect(value.commonAreaName, 'Salão de festas');
      expect(value.residentName, 'Apartamento 101');
      expect(reservationDateString(value.date), '2026-11-08');
      expect(() => Reservation.fromJson({...reservationJson, 'reservationDate': '2026-02-30'}), throwsFormatException);
      expect(() => ReservationCommonArea.fromJson({'id': 'area-1', 'name': 'Salão', 'limit': '20'}), throwsFormatException);
    });
  });

  test('service uses user token, exact routes, query and civil POST payload', () async {
    final requests = <http.Request>[];
    final service = serviceWith((request) async {
      requests.add(request);
      if (request.url.path == '/common-areas') {
        return jsonResponse([{'id': 'area-1', 'buildingId': 'building-1', 'name': 'Salão de festas', 'limit': 30}]);
      }
      if (request.method == 'POST') return jsonResponse(reservationJson);
      return jsonResponse([reservationJson]);
    });
    final user = session(['@core:admin']);
    final areas = await service.commonAreas(user);
    expect(areas.single.limit, 30);
    expect((await service.forArea(user, 'area-1')).single.id, 'reservation-1');
    expect((await service.forResidency(user)).single.id, 'reservation-1');
    await service.create(user, areas.single, DateTime(2026, 11, 8, 23, 59));
    expect(requests.map((request) => request.method), ['GET', 'GET', 'GET', 'POST']);
    expect(requests.map((request) => request.url.path), ['/common-areas', '/reservations', '/reservations/my-apartment', '/reservations']);
    expect(requests[1].url.queryParameters, {'commonAreaId': 'area-1'});
    expect(requests.every((request) => request.headers['Authorization'] == 'Bearer user-token'), isTrue);
    expect(jsonDecode(requests.last.body), {'commonAreaId': 'area-1', 'commonAreaName': 'Salão de festas', 'reservationDate': '2026-11-08'});
  });

  test('service retains HTTP conflict for the form to refresh occupancy', () async {
    final service = serviceWith((_) async => http.Response('{}', 409));
    await expectLater(service.create(session(['@reservation:create']),
      const ReservationCommonArea(id: 'area-1', name: 'Salão', limit: 30), DateTime(2026, 11, 8)),
      throwsA(isA<ApiException>().having((error) => error.statusCode, 'statusCode', 409)));
  });

  test('expired session never sends an HTTP request', () async {
    var called = false;
    final service = serviceWith((_) async { called = true; return jsonResponse([]); });
    await expectLater(service.forResidency(session(['@reservation:view:residency'], expires: DateTime.utc(2000))),
      throwsA(isA<ApiException>().having((error) => error.failure, 'failure', ApiFailure.unauthorized)));
    expect(called, isFalse);
  });

  test('malformed list responses are explicit failures, not empty lists', () async {
    final service = serviceWith((_) async => jsonResponse({'items': []}));
    await expectLater(service.commonAreas(session(['@reservation:create'])),
      throwsA(isA<ApiException>().having((error) => error.failure, 'failure', ApiFailure.invalidResponse)));
  });
}

const reservationJson = {
  'id': 'reservation-1',
  'residentName': 'Apartamento 101',
  'commonAreaId': 'area-1',
  'commonAreaName': 'Salão de festas',
  'reservationDate': '2026-11-08',
};

UserSession session(List<String> permissions, {String? residency = 'residence-1', DateTime? expires}) => UserSession(
  token: 'user-token', userId: 'user-1', buildingId: 'building-1', buildingName: 'Condomínio',
  residencyId: residency, permissions: permissions, expiresAt: expires ?? DateTime.utc(2100),
);

ReservationService serviceWith(Future<http.Response> Function(http.Request) handler) {
  final client = MockClient(handler);
  addTearDown(client.close);
  return ReservationService(ApiClient(client: client, baseUrl: 'https://example.test'));
}

http.Response jsonResponse(Object value) => http.Response(jsonEncode(value), 200, headers: {'content-type': 'application/json; charset=utf-8'});
