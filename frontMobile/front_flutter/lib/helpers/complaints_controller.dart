import '../types/complaint_failure.dart';

import 'package:flutter/foundation.dart';

import '../types/complaint.dart';
import 'complaint_access.dart';
import 'complaints_repository.dart';

class ComplaintsController extends ChangeNotifier {
  ComplaintsController({
    required this.repository,
    required ComplaintAccess access,
  }) : _access = access,
       _scope = access.scope;

  final ComplaintsRepository repository;
  ComplaintAccess _access;
  ComplaintScope _scope;
  ComplaintStatus? statusFilter;
  String? categoryFilter;
  List<Complaint> _items = const [];
  String? _selectedId;
  Complaint? _detail;
  bool _disposed = false;
  bool _sessionExpired = false;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _isDetailLoading = false;
  bool _isSubmitting = false;
  bool _hasMore = false;
  int _offset = 0;
  int _sessionGeneration = 0;
  int _listGeneration = 0;
  int _detailGeneration = 0;
  int _mutationGeneration = 0;
  ComplaintFailure? loadFailure;
  ComplaintFailure? detailFailure;
  ComplaintFailure? mutationFailure;

  ComplaintAccess get access => _access;
  ComplaintScope get scope => _scope;
  List<Complaint> get items => _items;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get isDetailLoading => _isDetailLoading;
  bool get isSubmitting => _isSubmitting;
  bool get hasMore => _hasMore;
  bool get loadFailed => loadFailure != null;
  bool get mutationFailed => mutationFailure != null;
  bool get sessionExpired => _sessionExpired || _access.isExpired;
  Complaint? get selected {
    if (_detail?.id == _selectedId) return _detail;
    for (final item in _items) {
      if (item.id == _selectedId) return item;
    }
    return null;
  }

  bool _current(int session) => !_disposed && session == _sessionGeneration;
  bool _readable() {
    if (_disposed || _sessionExpired) return false;
    if (_access.isExpired) {
      _expire();
      return false;
    }
    return _access.canAccess;
  }

  void updateAccess(ComplaintAccess access) {
    if (_disposed) return;
    final changed = _access.sessionIdentity != access.sessionIdentity;
    _access = access;
    if (changed || !access.canAccess || access.isExpired) {
      _sessionGeneration++;
      _invalidate();
      _items = const [];
      _detail = null;
      _selectedId = null;
      _scope = access.scope;
      statusFilter = null;
      categoryFilter = null;
      _offset = 0;
      _hasMore = false;
      loadFailure = detailFailure = mutationFailure = null;
      _sessionExpired = access.isExpired;
    }
    notifyListeners();
  }

  Future<void> setScope(ComplaintScope scope) async {
    if (!_readable() ||
        _isSubmitting ||
        !access.canReadScope(scope) ||
        _scope == scope) {
      return;
    }
    _scope = scope;
    await setFilters(status: null, category: null);
  }

  Future<void> setFilters({ComplaintStatus? status, String? category}) async {
    if (!_readable() || _isSubmitting) return;
    statusFilter = status;
    categoryFilter = category;
    _offset = 0;
    _hasMore = false;
    _listGeneration++;
    _detailGeneration++;
    _isLoading = _isLoadingMore = _isDetailLoading = false;
    _items = const [];
    _detail = null;
    _selectedId = null;
    detailFailure = mutationFailure = null;
    await load();
  }

  Future<void> load({bool more = false, bool afterMutation = false}) async {
    if (!_readable() ||
        !access.canReadScope(_scope) ||
        (_isSubmitting && !afterMutation) ||
        _isLoading ||
        _isLoadingMore ||
        (more && !_hasMore)) {
      return;
    }
    final session = _sessionGeneration;
    final generation = ++_listGeneration;
    final offset = more ? _offset : 0;
    _isLoading = !more;
    _isLoadingMore = more;
    loadFailure = null;
    notifyListeners();
    try {
      final page = await repository.list(
        scope: _scope,
        status: statusFilter,
        category: categoryFilter,
        limit: 20,
        offset: offset,
      );
      if (!_current(session) || generation != _listGeneration || !_readable()) {
        return;
      }
      // Offset and exhaustion use the raw page, never the deduplicated count.
      _offset = offset + page.length;
      _hasMore = page.length == 20;
      final unique = <String, Complaint>{
        if (more)
          for (final item in _items) item.id: item,
      };
      for (final item in page) {
        unique[item.id] = item;
      }
      _items = List<Complaint>.unmodifiable(unique.values);
    } on ComplaintSessionExpired {
      if (_current(session) && generation == _listGeneration) _expire();
    } catch (error) {
      if (_current(session) && generation == _listGeneration && _readable()) {
        loadFailure = _failure(error);
      }
    } finally {
      if (_current(session) && generation == _listGeneration) {
        _isLoading = _isLoadingMore = false;
        notifyListeners();
      }
    }
  }

  Future<void> select(
    String id, {
    bool preserveMutationFailure = false,
    bool afterMutation = false,
  }) async {
    if (!_readable() || !access.canRead || (_isSubmitting && !afterMutation)) {
      return;
    }
    _selectedId = id;
    if (_detail?.id != id) _detail = null;
    detailFailure = null;
    if (!preserveMutationFailure) mutationFailure = null;
    final generation = ++_detailGeneration;
    final session = _sessionGeneration;
    _isDetailLoading = true;
    notifyListeners();
    try {
      final detail = await repository.getDetail(id);
      if (!_current(session) ||
          generation != _detailGeneration ||
          !_readable()) {
        return;
      }
      _detail = detail;
    } on ComplaintSessionExpired {
      if (_current(session) && generation == _detailGeneration) _expire();
    } catch (error) {
      if (_current(session) && generation == _detailGeneration && _readable()) {
        detailFailure = _failure(error);
        if (detailFailure == ComplaintFailure.notFound) {
          _detail = null;
          _items = List<Complaint>.unmodifiable(
            _items.where((item) => item.id != id),
          );
        }
      }
    } finally {
      if (_current(session) && generation == _detailGeneration) {
        _isDetailLoading = false;
        notifyListeners();
      }
    }
  }

  void clearSelection() {
    if (_disposed || _isSubmitting) return;
    _detailGeneration++;
    _selectedId = null;
    _detail = null;
    _isDetailLoading = false;
    detailFailure = mutationFailure = null;
    notifyListeners();
  }

  Future<bool> create(
    String title,
    String description, {
    String category = 'outros',
  }) async {
    if (!_readable() || !access.canCreate || _isSubmitting) {
      return false;
    }
    if (!_valid(title, 200) ||
        !_valid(description, 10000) ||
        !complaintCategories.contains(category)) {
      return false;
    }
    return _mutate(
      () => repository.create(
        title: title.trim(),
        category: category,
        description: description.trim(),
      ),
    );
  }

  bool _valid(String text, int maximum) =>
      text.trim().isNotEmpty &&
      text.trim().length <= maximum &&
      !text.contains('\u0000');
  bool get _openSelection =>
      selected?.hasDetails == true &&
      !_isDetailLoading &&
      selected?.status != ComplaintStatus.closed &&
      selected?.status != ComplaintStatus.unknown;
  bool get canRespond => _openSelection && access.canRespondTo(selected!);
  bool get canChangeStatus => _openSelection && access.canChangeStatus;
  bool get canAct => canRespond || canChangeStatus;

  Future<bool> respond(String message) async {
    if (!_readable() ||
        !canRespond ||
        _isSubmitting ||
        !_valid(message, 5000)) {
      return false;
    }
    final id = selected!.id;
    return _mutate(
      () => repository.respond(complaintId: id, message: message.trim()),
    );
  }

  Future<bool> changeStatus(ComplaintStatus status) async {
    if (!_readable() || !canChangeStatus || _isSubmitting) return false;
    final item = selected!;
    if (status == ComplaintStatus.inAnalysis &&
        item.status != ComplaintStatus.open) {
      return false;
    }
    if (status == ComplaintStatus.closed &&
        !item.responses.any((response) => response.isAdministrative)) {
      return false;
    }
    if (status != ComplaintStatus.inAnalysis &&
        status != ComplaintStatus.closed) {
      return false;
    }
    return _mutate(
      () => repository.changeStatus(complaintId: item.id, status: status),
    );
  }

  Future<bool> close() => changeStatus(ComplaintStatus.closed);

  Future<bool> _mutate(Future<Complaint> Function() operation) async {
    final session = _sessionGeneration;
    final generation = ++_mutationGeneration;
    _listGeneration++;
    _detailGeneration++;
    _isLoading = _isLoadingMore = _isDetailLoading = false;
    _isSubmitting = true;
    mutationFailure = null;
    notifyListeners();
    bool success = false;
    bool reconcile = false;
    try {
      final result = await operation();
      if (!_current(session) ||
          generation != _mutationGeneration ||
          !_readable()) {
        return false;
      }
      _selectedId = result.id;
      _detail = result;
      success = true;
      reconcile = true;
    } on ComplaintSessionExpired {
      if (_current(session) && generation == _mutationGeneration) _expire();
    } catch (error) {
      if (_current(session) &&
          generation == _mutationGeneration &&
          _readable()) {
        mutationFailure = _failure(error);
        reconcile =
            mutationFailure == ComplaintFailure.conflict ||
            mutationFailure == ComplaintFailure.network;
      }
    } finally {
      if (_current(session) &&
          generation == _mutationGeneration &&
          reconcile &&
          _readable()) {
        final id = _selectedId;
        _offset = 0;
        _hasMore = false;
        await load(afterMutation: true);
        if (!success &&
            id != null &&
            _current(session) &&
            generation == _mutationGeneration) {
          await select(id, preserveMutationFailure: true, afterMutation: true);
        }
      }
      if (_current(session) && generation == _mutationGeneration) {
        _isSubmitting = false;
        notifyListeners();
      }
    }
    return success &&
        _current(session) &&
        generation == _mutationGeneration &&
        _readable();
  }

  ComplaintFailure _failure(Object error) =>
      error is ComplaintException ? error.failure : ComplaintFailure.server;
  void _invalidate() {
    _listGeneration++;
    _detailGeneration++;
    _mutationGeneration++;
    _isLoading = _isLoadingMore = _isDetailLoading = _isSubmitting = false;
  }

  void _expire() {
    if (_disposed || _sessionExpired) return;
    _sessionExpired = true;
    _invalidate();
    _items = const [];
    _selectedId = null;
    _detail = null;
    loadFailure = detailFailure = mutationFailure = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _invalidate();
    super.dispose();
  }
}
