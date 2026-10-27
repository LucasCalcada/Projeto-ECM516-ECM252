import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:http/http.dart' as http;

import 'config.dart';
import 'helpers/api_client.dart';
import 'helpers/auth_service.dart';
import 'helpers/communication_service.dart';
import 'helpers/core_service.dart';
import 'helpers/preferences_storage.dart';
import 'helpers/session_storage.dart';
import 'lang/app_localizations.dart';
import 'lang/login_localizations.dart';
import 'layouts/app_shell.dart';
import 'routes/app_routes.dart';
import 'routes/menu_destination.dart';
import 'types/api_failure.dart';
import 'types/user_session.dart';
import 'views/building_selector.dart';
import 'views/home.dart';
import 'views/login.dart';
import 'views/settings.dart';

class HiveApp extends StatefulWidget {
  const HiveApp({
    super.key,
    this.authService,
    this.sessionStorage,
    this.preferencesStorage,
    this.coreService,
    this.communicationService,
    this.client,
    this.locale,
  });

  final AuthService? authService;
  final SessionStorage? sessionStorage;
  final PreferencesStorage? preferencesStorage;
  final CoreService? coreService;
  final CommunicationService? communicationService;
  final http.Client? client;
  final Locale? locale;

  @override
  State<HiveApp> createState() => _HiveAppState();
}

class _HiveAppState extends State<HiveApp> {
  final _navigator = GlobalKey<NavigatorState>();
  final _messenger = GlobalKey<ScaffoldMessengerState>();
  late final http.Client _client;
  late final AuthService _authService;
  late final CoreService _coreService;
  late final CommunicationService _communicationService;
  late final SessionStorage _sessionStorage;
  late final PreferencesStorage _preferencesStorage;
  late Locale _locale;
  bool _authenticated = false;
  bool _expiring = false;
  int _languageRevision = 0;
  UserSession? _session;

  @override
  void initState() {
    super.initState();
    _client = widget.client ?? http.Client();
    _authService =
        widget.authService ??
        AuthService(client: _client, baseUrl: AppConfig.authUrl);
    _sessionStorage = widget.sessionStorage ?? const SecureSessionStorage();
    _preferencesStorage =
        widget.preferencesStorage ?? const SecurePreferencesStorage();
    _coreService =
        widget.coreService ??
        CoreService(ApiClient(client: _client, baseUrl: AppConfig.coreUrl));
    _communicationService =
        widget.communicationService ??
        CommunicationService(
          ApiClient(client: _client, baseUrl: AppConfig.communicationUrl),
        );
    _locale = widget.locale ?? const Locale(AppConfig.language);
    if (widget.locale == null) _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final revision = _languageRevision;
    try {
      final language = await _preferencesStorage.readLanguage();
      if (mounted &&
          revision == _languageRevision &&
          ['pt', 'en', 'es'].contains(language)) {
        setState(() => _locale = Locale(language!));
      }
    } catch (_) {
      // The configured language remains usable if preferences cannot be read.
    }
  }

  Future<void> _changeLanguage(String language) async {
    _languageRevision++;
    await _preferencesStorage.saveLanguage(language);
    if (mounted) setState(() => _locale = Locale(language));
  }

  @override
  void dispose() {
    if (widget.client == null) _client.close();
    super.dispose();
  }

  void _onAuthenticated() {
    _authenticated = true;
    _session = null;
    _navigator.currentState!.pushNamedAndRemoveUntil(
      AppRoutes.account,
      (_) => false,
    );
  }

  Future<void> _signOut() async {
    await _sessionStorage.clearSession();
    if (!mounted) return;
    _authenticated = false;
    _session = null;
    _navigator.currentState!.pushNamedAndRemoveUntil(
      AppRoutes.login,
      (_) => false,
    );
  }

  void _onSelected(UserSession session) {
    if (session.isExpired) {
      _expireSession();
      return;
    }
    _session = session;
    _navigator.currentState!.pushNamedAndRemoveUntil(
      AppRoutes.home,
      (_) => false,
    );
  }

  Future<void> _expireSession() async {
    if (_expiring || !_authenticated) return;
    _expiring = true;
    _authenticated = false;
    _session = null;
    var failure = ApiFailure.unauthorized;
    try {
      await _sessionStorage.clearSession();
    } catch (_) {
      failure = ApiFailure.storage;
    }
    if (!mounted) return;
    _navigator.currentState!.pushNamedAndRemoveUntil(
      AppRoutes.login,
      (_) => false,
    );
    final context = _navigator.currentContext;
    if (context != null && context.mounted) {
      _messenger.currentState?.showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).error(failure))),
      );
    }
    _expiring = false;
  }

  Route<void> _route(RouteSettings settings) {
    var route = AppRoutes.login;
    if (_authenticated) {
      final session = _session;
      if (session == null || session.isExpired) {
        route = AppRoutes.account;
      } else {
        final matches = MenuDestination.entries.where(
          (entry) => entry.route == settings.name,
        );
        route = matches.isNotEmpty && matches.first.canOpen(session)
            ? matches.first.route
            : AppRoutes.home;
      }
    }
    final session = _session;
    return MaterialPageRoute<void>(
      settings: RouteSettings(name: route),
      builder: (_) {
        if (route == AppRoutes.account) {
          return BuildingSelector(
            coreService: _coreService,
            sessionStorage: _sessionStorage,
            onSelected: _onSelected,
            onSignOut: _signOut,
            onSessionExpired: _expireSession,
          );
        }
        if (route == AppRoutes.home || route == AppRoutes.settings) {
          return AppShell(
            session: session!,
            route: route,
            onSignOut: _signOut,
            onSessionExpired: _expireSession,
            child: route == AppRoutes.settings
                ? SettingsScreen(onLanguageChanged: _changeLanguage)
                : HomeScreen(
                    service: _communicationService,
                    session: session,
                    onSessionExpired: _expireSession,
                  ),
          );
        }
        return Login(
          authService: _authService,
          sessionStorage: _sessionStorage,
          onAuthenticated: _onAuthenticated,
        );
      },
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
      scaffoldMessengerKey: _messenger,
      initialRoute: AppRoutes.login,
      onGenerateRoute: _route,
      onGenerateInitialRoutes: (_) => [
        _route(const RouteSettings(name: AppRoutes.login)),
      ],
      locale: _locale,
      supportedLocales: LoginLocalizations.supportedLocales,
      localizationsDelegates: const [
        LoginLocalizations.delegate,
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        brightness: Brightness.dark,
        disabledColor: const Color(0xFFA3A3A3),
        scaffoldBackgroundColor: background,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF171717),
          foregroundColor: foreground,
        ),
        drawerTheme: const DrawerThemeData(backgroundColor: Color(0xFF171717)),
        cardTheme: CardThemeData(
          color: const Color(0xFF171717),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFF404040)),
          ),
        ),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF60A5FA),
          surface: background,
          onSurface: foreground,
          onPrimary: Color(0xFF0A0A0A),
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
