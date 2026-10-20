import '../types/api_failure.dart';
import '../types/communication_post.dart';
import '../types/user_session.dart';
import 'api_client.dart';

class CommunicationService {
  const CommunicationService(this.api);

  final ApiClient api;

  Future<List<CommunicationPost>> listPosts(UserSession session) async {
    if (session.isExpired) {
      throw const ApiException(ApiFailure.unauthorized);
    }
    final result = await api.get('/posts', token: session.token);
    try {
      if (result is! List) throw const FormatException();
      return result.map(CommunicationPost.fromJson).toList();
    } on FormatException {
      throw const ApiException(ApiFailure.invalidResponse);
    } on TypeError {
      throw const ApiException(ApiFailure.invalidResponse);
    }
  }
}
