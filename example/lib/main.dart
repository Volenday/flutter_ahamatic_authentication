import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ahamatic_authentication/flutter_ahamatic_authentication.dart';
import 'package:flutter_ahamatic_authentication/cidaas/cidaas_web_auth.dart';
import 'package:flutter_ahamatic_authentication/services/ahamatic_api_service.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:go_router/go_router.dart';

// ============================================================================
// CONFIGURATION
// ============================================================================

const environment = "sandbox";
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

/// Cidaas configuration based on platform
final cidaasMobileConfig = CidaasConfiguration(
  clientId: 'dd982451-c2bb-409f-9649-3ca12a9ba0fd',
  issuer: 'https://abena-prod.cidaas.eu',
  redirectUri: 'app://abenaRestock/oauth2redirect',
  postLogoutRedirectUri: 'app://abenaRestock/logout',
  discoveryUrl: 'https://abena-prod.cidaas.eu/.well-known/openid-configuration',
  scopes: ['openid', 'profile', 'email', 'offline_access', 'dk-cpr'],
);

final cidaasWebConfig = CidaasConfiguration(
  clientId: '88658db5-3737-45ac-b350-c6e8527ed190',
  issuer: 'https://test-login.abena.com',
  redirectUri: 'app://abenaRestock/oauth2redirect',
  postLogoutRedirectUri: 'app://abenaRestock/logout',
  discoveryUrl: 'https://test-login.abena.com/.well-known/openid-configuration',
  scopes: ['openid', 'profile', 'email', 'offline_access'],
  redirectWebUri: 'http://localhost:8080/callback',
  postLogoutWebUri: 'http://localhost:8080/',
);

/// Gets the Cidaas configuration based on the platform
CidaasConfiguration getCidaasConfig() {
  final isWeb = PlatformService.isWeb;
  final config = isWeb ? cidaasWebConfig : cidaasMobileConfig;

  debugPrint('═══════════════════════════════════════════════════════');
  debugPrint('📱 CIDAAS CONFIG - Platform: ${isWeb ? "WEB" : "MOBILE"}');
  debugPrint('═══════════════════════════════════════════════════════');
  debugPrint('  clientId: ${config.clientId}');
  debugPrint('  issuer: ${config.issuer}');
  debugPrint('  redirectUri: ${config.redirectUri}');
  debugPrint('  postLogoutRedirectUri: ${config.postLogoutRedirectUri}');
  debugPrint('  discoveryUrl: ${config.discoveryUrl}');
  debugPrint('  scopes: ${config.scopes}');
  if (config.redirectWebUri != null) {
    debugPrint('  redirectWebUri: ${config.redirectWebUri}');
  }
  if (config.postLogoutWebUri != null) {
    debugPrint('  postLogoutWebUri: ${config.postLogoutWebUri}');
  }
  debugPrint('═══════════════════════════════════════════════════════');

  return config;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      appBar: AppBar(title: const Text('Plugin example app')),
      body: SafeArea(
        child: Center(
          child: FlutterAhaAuthentication(
            moduleName: 'abenaRestock',
            moduleWebName: 'abenaRestock',
            projectLogoAsset: 'assets/images/sample_logo.png',
            applicationCode: 'abenadata',
            environment: 'development',
            europe: true,
            cidaasConfiguration: getCidaasConfig(),
            onAuthSuccess: ({accessToken, refreshToken, idToken}) {
              _accessToken = accessToken;
              _refreshToken = refreshToken;
              _idToken = idToken;
              context.go('/home');
            },
            onAuthError: (error) {
              debugPrint('Error: $error');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error: $error')),
              );
            },
          ),
        ),
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
      setState(() => _error = 'Only works on web');
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
        'abenaRestock',
      );
      final apiKey = moduleConfig.apiKey ?? '';
      debugPrint(
          '🔑 ApiKey obtained: ${apiKey.isEmpty ? "(empty)" : "${apiKey.substring(0, 10)}..."}');

      if (apiKey.isEmpty) {
        setState(() => _error = 'Could not get the apiKey from module');
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
        debugPrint('❌ authResult is null');
        setState(
            () => _error = 'Authorization code not found or state mismatch');
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
    } catch (e, stack) {
      debugPrint('❌ Error in callback: $e');
      debugPrint('Stack: $stack');
      setState(() => _error = e.toString());
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
