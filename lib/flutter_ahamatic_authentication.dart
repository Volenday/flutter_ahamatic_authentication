// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_ahamatic_authentication/cidaas/cidaas_entity.dart';
import 'package:flutter_ahamatic_authentication/cidaas/cidaas_api.dart';
import 'package:flutter_ahamatic_authentication/cidaas/utils/error_handler.dart';
import 'package:flutter_ahamatic_authentication/models/app_config.dart';
import 'package:flutter_ahamatic_authentication/services/ahamatic_api_service.dart';
import 'package:flutter_ahamatic_authentication/services/openiam_auth_service.dart';
import 'package:flutter_ahamatic_authentication/services/auth_logging_service.dart';
import 'package:flutter_ahamatic_authentication/services/platform_service.dart';
import 'package:flutter_ahamatic_authentication/widgets/auth_webview.dart';
import 'package:flutter_ahamatic_authentication/cidaas/utils/pkce_utils.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_svg/flutter_svg.dart';

// Conditional import for web-specific functionality
import 'package:flutter_ahamatic_authentication/cidaas/cidaas_web_auth.dart'
    if (dart.library.io) 'package:flutter_ahamatic_authentication/cidaas/cidaas_web_auth_stub.dart';
import 'package:universal_html/html.dart' as html;

// Re-export entities to make them accessible from the main package
export 'package:flutter_ahamatic_authentication/cidaas/cidaas_entity.dart';
export 'package:flutter_ahamatic_authentication/models/app_config.dart';
export 'package:flutter_ahamatic_authentication/services/platform_service.dart';
export 'package:flutter_ahamatic_authentication/widgets/auth_webview.dart';
export 'package:flutter_ahamatic_authentication/widgets/oauth_callback_handler.dart';

/// Cidaas logo asset path (local asset to avoid CORS issues)
const _cidaasLogoAsset = 'assets/cidaas/cidaas_logo.png';

/// OpenIAM/Abena ID logo asset path (local fallback)
const _openIamLogoAsset = 'assets/openiam/abena_logo.png';

/// Supported login types
enum LoginType { azure, mitId, openIAM, cidaas }

/// Controller to trigger login flows from custom buttons without using
/// the library's built-in UI. Create an [AhamaticAuthController], pass it
/// to [FlutterAhaAuthentication], then call [launchOpenIamLogin] or
/// [launchCidaasLogin] from your own buttons.
///
/// Example:
/// ```dart
/// final authController = AhamaticAuthController();
///
/// // In the widget tree (e.g. above your screen so it stays mounted):
/// FlutterAhaAuthentication(
///   controller: authController,
///   applicationCode: '...',
///   environment: '...',
///   europe: true,
///   onAuthSuccess: (...) { ... },
///   onAuthError: (...) { ... },
/// );
///
/// // In your custom button:
/// ElevatedButton(
///   onPressed: () => authController.launchOpenIamLogin(),
///   child: Text('Log in as citizen'),
/// )
/// ```
class AhamaticAuthController {
  VoidCallback? _onOpenIamLogin;
  VoidCallback? _onCidaasLogin;
  VoidCallback? _onMitIdLogin;

  /// Called by [FlutterAhaAuthentication] to register the login actions.
  /// Do not call this directly.
  void setLaunchCallbacks(
    VoidCallback openIamLogin, {
    VoidCallback? cidaasLogin,
    VoidCallback? mitIdLogin,
  }) {
    _onOpenIamLogin = openIamLogin;
    _onCidaasLogin = cidaasLogin;
    _onMitIdLogin = mitIdLogin;
  }

  /// Launches the OpenIAM (e.g. "Log in as citizen") login flow.
  /// No-op if the widget has not yet registered callbacks.
  void launchOpenIamLogin() {
    _onOpenIamLogin?.call();
  }

  /// Launches the Cidaas login flow.
  /// No-op if Cidaas is not enabled or callbacks are not registered.
  void launchCidaasLogin() {
    _onCidaasLogin?.call();
  }

  /// Launches the MitID login flow (Cidaas with [CidaasConfiguration.cidaasClientIdMitID]).
  /// No-op if MitID is not configured or callbacks are not registered.
  void launchMitIdLogin() {
    _onMitIdLogin?.call();
  }
}

/// Main Ahamatic authentication widget
///
/// Provides an authentication interface with support for:
/// - OpenIAM
/// - Cidaas
/// - Google (requires external configuration)
class FlutterAhaAuthentication extends StatefulWidget {
  /// If true, shows only a login button instead of the full form
  final bool? isLoginButtonOnly;

  /// Project name to display
  final String? projectName;

  /// Project logo asset
  final String? projectLogoAsset;

  /// Enable Google login
  final bool enableGoogleLogin;

  /// Callback when Google login is pressed
  final VoidCallback? onPressedGoogleLogin;

  /// Form key
  final GlobalKey<FormState>? formKey;

  /// Module name for native apps
  final String? moduleName;

  /// Application code
  final String applicationCode;

  /// Environment: 'development', 'sandbox', 'production'
  final String environment;

  /// If true, uses European URLs
  final bool europe;

  /// Module name for web
  final String? moduleWebName;

  /// Current authentication status
  final String? authenticationStatus;

  /// Current token (if exists)
  final String? token;

  /// App version
  final String? appVersion;

  /// If true, opens login in external browser
  final bool? externalBrowserLogin;

  /// Cidaas configuration
  final CidaasConfiguration? cidaasConfiguration;

  /// Authentication success callback
  final AuthSuccessCallback? onAuthSuccess;

  /// Authentication error callback
  final AuthErrorCallback? onAuthError;

  /// Optional controller to trigger login from custom buttons.
  /// When set, the widget renders nothing ([SizedBox.shrink]) and
  /// registers its login actions with the controller.
  final AhamaticAuthController? controller;

  const FlutterAhaAuthentication({
    super.key,
    this.isLoginButtonOnly,
    this.projectName,
    this.projectLogoAsset,
    this.enableGoogleLogin = false,
    this.onPressedGoogleLogin,
    this.formKey,
    this.moduleName,
    this.moduleWebName,
    this.authenticationStatus,
    this.token,
    this.appVersion,
    this.externalBrowserLogin = false,
    this.cidaasConfiguration,
    this.onAuthSuccess,
    this.onAuthError,
    this.controller,
    required this.applicationCode,
    required this.environment,
    required this.europe,
  });

  @override
  State<FlutterAhaAuthentication> createState() =>
      _FlutterAhaAuthenticationState();
}

class _FlutterAhaAuthenticationState extends State<FlutterAhaAuthentication> {
  // Services
  late final Dio _dio;
  late final EnvironmentConfig _envConfig;
  late final AhamaticApiService _apiService;
  late final OpenIamAuthService _openIamService;
  late final AuthLoggingService _loggingService;

  // State
  String _projectName = '';
  String _apiKey = '';
  bool _isOpeniamEnabled = false;
  bool _isCidaasEnabled = false;
  String _openIamLogo = '';
  String _openIamTitle = '';
  String? _hostName;
  String? _openiamLoginUrl;

  // iOS Cidaas workaround: first attempt prepares the session, second completes it
  bool _cidaasFirstAttemptDone = false;

  // Development credentials
  final _devAccount = {
    'emailAddress': 'developers@volenday.com',
    'password': 'V0l3nd@yP@ssw0rd',
  };

  // Current web URL - works on both web and mobile
  String get _currentWebUrl {
    if (PlatformService.isWeb) {
      try {
        return html.window.location.href;
      } catch (e) {
        return '';
      }
    }
    return '';
  }

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _loadInitialData();

    // Check for OAuth callback on web
    if (PlatformService.isWeb) {
      _checkWebCallback();
    }
  }

  /// Checks for OAuth callback parameters in the URL (web only)
  void _checkWebCallback() {
    try {
      final uri = Uri.parse(html.window.location.href);
      if (uri.queryParameters.containsKey('token')) {
        final token = uri.queryParameters['token'];
        if (token != null) {
          _handleAuthenticationSuccess(token);
        }
      }
    } catch (e) {
      debugPrint('Error checking web callback: $e');
    }
  }

  /// Initializes the required services
  void _initializeServices() {
    _dio = Dio();
    _envConfig = EnvironmentConfig.fromEnvironment(
      widget.environment,
      widget.europe,
    );

    _apiService = AhamaticApiServiceImpl(
      dio: _dio,
      apiUrl: _envConfig.apiUrl,
    );

    _openIamService = OpenIamAuthServiceImpl();

    _loggingService = AuthLoggingServiceImpl(
      dio: _dio,
      apiUrl: _envConfig.apiUrl,
    );

    debugPrint(
      'Services initialized with environment: ${widget.environment}, '
      'platform: ${PlatformService.platformName}',
    );
  }

  /// Loads initial application data
  Future<void> _loadInitialData() async {
    debugPrint(
      'FlutterAhaAuthentication: [INIT] environment=${widget.environment}, '
      'europe=${widget.europe}, '
      'applicationCode=${widget.applicationCode}, '
      'moduleName=${widget.moduleName}, '
      'moduleWebName=${widget.moduleWebName}, '
      'apiUrl=${_envConfig.apiUrl}, '
      'portalUrl=${_envConfig.portalUrl}, '
      'initialApiKey=$_apiKey',
    );
    await _fetchModuleConfig();
    await _fetchLoginUrl();
  }

  /// Gets module configuration from the API
  Future<void> _fetchModuleConfig() async {
    if (widget.moduleName == null) return;

    try {
      final moduleConfig = await _apiService.getModuleConfig(
        widget.applicationCode,
        widget.moduleName!,
      );

      final appResponse = await _apiService.validateApp(widget.applicationCode);

      if (mounted) {
        setState(() {
          _projectName = appResponse.name;
          _apiKey = moduleConfig.apiKey ?? '';
          _isCidaasEnabled = moduleConfig.isCidaasEnabled;
          _isOpeniamEnabled = moduleConfig.isOpeniamEnabled;
          _openIamLogo = moduleConfig.openIamLogo ?? '';
          _openIamTitle = moduleConfig.openIamTitle ?? '';
          _hostName = moduleConfig.hostName;
        });
      }

      debugPrint(
        'FlutterAhaAuthentication: [MODULE_CONFIG] '
        'projectName=$_projectName, '
        'apiKey=$_apiKey, '
        'cidaasEnabled=$_isCidaasEnabled, '
        'openIamEnabled=$_isOpeniamEnabled, '
        'hostName=$_hostName',
      );
    } on AhamaticApiException catch (e) {
      debugPrint('Error fetching module config: $e');
    }
  }

  /// Gets and stores the OpenIAM login URL
  Future<void> _fetchLoginUrl() async {
    final loginParams = OpenIamLoginParams(
      applicationCode: widget.applicationCode,
      moduleName: widget.moduleName,
      moduleWebName: widget.moduleWebName,
      hostName: _hostName,
      portalUrl: _envConfig.portalUrl,
      authenticationStatus: widget.authenticationStatus,
      currentWebUrl: _currentWebUrl,
    );

    final loginUrl = _openIamService.generateLoginUrl(
      loginParams,
      isWeb: kIsWeb,
    );

    if (mounted && loginUrl != null) {
      setState(() => _openiamLoginUrl = loginUrl);
    }
  }

  /// Handles authentication success
  Future<void> _handleAuthenticationSuccess(String token) async {
    await _loggingService.logLoginEvent(
      token: token,
      loginUrl: _openiamLoginUrl ?? '',
      moduleName: widget.moduleName,
      appVersion: widget.appVersion,
    );

    if (mounted && context.mounted) {
      Navigator.of(context).pop();
    }
  }

  /// Launches the OpenIAM login flow
  ///
  /// This method handles both web and mobile platforms automatically.
  Future<void> _launchOpenIamLogin(BuildContext context) async {
    debugPrint(
        'FlutterAhaAuthentication: [DEBUG] _launchOpenIamLogin applicationCode=${widget.applicationCode} moduleName=${widget.moduleName}');
    // Update hostName if not available
    if (_hostName == null && widget.moduleName != null) {
      try {
        final moduleConfig = await _apiService.getModuleConfig(
          widget.applicationCode,
          widget.moduleName!,
        );
        _hostName = moduleConfig.hostName;
      } catch (e) {
        debugPrint('Error getting hostName: $e');
      }
    }

    final loginParams = OpenIamLoginParams(
      applicationCode: widget.applicationCode,
      moduleName: widget.moduleName,
      moduleWebName: widget.moduleWebName,
      hostName: _hostName,
      portalUrl: _envConfig.portalUrl,
      authenticationStatus: widget.authenticationStatus,
      currentWebUrl: _currentWebUrl,
    );

    final loginUrl = _openIamService.generateLoginUrl(
      loginParams,
      isWeb: PlatformService.isWeb,
    );

    if (loginUrl == null) {
      debugPrint(
          'FlutterAhaAuthentication: [ERROR] OpenIAM could not generate login URL');
      widget.onAuthError?.call('Could not generate login URL');
      return;
    }

    _openiamLoginUrl = loginUrl;
    debugPrint(
        'FlutterAhaAuthentication: [DEBUG] OpenIAM loginUrl (length ${loginUrl.length}) externalBrowser=${widget.externalBrowserLogin} platform=${PlatformService.isWeb ? "web" : "mobile"}');

    // Handle external browser login
    if (widget.externalBrowserLogin == true) {
      await launchUrl(
        Uri.parse(loginUrl),
        mode: LaunchMode.externalApplication,
      );
      return;
    }

    // Platform-specific authentication handling
    if (PlatformService.isWeb) {
      // On web, redirect to the login URL
      html.window.location.href = loginUrl;
    } else {
      // On mobile, show the authentication dialog with WebView
      await showAuthDialog(
        context,
        url: loginUrl,
        onAuthSuccess: (token) async {
          await _handleAuthenticationSuccess(token);
          widget.onAuthSuccess?.call(
            accessToken: token,
            refreshToken: null,
            idToken: null,
          );
        },
        onAuthError: (error) {
          debugPrint('Auth error: $error');
          widget.onAuthError?.call(error);
        },
        onClose: () {
          // User manually closed the dialog - this is not an error, just log it
          debugPrint('FlutterAhaAuthentication: [INFO] Auth dialog closed by user (manual cancellation)');
          // Note: We don't call onAuthError here because closing the dialog is a normal user action
        },
      );
    }
  }

  /// Launches the classic Cidaas login flow (uses [CidaasConfiguration.clientId]).
  Future<void> _launchCidaasLogin() async {
    debugPrint('FlutterAhaAuthentication: [DEBUG] _launchCidaasLogin (classic)');
    final config = widget.cidaasConfiguration;
    if (config == null) {
      debugPrint('FlutterAhaAuthentication: [ERROR] CidaasConfiguration not provided');
      widget.onAuthError?.call('Cidaas configuration not provided.');
      return;
    }
    debugPrint(
        'FlutterAhaAuthentication: [DEBUG] classic clientId: ${config.clientId}');
    await _launchCidaasLoginWithClientId(config.clientId);
  }

  /// Launches the MitID login flow (uses [CidaasConfiguration.cidaasClientIdMitID]).
  /// No-op if [cidaasClientIdMitID] is null or empty.
  Future<void> _launchMitIdLogin() async {
    debugPrint('FlutterAhaAuthentication: [DEBUG] _launchMitIdLogin (MitID)');
    final config = widget.cidaasConfiguration;
    if (config == null) {
      debugPrint('FlutterAhaAuthentication: [ERROR] CidaasConfiguration not provided');
      widget.onAuthError?.call('Cidaas configuration not provided.');
      return;
    }
    final mitIdClientId = config.cidaasClientIdMitID?.trim();
    if (mitIdClientId == null || mitIdClientId.isEmpty) {
      debugPrint(
          'FlutterAhaAuthentication: [ERROR] cidaasClientIdMitID not set');
      widget.onAuthError?.call('MitID is not configured.');
      return;
    }
    debugPrint(
        'FlutterAhaAuthentication: [DEBUG] MitID clientId: $mitIdClientId');
    await _launchCidaasLoginWithClientId(mitIdClientId);
  }

  /// Launches the Cidaas login flow with the given [clientId] (classic or MitID).
  Future<void> _launchCidaasLoginWithClientId(String clientId) async {
    final config = widget.cidaasConfiguration;
    if (config == null) {
      return;
    }

    debugPrint(
        'FlutterAhaAuthentication: [DEBUG] _launchCidaasLoginWithClientId clientId=$clientId platform=${PlatformService.isWeb ? "web" : "mobile"}');

    // iOS workaround: Mark first attempt immediately when user taps the button
    final isFirstIOSAttempt = PlatformService.isIOS && !_cidaasFirstAttemptDone;
    if (isFirstIOSAttempt) {
      debugPrint('FlutterAhaAuthentication: [DEBUG] iOS first attempt');
      _cidaasFirstAttemptDone = true;
      if (mounted) {
        setState(() {});
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }

    try {
      if (PlatformService.isWeb) {
        debugPrint(
            'FlutterAhaAuthentication: [DEBUG] starting Cidaas web flow');
        await _launchCidaasLoginWeb(config, clientId);
      } else {
        final isMitIdFlow = config.cidaasClientIdMitID?.trim().isNotEmpty == true &&
            clientId == config.cidaasClientIdMitID?.trim();
        final mitIdAuthUrl = config.mitIdAuthUrl?.trim();
        if (isMitIdFlow && mitIdAuthUrl != null && mitIdAuthUrl.isNotEmpty) {
          debugPrint(
              'FlutterAhaAuthentication: [DEBUG] starting MitID mobile flow (full URL)');
          await _launchMitIdLoginMobileWithFullUrl(config, clientId);
        } else {
          debugPrint(
              'FlutterAhaAuthentication: [DEBUG] starting Cidaas mobile flow');
          await _launchCidaasLoginMobile(config, clientId);
        }
      }
    } on PlatformException catch (e) {
      // Check if this is a user cancellation (manual action, not an error)
      if (e.code == CidaasErrorHandler.userCancelledCode) {
        debugPrint(
            'FlutterAhaAuthentication: [INFO] User manually cancelled authentication');
        // Don't call onAuthError for manual cancellations - it's a normal user action
        return;
      }

      // Real error - log and notify
      debugPrint(
          'FlutterAhaAuthentication: [ERROR] Cidaas PlatformException: ${e.code} ${e.message}');
      widget.onAuthError
          ?.call(e.message ?? 'An unknown platform error occurred.');
    } catch (e, stack) {
      // Unexpected error - provide better error message
      debugPrint(
          'FlutterAhaAuthentication: [ERROR] Cidaas unexpected error: $e');
      debugPrint('FlutterAhaAuthentication: [ERROR] Stack trace: $stack');
      
      final errorMessage = e is DioException
          ? CidaasErrorHandler.getUserFriendlyMessage(e)
          : 'An unexpected error occurred during authentication. Please try again.';
      
      widget.onAuthError?.call(errorMessage);
    }
  }

  /// Launches Cidaas login for web platform.
  /// [clientIdOverride] is the client ID to use (classic [config.clientId] or MitID [config.cidaasClientIdMitID]).
  Future<void> _launchCidaasLoginWeb(
      CidaasConfiguration config, String clientIdOverride) async {
    debugPrint(
        'FlutterAhaAuthentication: [DEBUG] _launchCidaasLoginWeb clientId=$clientIdOverride issuer=${config.issuer} redirectWebUri=${config.redirectWebUri}');

    final cidaasWebAuth = CidaasWebAuth(_dio, config, _devAccount);
    cidaasWebAuth.initiateAuthFlow(clientIdOverride: clientIdOverride);

    // Note: The flow continues when the user returns to the callback URL.
  }

  /// Launches MitID login on mobile using the full [mitIdAuthUrl].
  /// Opens the URL in a WebView with PKCE and app redirect_uri; intercepts
  /// the callback and exchanges the code for tokens.
  Future<void> _launchMitIdLoginMobileWithFullUrl(
      CidaasConfiguration config, String clientId) async {
    final mitIdAuthUrl = config.mitIdAuthUrl?.trim();
    final issuer = config.mitIdEffectiveIssuer;
    if (mitIdAuthUrl == null ||
        mitIdAuthUrl.isEmpty ||
        issuer == null ||
        issuer.isEmpty) {
      widget.onAuthError?.call('MitID URL or issuer not configured.');
      return;
    }

    final codeVerifier = PkceUtils.generateCodeVerifier();
    final codeChallenge = PkceUtils.generateCodeChallenge(codeVerifier);
    final state = PkceUtils.generateState();
    final scopes = config.scopes.isNotEmpty
        ? config.scopes.join(' ')
        : 'openid profile email';

    final baseUri = Uri.parse(mitIdAuthUrl);
    final params = Map<String, String>.from(baseUri.queryParameters)
      ..['state'] = state
      ..['code_challenge'] = codeChallenge
      ..['code_challenge_method'] = 'S256'
      ..['redirect_uri'] = config.redirectUri
      ..['prompt'] = 'login';
    if (!params.containsKey('scope') || params['scope']!.isEmpty) {
      params['scope'] = scopes;
    }
    final authUrl = baseUri.replace(queryParameters: params);
    debugPrint(
        'FlutterAhaAuthentication: [DEBUG] MitID full URL (mobile) platform=${PlatformService.platformName} url=$authUrl');

    if (!mounted || !context.mounted) return;
    String? receivedCode;
    String? receivedState;
    final navigator = Navigator.of(context);

    // iOS: WKWebView can reload or reflow when the keyboard appears (view insets change).
    // Using resizeToAvoidBottomInset: false avoids resizing the WebView when the keyboard
    // is shown, which can reduce or prevent the unwanted reload on text field focus.
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: MediaQuery.of(dialogContext).size.width * 0.9,
            height: MediaQuery.of(dialogContext).size.height * 0.85,
            child: Scaffold(
              resizeToAvoidBottomInset: false,
              appBar: AppBar(
                title: const Text('MitID Login'),
                leading: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => navigator.pop(),
                ),
              ),
              body: WebViewWidget(
                controller: WebViewController()
                  ..setJavaScriptMode(JavaScriptMode.unrestricted)
                  ..setNavigationDelegate(
                    NavigationDelegate(
                      onNavigationRequest: (request) {
                        final uri = Uri.parse(request.url);
                        if (uri.toString().startsWith(config.redirectUri) &&
                            uri.queryParameters.containsKey('code') &&
                            uri.queryParameters.containsKey('state')) {
                          receivedCode = uri.queryParameters['code'];
                          receivedState = uri.queryParameters['state'];
                          navigator.pop();
                          return NavigationDecision.prevent;
                        }
                        if (uri.queryParameters.containsKey('error')) {
                          navigator.pop();
                          return NavigationDecision.prevent;
                        }
                        return NavigationDecision.navigate;
                      },
                    ),
                  )
                  ..loadRequest(authUrl),
              ),
            ),
          ),
        ),
      ),
    );

    if (receivedCode == null || receivedState == null) {
      debugPrint(
          'FlutterAhaAuthentication: [INFO] MitID dialog closed without code');
      return;
    }
    if (receivedState != state) {
      widget.onAuthError?.call('Invalid state (possible CSRF).');
      return;
    }

    final mobileService = CidaasMobileAuthService(
      _dio,
      const FlutterAppAuth(),
      config,
      _devAccount,
    );
    try {
      final tokenResponse = await mobileService.signInWithCidaasCode(
        _apiKey,
        _envConfig.apiUrl,
        receivedCode!,
        codeVerifier,
        clientId,
        issuer,
      );
      if (tokenResponse.accessToken != null) {
        widget.onAuthSuccess?.call(
          accessToken: tokenResponse.accessToken,
          refreshToken: tokenResponse.refreshToken,
          idToken: tokenResponse.idToken,
        );
      } else {
        widget.onAuthError?.call('Login failed, no access token.');
      }
    } on PlatformException catch (e) {
      if (e.code == CidaasErrorHandler.userCancelledCode) return;
      widget.onAuthError?.call(e.message ?? 'Authentication failed.');
    } catch (e) {
      widget.onAuthError?.call(e.toString());
    }
  }

  /// Launches Cidaas login for mobile platforms.
  /// [clientIdOverride] is the client ID to use (classic or MitID).
  Future<void> _launchCidaasLoginMobile(
      CidaasConfiguration config, String clientIdOverride) async {
    debugPrint(
        'FlutterAhaAuthentication: [DEBUG] _launchCidaasLoginMobile clientId=$clientIdOverride apiUrl=${_envConfig.apiUrl}');

    final cidaasAuthApi = CidaasAuthApiImpl(
      _dio,
      const FlutterAppAuth(),
      config,
      _devAccount,
    );

    final tokenResponse = await cidaasAuthApi.signInWithCidaas(
      _apiKey,
      _envConfig.apiUrl,
      clientIdOverride: clientIdOverride,
    );

    if (tokenResponse.accessToken != null) {
      debugPrint(
          'FlutterAhaAuthentication: [DEBUG] Cidaas login success (accessToken: ${tokenResponse.accessToken!.length} chars)');
      widget.onAuthSuccess?.call(
        accessToken: tokenResponse.accessToken,
        refreshToken: tokenResponse.refreshToken,
        idToken: tokenResponse.idToken,
      );
    } else {
      debugPrint(
          'FlutterAhaAuthentication: [ERROR] Cidaas login failed: no access token');
      widget.onAuthError?.call('Login failed, no access token.');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.controller != null) {
      final config = widget.cidaasConfiguration;
      final hasMitId = config != null &&
          (config.cidaasClientIdMitID?.trim().isNotEmpty ?? false);
      debugPrint(
          'FlutterAhaAuthentication: [DEBUG] build with controller cidaasEnabled=$_isCidaasEnabled hasMitId=$hasMitId');
      widget.controller!.setLaunchCallbacks(
        () => _launchOpenIamLogin(context),
        cidaasLogin: _isCidaasEnabled ? () => _launchCidaasLogin() : null,
        mitIdLogin: _isCidaasEnabled && hasMitId ? () => _launchMitIdLogin() : null,
      );
      return const SizedBox.shrink();
    }

    final isLoginButtonOnly = widget.isLoginButtonOnly ?? false;

    return isLoginButtonOnly
        ? _buildLoginButton(context)
        : _buildLoginForm(context);
  }

  Widget _buildLoginButton(BuildContext context) {
    final isPhone = MediaQuery.of(context).size.width < 600;

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(
          horizontal: isPhone ? 25 : 40,
          vertical: isPhone ? 4 : 15,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(5),
        ),
      ),
      onPressed: () => _launchOpenIamLogin(context),
      child: Text(
        'Log in',
        style: TextStyle(
          color: const Color(0xFF173A78),
          fontSize: isPhone ? 16 : 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildLoginForm(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    final isPhone = width < 600;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (widget.projectLogoAsset != null)
            Image.asset(
              widget.projectLogoAsset!,
              width: width / 4,
              height: height / 6,
            ),
          Container(
            margin: EdgeInsets.only(top: isPhone ? 10 : 20),
            padding: EdgeInsets.symmetric(
              horizontal: isPhone ? 20 : 50,
              vertical: isPhone ? 8 : 20,
            ),
            width: isPhone ? width * 0.9 : width * 0.5,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(10),
              boxShadow: const [
                BoxShadow(
                  color: Colors.grey,
                  offset: Offset(0, 1),
                  blurRadius: 1,
                  spreadRadius: 1,
                )
              ],
            ),
            child: Form(
              key: widget.formKey,
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Text(
                    widget.projectName ?? _projectName,
                    style: TextStyle(
                      fontSize: isPhone ? 18 : 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildAuthButtons(context, isPhone),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthButtons(BuildContext context, bool isPhone) {
    // Always use local assets for both Cidaas and OpenIAM to avoid
    // CORS issues on web and network loading issues on mobile

    // iOS workaround: after first attempt, show "Continue" button
    debugPrint(
        '🔘 Button state - isIOS: ${PlatformService.isIOS}, firstAttemptDone: $_cidaasFirstAttemptDone');
    final cidaasButtonName = (PlatformService.isIOS && _cidaasFirstAttemptDone)
        ? 'Continue'
        : 'Cidaas';
    debugPrint('🔘 Button name: $cidaasButtonName');

    final config = widget.cidaasConfiguration;
    final hasMitId = config != null &&
        (config.cidaasClientIdMitID?.trim().isNotEmpty ?? false);
    debugPrint(
        'FlutterAhaAuthentication: [DEBUG] _buildAuthButtons cidaas=$_isCidaasEnabled openiam=$_isOpeniamEnabled hasMitId=$hasMitId');

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 20,
      runSpacing: 10,
      children: [
        if (_isCidaasEnabled)
          _SignInAlternatives(
            name: cidaasButtonName,
            logo: _cidaasLogoAsset,
            isAsset: true,
            onPressed: _launchCidaasLogin,
            // Show highlight effect after first attempt on iOS
            highlighted: PlatformService.isIOS && _cidaasFirstAttemptDone,
          ),
        if (_isCidaasEnabled && hasMitId)
          _SignInAlternatives(
            name: 'MitID',
            logo: _cidaasLogoAsset,
            isAsset: true,
            onPressed: _launchMitIdLogin,
          ),
        if (_isOpeniamEnabled)
          _SignInAlternatives(
            name: _openIamTitle.isNotEmpty ? _openIamTitle : 'Abena ID',
            logo: _openIamLogoAsset,
            isAsset: true,
            onPressed: () {
              if (widget.environment != 'production') {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('$_openiamLoginUrl')),
                );
              }
              _launchOpenIamLogin(context);
            },
          ),
        if (widget.enableGoogleLogin)
          _SignInAlternatives(
            name: 'Google',
            logo: 'google',
            isAsset: false,
            onPressed: () => widget.onPressedGoogleLogin?.call(),
          ),
      ],
    );
  }
}

/// Widget to display sign-in alternatives
class _SignInAlternatives extends StatelessWidget {
  final String logo;
  final String name;
  final bool isAsset;
  final VoidCallback onPressed;
  final bool highlighted;

  const _SignInAlternatives({
    required this.logo,
    required this.name,
    required this.onPressed,
    this.isAsset = false,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final isPhone = MediaQuery.of(context).size.width < 600;
    final size = isPhone ? 50.0 : 60.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor:
                highlighted ? Colors.blue.shade50 : Colors.transparent,
            elevation: highlighted ? 2 : 0,
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(
                color: highlighted ? Colors.blue : Colors.grey,
                width: highlighted ? 2 : 1,
              ),
            ),
          ),
          child: Container(
            width: size,
            height: size,
            padding: const EdgeInsets.all(8),
            child: _buildLogo(isPhone),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          name,
          style: TextStyle(
            fontSize: isPhone ? 12 : 14,
            fontWeight: highlighted ? FontWeight.bold : FontWeight.normal,
            color: highlighted ? Colors.blue : null,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildLogo(bool isPhone) {
    final size = isPhone ? 34.0 : 44.0;

    // Load from local asset
    if (isAsset && logo.isNotEmpty) {
      // Handle SVG assets
      if (logo.endsWith('.svg')) {
        return SvgPicture.asset(
          logo,
          package: 'flutter_ahamatic_authentication',
          width: size,
          height: size,
          fit: BoxFit.contain,
          placeholderBuilder: (context) => _buildLoadingIndicator(size),
        );
      }

      // Handle PNG/JPG assets
      return Image.asset(
        logo,
        package: 'flutter_ahamatic_authentication',
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          debugPrint('Error loading asset $logo: $error');
          return _buildFallbackIcon(size);
        },
      );
    }

    // Load from network URL
    if (logo.isNotEmpty && !isAsset) {
      // Handle SVG files from network
      if (logo.endsWith('.svg')) {
        return SvgPicture.network(
          logo,
          width: size,
          height: size,
          fit: BoxFit.contain,
          placeholderBuilder: (context) => _buildLoadingIndicator(size),
        );
      }

      // Handle regular images from network
      return CachedNetworkImage(
        imageUrl: logo,
        width: size,
        height: size,
        fit: BoxFit.contain,
        placeholder: (context, url) => _buildLoadingIndicator(size),
        errorWidget: (context, url, error) {
          debugPrint('Error loading network image $logo: $error');
          return _buildFallbackIcon(size);
        },
      );
    }

    // Fallback icon when logo is empty
    return _buildFallbackIcon(size);
  }

  /// Builds a loading indicator
  Widget _buildLoadingIndicator(double size) {
    return SizedBox(
      width: size,
      height: size,
      child: const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  /// Builds a fallback icon based on the name
  Widget _buildFallbackIcon(double size) {
    // Determine icon color based on name
    Color bgColor;
    String letter;

    if (name.toLowerCase().contains('cidaas')) {
      bgColor = const Color(0xFF1A1A2E);
      letter = 'C';
    } else if (name.toLowerCase().contains('abena') ||
        name.toLowerCase().contains('openiam')) {
      bgColor = const Color(0xFF6366F1);
      letter = 'A';
    } else if (name.toLowerCase().contains('google')) {
      bgColor = const Color(0xFF4285F4);
      letter = 'G';
    } else {
      bgColor = Colors.grey;
      letter = name.isNotEmpty ? name[0].toUpperCase() : '?';
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Center(
        child: Text(
          letter,
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.45,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
