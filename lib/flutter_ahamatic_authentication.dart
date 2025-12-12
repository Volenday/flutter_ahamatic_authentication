// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_ahamatic_authentication/cidaas/cidaas_entity.dart';
import 'package:flutter_ahamatic_authentication/cidaas/cidaas_api.dart';
import 'package:flutter_ahamatic_authentication/models/app_config.dart';
import 'package:flutter_ahamatic_authentication/services/ahamatic_api_service.dart';
import 'package:flutter_ahamatic_authentication/services/openiam_auth_service.dart';
import 'package:flutter_ahamatic_authentication/services/auth_logging_service.dart';
import 'package:flutter_ahamatic_authentication/services/platform_service.dart';
import 'package:flutter_ahamatic_authentication/widgets/auth_webview.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:url_launcher/url_launcher.dart';

// Conditional import for web-specific functionality
import 'package:flutter_ahamatic_authentication/cidaas/cidaas_web_auth.dart'
    if (dart.library.io) 'package:flutter_ahamatic_authentication/cidaas/cidaas_api.dart';
import 'package:universal_html/html.dart' as html;

// Re-export entities to make them accessible from the main package
export 'package:flutter_ahamatic_authentication/cidaas/cidaas_entity.dart';
export 'package:flutter_ahamatic_authentication/models/app_config.dart';
export 'package:flutter_ahamatic_authentication/services/platform_service.dart';
export 'package:flutter_ahamatic_authentication/widgets/auth_webview.dart';
export 'package:flutter_ahamatic_authentication/widgets/oauth_callback_handler.dart';

/// Supported login types
enum LoginType { azure, mitId, openIAM, cidaas }

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
          'Module config loaded: Cidaas=$_isCidaasEnabled, OpenIAM=$_isOpeniamEnabled');
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
      debugPrint('Could not generate login URL');
      widget.onAuthError?.call('Could not generate login URL');
      return;
    }

    _openiamLoginUrl = loginUrl;
    debugPrint('OpenIAM Login URL: $loginUrl');

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
          debugPrint('Auth dialog closed by user');
        },
      );
    }
  }

  /// Launches the Cidaas login flow
  ///
  /// On mobile, uses flutter_appauth for native OAuth2 flow.
  /// On web, uses standard OAuth2 with redirect/popup.
  Future<void> _launchCidaasLogin() async {
    final config = widget.cidaasConfiguration;

    if (config == null) {
      debugPrint('Error: CidaasConfiguration not provided');
      widget.onAuthError?.call('Cidaas configuration not provided.');
      return;
    }

    try {
      if (PlatformService.isWeb) {
        // Web: Use OAuth2 redirect flow
        await _launchCidaasLoginWeb(config);
      } else {
        // Mobile: Use flutter_appauth
        await _launchCidaasLoginMobile(config);
      }
    } on PlatformException catch (e) {
      debugPrint('Cidaas PlatformException: ${e.message}');
      widget.onAuthError
          ?.call(e.message ?? 'An unknown platform error occurred.');
    } catch (e) {
      debugPrint('Cidaas unexpected error: $e');
      widget.onAuthError?.call('An unexpected error occurred: $e');
    }
  }

  /// Launches Cidaas login for web platform
  Future<void> _launchCidaasLoginWeb(CidaasConfiguration config) async {
    debugPrint('Launching Cidaas login for web');

    final cidaasWebAuth = CidaasWebAuth(_dio, config, _devAccount);

    // Initiate the OAuth2 flow - this will redirect the browser
    cidaasWebAuth.initiateAuthFlow();

    // Note: The flow continues when the user returns to the callback URL.
    // The callback handling should be done in initState or a dedicated callback page.
  }

  /// Launches Cidaas login for mobile platforms
  Future<void> _launchCidaasLoginMobile(CidaasConfiguration config) async {
    debugPrint('Launching Cidaas login for mobile');

    final cidaasAuthApi = CidaasAuthApiImpl(
      _dio,
      const FlutterAppAuth(),
      config,
      _devAccount,
    );

    final tokenResponse = await cidaasAuthApi.signInWithCidaas(
      _apiKey,
      _envConfig.apiUrl,
    );

    if (tokenResponse.accessToken != null) {
      debugPrint('Cidaas login successful');
      widget.onAuthSuccess?.call(
        accessToken: tokenResponse.accessToken,
        refreshToken: tokenResponse.refreshToken,
        idToken: tokenResponse.idToken,
      );
    } else {
      debugPrint('Cidaas login failed: no access token');
      widget.onAuthError?.call('Login failed, no access token.');
    }
  }

  @override
  Widget build(BuildContext context) {
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (_isCidaasEnabled)
          _SignInAlternatives(
            name: 'Cidaas',
            logo:
                'https://brandfetch.com/cidaas.com?view=library&library=default&collection=logos&asset=idSp1mW6xT',
            onPressed: _launchCidaasLogin,
          ),
        if (_isOpeniamEnabled)
          _SignInAlternatives(
            name: _openIamTitle,
            logo: _openIamLogo,
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
  final VoidCallback onPressed;

  const _SignInAlternatives({
    required this.logo,
    required this.name,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isPhone = MediaQuery.of(context).size.width < 600;
    final size = isPhone ? 50.0 : 60.0;

    return Column(
      children: [
        ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            elevation: 0,
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: const BorderSide(color: Colors.grey),
            ),
          ),
          child: Container(
            width: size,
            height: size,
            padding: const EdgeInsets.all(10),
            child: _buildLogo(isPhone),
          ),
        ),
        const SizedBox(height: 10),
        Text(name, style: TextStyle(fontSize: isPhone ? 12 : 14)),
      ],
    );
  }

  Widget _buildLogo(bool isPhone) {
    final size = isPhone ? 50.0 : 60.0;

    return CachedNetworkImage(
      imageUrl: logo,
      placeholder: (context, url) => const CircularProgressIndicator(),
      errorWidget: (context, url, error) {
        if (logo.startsWith('assets/')) {
          return Image.asset(
            logo,
            width: size,
            height: size,
            fit: BoxFit.contain,
          );
        }
        return const Icon(Icons.error);
      },
    );
  }
}
