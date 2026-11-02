import '../domain/complaint.dart';
import '../domain/complaints_repository.dart';

/// In-memory fixtures exclusively for the explicit complaints_preview entry.
/// Production callers must supply their authenticated repository adapter.
class DemoComplaintsRepository implements ComplaintsRepository {
  DemoComplaintsRepository() : _items = _fixtures();

  List<Complaint> _items;
  bool failNextRead = false;
  bool get isEmpty => _items.isEmpty;

  void clear() => _items = [];

  void restore() => _items = _fixtures();

  static List<Complaint> _fixtures() => [
    Complaint(
      id: 'demo-1',
      title: 'Ruído após o horário de silêncio',
      description: 'Houve ruído elevado na área de convivência após as 22h nos últimos dois dias. Gostaria de orientação sobre o cumprimento do horário de silêncio.',
      createdAt: DateTime(2026, 10, 24),
      status: ComplaintStatus.open,
    ),
    Complaint(
      id: 'demo-2',
      title: 'Iluminação da garagem',
      description: 'Algumas luminárias próximas ao acesso de pedestres estão apagadas, dificultando a circulação à noite.',
      createdAt: DateTime(2026, 10, 22),
      status: ComplaintStatus.inAnalysis,
      responses: [
        ComplaintResponse(
          message: 'A manutenção foi acionada para verificar as luminárias. A atualização do atendimento ficará disponível aqui.',
          createdAt: DateTime(2026, 10, 23),
        ),
      ],
    ),
    Complaint(
      id: 'demo-3',
      title: 'Limpeza da área de convivência',
      description: 'A área de convivência precisava de limpeza após a utilização no fim de semana.',
      createdAt: DateTime(2026, 10, 18),
      status: ComplaintStatus.closed,
      responses: [
        ComplaintResponse(
          message:
              'A limpeza foi concluída e o espaço está disponível para uso.',
          createdAt: DateTime(2026, 10, 19),
        ),
      ],
    ),
  ];

  @override
  Future<List<Complaint>> list({
    required ComplaintScope scope,
    ComplaintStatus? status,
    String? category,
    int limit = 20,
    int offset = 0,
  }) async {
    if (failNextRead) {
      failNextRead = false;
      throw StateError('Simulated read failure');
    }
    // The explicit preview has one isolated data set per selected profile.
    return List<Complaint>.unmodifiable(
      _items
          .where(
            (item) =>
                (status == null || item.status == status) &&
                (category == null || item.category == category),
          )
          .skip(offset)
          .take(limit)
          .map((item) => item.copyWith(hasDetails: false)),
    );
  }

  @override
  Future<Complaint> getDetail(String id) async {
    return _items.firstWhere((item) => item.id == id);
  }

  @override
  Future<Complaint> create({
    required String title,
    required String category,
    required String description,
  }) async {
    final now = DateTime.now();
    final item = Complaint(
      id: 'demo-${now.microsecondsSinceEpoch}',
      title: title,
      category: category,
      description: description,
      createdAt: now,
      status: ComplaintStatus.open,
    );
    _items.insert(0, item);
    return item;
  }

  @override
  Future<Complaint> respond({
    required String complaintId,
    required String message,
  }) async {
    final index = _items.indexWhere((item) => item.id == complaintId);
    final item = _items[index];
    final updated = item.copyWith(
      responses: [
        ...item.responses,
        ComplaintResponse(message: message, createdAt: DateTime.now()),
      ],
    );
    _items[index] = updated;
    return updated;
  }

  @override
  Future<Complaint> close({required String complaintId}) =>
      changeStatus(complaintId: complaintId, status: ComplaintStatus.closed);

  @override
  Future<Complaint> changeStatus({
    required String complaintId,
    required ComplaintStatus status,
  }) async {
    final index = _items.indexWhere((item) => item.id == complaintId);
    final item = _items[index];
    if (item.status == ComplaintStatus.closed ||
        (status == ComplaintStatus.closed && item.responses.isEmpty) ||
        (status == ComplaintStatus.inAnalysis &&
            item.status != ComplaintStatus.open)) {
      throw const ComplaintException(ComplaintFailure.conflict);
    }
    final now = DateTime.now();
    final updated = item.copyWith(
      status: status,
      updatedAt: now,
      closedAt: status == ComplaintStatus.closed ? now : null,
      history: [
        ...item.history,
        ComplaintStatusChange(
          status: status,
          previousStatus: item.status,
          createdAt: now,
        ),
      ],
    );
    _items[index] = updated;
    return updated;
  }
}
