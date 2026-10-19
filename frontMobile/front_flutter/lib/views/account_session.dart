import 'package:flutter/material.dart';

import '../components/login_box/login_button.dart';
import '../helpers/session_storage.dart';
import '../lang/login_localizations.dart';
import '../layouts/auth_layout.dart';
import '../types/auth_result.dart';

/// Destination for a completed login until residence selection is migrated.
class AccountSession extends StatefulWidget {
  const AccountSession({
    super.key,
    required this.sessionStorage,
    required this.onSignedOut,
  });

  final SessionStorage sessionStorage;
  final VoidCallback onSignedOut;

  @override
  State<AccountSession> createState() => _AccountSessionState();
}

class _AccountSessionState extends State<AccountSession> {
  bool _isLoading = false;
  bool _hasError = false;

  Future<void> _signOut() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      await widget.sessionStorage.clearSession();
      if (mounted) widget.onSignedOut();
    } catch (_) {
      if (mounted) setState(() => _hasError = true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = LoginLocalizations.of(context);
    return AuthLayout(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            strings.text('success.title'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          Text(strings.text('success.message'), textAlign: TextAlign.center),
          const SizedBox(height: 24),
          if (_hasError) ...[
            Semantics(
              liveRegion: true,
              child: Text(
                strings.error(AuthFailure.storage),
                textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
            const SizedBox(height: 16),
          ],
          LoginButton(
            text: strings.text('signOut'),
            loadingText: strings.text('signingOut'),
            isLoading: _isLoading,
            onPressed: _signOut,
          ),
        ],
      ),
    );
  }
}
