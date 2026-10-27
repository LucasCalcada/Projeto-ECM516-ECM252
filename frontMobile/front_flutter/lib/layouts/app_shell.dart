import 'dart:async';

import 'package:flutter/material.dart';

import '../components/navigation/app_drawer.dart';
import '../lang/app_localizations.dart';
import '../routes/app_routes.dart';
import '../types/api_failure.dart';
import '../types/user_session.dart';

class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    required this.session,
    required this.route,
    required this.child,
    required this.onSignOut,
    required this.onSessionExpired,
  });

  final UserSession session;
  final String route;
  final Widget child;
  final Future<void> Function() onSignOut;
  final VoidCallback onSessionExpired;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with WidgetsBindingObserver {
  Timer? _expiryTimer;
  bool _signingOut = false;

  @override
  void initState() {
    super.initState();
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

  void _navigate(String route) {
    Navigator.of(context).pop(); // Close the drawer before changing pages.
    if (route == widget.route) return;
    if (route == AppRoutes.home) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else {
      Navigator.of(context).pushNamed(route);
    }
  }

  Future<void> _signOut() async {
    if (_signingOut) return;
    setState(() => _signingOut = true);
    try {
      await widget.onSignOut();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).error(ApiFailure.storage),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _signingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          strings.text(
            widget.route == AppRoutes.settings ? 'menu.settings' : 'menu.home',
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      drawer: AppDrawer(
        session: widget.session,
        currentRoute: widget.route,
        onNavigate: _navigate,
        onSignOut: _signOut,
        signingOut: _signingOut,
      ),
      body: SafeArea(top: false, child: widget.child),
    );
  }
}
