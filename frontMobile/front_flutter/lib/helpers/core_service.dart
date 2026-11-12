import '../types/account_user.dart';
import '../types/api_failure.dart';
import '../types/residency_group.dart';
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

  Future<String> selectUser(String accountToken, AccountUser user) async {
    final result = await api.get(
      '/auth',
      token: accountToken,
      query: {'userId': user.userId},
    );
    try {
      if (result is! Map<String, dynamic> || result['token'] is! String) {
        throw const FormatException();
      }
      return result['token'] as String;
    } on FormatException {
      throw const ApiException(ApiFailure.invalidResponse);
    } on TypeError {
      throw const ApiException(ApiFailure.invalidResponse);
    } on ArgumentError {
      throw const ApiException(ApiFailure.invalidResponse);
    }
  }

  /// Residencies of the session's building, used to address notifications.
  Future<List<ResidencyGroup>> listResidencies(UserSession session) async {
    if (session.isExpired) {
      throw const ApiException(ApiFailure.unauthorized);
    }
    final result = await api.get(
      '/building/${Uri.encodeComponent(session.buildingId)}/details',
      token: session.token,
    );
    try {
      return ResidencyGroup.listFromBuildingDetails(result);
    } on FormatException {
      throw const ApiException(ApiFailure.invalidResponse);
    } on TypeError {
      throw const ApiException(ApiFailure.invalidResponse);
    }
  }
}
