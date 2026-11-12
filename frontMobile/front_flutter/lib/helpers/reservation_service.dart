import '../types/api_failure.dart';
import '../types/reservation.dart';
import '../types/user_session.dart';
import 'api_client.dart';

class ReservationService {
  const ReservationService(this.api);
  final ApiClient api;

  void _check(UserSession session) {
    if (session.isExpired) throw const ApiException(ApiFailure.unauthorized);
  }

  Future<List<T>> _list<T>(UserSession session, String path, T Function(Object?) parse, {Map<String, String>? query}) async {
    _check(session);
    final result = await api.get(path, token: session.token, query: query);
    try {
      if (result is! List) throw const FormatException();
      return result.map(parse).toList();
    } on FormatException {
      throw const ApiException(ApiFailure.invalidResponse);
    } on TypeError {
      throw const ApiException(ApiFailure.invalidResponse);
    }
  }

  Future<List<ReservationCommonArea>> commonAreas(UserSession session) =>
      _list(session, '/common-areas', ReservationCommonArea.fromJson);

  Future<List<Reservation>> forArea(UserSession session, String areaId) =>
      _list(session, '/reservations', Reservation.fromJson, query: {'commonAreaId': areaId});

  Future<List<Reservation>> forResidency(UserSession session) =>
      _list(session, '/reservations/my-apartment', Reservation.fromJson);

  Future<Reservation> create(UserSession session, ReservationCommonArea area, DateTime date) async {
    _check(session);
    final result = await api.post('/reservations', token: session.token, body: {
      'commonAreaId': area.id,
      'commonAreaName': area.name,
      'reservationDate': reservationDateString(date),
    });
    try {
      return Reservation.fromJson(result);
    } on FormatException {
      throw const ApiException(ApiFailure.invalidResponse);
    } on TypeError {
      throw const ApiException(ApiFailure.invalidResponse);
    }
  }
}
