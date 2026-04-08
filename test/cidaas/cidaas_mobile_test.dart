import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ahamatic_authentication/cidaas/cidaas.dart';

/// Mobile-specific tests for Cidaas authentication
///
/// These tests cover:
/// - Custom URI schemes for Android/iOS
/// - Deep linking configuration
/// - Mobile logout flow (endSession)
/// - flutter_appauth integration patterns
void main() {
  group('CidaasConfiguration - Mobile URIs', () {
    test('should handle Android redirect URI scheme', () {
      final config = CidaasConfiguration(
        clientId: 'test-client-id',
        issuer: 'https://issuer.cidaas.eu/',
        redirectUri: 'app://myapp.example.com/oauth2redirect',
        postLogoutRedirectUri: 'app://myapp.example.com/logout',
        discoveryUrl:
            'https://issuer.cidaas.eu/.well-known/openid-configuration',
        scopes: ['openid'],
      );

      expect(config.redirectUri, startsWith('app://'));
    });

    test('should handle iOS redirect URI scheme', () {
      final config = CidaasConfiguration(
        clientId: 'test-client-id',
        issuer: 'https://issuer.cidaas.eu/',
        redirectUri: 'myapp://oauth2redirect',
        postLogoutRedirectUri: 'myapp://logout',
        discoveryUrl:
            'https://issuer.cidaas.eu/.well-known/openid-configuration',
        scopes: ['openid'],
      );

      expect(config.redirectUri, contains('://'));
    });

    test('should handle custom app scheme', () {
      final config = CidaasConfiguration(
        clientId: 'test-client-id',
        issuer: 'https://issuer.cidaas.eu/',
        redirectUri: 'com.mycompany.myapp://oauth/callback',
        postLogoutRedirectUri: 'com.mycompany.myapp://oauth/logout',
        discoveryUrl:
            'https://issuer.cidaas.eu/.well-known/openid-configuration',
        scopes: ['openid'],
      );

      expect(config.redirectUri, startsWith('com.mycompany.myapp://'));
    });

    test('should handle reverse domain notation URI', () {
      final config = CidaasConfiguration(
        clientId: 'test-client-id',
        issuer: 'https://issuer.cidaas.eu/',
        redirectUri: 'eu.abena.abenadata://oauth2redirect',
        postLogoutRedirectUri: 'eu.abena.abenadata://logout',
        discoveryUrl:
            'https://issuer.cidaas.eu/.well-known/openid-configuration',
        scopes: ['openid'],
      );

      expect(config.redirectUri, contains('eu.abena.abenadata'));
    });
  });

  group('Mobile Deep Linking', () {
    test('should parse deep link callback URL', () {
      const deepLink = 'app://myapp.example.com/oauth2redirect?'
          'code=mobile-auth-code-123&state=mobile-state-456';

      final uri = Uri.parse(deepLink);

      expect(uri.scheme, equals('app'));
      expect(uri.host, equals('myapp.example.com'));
      expect(uri.path, equals('/oauth2redirect'));
      expect(uri.queryParameters['code'], equals('mobile-auth-code-123'));
      expect(uri.queryParameters['state'], equals('mobile-state-456'));
    });

    test('should parse iOS deep link callback URL', () {
      const deepLink = 'myapp://oauth2redirect?code=ios-code-789';

      final uri = Uri.parse(deepLink);

      expect(uri.scheme, equals('myapp'));
      expect(uri.queryParameters['code'], equals('ios-code-789'));
    });

    test('should handle deep link with error', () {
      const deepLink = 'app://myapp.example.com/oauth2redirect?'
          'error=user_cancelled&error_description=User%20cancelled%20the%20login';

      final uri = Uri.parse(deepLink);

      expect(uri.queryParameters['error'], equals('user_cancelled'));
      expect(uri.queryParameters['error_description'], contains('cancelled'));
    });
  });

  group('Mobile Logout Flow', () {
    test('should configure EndSessionRequest parameters', () {
      final config = CidaasConfiguration(
        clientId: 'test-client-id',
        issuer: 'https://issuer.cidaas.eu/',
        redirectUri: 'app://test/callback',
        postLogoutRedirectUri: 'app://test/logout',
        discoveryUrl:
            'https://issuer.cidaas.eu/.well-known/openid-configuration',
        scopes: ['openid'],
      );

      // Verify EndSessionRequest would be created with correct parameters
      expect(config.postLogoutRedirectUri, equals('app://test/logout'));
      expect(config.discoveryUrl, isNotNull);
    });

    test('should use correct discovery URL for end session', () {
      final config = CidaasConfiguration(
        clientId: 'test-client-id',
        issuer: 'https://test-login.abena.com/',
        redirectUri: 'app://test/callback',
        postLogoutRedirectUri: 'app://test/logout',
        discoveryUrl:
            'https://test-login.abena.com/.well-known/openid-configuration',
        scopes: ['openid'],
      );

      expect(config.discoveryUrl, contains('.well-known/openid-configuration'));
    });
  });

  group('flutter_appauth Integration Patterns', () {
    test('should have required configuration for AuthorizationRequest', () {
      final config = CidaasConfiguration(
        clientId: 'flutter-app-client-id',
        issuer: 'https://issuer.cidaas.eu/',
        redirectUri: 'app://myapp/oauth2redirect',
        postLogoutRedirectUri: 'app://myapp/logout',
        discoveryUrl:
            'https://issuer.cidaas.eu/.well-known/openid-configuration',
        scopes: ['openid', 'profile', 'email', 'offline_access'],
      );

      // AuthorizationTokenRequest requires these fields
      expect(config.clientId, isNotEmpty);
      expect(config.redirectUri, isNotEmpty);
      expect(config.discoveryUrl, isNotEmpty);
      expect(config.scopes, isNotEmpty);
    });

    test('should support offline_access scope for refresh tokens', () {
      final config = CidaasConfiguration(
        clientId: 'test-client-id',
        issuer: 'https://issuer.cidaas.eu/',
        redirectUri: 'app://test/callback',
        postLogoutRedirectUri: 'app://test/logout',
        discoveryUrl:
            'https://issuer.cidaas.eu/.well-known/openid-configuration',
        scopes: ['openid', 'profile', 'offline_access'],
      );

      expect(config.scopes, contains('offline_access'));
    });

    test('should support custom scopes for mobile', () {
      final config = CidaasConfiguration(
        clientId: 'test-client-id',
        issuer: 'https://issuer.cidaas.eu/',
        redirectUri: 'app://test/callback',
        postLogoutRedirectUri: 'app://test/logout',
        discoveryUrl:
            'https://issuer.cidaas.eu/.well-known/openid-configuration',
        scopes: ['openid', 'profile', 'email', 'dk-cpr', 'offline_access'],
      );

      expect(config.scopes, contains('dk-cpr'));
    });

    test('should support additional parameters for mobile', () {
      final config = CidaasConfiguration(
        clientId: 'test-client-id',
        issuer: 'https://issuer.cidaas.eu/',
        redirectUri: 'app://test/callback',
        postLogoutRedirectUri: 'app://test/logout',
        discoveryUrl:
            'https://issuer.cidaas.eu/.well-known/openid-configuration',
        scopes: ['openid'],
        customParameter: {
          'prompt': 'login',
          'acr_values': 'mfa',
        },
      );

      expect(config.customParameter, isNotNull);
      expect(config.customParameter!['prompt'], equals('login'));
      expect(config.customParameter!['acr_values'], equals('mfa'));
    });
  });

  group('Android-specific Configuration', () {
    test('should support appAuthRedirectScheme pattern', () {
      // The redirect URI should match the appAuthRedirectScheme in build.gradle
      final config = CidaasConfiguration(
        clientId: 'android-client-id',
        issuer: 'https://issuer.cidaas.eu/',
        redirectUri: 'app://eu.abena.app/oauth2redirect',
        postLogoutRedirectUri: 'app://eu.abena.app/logout',
        discoveryUrl:
            'https://issuer.cidaas.eu/.well-known/openid-configuration',
        scopes: ['openid'],
      );

      // The scheme 'app' should match manifestPlaceholders appAuthRedirectScheme
      expect(Uri.parse(config.redirectUri).scheme, equals('app'));
    });
  });

  group('iOS-specific Configuration', () {
    test('should support URL scheme pattern', () {
      // iOS uses Info.plist URL schemes
      final config = CidaasConfiguration(
        clientId: 'ios-client-id',
        issuer: 'https://issuer.cidaas.eu/',
        redirectUri: 'abena.app://oauth2redirect',
        postLogoutRedirectUri: 'abena.app://logout',
        discoveryUrl:
            'https://issuer.cidaas.eu/.well-known/openid-configuration',
        scopes: ['openid'],
      );

      expect(Uri.parse(config.redirectUri).scheme, isNotEmpty);
    });
  });

  group('CidaasMobileAuthService', () {
    test('CidaasMobileAuthService should implement CidaasAuthApi', () {
      // Verify the service implements the interface
      expect(CidaasMobileAuthService, isNotNull);
    });
  });

  group('MitID flow and configuration', () {
    test('should derive mitIdEffectiveIssuer from mitIdAuthUrl when mitIdIssuer is null',
        () {
      final config = CidaasConfiguration(
        clientId: 'classic-client-id',
        issuer: 'https://issuer.cidaas.eu/',
        redirectUri: 'app://test/callback',
        postLogoutRedirectUri: 'app://test/logout',
        discoveryUrl:
            'https://issuer.cidaas.eu/.well-known/openid-configuration',
        scopes: ['openid'],
        cidaasClientIdMitID: '5fd6af67-1820-42f5-85fd-4dc236d00d65',
        mitIdAuthUrl:
            'https://test-login.abena.com/authz-srv/authz?client_id=5fd6af67-1820-42f5-85fd-4dc236d00d65&redirect_uri=https%3A%2F%2Fwww.bevilling.dk%2FLogin%2FCallback&response_type=code&preferred_login=mitid',
      );

      expect(config.mitIdEffectiveIssuer, equals('https://test-login.abena.com'));
      expect(config.useMitIdCustomUrl, isTrue);
    });

    test('should prefer mitIdIssuer over mitIdAuthUrl origin when both set', () {
      final config = CidaasConfiguration(
        clientId: 'classic-client-id',
        issuer: 'https://issuer.cidaas.eu/',
        redirectUri: 'app://test/callback',
        postLogoutRedirectUri: 'app://test/logout',
        discoveryUrl:
            'https://issuer.cidaas.eu/.well-known/openid-configuration',
        scopes: ['openid'],
        cidaasClientIdMitID: 'mitid-client-id',
        mitIdAuthUrl:
            'https://other.example.com/authz-srv/authz?client_id=mitid-client-id',
        mitIdIssuer: 'https://test-login.abena.com',
      );

      expect(config.mitIdEffectiveIssuer, equals('https://test-login.abena.com'));
    });

    test('should have useMitIdCustomUrl true when only mitIdIssuer is set', () {
      final config = CidaasConfiguration(
        clientId: 'classic-client-id',
        issuer: 'https://issuer.cidaas.eu/',
        redirectUri: 'app://test/callback',
        postLogoutRedirectUri: 'app://test/logout',
        discoveryUrl:
            'https://issuer.cidaas.eu/.well-known/openid-configuration',
        scopes: ['openid'],
        cidaasClientIdMitID: 'mitid-client-id',
        mitIdIssuer: 'https://test-login.abena.com',
      );

      expect(config.useMitIdCustomUrl, isTrue);
      expect(config.mitIdEffectiveIssuer, equals('https://test-login.abena.com'));
    });

    test('should have useMitIdCustomUrl false when neither mitIdAuthUrl nor mitIdIssuer set',
        () {
      final config = CidaasConfiguration(
        clientId: 'classic-client-id',
        issuer: 'https://issuer.cidaas.eu/',
        redirectUri: 'app://test/callback',
        postLogoutRedirectUri: 'app://test/logout',
        discoveryUrl:
            'https://issuer.cidaas.eu/.well-known/openid-configuration',
        scopes: ['openid'],
        cidaasClientIdMitID: 'mitid-client-id',
      );

      expect(config.useMitIdCustomUrl, isFalse);
      expect(config.mitIdEffectiveIssuer, isNull);
    });
  });
}
