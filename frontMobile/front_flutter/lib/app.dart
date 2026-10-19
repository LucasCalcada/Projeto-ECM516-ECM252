import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:http/http.dart' as http;

import 'config.dart';
import 'helpers/auth_service.dart';
import 'helpers/session_storage.dart';
import 'lang/login_localizations.dart';
import 'routes/app_routes.dart';
import 'views/account_session.dart';
import 'views/login.dart';

class HiveApp extends StatefulWidget {
  const HiveApp({
    super.key,
    this.authService,
    this.sessionStorage,
    this.locale,
  });

  final AuthService? authService;
  final SessionStorage? sessionStorage;
  final Locale? locale;

  @override
  State<HiveApp> createState() => _HiveAppState();
}

class _HiveAppState extends State<HiveApp> {
  final _navigator = GlobalKey<NavigatorState>();
  http.Client? _ownedClient;
  late final AuthService _authService;
  late final SessionStorage _sessionStorage;
  bool _authenticated = false;

  @override
  void initState() {
    super.initState();
    _authService =
        widget.authService ??
        AuthService(
          client: _ownedClient = http.Client(),
          baseUrl: AppConfig.authUrl,
        );
    _sessionStorage = widget.sessionStorage ?? const SecureSessionStorage();
  }

  @override
  void dispose() {
    _ownedClient?.close();
    super.dispose();
  }

  void _onAuthenticated() {
    _authenticated = true;
    _navigator.currentState!.pushNamedAndRemoveUntil(
      AppRoutes.account,
      (_) => false,
    );
  }

  void _onSignedOut() {
    _authenticated = false;
    _navigator.currentState!.pushNamedAndRemoveUntil(
      AppRoutes.login,
      (_) => false,
    );
  }

  Route<void> _route(RouteSettings settings) {
    final isAccount = settings.name == AppRoutes.account && _authenticated;
    return MaterialPageRoute<void>(
      settings: RouteSettings(
        name: isAccount ? AppRoutes.account : AppRoutes.login,
      ),
      builder: (_) => isAccount
          ? AccountSession(
              sessionStorage: _sessionStorage,
              onSignedOut: _onSignedOut,
            )
          : Login(
              authService: _authService,
              sessionStorage: _sessionStorage,
              onAuthenticated: _onAuthenticated,
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const foreground = Color(0xFFF5F5F5);
    const background = Color(0xFF262626);
    const blue = Color(0xFF2563EB);
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: const BorderSide(color: foreground),
    );
    return MaterialApp(
      title: 'HiveApp',
      debugShowCheckedModeBanner: false,
      navigatorKey: _navigator,
      initialRoute: AppRoutes.login,
      onGenerateRoute: _route,
      onGenerateInitialRoutes: (_) => [
        _route(const RouteSettings(name: AppRoutes.login)),
      ],
      locale: widget.locale ?? const Locale(AppConfig.language),
      supportedLocales: LoginLocalizations.supportedLocales,
      localizationsDelegates: const [
        LoginLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: background,
        colorScheme: const ColorScheme.dark(
          primary: blue,
          surface: background,
          onSurface: foreground,
          onPrimary: Colors.white,
          error: Color(0xFFF87171),
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(fontSize: 16, color: foreground),
          titleMedium: TextStyle(fontSize: 16, color: foreground),
          headlineSmall: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: foreground,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          contentPadding: const EdgeInsets.all(12),
          hintStyle: const TextStyle(color: Color(0xFFA3A3A3)),
          border: border,
          enabledBorder: border,
          disabledBorder: border.copyWith(
            borderSide: const BorderSide(color: Color(0xFF737373)),
          ),
          focusedBorder: border.copyWith(
            borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2),
          ),
          errorBorder: border.copyWith(
            borderSide: const BorderSide(color: Color(0xFFF87171)),
          ),
          focusedErrorBorder: border.copyWith(
            borderSide: const BorderSide(color: Color(0xFFF87171), width: 2),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: blue,
            foregroundColor: Colors.white,
            disabledBackgroundColor: const Color(0xFF1E40AF),
            disabledForegroundColor: Colors.white,
            minimumSize: const Size.fromHeight(48),
            padding: const EdgeInsets.all(12),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
