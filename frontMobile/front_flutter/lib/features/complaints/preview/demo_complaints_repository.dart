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
      protocol: 'RCL-2026-024',
      subject: 'Ruído após o horário de silêncio',
      description: 'Houve ruído elevado na área de convivência após as 22h nos últimos dois dias. Gostaria de orientação sobre o cumprimento do horário de silêncio.',
      createdAt: DateTime(2026, 10, 24),
      status: ComplaintStatus.open,
    ),
    Complaint(
      id: 'demo-2',
      protocol: 'RCL-2026-021',
      subject: 'Iluminação da garagem',
      description: 'Algumas luminárias próximas ao acesso de pedestres estão apagadas, dificultando a circulação à noite.',
      createdAt: DateTime(2026, 10, 22),
      status: ComplaintStatus.answered,
      responses: [
        ComplaintResponse(
          message: 'A manutenção foi acionada para verificar as luminárias. A atualização do atendimento ficará disponível aqui.',
          createdAt: DateTime(2026, 10, 23),
        ),
      ],
    ),
    Complaint(
      id: 'demo-3',
      protocol: 'RCL-2026-018',
      subject: 'Limpeza da área de convivência',
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
  Future<List<Complaint>> list({required ComplaintScope scope}) async {
    if (failNextRead) {
      failNextRead = false;
      throw StateError('Simulated read failure');
    }
    // The explicit preview has one isolated data set per selected profile.
    return List<Complaint>.unmodifiable(_items);
  }

  @override
  Future<Complaint> create({
    required String subject,
    required String description,
  }) async {
    final now = DateTime.now();
    final item = Complaint(
      id: 'demo-${now.microsecondsSinceEpoch}',
      protocol: 'RCL-DEMO-${_items.length + 1}',
      subject: subject,
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
      status: ComplaintStatus.answered,
      responses: [
        ...item.responses,
        ComplaintResponse(message: message, createdAt: DateTime.now()),
      ],
    );
    _items[index] = updated;
    return updated;
  }

  @override
  Future<Complaint> close({required String complaintId}) async {
    final index = _items.indexWhere((item) => item.id == complaintId);
    final updated = _items[index].copyWith(status: ComplaintStatus.closed);
    _items[index] = updated;
    return updated;
  }
}
