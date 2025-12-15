import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ahamatic_authentication/flutter_ahamatic_authentication.dart';
import 'package:flutter_ahamatic_authentication/cidaas/cidaas_web_auth.dart';
import 'package:go_router/go_router.dart';

// ============================================================================
// CONFIGURACIÓN
// ============================================================================

const environment = "production";
const apiURL = 'https://api-eu.ahamatic.com';
final dio = Dio();

const devAccount = {
  'emailAddress': 'developers@volenday.com',
  'password': 'V0l3nd@yP@ssw0rd',
};

/// Configuración de Cidaas según plataforma
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

/// Obtiene la configuración de Cidaas según la plataforma
CidaasConfiguration getCidaasConfig() {
  final isWeb = PlatformService.isWeb;
  final config = isWeb ? cidaasWebConfig : cidaasMobileConfig;

  debugPrint('═══════════════════════════════════════════════════════');
  debugPrint('📱 CIDAAS CONFIG - Plataforma: ${isWeb ? "WEB" : "MOBILE"}');
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

// Estado global de autenticación
String? _accessToken;
String? _refreshToken;
String? _idToken;

// ============================================================================
// ROUTER
// ============================================================================

final router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (_, __) => const LoginPage()),
    GoRoute(path: '/callback', builder: (_, __) => const CallbackPage()),
    GoRoute(path: '/home', builder: (_, __) => const HomePage()),
  ],
);

// ============================================================================
// MAIN
// ============================================================================

void main() => runApp(const MyApp());

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

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

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
// CALLBACK PAGE (OAuth redirect en web)
// ============================================================================

class CallbackPage extends StatefulWidget {
  const CallbackPage({super.key});

  @override
  State<CallbackPage> createState() => _CallbackPageState();
}

class _CallbackPageState extends State<CallbackPage> {
  String? _error;

  @override
  void initState() {
    super.initState();
    _handleCallback();
  }

  Future<void> _handleCallback() async {
    if (!PlatformService.isWeb) {
      setState(() => _error = 'Solo funciona en web');
      return;
    }

    try {
      final cidaasWebAuth = CidaasWebAuth(dio, getCidaasConfig(), devAccount);
      final authResult = cidaasWebAuth.handleCallback();

      if (authResult == null) {
        setState(() => _error = 'No se encontró código de autorización');
        return;
      }

      final response =
          await cidaasWebAuth.signInComplete('', apiURL, authResult);

      _accessToken = response.accessToken;
      _refreshToken = response.refreshToken;
      _idToken = response.idToken;

      if (mounted) context.go('/home');
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_error!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go('/'),
                child: const Text('Volver'),
              ),
            ],
          ),
        ),
      );
    }

    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

// ============================================================================
// HOME PAGE (muestra tokens)
// ============================================================================

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Autenticado'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              _accessToken = null;
              _refreshToken = null;
              _idToken = null;
              context.go('/');
            },
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
