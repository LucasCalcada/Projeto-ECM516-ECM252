import '../types/api_failure.dart';
import '../types/communication_post.dart';
import '../types/user_session.dart';
import 'api_client.dart';

class CommunicationService {
  const CommunicationService(this.api);

  final ApiClient api;

  /// Notifications for the whole building plus those addressed to the
  /// residency of the selected session.
  Future<List<CommunicationPost>> listPosts(UserSession session) =>
      _list('/posts', session);

  /// An empty [residencyIds] sends the notification to the whole building.
  Future<CommunicationPost> createPost(
    UserSession session, {
    required String title,
    required String description,
    DateTime? eventAt,
    List<String> residencyIds = const [],
  }) async {
    _ensureActive(session);
    final result = await api.post(
      '/posts',
      token: session.token,
      body: {
        'title': title,
        'description': description,
        'eventAt': eventAt?.toUtc().toIso8601String(),
        'residencyIds': residencyIds,
      },
    );
    return _parse(() => CommunicationPost.fromJson(result));
  }

  Future<List<CommunicationPost>> _list(
    String path,
    UserSession session,
  ) async {
    _ensureActive(session);
    final result = await api.get(path, token: session.token);
    return _parse(() {
      if (result is! List) throw const FormatException();
      return result.map(CommunicationPost.fromJson).toList();
    });
  }

  void _ensureActive(UserSession session) {
    if (session.isExpired) {
      throw const ApiException(ApiFailure.unauthorized);
    }
  }

  T _parse<T>(T Function() parse) {
    try {
      return parse();
    } on FormatException {
      throw const ApiException(ApiFailure.invalidResponse);
    } on TypeError {
      throw const ApiException(ApiFailure.invalidResponse);
    }
  }
}
