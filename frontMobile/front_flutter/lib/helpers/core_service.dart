import '../types/account_user.dart';
import '../types/api_failure.dart';
import '../types/user_session.dart';
import 'api_client.dart';

class CoreService {
  const CoreService(this.api);

  final ApiClient api;

  Future<List<AccountUser>> listUsers(String accountToken) async {
    final result = await api.get('/account', token: accountToken);
    try {
      if (result is! List) throw const FormatException();
      return result.map(AccountUser.fromJson).toList();
    } on FormatException {
      throw const ApiException(ApiFailure.invalidResponse);
    } on TypeError {
      throw const ApiException(ApiFailure.invalidResponse);
    }
  }

  Future<UserSession> selectUser(String accountToken, AccountUser user) async {
    final result = await api.get(
      '/auth',
      token: accountToken,
      query: {'userId': user.userId},
    );
    try {
      if (result is! Map<String, dynamic> || result['token'] is! String) {
        throw const FormatException();
      }
      final session = UserSession.fromToken(result['token'] as String);
      if (session.userId != user.userId ||
          (user.buildingId != null && session.buildingId != user.buildingId)) {
        throw const FormatException();
      }
      if (session.isExpired) {
        throw const ApiException(ApiFailure.unauthorized);
      }
      return session;
    } on FormatException {
      throw const ApiException(ApiFailure.invalidResponse);
    } on TypeError {
      throw const ApiException(ApiFailure.invalidResponse);
    } on ArgumentError {
      throw const ApiException(ApiFailure.invalidResponse);
    }
  }
}
