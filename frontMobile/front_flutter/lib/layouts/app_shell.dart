import 'dart:async';

import 'package:flutter/material.dart';

import '../components/navigation/app_sidebar.dart';
import '../lang/app_localizations.dart';
import '../routes/app_routes.dart';
import '../routes/menu_destination.dart';
import '../types/api_failure.dart';
import '../types/user_session.dart';

/// A view and its navigation guards, created once per selection.
class AppShellView {
  const AppShellView({required this.child, this.onBeforeLeave, this.onBack});

  final Widget child;
  final Future<bool> Function()? onBeforeLeave;

  /// True when the view consumed Back (including a cancelled action).
  final Future<bool> Function()? onBack;
}

class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    required this.session,
    required this.initialRoute,
    required this.viewBuilder,
    required this.onSignOut,
    required this.onSessionExpired,
    this.onSectionChanged,
  });

  final UserSession session;
  final String initialRoute;
  final AppShellView Function(String route) viewBuilder;
  final Future<void> Function() onSignOut;
  final VoidCallback onSessionExpired;
  final ValueChanged<String>? onSectionChanged;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with WidgetsBindingObserver {
  Timer? _expiryTimer;
  final _contentMessenger = GlobalKey<ScaffoldMessengerState>();
  bool _transitioning = false;
  bool _signingOut = false;
  late String _route;
  late AppShellView _view;
  // A reopened view starts fresh, including its scroll positions.
  PageStorageBucket _storage = PageStorageBucket();

  bool _canOpen(String route) => MenuDestination.entries.any(
    (entry) => entry.route == route && entry.canOpen(widget.session),
  );

  @override
  void initState() {
    super.initState();
    _route = _canOpen(widget.initialRoute)
        ? widget.initialRoute
        : AppRoutes.home;
    _view = widget.viewBuilder(_route);
    WidgetsBinding.instance.addObserver(this);
    _expiryTimer = Timer(
      widget.session.expiresAt.difference(DateTime.now()),
      widget.onSessionExpired,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && widget.session.isExpired) {
      widget.onSessionExpired();
    }
  }

  @override
  void dispose() {
    _expiryTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _select(String route) {
    FocusManager.instance.primaryFocus?.unfocus();
    _contentMessenger.currentState?.clearSnackBars();
    setState(() {
      _route = route;
      _view = widget.viewBuilder(route);
      _storage = PageStorageBucket();
    });
    widget.onSectionChanged?.call(route);
  }

  Future<void> _navigate(String route) async {
    if (_transitioning || route == _route || !_canOpen(route)) return;
    setState(() => _transitioning = true);
    try {
      if (_view.onBeforeLeave != null && !await _view.onBeforeLeave!()) return;
      if (mounted && _canOpen(route)) _select(route);
    } finally {
      if (mounted) setState(() => _transitioning = false);
    }
  }

  Future<void> _back() async {
    if (_transitioning || _route == AppRoutes.home) return;
    setState(() => _transitioning = true);
    try {
      if (_view.onBack != null && await _view.onBack!()) return;
      if (mounted && _canOpen(AppRoutes.home)) _select(AppRoutes.home);
    } finally {
      if (mounted) setState(() => _transitioning = false);
    }
  }

  Future<void> _signOut() async {
    if (_transitioning) return;
    setState(() => _transitioning = true);
    try {
      if (_view.onBeforeLeave != null && !await _view.onBeforeLeave!()) return;
      if (!mounted) return;
      setState(() => _signingOut = true);
      await widget.onSignOut();
    } catch (_) {
      if (mounted) {
        _contentMessenger.currentState?.showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).error(ApiFailure.storage),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _signingOut = false;
          _transitioning = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final destination = MenuDestination.entries.firstWhere(
      (entry) => entry.route == _route,
    );
    return PopScope(
      canPop: _route == AppRoutes.home && !_transitioning,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) unawaited(_back());
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final expanded = constraints.maxWidth >= 1024;
              return Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppSidebar(
                    session: widget.session,
                    currentRoute: _route,
                    expanded: expanded,
                    onNavigate: _navigate,
                    onSignOut: _signOut,
                    signingOut: _signingOut,
                    busy: _transitioning,
                  ),
                  Expanded(
                    child: Material(
                      key: const Key('main-box'),
                      color: Theme.of(context).colorScheme.surface,
                      child: ScaffoldMessenger(
                        key: _contentMessenger,
                        child: Scaffold(
                          backgroundColor: Theme.of(context)
                              .colorScheme
                              .surface,
                          resizeToAvoidBottomInset: false,
                          body: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Semantics(
                                  header: true,
                                  child: Text(
                                    AppLocalizations.of(context)
                                        .text(destination.label),
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: PageStorage(
                                  bucket: _storage,
                                  child: KeyedSubtree(
                                    key: ValueKey(_route),
                                    child: _view.child,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
