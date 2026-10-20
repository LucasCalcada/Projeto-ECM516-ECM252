import 'package:flutter/material.dart';

import '../components/shared/request_feedback.dart';
import '../helpers/core_service.dart';
import '../helpers/session_storage.dart';
import '../lang/app_localizations.dart';
import '../types/account_user.dart';
import '../types/api_failure.dart';
import '../types/user_session.dart';

class BuildingSelector extends StatefulWidget {
  const BuildingSelector({
    super.key,
    required this.coreService,
    required this.sessionStorage,
    required this.onSelected,
    required this.onSignOut,
    required this.onSessionExpired,
  });

  final CoreService coreService;
  final SessionStorage sessionStorage;
  final ValueChanged<UserSession> onSelected;
  final Future<void> Function() onSignOut;
  final VoidCallback onSessionExpired;

  @override
  State<BuildingSelector> createState() => _BuildingSelectorState();
}

class _BuildingSelectorState extends State<BuildingSelector> {
  List<AccountUser>? _users;
  ApiFailure? _error;
  bool _loading = true;
  bool _signingOut = false;
  String? _selecting;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<String> _accountToken() async {
    String? token;
    try {
      token = await widget.sessionStorage.readAccountToken();
    } catch (_) {
      throw const ApiException(ApiFailure.storage);
    }
    if (token == null || token.isEmpty) {
      throw const ApiException(ApiFailure.unauthorized);
    }
    return token;
  }

  void _handleError(Object error) {
    if (!mounted) return;
    final failure = error is ApiException
        ? error.failure
        : ApiFailure.unexpected;
    if (failure == ApiFailure.unauthorized) {
      widget.onSessionExpired();
    } else {
      setState(() => _error = failure);
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final users = await widget.coreService.listUsers(await _accountToken());
      if (mounted) setState(() => _users = users);
    } catch (error) {
      _handleError(error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _select(AccountUser user) async {
    if (_selecting != null || _signingOut) return;
    setState(() {
      _selecting = user.userId;
      _error = null;
    });
    try {
      final session = await widget.coreService.selectUser(
        await _accountToken(),
        user,
      );
      if (!mounted) return;
      try {
        await widget.sessionStorage.saveUserToken(session.token);
      } catch (_) {
        throw const ApiException(ApiFailure.storage);
      }
      if (mounted) widget.onSelected(session);
    } catch (error) {
      _handleError(error);
    } finally {
      if (mounted) setState(() => _selecting = null);
    }
  }

  Future<void> _signOut() async {
    setState(() {
      _signingOut = true;
      _error = null;
    });
    try {
      await widget.onSignOut();
    } catch (_) {
      if (mounted) setState(() => _error = ApiFailure.storage);
    } finally {
      if (mounted) setState(() => _signingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final busy = _selecting != null || _signingOut;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          strings.text('selector.title'),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(strings.text('selector.subtitle')),
                const SizedBox(height: 24),
                if (_loading)
                  const Center(child: CircularProgressIndicator())
                else ...[
                  if (_error != null)
                    RequestFeedback(
                      failure: _error!,
                      onRetry: busy ? null : _load,
                    ),
                  if (_users?.isEmpty == true)
                    RequestFeedback(
                      message: strings.text('selector.empty'),
                      onRetry: busy ? null : _load,
                    ),
                  for (final user in _users ?? <AccountUser>[])
                    Card(
                      child: ListTile(
                        key: ValueKey('building-${user.userId}'),
                        contentPadding: const EdgeInsets.all(16),
                        leading: const Icon(Icons.apartment_outlined),
                        title: Text(
                          user.buildingName.isEmpty
                              ? strings.text('selector.unnamedBuilding')
                              : user.buildingName,
                        ),
                        subtitle: Text(
                          [
                            user.userName,
                            if (user.residencyName != null) user.residencyName!,
                          ].join('\n'),
                        ),
                        trailing: _selecting == user.userId
                            ? const SizedBox.square(
                                dimension: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.chevron_right),
                        onTap: busy ? null : () => _select(user),
                      ),
                    ),
                ],
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: busy ? null : _signOut,
                  icon: const Icon(Icons.logout),
                  label: Text(
                    strings.text(_signingOut ? 'signingOut' : 'signOut'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
