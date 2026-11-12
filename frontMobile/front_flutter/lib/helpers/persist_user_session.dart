import '../types/account_user.dart';
import '../types/api_failure.dart';
import '../types/user_session.dart';
import 'session_storage.dart';


/// Decode once, validate the selected membership, then persist before publishing.
Future<UserSession> persistUserSession(
  String token, {
  required AccountUser selectedUser,
  required SessionStorage sessionStorage,

}) async {
  final UserSession session;
  try {
    session = UserSession.fromToken(token);
    if (session.userId != selectedUser.userId ||
        (selectedUser.buildingId != null &&
            session.buildingId != selectedUser.buildingId)) {
      throw const FormatException(
        'User token does not match selected membership',
      );
    }
    if (session.isExpired) {
      throw const ApiException(ApiFailure.unauthorized);
    }
  } on FormatException {
    throw const ApiException(ApiFailure.invalidResponse);
  } on TypeError {
    throw const ApiException(ApiFailure.invalidResponse);
  } on ArgumentError {
    throw const ApiException(ApiFailure.invalidResponse);
  }

  try {
    await sessionStorage.saveUserToken(token);
    if (session.isExpired) {
      throw const ApiException(ApiFailure.unauthorized);
    }
    return session;
  } catch (error) {
    // Clear an incomplete user session. Keep accountToken
    // so a failed membership selection can be retried without another login.
    try {
      await sessionStorage.clearUserToken();
    } catch (_) {
      throw const ApiException(ApiFailure.storage);
    }
    if (error is ApiException && error.failure == ApiFailure.unauthorized) {
      rethrow;
    }
    throw const ApiException(ApiFailure.storage);
  }
}
