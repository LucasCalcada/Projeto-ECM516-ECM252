import '../types/api_failure.dart';
import '../types/delivery_package.dart';
import '../types/user_session.dart';
import 'api_client.dart';

/// Operations of the delivery (packages) service. The server remains the
/// authority on permissions; views only use the session to decide what to show.
abstract interface class PackagesService {
  Future<List<ResidencyOption>> listResidencies(UserSession session);

  Future<List<DeliveryPackage>> listPackages(
    UserSession session,
    PackageScope scope,
  );

  Future<DeliveryPackage> createPackage(
    UserSession session, {
    required String residencyId,
    required String description,
  });

  Future<void> confirmDelivery(UserSession session, String packageId);
}

class HttpPackagesService implements PackagesService {
  const HttpPackagesService({required this.delivery, required this.core});
  final ApiClient delivery;
  final ApiClient core;

  void _check(UserSession session) {
    if (session.isExpired) throw const ApiException(ApiFailure.unauthorized);
  }

  T _parse<T>(T Function() parse) {
    try { return parse(); }
    on FormatException { throw const ApiException(ApiFailure.invalidResponse); }
    on TypeError { throw const ApiException(ApiFailure.invalidResponse); }
  }

  @override
  Future<List<ResidencyOption>> listResidencies(UserSession session) async {
    _check(session);
    final data = await core.get('/building/${Uri.encodeComponent(session.buildingId)}/details', token: session.token);
    return _parse(() {
      final groups = (data as Map<String, dynamic>)['residentData'] as List;
      final result = <ResidencyOption>[];
      for (final group in groups) {
        for (final item in (group as Map<String, dynamic>)['residencies'] as List) {
          final residency = item as Map<String, dynamic>;
          final name = residency['name'];
          if (name is String) result.add(ResidencyOption(id: residency['id'] as String, name: name));
        }
      }
      return result;
    });
  }

  @override
  Future<List<DeliveryPackage>> listPackages(UserSession session, PackageScope scope) async {
    _check(session);
    final data = await delivery.get('/packages/view', token: session.token, query: {'scope': scope.name});
    final items = _parse(() => (data as List).map(DeliveryPackage.fromJson).toList());
    if (scope == PackageScope.residency) return items;
    Map<String, String> names = {};
    try {
      names = {for (final item in await listResidencies(session)) item.id: item.name};
    } on ApiException catch (error) {
      if (error.failure == ApiFailure.unauthorized) rethrow;
    }
    return [for (final item in items) item.withResidencyName(names[item.residencyId] ?? item.residencyId)];
  }

  @override
  Future<DeliveryPackage> createPackage(UserSession session, {required String residencyId, required String description}) async {
    _check(session);
    final data = await delivery.post('/packages', token: session.token, body: {'residencyId': residencyId, 'description': description.trim()});
    return _parse(() => DeliveryPackage.fromJson(data));
  }

  @override
  Future<void> confirmDelivery(UserSession session, String packageId) async {
    _check(session);
    final data = await delivery.put('/packages', token: session.token, body: {'packageId': packageId});
    _parse(() => DeliveryPackage.fromJson(data));
  }
}


