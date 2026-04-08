import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ahamatic_authentication/flutter_ahamatic_authentication.dart';
import 'package:flutter_ahamatic_authentication/cidaas/cidaas_web_auth.dart';
import 'package:flutter_ahamatic_authentication/services/ahamatic_api_service.dart';
import 'package:flutter_ahamatic_authentication/services/platform_service.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:go_router/go_router.dart';

// ============================================================================
// ERROR HANDLING UTILITIES
// ============================================================================

/// Logs error details to console and returns a user-friendly message
String _handleError(Object error, StackTrace stackTrace, String context) {
  // Log detailed error to console
  debugPrint('');
  debugPrint('╔══════════════════════════════════════════════════════════════');
  debugPrint('║ ❌ ERROR: $context');
  debugPrint('╠══════════════════════════════════════════════════════════════');
  debugPrint('║ Type: ${error.runtimeType}');
  debugPrint('║ Message: $error');

  // If it's a DioException, log HTTP details
  if (error is DioException) {
    debugPrint(
        '╠══════════════════════════════════════════════════════════════');
    debugPrint('║ HTTP DETAILS:');
    debugPrint(
        '╠══════════════════════════════════════════════════════════════');
    debugPrint('║ Exception Type: ${error.type}');
    debugPrint('║ Request URL: ${error.requestOptions.uri}');
    debugPrint('║ Request Method: ${error.requestOptions.method}');

    if (error.response != null) {
      debugPrint('║ Status Code: ${error.response?.statusCode}');
      debugPrint('║ Status Message: ${error.response?.statusMessage}');
      debugPrint('║ Response Headers:');
      error.response?.headers.forEach((name, values) {
        debugPrint('║   $name: ${values.join(", ")}');
      });
      debugPrint('║ Response Body:');
      final responseData = error.response?.data;
      if (responseData != null) {
        final bodyStr = responseData.toString();
        // Truncate if too long
        if (bodyStr.length > 500) {
          debugPrint('║   ${bodyStr.substring(0, 500)}...');
          debugPrint('║   (truncated, ${bodyStr.length} total characters)');
        } else {
          debugPrint('║   $bodyStr');
        }
      }
    } else {
      debugPrint('║ No response received from server');
    }
  }

  debugPrint('╠══════════════════════════════════════════════════════════════');
  debugPrint('║ STACK TRACE:');
  debugPrint('╠══════════════════════════════════════════════════════════════');

  // Print stack trace line by line for better readability
  final stackLines = stackTrace.toString().split('\n');
  for (final line in stackLines.take(15)) {
    if (line.trim().isNotEmpty) {
      debugPrint('║ $line');
    }
  }
  if (stackLines.length > 15) {
    debugPrint('║ ... (${stackLines.length - 15} more lines)');
  }
  debugPrint('╚══════════════════════════════════════════════════════════════');
  debugPrint('');

  // Return user-friendly message based on error type
  if (error is DioException) {
    return _getDioErrorMessage(error);
  }

  if (error is FormatException) {
    return 'Invalid data format received. Please try again.';
  }

  if (error is TypeError) {
    return 'Error processing server response. Please try again.';
  }

  final errorStr = error.toString().toLowerCase();

  if (errorStr.contains('timeout') || errorStr.contains('timed out')) {
    return 'Connection timed out. Please check your internet connection and try again.';
  }

  if (errorStr.contains('socket') ||
      errorStr.contains('network') ||
      errorStr.contains('connection')) {
    return 'Connection error. Please check your internet connection and try again.';
  }

  if (errorStr.contains('unauthorized') || errorStr.contains('401')) {
    return 'Invalid session. Please sign in again.';
  }

  if (errorStr.contains('forbidden') || errorStr.contains('403')) {
    return 'You do not have permission to perform this action.';
  }

  // Generic message for unknown errors
  return 'An unexpected error occurred. Please try again later.';
}

/// Get user-friendly message for Dio errors
String _getDioErrorMessage(DioException error) {
  switch (error.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return 'Connection timed out. Please check your internet connection and try again.';

    case DioExceptionType.connectionError:
      return 'Could not connect to the server. Please check your internet connection.';

    case DioExceptionType.badCertificate:
      return 'Security error in connection. Please contact technical support.';

    case DioExceptionType.badResponse:
      final statusCode = error.response?.statusCode;
      switch (statusCode) {
        case 400:
          return 'Invalid request. Please verify the data and try again.';
        case 401:
          return 'Session expired or invalid credentials. Please sign in again.';
        case 403:
          return 'You do not have permission to perform this action.';
        case 404:
          return 'The requested resource was not found.';
        case 500:
        case 502:
        case 503:
          return 'The server is experiencing issues. Please try again later.';
        default:
          return 'Server error (code: $statusCode). Please try again later.';
      }

    case DioExceptionType.cancel:
      return 'The operation was cancelled.';

    case DioExceptionType.unknown:
      if (error.message?.contains('SocketException') == true) {
        return 'Could not connect to the server. Please check your internet connection.';
      }
      return 'A connection error occurred. Please try again.';
  }
}

// ============================================================================
// CONFIGURATION
// ============================================================================

// Same config as Bevilling (Reimbursement-App): production
const environment = "production";
String get apiURL {
  switch (environment) {
    case 'production':
      return 'https://api-eu.ahamatic.com';
    case 'sandbox':
      return 'https://test.api.ahamatic.com';
    case 'development':
    default:
      return 'https://dev.api.ahamatic.com';
  }
}

final dio = Dio();

const devAccount = {
  'emailAddress': 'developers@volenday.com',
  'password': 'V0l3nd@yP@ssw0rd',
};

/// Bevilling Cidaas configuration (hardcoded for testing).
CidaasConfiguration getBevillingCidaasConfig() {
  const clientId = 'ee75cd84-4622-4e7e-8b50-c5bbd79576ac';
  const clientIdMitID = '5fd6af67-1820-42f5-85fd-4dc236d00d65';
  const issuer = 'https://test-login.abena.com';
  const redirectUri = 'app://reimbursment/oauth2redirect';
  const postLogoutUri = 'app://reimbursment/logout';
  const mitIdAuthUrl =
      'https://test-login.abena.com/authz-srv/authz?client_id=5fd6af67-1820-42f5-85fd-4dc236d00d65&redirect_uri=https%3A%2F%2Fwww.bevilling.dk%2FLogin%2FCallback&response_type=code&preferred_login=mitid';

  return CidaasConfiguration(
    clientId: clientId,
    issuer: issuer,
    redirectUri: redirectUri,
    postLogoutRedirectUri: postLogoutUri,
    discoveryUrl: '$issuer/.well-known/openid-configuration',
    cidaasClientIdMitID: clientIdMitID,
    mitIdAuthUrl: mitIdAuthUrl,
    scopes: [
      'openid',
      'profile',
      'email',
      'phone',
      'address',
      'offline_access',
      'identities',
      'roles',
      'groups',
    ],
  );
}

/// Gets the Cidaas configuration (Bevilling). On web adds redirect URIs for browser.
CidaasConfiguration getCidaasConfig() {
  final config = getBevillingCidaasConfig();
  final isWeb = PlatformService.isWeb;

  final CidaasConfiguration effectiveConfig;
  if (isWeb) {
    const redirectWebUri = 'http://localhost:8080/callback';
    const postLogoutWebUri = 'http://localhost:8080/';
    effectiveConfig = CidaasConfiguration(
      clientId: config.clientId,
      issuer: config.issuer,
      redirectUri: config.redirectUri,
      postLogoutRedirectUri: config.postLogoutRedirectUri,
      discoveryUrl: config.discoveryUrl,
      scopes: config.scopes,
      redirectWebUri: redirectWebUri,
      postLogoutWebUri: postLogoutWebUri,
      cidaasClientIdMitID: config.cidaasClientIdMitID,
      mitIdAuthUrl: config.mitIdAuthUrl,
    );
  } else {
    effectiveConfig = config;
  }

  debugPrint('═══════════════════════════════════════════════════════');
  debugPrint('📱 CIDAAS CONFIG - Platform: ${isWeb ? "WEB" : "MOBILE"}');
  debugPrint('═══════════════════════════════════════════════════════');
  debugPrint('  clientId: ${effectiveConfig.clientId}');
  debugPrint('  issuer: ${effectiveConfig.issuer}');
  debugPrint('  redirectUri: ${effectiveConfig.redirectUri}');
  debugPrint(
      '  postLogoutRedirectUri: ${effectiveConfig.postLogoutRedirectUri}');
  debugPrint('  discoveryUrl: ${effectiveConfig.discoveryUrl}');
  debugPrint('  scopes: ${effectiveConfig.scopes}');
  debugPrint('  cidaasClientIdMitID: ${effectiveConfig.cidaasClientIdMitID}');
  debugPrint('  mitIdAuthUrl: ${effectiveConfig.mitIdAuthUrl ?? "(not set)"}');
  if (effectiveConfig.redirectWebUri != null) {
    debugPrint('  redirectWebUri: ${effectiveConfig.redirectWebUri}');
  }
  if (effectiveConfig.postLogoutWebUri != null) {
    debugPrint('  postLogoutWebUri: ${effectiveConfig.postLogoutWebUri}');
  }
  debugPrint('═══════════════════════════════════════════════════════');

  return effectiveConfig;
}

// Global authentication state
String? _accessToken;
String? _refreshToken;
String? _idToken;

// ============================================================================
// ROUTER
// ============================================================================

final router = GoRouter(
  initialLocation: '/',
  debugLogDiagnostics: true,
  redirect: (context, state) {
    debugPrint('🚦 ROUTER - Path: ${state.uri.path}');
    debugPrint('🚦 ROUTER - Full URI: ${state.uri}');
    debugPrint('🚦 ROUTER - Query params: ${state.uri.queryParameters}');
    return null; // No redirect
  },
  routes: [
    GoRoute(path: '/', builder: (_, __) => const LoginPage()),
    GoRoute(
      path: '/callback',
      builder: (context, state) {
        debugPrint('📍 CALLBACK ROUTE - Building CallbackPage');
        debugPrint('📍 Query params: ${state.uri.queryParameters}');
        return const CallbackPage();
      },
    ),
    GoRoute(path: '/home', builder: (_, __) => const HomePage()),
  ],
);

// ============================================================================
// MAIN
// ============================================================================

void main() {
  // Use path URL strategy (URLs without hash #) for OAuth callbacks to work
  usePathUrlStrategy();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Cidaas Test',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
    );
  }
}

// ============================================================================
// LOGIN PAGE
// ============================================================================

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _assetsPreloaded = false;
  bool _useCustomButtons = false;
  final _authController = AhamaticAuthController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_assetsPreloaded) {
      _precacheAssets();
    }
  }

  Future<void> _precacheAssets() async {
    debugPrint('📦 Preloading assets...');

    // Preload library assets
    await Future.wait([
      precacheImage(
        const AssetImage(
          'assets/cidaas/cidaas_logo.png',
          package: 'flutter_ahamatic_authentication',
        ),
        context,
      ),
      precacheImage(
        const AssetImage(
          'assets/openiam/abena_logo.png',
          package: 'flutter_ahamatic_authentication',
        ),
        context,
      ),
    ]);

    debugPrint('✅ Assets preloaded');
    if (mounted) {
      setState(() => _assetsPreloaded = true);
    }
  }

  void _onAuthSuccess(
      {String? accessToken, String? refreshToken, String? idToken}) {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    _idToken = idToken;
    if (mounted) context.go('/home');
  }

  void _onAuthError(String error) {
    final userMessage = _handleError(
      error,
      StackTrace.current,
      'Authentication error in FlutterAhaAuthentication',
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(userMessage),
        backgroundColor: Colors.red[700],
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      appBar: AppBar(title: const Text('Plugin example app')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ChoiceChip(
                    label: const Text('Default form'),
                    selected: !_useCustomButtons,
                    onSelected: (selected) {
                      if (selected) setState(() => _useCustomButtons = false);
                    },
                  ),
                  const SizedBox(width: 12),
                  ChoiceChip(
                    label: const Text('Custom buttons (Controller)'),
                    selected: _useCustomButtons,
                    onSelected: (selected) {
                      if (selected) setState(() => _useCustomButtons = true);
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: _useCustomButtons
                    ? _buildCustomButtonsExample(context)
                    : FlutterAhaAuthentication(
                        moduleName: 'Reimbursment-App',
                        moduleWebName: 'Reimbursment-App',
                        projectLogoAsset: 'assets/images/sample_logo.png',
                        applicationCode: 'abenadata',
                        environment: 'production',
                        europe: false,
                        cidaasConfiguration: getCidaasConfig(),
                        onAuthSuccess: _onAuthSuccess,
                        onAuthError: _onAuthError,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Example: login using [AhamaticAuthController] with your own buttons.
  /// The widget is in the tree only to wire the controller; it renders
  /// [SizedBox.shrink]. Your buttons call [launchOpenIamLogin] and
  /// [launchCidaasLogin].
  Widget _buildCustomButtonsExample(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Widget with controller: registers callbacks, renders nothing
          FlutterAhaAuthentication(
            controller: _authController,
            moduleName: 'Reimbursment-App',
            moduleWebName: 'Reimbursment-App',
            applicationCode: 'abenadata',
            environment: 'production',
            europe: false,
            cidaasConfiguration: getCidaasConfig(),
            onAuthSuccess: _onAuthSuccess,
            onAuthError: _onAuthError,
          ),
          const SizedBox(height: 24),
          const Text(
            'Custom buttons (Controller)',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'These buttons use the same login logic via AhamaticAuthController.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
          const SizedBox(height: 20),
          // Log in as citizen = MitID (same as Bevilling; OpenIAM is not enabled in this module)
          SizedBox(
            width: MediaQuery.of(context).size.width,
            child: ElevatedButton(
              onPressed: () => _authController.launchMitIdLogin(),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.green,
                minimumSize: const Size(40, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(3.0),
                ),
              ),
              child: const Text(
                'Log in as citizen',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Log in as commune = Cidaas classic
          SizedBox(
            width: MediaQuery.of(context).size.width,
            child: OutlinedButton(
              onPressed: () => _authController.launchCidaasLogin(),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(40, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(3.0),
                ),
              ),
              child: const Text(
                'Log in with Cidaas (classic)',
                style: TextStyle(fontSize: 14),
              ),
            ),
          ),
          if (getCidaasConfig().cidaasClientIdMitID != null &&
              getCidaasConfig().cidaasClientIdMitID!.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: MediaQuery.of(context).size.width,
              child: OutlinedButton(
                onPressed: () => _authController.launchMitIdLogin(),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(40, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(3.0),
                  ),
                ),
                child: const Text(
                  'Log in with MitID',
                  style: TextStyle(fontSize: 14),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ============================================================================
// CALLBACK PAGE (OAuth redirect on web)
// ============================================================================

class CallbackPage extends StatefulWidget {
  const CallbackPage({super.key});

  @override
  State<CallbackPage> createState() => _CallbackPageState();
}

class _CallbackPageState extends State<CallbackPage>
    with SingleTickerProviderStateMixin {
  String? _error;
  String _statusMessage = 'Starting authentication...';
  String _statusEmoji = '🔐';
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _fadeController.forward();
    _handleCallback();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _updateStatus(String message, String emoji) {
    if (mounted) {
      _fadeController.reverse().then((_) {
        if (mounted) {
          setState(() {
            _statusMessage = message;
            _statusEmoji = emoji;
          });
          _fadeController.forward();
        }
      });
    }
  }

  Future<void> _handleCallback() async {
    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('🔄 CALLBACK - Starting processing...');
    debugPrint('═══════════════════════════════════════════════════════');

    if (!PlatformService.isWeb) {
      debugPrint('');
      debugPrint(
          '╔══════════════════════════════════════════════════════════════');
      debugPrint('║ ❌ ERROR: Platform not supported');
      debugPrint(
          '╠══════════════════════════════════════════════════════════════');
      debugPrint('║ The callback page only works on web platform.');
      debugPrint('║ On mobile, the callback is handled natively.');
      debugPrint(
          '╚══════════════════════════════════════════════════════════════');
      debugPrint('');
      setState(
          () => _error = 'This feature is only available in the web version.');
      return;
    }

    try {
      // 1. Get the apiKey from module config
      _updateStatus('Getting configuration...', '⚙️');
      await Future.delayed(const Duration(milliseconds: 400));

      debugPrint('🔑 Getting module configuration...');
      final ahamaticApiService =
          AhamaticApiServiceImpl(dio: dio, apiUrl: apiURL);
      final moduleConfig = await ahamaticApiService.getModuleConfig(
        'abenadata',
        'Reimbursment-App',
      );
      final apiKey = moduleConfig.apiKey ?? '';
      debugPrint(
          '🔑 ApiKey obtained: ${apiKey.isEmpty ? "(empty)" : "${apiKey.substring(0, 10)}..."}');

      if (apiKey.isEmpty) {
        debugPrint('');
        debugPrint(
            '╔══════════════════════════════════════════════════════════════');
        debugPrint('║ ❌ ERROR: API Key not found');
        debugPrint(
            '╠══════════════════════════════════════════════════════════════');
        debugPrint(
            '║ Could not retrieve the apiKey from module configuration.');
        debugPrint('║ Module: abenadata / Reimbursment-App');
        debugPrint('║ Please verify that the module is properly configured.');
        debugPrint(
            '╚══════════════════════════════════════════════════════════════');
        debugPrint('');
        setState(() => _error =
            'Configuration error: Could not retrieve the API key from the module. Please contact the administrator.');
        return;
      }

      // 2. Validate authorization code
      _updateStatus('Validating authorization code...', '🔑');
      await Future.delayed(const Duration(milliseconds: 400));

      final config = getCidaasConfig();
      debugPrint('🔑 Cidaas Config loaded: ${config.clientId}');

      final cidaasWebAuth = CidaasWebAuth(dio, config, devAccount);
      debugPrint('🔑 CidaasWebAuth created');

      final authResult = cidaasWebAuth.handleCallback();
      debugPrint('🔑 handleCallback executed');

      if (authResult == null) {
        debugPrint('');
        debugPrint(
            '╔══════════════════════════════════════════════════════════════');
        debugPrint('║ ❌ ERROR: Authorization code not found');
        debugPrint(
            '╠══════════════════════════════════════════════════════════════');
        debugPrint('║ The authorization code was not found in the URL');
        debugPrint(
            '║ or the "state" parameter does not match the expected value.');
        debugPrint('║ This can happen if:');
        debugPrint('║   - The session expired during the login process');
        debugPrint(
            '║   - The /callback page was accessed directly without prior authorization');
        debugPrint('║   - There was a security issue (CSRF)');
        debugPrint(
            '╚══════════════════════════════════════════════════════════════');
        debugPrint('');
        setState(() =>
            _error = 'Authorization code not found. Please sign in again.');
        return;
      }

      debugPrint(
          '✅ Code obtained: ${authResult.authorizationCode.substring(0, 10)}...');

      // 3. Exchange code for Cidaas tokens
      _updateStatus('Exchanging code for tokens...', '🔄');
      await Future.delayed(const Duration(milliseconds: 400));

      debugPrint('🔄 Exchanging code for tokens...');

      // 4. This method internally logs into Ahamatic
      _updateStatus('Connecting to Ahamatic...', '🌐');

      final response =
          await cidaasWebAuth.signInComplete(apiKey, apiURL, authResult);

      // 5. Tokens received
      _updateStatus('Tokens received, preparing session...', '✅');
      await Future.delayed(const Duration(milliseconds: 500));

      debugPrint('✅ Tokens received!');
      debugPrint(
          '  - Access Token: ${response.accessToken?.substring(0, 20)}...');

      _accessToken = response.accessToken;
      _refreshToken = response.refreshToken;
      _idToken = response.idToken;

      // 6. Finished
      _updateStatus('Done! Redirecting...', '🚀');
      await Future.delayed(const Duration(milliseconds: 600));

      if (mounted) context.go('/home');
    } catch (e, stackTrace) {
      final userMessage = _handleError(
        e,
        stackTrace,
        'OAuth callback processing',
      );
      setState(() => _error = userMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Authentication Error',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  _error!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => context.go('/'),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Back to home'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
            const SizedBox(height: 32),
            FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  Text(
                    _statusEmoji,
                    style: const TextStyle(fontSize: 32),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _statusMessage,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.grey[700],
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Please wait a moment...',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[500],
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// HOME PAGE (displays tokens)
// ============================================================================

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  void _handleLogout(BuildContext context) {
    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('🚪 LOGOUT - Starting logout process...');
    debugPrint('═══════════════════════════════════════════════════════');

    final savedIdToken = _idToken;

    // Clear local tokens first
    _accessToken = null;
    _refreshToken = null;
    _idToken = null;

    if (PlatformService.isWeb) {
      // On web: use CidaasWebAuth.signOut() to invalidate session on Cidaas
      final config = getCidaasConfig();
      final cidaasWebAuth = CidaasWebAuth(dio, config, devAccount);

      debugPrint('🔑 Calling Cidaas signOut...');
      debugPrint(
          '  - idToken: ${savedIdToken != null ? "provided" : "not available"}');
      debugPrint('  - postLogoutWebUri: ${config.postLogoutWebUri}');

      // This redirects to Cidaas logout endpoint
      cidaasWebAuth.signOut(idToken: savedIdToken);
    } else {
      // On mobile: simply navigate to login (native logout handled differently)
      debugPrint('📱 Mobile logout - navigating to login');
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Authenticated'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _handleLogout(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            const Text('Access Token:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            SelectableText(_accessToken ?? 'N/A',
                style: const TextStyle(fontSize: 10)),
            const SizedBox(height: 16),
            const Text('Refresh Token:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            SelectableText(_refreshToken ?? 'N/A',
                style: const TextStyle(fontSize: 10)),
            const SizedBox(height: 16),
            const Text('ID Token:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            SelectableText(_idToken ?? 'N/A',
                style: const TextStyle(fontSize: 10)),
          ],
        ),
      ),
    );
  }
}
