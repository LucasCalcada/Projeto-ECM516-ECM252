import '../types/api_failure.dart';
import '../types/resident.dart';
import '../types/user_session.dart';
import 'api_client.dart';

class ResidentsService {
  const ResidentsService(this.api);
  final ApiClient api;

  void _authorize(UserSession session) {
    if (session.isExpired) throw const ApiException(ApiFailure.unauthorized);
    if (!session.allows(['@core:user:manage'])) {
      throw const ApiException(ApiFailure.forbidden);
    }
  }

  Future<List<T>> _list<T>(UserSession session, String path, String key, T Function(Object?) parse) async {
    _authorize(session);
    try {
      final result = await api.get(path, token: session.token);
      if (result is! Map<String, dynamic> || result[key] is! List) {
        throw const FormatException('Invalid resident list');
      }
      return (result[key] as List).map(parse).toList();
    } on ApiException catch (error) {
      // Core represents an empty group/residency list as HTTP 404.
      if (error.statusCode == 404) return [];
      rethrow;
    } on FormatException {
      throw const ApiException(ApiFailure.invalidResponse);
    } on TypeError {
      throw const ApiException(ApiFailure.invalidResponse);
    }
  }

  Future<List<ResidentGroup>> groups(UserSession session) =>
      _list(session, '/groups', 'groups', ResidentGroup.fromJson);

  Future<List<ResidentResidency>> residencies(UserSession session, String groupId) =>
      _list(session, '/residencies/list/${Uri.encodeComponent(groupId)}', 'residencies', ResidentResidency.fromJson);

  Future<List<Resident>> residents(UserSession session, String residencyId) =>
      _list(session, '/residencies/${Uri.encodeComponent(residencyId)}/users', 'users', Resident.fromJson);

  Future<Resident> detail(UserSession session, String userId) async {
    _authorize(session);
    final result = await api.get('/user/${Uri.encodeComponent(userId)}', token: session.token);
    return _resident(result);
  }

  Future<Resident> update(UserSession session, String userId, {
    required String name,
    required List<String> permissions,
  }) async {
    _authorize(session);
    final result = await api.put(
      '/user/${Uri.encodeComponent(userId)}',
      token: session.token,
      body: {
        'name': name.trim(),
        if (userId != session.userId)
          'permissions': permissions.map((value) => value.trim()).where((value) => value.isNotEmpty).toSet().toList(),
      },
    );
    return _resident(result);
  }

  Resident _resident(Object? value) {
    try {
      if (value is! Map<String, dynamic>) throw const FormatException('Invalid resident response');
      return Resident.fromJson(value['user']);
    } on FormatException {
      throw const ApiException(ApiFailure.invalidResponse);
    } on TypeError {
      throw const ApiException(ApiFailure.invalidResponse);
    }
  }
}
