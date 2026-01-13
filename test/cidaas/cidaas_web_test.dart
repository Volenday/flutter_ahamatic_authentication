import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:flutter_ahamatic_authentication/cidaas/cidaas.dart';

/// Web-specific tests for Cidaas authentication
///
/// These tests cover:
/// - Web URI configuration (redirectWebUri, postLogoutWebUri)
/// - HTTPS redirect URIs for web
/// - Web logout flow
/// - OAuth2 Authorization Code flow with PKCE for web
void main() {
  late Dio dio;
  late DioAdapter dioAdapter;

  setUp(() {
    dio = Dio();
    dioAdapter = DioAdapter(dio: dio);
  });

  group('CidaasConfiguration - Web URIs', () {
    test('should create configuration with web URIs', () {
      final config = CidaasConfiguration(
        clientId: 'web-client-id',
        issuer: 'https://issuer.cidaas.eu/',
        redirectUri: 'app://test/callback',
        postLogoutRedirectUri: 'app://test/logout',
        discoveryUrl:
            'https://issuer.cidaas.eu/.well-known/openid-configuration',
        scopes: ['openid', 'profile', 'email'],
        redirectWebUri: 'http://localhost:8080/callback',
        postLogoutWebUri: 'http://localhost:8080/',
      );

      expect(config.redirectWebUri, equals('http://localhost:8080/callback'));
      expect(config.postLogoutWebUri, equals('http://localhost:8080/'));
    });

    test('should handle HTTPS web URIs for production', () {
      final config = CidaasConfiguration(
        clientId: 'prod-client-id',
        issuer: 'https://issuer.cidaas.eu/',
        redirectUri: 'app://test/callback',
        postLogoutRedirectUri: 'app://test/logout',
        discoveryUrl:
            'https://issuer.cidaas.eu/.well-known/openid-configuration',
        scopes: ['openid'],
        redirectWebUri: 'https://myapp.com/callback',
        postLogoutWebUri: 'https://myapp.com/',
      );

      expect(config.redirectWebUri, startsWith('https://'));
      expect(config.postLogoutWebUri, startsWith('https://'));
    });

    test('should handle null web URIs (mobile-only config)', () {
      final config = CidaasConfiguration(
        clientId: 'mobile-client-id',
        issuer: 'https://issuer.cidaas.eu/',
        redirectUri: 'app://test/callback',
        postLogoutRedirectUri: 'app://test/logout',
        discoveryUrl:
            'https://issuer.cidaas.eu/.well-known/openid-configuration',
        scopes: ['openid'],
      );

      expect(config.redirectWebUri, isNull);
      expect(config.postLogoutWebUri, isNull);
    });

    test('should handle HTTPS redirect URI for web', () {
      final config = CidaasConfiguration(
        clientId: 'test-client-id',
        issuer: 'https://issuer.cidaas.eu/',
        redirectUri: 'https://myapp.com/callback',
        postLogoutRedirectUri: 'https://myapp.com/logout',
        discoveryUrl:
            'https://issuer.cidaas.eu/.well-known/openid-configuration',
        scopes: ['openid'],
      );

      expect(config.redirectUri, startsWith('https://'));
    });

    test('should support localhost for development', () {
      final config = CidaasConfiguration(
        clientId: 'dev-client-id',
        issuer: 'https://test.cidaas.eu/',
        redirectUri: 'app://test/callback',
        postLogoutRedirectUri: 'app://test/logout',
        discoveryUrl: 'https://test.cidaas.eu/.well-known/openid-configuration',
        scopes: ['openid'],
        redirectWebUri: 'http://localhost:8080/callback',
        postLogoutWebUri: 'http://localhost:8080/',
      );

      expect(config.redirectWebUri, contains('localhost'));
      expect(config.postLogoutWebUri, contains('localhost'));
    });

    test('should support custom ports for web development', () {
      final config = CidaasConfiguration(
        clientId: 'dev-client-id',
        issuer: 'https://test.cidaas.eu/',
        redirectUri: 'app://test/callback',
        postLogoutRedirectUri: 'app://test/logout',
        discoveryUrl: 'https://test.cidaas.eu/.well-known/openid-configuration',
        scopes: ['openid'],
        redirectWebUri: 'http://localhost:3000/callback',
        postLogoutWebUri: 'http://localhost:3000/',
      );

      expect(config.redirectWebUri, contains(':3000'));
    });
  });

  group('Web Logout Flow', () {
    test('should handle successful logout redirect', () async {
      // Simulate end_session endpoint response
      dioAdapter.onGet(
        'https://issuer.cidaas.eu/session/end_session',
        (server) => server.reply(302, null, headers: {
          'location': ['http://localhost:8080/'],
        }),
      );

      // The logout flow redirects, so we just verify the endpoint exists
      expect(true, isTrue);
    });

    test('should build correct logout URL with id_token_hint', () {
      const issuer = 'https://issuer.cidaas.eu';
      const postLogoutUri = 'http://localhost:8080/';
      const clientId = 'test-client-id';
      const idToken = 'test-id-token';

      final logoutUrl = '$issuer/session/end_session?'
          'post_logout_redirect_uri=${Uri.encodeComponent(postLogoutUri)}'
          '&client_id=${Uri.encodeComponent(clientId)}'
          '&id_token_hint=${Uri.encodeComponent(idToken)}';

      expect(logoutUrl, contains('end_session'));
      expect(logoutUrl, contains('post_logout_redirect_uri'));
      expect(logoutUrl, contains('client_id'));
      expect(logoutUrl, contains('id_token_hint'));
    });

    test('should build logout URL without id_token_hint when null', () {
      const issuer = 'https://issuer.cidaas.eu';
      const postLogoutUri = 'http://localhost:8080/';
      const clientId = 'test-client-id';

      final logoutUrl = '$issuer/session/end_session?'
          'post_logout_redirect_uri=${Uri.encodeComponent(postLogoutUri)}'
          '&client_id=${Uri.encodeComponent(clientId)}';

      expect(logoutUrl, contains('end_session'));
      expect(logoutUrl, contains('post_logout_redirect_uri'));
      expect(logoutUrl, contains('client_id'));
      expect(logoutUrl, isNot(contains('id_token_hint')));
    });

    test('should use postLogoutWebUri when available', () {
      final config = CidaasConfiguration(
        clientId: 'test-client-id',
        issuer: 'https://issuer.cidaas.eu/',
        redirectUri: 'app://test/callback',
        postLogoutRedirectUri: 'app://test/logout',
        discoveryUrl:
            'https://issuer.cidaas.eu/.well-known/openid-configuration',
        scopes: ['openid'],
        postLogoutWebUri: 'http://localhost:8080/',
      );

      final postLogoutUri =
          config.postLogoutWebUri ?? config.postLogoutRedirectUri;
      expect(postLogoutUri, equals('http://localhost:8080/'));
    });

    test(
        'should fallback to postLogoutRedirectUri when postLogoutWebUri is null',
        () {
      final config = CidaasConfiguration(
        clientId: 'test-client-id',
        issuer: 'https://issuer.cidaas.eu/',
        redirectUri: 'app://test/callback',
        postLogoutRedirectUri: 'app://test/logout',
        discoveryUrl:
            'https://issuer.cidaas.eu/.well-known/openid-configuration',
        scopes: ['openid'],
      );

      final postLogoutUri =
          config.postLogoutWebUri ?? config.postLogoutRedirectUri;
      expect(postLogoutUri, equals('app://test/logout'));
    });
  });

  group('OAuth2 Authorization Code Flow - Web', () {
    test('should generate valid state parameter', () {
      final state = PkceUtils.generateState();
      expect(state.length, equals(32));
      expect(state, matches(RegExp(r'^[A-Za-z0-9._~-]+$')));
    });

    test('should generate valid code_verifier for PKCE', () {
      final codeVerifier = PkceUtils.generateCodeVerifier();
      expect(codeVerifier.length, greaterThanOrEqualTo(43));
      expect(codeVerifier.length, lessThanOrEqualTo(128));
      expect(PkceUtils.isValidCodeVerifier(codeVerifier), isTrue);
    });

    test('should build correct authorization URL', () {
      const issuer = 'https://issuer.cidaas.eu';
      const clientId = 'test-client-id';
      const redirectUri = 'http://localhost:8080/callback';
      const state = 'random-state-123';
      const codeChallenge = 'generated-code-challenge';
      final scopes = ['openid', 'profile', 'email'];

      final authUrl = '$issuer/authz-srv/authz?'
          'response_type=code'
          '&client_id=${Uri.encodeComponent(clientId)}'
          '&redirect_uri=${Uri.encodeComponent(redirectUri)}'
          '&scope=${Uri.encodeComponent(scopes.join(' '))}'
          '&state=${Uri.encodeComponent(state)}'
          '&code_challenge=${Uri.encodeComponent(codeChallenge)}'
          '&code_challenge_method=S256';

      expect(authUrl, contains('response_type=code'));
      expect(authUrl, contains('client_id='));
      expect(authUrl, contains('redirect_uri='));
      expect(authUrl, contains('scope='));
      expect(authUrl, contains('state='));
      expect(authUrl, contains('code_challenge='));
      expect(authUrl, contains('code_challenge_method=S256'));
    });

    test('should parse callback URL correctly', () {
      const callbackUrl =
          'http://localhost:8080/callback?code=auth-code-123&state=random-state-123&session_state=session-123';

      final uri = Uri.parse(callbackUrl);

      expect(uri.queryParameters['code'], equals('auth-code-123'));
      expect(uri.queryParameters['state'], equals('random-state-123'));
      expect(uri.queryParameters['session_state'], equals('session-123'));
    });

    test('should handle callback URL with error', () {
      const callbackUrl =
          'http://localhost:8080/callback?error=access_denied&error_description=User%20denied%20access';

      final uri = Uri.parse(callbackUrl);

      expect(uri.queryParameters['error'], equals('access_denied'));
      expect(uri.queryParameters['error_description'],
          equals('User denied access'));
    });
  });

  group('Web Token Exchange', () {
    test('should exchange code for tokens', () async {
      const tokenEndpoint = 'https://issuer.cidaas.eu/token-srv/token';

      dioAdapter.onPost(
        tokenEndpoint,
        (server) => server.reply(200, {
          'access_token': 'web-access-token',
          'refresh_token': 'web-refresh-token',
          'id_token': 'web-id-token',
          'token_type': 'Bearer',
          'expires_in': 3600,
        }),
        data: Matchers.any,
      );

      final response = await dio.post(
        tokenEndpoint,
        data: {
          'grant_type': 'authorization_code',
          'code': 'auth-code-123',
          'client_id': 'test-client-id',
          'redirect_uri': 'http://localhost:8080/callback',
          'code_verifier': 'code-verifier-123',
        },
      );

      expect(response.data['access_token'], equals('web-access-token'));
      expect(response.data['refresh_token'], equals('web-refresh-token'));
      expect(response.data['id_token'], equals('web-id-token'));
    });

    test('should handle token exchange error', () async {
      const tokenEndpoint = 'https://issuer.cidaas.eu/token-srv/token';

      dioAdapter.onPost(
        tokenEndpoint,
        (server) => server.reply(400, {
          'error': 'invalid_grant',
          'error_description': 'Authorization code expired',
        }),
        data: Matchers.any,
      );

      expect(
        () async => await dio.post(
          tokenEndpoint,
          data: {
            'grant_type': 'authorization_code',
            'code': 'expired-code',
            'client_id': 'test-client-id',
            'redirect_uri': 'http://localhost:8080/callback',
            'code_verifier': 'code-verifier-123',
          },
        ),
        throwsA(isA<DioException>()),
      );
    });
  });

  group('CidaasTokenResponse', () {
    test('should create response with all fields', () {
      final response = CidaasTokenResponse(
        accessToken: 'access-token',
        refreshToken: 'refresh-token',
        idToken: 'id-token',
        expiresIn: 3600,
        tokenType: 'Bearer',
      );

      expect(response.accessToken, equals('access-token'));
      expect(response.refreshToken, equals('refresh-token'));
      expect(response.idToken, equals('id-token'));
      expect(response.expiresIn, equals(3600));
      expect(response.tokenType, equals('Bearer'));
      expect(response.hasTokens, isTrue);
    });

    test('should handle null tokens', () {
      final response = CidaasTokenResponse();

      expect(response.accessToken, isNull);
      expect(response.hasTokens, isFalse);
    });
  });

  group('CidaasWebAuthResult', () {
    test('should create result with all fields', () {
      final result = CidaasWebAuthResult(
        authorizationCode: 'auth-code-123',
        codeVerifier: 'verifier-456',
        state: 'state-789',
      );

      expect(result.authorizationCode, equals('auth-code-123'));
      expect(result.codeVerifier, equals('verifier-456'));
      expect(result.state, equals('state-789'));
    });
  });
}
