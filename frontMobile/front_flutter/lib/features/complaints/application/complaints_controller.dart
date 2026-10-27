import 'package:flutter/foundation.dart';

import '../domain/complaint.dart';
import '../domain/complaint_access.dart';
import '../domain/complaints_repository.dart';

class ComplaintsController extends ChangeNotifier {
  ComplaintsController({
    required this.repository,
    required ComplaintAccess access,
  }) : _access = access,
       _sessionExpired = access.isExpired;

  final ComplaintsRepository repository;
  ComplaintAccess _access;
  List<Complaint> _items = const [];
  String? _selectedId;
  bool _isLoading = false;
  bool _isSubmitting = false;
  bool _loadFailed = false;
  bool _mutationFailed = false;
  bool _sessionExpired;
  bool _disposed = false;
  int _loadGeneration = 0;
  int _mutationGeneration = 0;
  int _sessionGeneration = 0;

  ComplaintAccess get access => _access;
  List<Complaint> get items => _items;
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  bool get loadFailed => _loadFailed;
  bool get mutationFailed => _mutationFailed;
  bool get sessionExpired => _sessionExpired || _access.isExpired;

  Complaint? get selected {
    for (final item in _items) {
      if (item.id == _selectedId) return item;
    }
    return null;
  }

  /// The caller explicitly loads the replacement session after updating access.
  void updateAccess(ComplaintAccess access) {
    if (_disposed) return;
    final changed = _access.sessionIdentity != access.sessionIdentity;
    _access = access;
    if (changed) {
      _sessionGeneration++;
      _sessionExpired = access.isExpired;
    } else {
      _sessionExpired = _sessionExpired || access.isExpired;
    }
    if (changed || !access.canRead || _sessionExpired) {
      _invalidateOperations();
      _items = const [];
      _selectedId = null;
      _loadFailed = false;
      _mutationFailed = false;
    }
    notifyListeners();
  }

  Future<void> load() async {
    if (!_readable() || _isLoading || _isSubmitting) return;
    final generation = ++_loadGeneration;
    final session = _sessionGeneration;
    _isLoading = true;
    _loadFailed = false;
    notifyListeners();
    try {
      final results = await repository.list(scope: _access.scope);
      if (!_currentLoad(generation, session) || !_readable()) return;
      _items = List<Complaint>.unmodifiable(results);
      if (!_items.any((item) => item.id == _selectedId)) _selectedId = null;
    } on ComplaintSessionExpired {
      if (_currentLoad(generation, session)) _expireSession();
    } catch (_) {
      if (_currentLoad(generation, session) && _readable()) {
        _loadFailed = true;
      }
    } finally {
      if (_currentLoad(generation, session)) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  void select(String id) {
    if (!_readable() || _isSubmitting) return;
    if (!_items.any((item) => item.id == id)) return;
    _selectedId = id;
    _mutationFailed = false;
    notifyListeners();
  }

  Future<bool> create(String subject, String description) async {
    if (!_readable() || !_access.canCreate || _isSubmitting) return false;
    final cleanedSubject = subject.trim();
    final cleanedDescription = description.trim();
    if (cleanedSubject.isEmpty || cleanedDescription.isEmpty) return false;
    return _mutate(
      () => repository.create(
        subject: cleanedSubject,
        description: cleanedDescription,
      ),
      selectResult: true,
    );
  }

  Future<bool> respond(String message) async {
    if (!_readable() || !_access.canManage || _isSubmitting) return false;
    final item = selected;
    final cleanedMessage = message.trim();
    if (item == null ||
        item.status == ComplaintStatus.closed ||
        cleanedMessage.isEmpty) {
      return false;
    }
    return _mutate(
      () => repository.respond(complaintId: item.id, message: cleanedMessage),
    );
  }

  Future<bool> close() async {
    if (!_readable() || !_access.canManage || _isSubmitting) return false;
    final item = selected;
    if (item == null || item.status == ComplaintStatus.closed) return false;
    return _mutate(() => repository.close(complaintId: item.id));
  }

  Future<bool> _mutate(
    Future<Complaint> Function() operation, {
    bool selectResult = false,
  }) async {
    final generation = ++_mutationGeneration;
    final session = _sessionGeneration;
    // An older list response must never overwrite a completed mutation.
    _loadGeneration++;
    _isLoading = false;
    _isSubmitting = true;
    _mutationFailed = false;
    notifyListeners();
    try {
      final result = await operation();
      if (!_currentMutation(generation, session) || !_readable()) return false;
      final exists = _items.any((item) => item.id == result.id);
      _items = List<Complaint>.unmodifiable([
        if (!exists) result,
        for (final item in _items) item.id == result.id ? result : item,
      ]);
      if (selectResult) _selectedId = result.id;
      return true;
    } on ComplaintSessionExpired {
      if (_currentMutation(generation, session)) _expireSession();
      return false;
    } catch (_) {
      if (_currentMutation(generation, session) && _readable()) {
        _mutationFailed = true;
      }
      return false;
    } finally {
      if (_currentMutation(generation, session)) {
        _isSubmitting = false;
        notifyListeners();
      }
    }
  }

  bool _readable() {
    if (_disposed || _sessionExpired) return false;
    if (_access.isExpired) {
      _expireSession();
      return false;
    }
    return _access.canRead;
  }

  bool _currentLoad(int generation, int session) =>
      !_disposed &&
      generation == _loadGeneration &&
      session == _sessionGeneration;

  bool _currentMutation(int generation, int session) =>
      !_disposed &&
      generation == _mutationGeneration &&
      session == _sessionGeneration;

  void _expireSession() {
    _sessionExpired = true;
    _invalidateOperations();
    _items = const [];
    _selectedId = null;
    _loadFailed = false;
    _mutationFailed = false;
    notifyListeners();
  }

  void _invalidateOperations() {
    _loadGeneration++;
    _mutationGeneration++;
    _isLoading = false;
    _isSubmitting = false;
  }

  @override
  void dispose() {
    _disposed = true;
    _invalidateOperations();
    super.dispose();
  }
}
