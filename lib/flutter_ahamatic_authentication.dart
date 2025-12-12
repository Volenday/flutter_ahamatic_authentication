// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_ahamatic_authentication/cidaas/cidaas_entity.dart';
import 'package:flutter_ahamatic_authentication/cidaas/cidaas_api.dart';
import 'package:flutter_ahamatic_authentication/models/app_config.dart';
import 'package:flutter_ahamatic_authentication/services/ahamatic_api_service.dart';
import 'package:flutter_ahamatic_authentication/services/openiam_auth_service.dart';
import 'package:flutter_ahamatic_authentication/services/auth_logging_service.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:universal_html/html.dart' as html;

// Re-export entities to make them accessible from the main package
export 'package:flutter_ahamatic_authentication/cidaas/cidaas_entity.dart';
export 'package:flutter_ahamatic_authentication/models/app_config.dart';

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
  int _loadingPercentage = 0;
  String? _openiamLoginUrl;

  // WebView
  final _webViewKey = UniqueKey();
  late final WebViewController _webViewController;
  final Set<Factory<OneSequenceGestureRecognizer>> _gestureRecognizers = {
    Factory(() => EagerGestureRecognizer())
  };

  // Development credentials
  final _devAccount = {
    'emailAddress': 'developers@volenday.com',
    'password': 'V0l3nd@yP@ssw0rd',
  };

  // Current web URL
  String get _currentWebUrl => kIsWeb ? html.window.location.href : '';

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _initializeWebView();
    _loadInitialData();
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

    debugPrint('Services initialized with environment: ${widget.environment}');
  }

  /// Initializes the WebViewController for native apps
  void _initializeWebView() {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: _onWebViewProgress,
          onPageStarted: _onWebViewPageStarted,
          onPageFinished: _onWebViewPageFinished,
          onWebResourceError: _onWebViewError,
          onNavigationRequest: _onWebViewNavigationRequest,
        ),
      );

    if (!kIsWeb) {
      WebViewCookieManager().clearCookies();
      debugPrint('WebView cookies cleared');
    }
  }

  void _onWebViewProgress(int progress) {
    setState(() => _loadingPercentage = progress);
  }

  void _onWebViewPageStarted(String url) {
    setState(() => _loadingPercentage = 0);
  }

  void _onWebViewPageFinished(String url) {
    setState(() => _loadingPercentage = 100);
  }

  void _onWebViewError(WebResourceError error) {
    debugPrint('WebView error: ${error.errorCode} - ${error.description}');
  }

  Future<NavigationDecision> _onWebViewNavigationRequest(
    NavigationRequest request,
  ) async {
    final uri = Uri.parse(request.url);

    if (uri.queryParameters.containsKey('refreshToken')) {
      final token = uri.queryParameters['token'];
      if (token != null) {
        await _handleAuthenticationSuccess(token);
      }
      return NavigationDecision.prevent;
    }

    return NavigationDecision.navigate;
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
      isWeb: kIsWeb,
    );

    if (loginUrl == null) {
      debugPrint('Could not generate login URL');
      return;
    }

    _openiamLoginUrl = loginUrl;

    if (widget.externalBrowserLogin == true) {
      await launchUrl(
        Uri.parse(loginUrl),
        mode: LaunchMode.externalApplication,
      );
      return;
    }

    if (kIsWeb) {
      html.window.open(loginUrl, '_self');
    } else {
      _webViewController.loadRequest(Uri.parse(loginUrl));
      _showWebViewDialog(context, loginUrl);
    }
  }

  /// Shows the WebView dialog for login
  void _showWebViewDialog(BuildContext context, String url) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Scaffold(
              backgroundColor: Colors.transparent,
              body: Stack(
                children: [
                  AlertDialog(
                    contentPadding: const EdgeInsets.fromLTRB(5, 5, 5, 10),
                    insetPadding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                    content: Column(
                      children: [
                        _buildCloseButton(dialogContext),
                        Expanded(
                          child: SizedBox(
                            width: MediaQuery.of(context).size.width,
                            height: MediaQuery.of(context).size.height * 0.9,
                            child: Stack(
                              children: [
                                _buildWebView(),
                                if (_loadingPercentage < 100)
                                  const Center(
                                    child: CircularProgressIndicator(
                                      color: Color(0xFF003D7F),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCloseButton(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: const Align(
        alignment: Alignment.topRight,
        child: Icon(
          Icons.close,
          color: Colors.red,
          size: 30,
          textDirection: TextDirection.rtl,
        ),
      ),
    );
  }

  Widget _buildWebView() {
    return WebViewWidget(
      key: _webViewKey,
      controller: _webViewController,
      gestureRecognizers: _gestureRecognizers,
    );
  }

  /// Launches the Cidaas login flow
  Future<void> _launchCidaasLogin() async {
    final config = widget.cidaasConfiguration;

    if (config == null) {
      debugPrint('Error: CidaasConfiguration not provided');
      widget.onAuthError?.call('Cidaas configuration not provided.');
      return;
    }

    try {
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
    } on PlatformException catch (e) {
      debugPrint('Cidaas PlatformException: ${e.message}');
      widget.onAuthError
          ?.call(e.message ?? 'An unknown platform error occurred.');
    } catch (e) {
      debugPrint('Cidaas unexpected error: $e');
      widget.onAuthError?.call('An unexpected error occurred: $e');
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
