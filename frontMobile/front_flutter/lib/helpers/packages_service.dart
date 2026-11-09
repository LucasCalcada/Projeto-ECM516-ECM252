import '../types/api_failure.dart';
import '../types/delivery_package.dart';
import '../types/user_session.dart';

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

/// Temporary implementation that keeps packages in memory for the running app.
/// It makes no HTTP calls; replace it with an `ApiClient` based service later.
class InMemoryPackagesService implements PackagesService {
  InMemoryPackagesService({this.latency = const Duration(milliseconds: 300)});

  final Duration latency;
  final List<ResidencyOption> _residencies = [];
  final List<DeliveryPackage> _packages = [];
  String? _seededFor;
  int _nextId = 1;

  Future<void> _delay() => Future<void>.delayed(latency);

  /// Seeds once per building so the session's own residency has data to show.
  void _seed(UserSession session) {
    if (_seededFor == session.buildingId) return;
    _seededFor = session.buildingId;
    _residencies.clear();
    _packages.clear();
    final ownId = session.residencyId;
    final own = ownId == null || ownId.isEmpty
        ? null
        : ResidencyOption(
            id: ownId,
            name: session.residencyName?.isNotEmpty == true
                ? session.residencyName!
                : 'Residência',
          );
    _residencies.addAll([
      ?own,
      const ResidencyOption(id: 'demo-101', name: 'Apto 101'),
      const ResidencyOption(id: 'demo-102', name: 'Apto 102'),
      const ResidencyOption(id: 'demo-201', name: 'Apto 201'),
    ]);
    final now = DateTime.now().toUtc();
    DeliveryPackage seed(
      ResidencyOption residency,
      String description,
      DeliveryStatus status,
      int daysAgo,
    ) => DeliveryPackage(
      id: 'pkg-${_nextId++}',
      buildingId: session.buildingId,
      residencyId: residency.id,
      residencyName: residency.name,
      description: description,
      status: status,
      createdAt: now.subtract(Duration(days: daysAgo)),
      deliveredAt: status == DeliveryStatus.delivered
          ? now.subtract(Duration(days: daysAgo - 1))
          : null,
    );
    final first = _residencies.first;
    final second = _residencies[1];
    _packages.addAll([
      seed(first, 'Pacote Amazon', DeliveryStatus.pending, 1),
      seed(first, 'Caixa de documentos', DeliveryStatus.delivered, 6),
      seed(second, 'Pacote Mercado Livre', DeliveryStatus.pending, 2),
      seed(second, 'Encomenda devolvida', DeliveryStatus.canceled, 9),
    ]);
  }

  @override
  Future<List<ResidencyOption>> listResidencies(UserSession session) async {
    await _delay();
    _seed(session);
    return List.unmodifiable(_residencies);
  }

  @override
  Future<List<DeliveryPackage>> listPackages(
    UserSession session,
    PackageScope scope,
  ) async {
    await _delay();
    _seed(session);
    final visible = _packages.where(
      (item) =>
          scope == PackageScope.building ||
          item.residencyId == session.residencyId,
    );
    return (visible.toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt)))
        .toList(growable: false);
  }

  @override
  Future<DeliveryPackage> createPackage(
    UserSession session, {
    required String residencyId,
    required String description,
  }) async {
    await _delay();
    _seed(session);
    final residency = _residencies.where((item) => item.id == residencyId);
    if (residency.isEmpty) throw const ApiException(ApiFailure.invalidResponse);
    final created = DeliveryPackage(
      id: 'pkg-${_nextId++}',
      buildingId: session.buildingId,
      residencyId: residencyId,
      residencyName: residency.first.name,
      description: description,
      status: DeliveryStatus.pending,
      createdAt: DateTime.now().toUtc(),
    );
    _packages.add(created);
    return created;
  }

  @override
  Future<void> confirmDelivery(UserSession session, String packageId) async {
    await _delay();
    _seed(session);
    final index = _packages.indexWhere((item) => item.id == packageId);
    if (index < 0 || _packages[index].status != DeliveryStatus.pending) {
      throw const ApiException(ApiFailure.invalidResponse);
    }
    _packages[index] = _packages[index].copyWith(
      status: DeliveryStatus.delivered,
      deliveredAt: DateTime.now().toUtc(),
    );
  }
}
