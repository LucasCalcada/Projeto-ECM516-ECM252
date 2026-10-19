import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../components/login_box/login_button.dart';
import '../components/login_box/login_text_field.dart';
import '../helpers/auth_service.dart';
import '../helpers/session_storage.dart';
import '../lang/login_localizations.dart';
import '../layouts/auth_layout.dart';
import '../types/auth_result.dart';

class Login extends StatefulWidget {
  const Login({
    super.key,
    required this.authService,
    required this.sessionStorage,
    required this.onAuthenticated,
  });

  final AuthService authService;
  final SessionStorage sessionStorage;
  final VoidCallback onAuthenticated;

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  AuthFailure? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isLoading) return;
    setState(() => _error = null);
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    try {
      final result = await widget.authService.login(
        email: _email.text,
        password: _password.text,
      );
      if (!mounted) return;
      try {
        await widget.sessionStorage.saveAccountToken(result.token);
      } catch (_) {
        throw const AuthException(AuthFailure.storage);
      }
      if (!mounted) return;
      _password.clear();
      TextInput.finishAutofillContext();
      widget.onAuthenticated();
    } on AuthException catch (error) {
      if (mounted) setState(() => _error = error.failure);
    } catch (_) {
      if (mounted) setState(() => _error = AuthFailure.unexpected);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = LoginLocalizations.of(context);
    return AuthLayout(
      child: AutofillGroup(
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                strings.text('title'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 32),
              LoginTextField(
                key: const Key('login-email'),
                controller: _email,
                label: strings.text('fields.email.label'),
                placeholder: strings.text('fields.email.placeholder'),
                requiredMessage: strings.text('validation.emailRequired'),
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [
                  AutofillHints.username,
                  AutofillHints.email,
                ],
                enabled: !_isLoading,
              ),
              const SizedBox(height: 16),
              LoginTextField(
                key: const Key('login-password'),
                controller: _password,
                label: strings.text('fields.password.label'),
                placeholder: strings.text('fields.password.placeholder'),
                requiredMessage: strings.text('validation.passwordRequired'),
                autofillHints: const [AutofillHints.password],
                obscureText: _obscurePassword,
                enabled: !_isLoading,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
                suffixIcon: IconButton(
                  tooltip: strings.text(
                    _obscurePassword ? 'showPassword' : 'hidePassword',
                  ),
                  onPressed: _isLoading
                      ? null
                      : () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Semantics(
                liveRegion: true,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 20),
                  child: Text(
                    _error == null ? '' : strings.error(_error!),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              LoginButton(
                key: const Key('login-submit'),
                text: strings.text('login'),
                loadingText: strings.text('loading'),
                isLoading: _isLoading,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
