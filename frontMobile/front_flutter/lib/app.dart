import 'dart:convert';

import 'package:flutter/material.dart';

import 'components/shared/request_feedback.dart';

import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:http/http.dart' as http;

import 'config.dart';
import 'helpers/complaint_access.dart';
import 'helpers/complaints_repository.dart';
import 'helpers/http_complaints_repository.dart';
import 'theme/app_theme.dart';
import 'helpers/api_client.dart';
import 'helpers/auth_service.dart';
import 'helpers/communication_service.dart';
import 'helpers/core_service.dart';
import 'helpers/packages_service.dart';
import 'helpers/preferences_storage.dart';
import 'helpers/session_storage.dart';
import 'helpers/visitor_service.dart';
import 'helpers/reservation_service.dart';
import 'helpers/residents_service.dart';
import 'lang/app_localizations.dart';
import 'lang/login_localizations.dart';
import 'layouts/app_shell.dart';
import 'routes/app_routes.dart';
import 'routes/menu_destination.dart';
import 'types/api_failure.dart';
import 'types/user_session.dart';
import 'views/building_selector.dart';
import 'views/complaints.dart';
import 'views/home.dart';
import 'views/login.dart';
import 'views/packages.dart';
import 'views/settings.dart';
import 'views/visitor_access.dart';
import 'views/reservations.dart';
import 'views/residents.dart';

class HiveApp extends StatefulWidget {
  const HiveApp({
    super.key,
    this.authService,
    this.sessionStorage,
    this.preferencesStorage,
    this.coreService,
    this.communicationService,
    this.reservationService,
    this.residentsService,
    this.client,
    this.locale,
    this.complaintsRepositoryFactory,
    this.packagesService,
  });

  final AuthService? authService;
  final SessionStorage? sessionStorage;
  final PreferencesStorage? preferencesStorage;
  final CoreService? coreService;
  final CommunicationService? communicationService;
  final ReservationService? reservationService;
  final ResidentsService? residentsService;
  final http.Client? client;
  final Locale? locale;
  final ComplaintsRepository Function(UserSession)? complaintsRepositoryFactory;
  final PackagesService? packagesService;

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
  late final VisitorService _visitorService;
  late final ReservationService _reservationService;
  late final ResidentsService _residentsService;
  late final SessionStorage _sessionStorage;
  late final PreferencesStorage _preferencesStorage;
  late Locale _locale;
  bool _authenticated = false;
  bool _expiring = false;
  bool _restoring = true;
  bool _restoreFailure = false;
  bool _endingSession = false;
  String _initialRoute = AppRoutes.login;
  int _languageRevision = 0;
  UserSession? _session;
  PackagesService? _packagesService;

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
    _visitorService = VisitorService(
      ApiClient(client: _client, baseUrl: AppConfig.visitorUrl),
    );
    _reservationService =
        widget.reservationService ??
        ReservationService(
          ApiClient(client: _client, baseUrl: AppConfig.reservationUrl),
        );
    _residentsService =
        widget.residentsService ??
        ResidentsService(
          ApiClient(client: _client, baseUrl: AppConfig.coreUrl),
        );
    _locale = widget.locale ?? const Locale(AppConfig.language);
    if (widget.locale == null) _loadLanguage();
    _restoreSession();
  }

  bool _validAccountToken(String? token) {
    try {
      if (token == null || token.split('.').length != 3) return false;
      final data = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(token.split('.')[1]))),
      );
      return data is Map<String, dynamic> &&
          data['tokenKind'] == 'account' &&
          data['accountId'] is String &&
          (data['accountId'] as String).isNotEmpty &&
          data['exp'] is int &&
          (data['exp'] as int) > DateTime.now().millisecondsSinceEpoch ~/ 1000;
    } catch (_) {
      return false;
    }
  }

  Future<void> _restoreSession() async {
    setState(() => _restoreFailure = false);
    try {
      // Finish reads before cleanup: a read failure must not erase credentials.
      final userToken = await _sessionStorage.readUserToken();
      final accountToken = await _sessionStorage.readAccountToken();
      final section = await _sessionStorage.readSection();
      UserSession? session;
      if (userToken != null && userToken.isNotEmpty) {
        try {
          final candidate = UserSession.fromToken(userToken);
          if (!candidate.isExpired) session = candidate;
        } on FormatException {
          // Invalid saved token; fall back to the account session.
        } on TypeError {
          // Invalid claim type.
        } on ArgumentError {
          // Invalid encoding or expiry.
        }
      }
      var route = AppRoutes.login;
      var authenticated = false;
      if (session != null) {
        authenticated = true;
        route = AppRoutes.home;
        if (section != null &&
            section.userId == session.userId &&
            section.buildingId == session.buildingId &&
            MenuDestination.entries.any(
              (entry) =>
                  entry.route == section.route && entry.canOpen(session!),
            )) {
          route = section.route;
        }
      } else if (_validAccountToken(accountToken)) {
        if (userToken != null || section != null)
          await _sessionStorage.clearUserToken();
        authenticated = true;
        route = AppRoutes.account;
      } else if (userToken != null || accountToken != null || section != null) {
        await _sessionStorage.clearSession();
      }
      if (!mounted) return;
      setState(() {
        _session = session;
        _authenticated = authenticated;
        _initialRoute = route;
        _restoring = false;
      });
    } catch (_) {
      if (mounted) setState(() => _restoreFailure = true);
    }
  }

  Future<void> _rememberSection(UserSession session, String route) async {
    if (!_authenticated || _endingSession || !identical(_session, session))
      return;
    try {
      await _sessionStorage.saveSection(
        SessionSection(
          userId: session.userId,
          buildingId: session.buildingId,
          route: route,
        ),
      );
    } catch (_) {
      if (!mounted || _endingSession || !identical(_session, session)) return;
      final context = _navigator.currentContext;
      if (context != null) {
        _messenger.currentState?.showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).error(ApiFailure.storage),
            ),
          ),
        );
      }
    }
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
    _endingSession = true;
    try {
      await _clearStoredSession();
    } finally {
      _endingSession = false;
    }
    if (!mounted) return;
    _authenticated = false;
    _session = null;
    _navigator.currentState!.pushNamedAndRemoveUntil(
      AppRoutes.login,
      (_) => false,
    );
  }

  Future<void> _clearStoredSession() => _sessionStorage.clearSession();

  void _onSelected(UserSession session) {
    if (session.isExpired) {
      _expireSession();
      return;
    }
    _session = session;
    _packagesService = null;
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
      await _clearStoredSession();
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

  AppShellView _buildView(String route, UserSession session) {
    if (route == AppRoutes.reservations) {
      final navigation = ReservationsNavigationController();
      return AppShellView(
        child: ReservationsView(
          session: session,
          service: _reservationService,
          navigation: navigation,
          onSessionExpired: _expireSession,
        ),
        onBeforeLeave: navigation.onBeforeLeave,
        onBack: navigation.onBack,
      );
    }
    if (route == AppRoutes.residents) {
      return AppShellView(
        child: ResidentsView(
          session: session,
          service: _residentsService,
          onSessionExpired: _expireSession,
        ),
      );
    }
    if (route == AppRoutes.complaints) {
      final navigation = ComplaintsNavigationController();
      final repository =
          widget.complaintsRepositoryFactory?.call(session) ??
          HttpComplaintsRepository(
            ApiClient(client: _client, baseUrl: AppConfig.complaintUrl),
            token: session.token,
          );
      return AppShellView(
        child: ComplaintsView(
          access: ComplaintAccess.fromSession(
            userId: session.userId,
            buildingId: session.buildingId,
            permissions: session.permissions,
            expiresAt: session.expiresAt,
            residentAccess: session.residencyId?.isNotEmpty == true,
            residencyId: session.residencyId,
          ),
          buildingName: session.buildingName,
          shellManaged: true,
          repository: repository,
          navigation: navigation,
          onSessionExpired: _expireSession,
        ),
        onBeforeLeave: navigation.confirmLeave,
        onBack: navigation.handleBack,
      );
    }
    if (route == AppRoutes.packages) {
      return AppShellView(
        child: PackagesView(
          session: session,
          service: _packagesService ??=
              widget.packagesService ??
              HttpPackagesService(
                delivery: ApiClient(
                  client: _client,
                  baseUrl: AppConfig.deliveryUrl,
                ),
                core: ApiClient(client: _client, baseUrl: AppConfig.coreUrl),
              ),
          onSessionExpired: _expireSession,
        ),
      );
    }
    if (route == AppRoutes.visitorAccess) {
      return AppShellView(
        child: VisitorAccessView(
          session: session,
          service: _visitorService,
          onSessionExpired: _expireSession,
        ),
      );
    }
    return AppShellView(
      child: route == AppRoutes.settings
          ? SettingsScreen(onLanguageChanged: _changeLanguage)
          : HomeScreen(
              service: _communicationService,
              session: session,
              onSessionExpired: _expireSession,
            ),
    );
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
        if (route == AppRoutes.home ||
            route == AppRoutes.settings ||
            route == AppRoutes.packages ||
            route == AppRoutes.complaints ||
            route == AppRoutes.reservations ||
            route == AppRoutes.residents ||
            route == AppRoutes.visitorAccess) {
          return AppShell(
            session: session!,
            initialRoute: route,
            onSectionChanged: (destination) =>
                _rememberSection(session!, destination),
            viewBuilder: (destination) => _buildView(destination, session),
            onSignOut: _signOut,
            onSessionExpired: _expireSession,
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
    return MaterialApp(
      key: ValueKey(_restoring),
      title: 'HiveApp',
      debugShowCheckedModeBanner: false,
      navigatorKey: _restoring ? null : _navigator,
      scaffoldMessengerKey: _messenger,
      home: _restoring
          ? Scaffold(
              body: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: _restoreFailure
                        ? RequestFeedback(
                            failure: ApiFailure.storage,
                            onRetry: _restoreSession,
                          )
                        : const CircularProgressIndicator(),
                  ),
                ),
              ),
            )
          : null,
      initialRoute: _restoring ? null : _initialRoute,
      onGenerateRoute: _restoring ? null : _route,
      onGenerateInitialRoutes: _restoring
          ? null
          : (_) => [_route(RouteSettings(name: _initialRoute))],
      locale: _locale,
      supportedLocales: LoginLocalizations.supportedLocales,
      localizationsDelegates: const [
        LoginLocalizations.delegate,
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: HiveTheme.apply(ThemeData.dark(useMaterial3: true)),
    );
  }
}
