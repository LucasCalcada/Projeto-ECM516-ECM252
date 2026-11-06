import '../types/api_failure.dart';
import '../types/user_session.dart';
import '../types/visitor_access.dart';
import 'api_client.dart';

class VisitorService {
  const VisitorService(this.api);

  final ApiClient api;

  Future<List<VisitorAccess>> list(UserSession session) async {
    if (session.isExpired) {
      throw const ApiException(ApiFailure.unauthorized);
    }
    final result = await api.get('/access', token: session.token);
    try {
      if (result is! List) throw const FormatException();
      return result.map(VisitorAccess.fromJson).toList();
    } on FormatException {
      throw const ApiException(ApiFailure.invalidResponse);
    } on TypeError {
      throw const ApiException(ApiFailure.invalidResponse);
    }
  }

  Future<void> register(
    UserSession session, {
    required String name,
    required String cpf,
    required String rg,
    DateTime? entryAt,
  }) async {
    if (session.isExpired) {
      throw const ApiException(ApiFailure.unauthorized);
    }
    await api.post(
      '/access/register',
      token: session.token,
      body: {
        'name': name,
        'cpf': cpf,
        'rg': rg,
        if (entryAt != null) 'entryAt': entryAt.toUtc().toIso8601String(),
      },
    );
  }
}
