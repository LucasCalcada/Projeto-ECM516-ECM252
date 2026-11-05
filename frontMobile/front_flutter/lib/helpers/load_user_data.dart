import '../types/account_user.dart';
import '../types/api_failure.dart';
import '../types/user_session.dart';
import 'session_storage.dart';
import 'user_data_storage.dart';

/// Decode once, validate the selected membership, then persist before publishing.
Future<UserSession> loadUserData(
  String token, {
  required AccountUser selectedUser,
  required SessionStorage sessionStorage,
  required UserDataStorage userDataStorage,
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
    await userDataStorage.clearUserData();
    await sessionStorage.saveUserToken(token);
    // Persist only the presentation claims; bearer tokens stay in secure storage.
    await userDataStorage.saveUserData({
      for (final key in const [
        'userId',
        'buildingId',
        'buildingName',
        'residencyId',
        'residencyName',
        'permissions',
        'tokenKind',
        'iat',
        'exp',
      ])
        if (session.claims.containsKey(key)) key: session.claims[key],
    });
    if (session.isExpired) {
      throw const ApiException(ApiFailure.unauthorized);
    }
    return session;
  } catch (error) {
    // Attempt both cleanups even if one storage is unavailable. Keep accountToken
    // so a failed membership selection can be retried without another login.
    try {
      await Future.wait<void>([
        sessionStorage.clearUserToken(),
        userDataStorage.clearUserData(),
      ]);
    } catch (_) {
      throw const ApiException(ApiFailure.storage);
    }
    if (error is ApiException && error.failure == ApiFailure.unauthorized) {
      rethrow;
    }
    throw const ApiException(ApiFailure.storage);
  }
}
