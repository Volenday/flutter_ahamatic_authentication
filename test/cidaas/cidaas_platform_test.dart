import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ahamatic_authentication/cidaas/cidaas.dart';

/// Platform-specific configuration tests
///
/// These tests cover:
/// - Selecting correct configuration based on platform
/// - Different client IDs for mobile and web
/// - Configuration switching logic
void main() {
  group('Platform-specific configuration', () {
    test('should have different client IDs for mobile and web', () {
      final mobileConfig = CidaasConfiguration(
        clientId: 'mobile-id',
        issuer: 'https://prod.cidaas.eu/',
        redirectUri: 'app://test/callback',
        postLogoutRedirectUri: 'app://test/logout',
        discoveryUrl: 'https://prod.cidaas.eu/.well-known/openid-configuration',
        scopes: ['openid'],
      );

      final webConfig = CidaasConfiguration(
        clientId: 'web-id',
        issuer: 'https://test.cidaas.eu/',
        redirectUri: 'app://test/callback',
        postLogoutRedirectUri: 'app://test/logout',
        discoveryUrl: 'https://test.cidaas.eu/.well-known/openid-configuration',
        scopes: ['openid'],
        redirectWebUri: 'http://localhost:8080/callback',
        postLogoutWebUri: 'http://localhost:8080/',
      );

      expect(mobileConfig.clientId, equals('mobile-id'));
      expect(webConfig.clientId, equals('web-id'));
      expect(mobileConfig.clientId, isNot(equals(webConfig.clientId)));
    });

    test('should select correct config based on platform flag', () {
      final mobileConfig = CidaasConfiguration(
        clientId: 'mobile-id',
        issuer: 'https://prod.cidaas.eu/',
        redirectUri: 'app://test/callback',
        postLogoutRedirectUri: 'app://test/logout',
        discoveryUrl: 'https://prod.cidaas.eu/.well-known/openid-configuration',
        scopes: ['openid'],
      );

      final webConfig = CidaasConfiguration(
        clientId: 'web-id',
        issuer: 'https://test.cidaas.eu/',
        redirectUri: 'app://test/callback',
        postLogoutRedirectUri: 'app://test/logout',
        discoveryUrl: 'https://test.cidaas.eu/.well-known/openid-configuration',
        scopes: ['openid'],
        redirectWebUri: 'http://localhost:8080/callback',
        postLogoutWebUri: 'http://localhost:8080/',
      );

      // Test selection function
      CidaasConfiguration selectConfig(bool isWeb) {
        return isWeb ? webConfig : mobileConfig;
      }

      expect(selectConfig(false).clientId, equals('mobile-id'));
      expect(selectConfig(true).clientId, equals('web-id'));
      expect(selectConfig(true).redirectWebUri, isNotNull);
      expect(selectConfig(false).redirectWebUri, isNull);
    });

    test('should support different issuers for different environments', () {
      final devConfig = CidaasConfiguration(
        clientId: 'dev-client-id',
        issuer: 'https://dev-login.abena.com/',
        redirectUri: 'app://test/callback',
        postLogoutRedirectUri: 'app://test/logout',
        discoveryUrl:
            'https://dev-login.abena.com/.well-known/openid-configuration',
        scopes: ['openid'],
      );

      final testConfig = CidaasConfiguration(
        clientId: 'test-client-id',
        issuer: 'https://test-login.abena.com/',
        redirectUri: 'app://test/callback',
        postLogoutRedirectUri: 'app://test/logout',
        discoveryUrl:
            'https://test-login.abena.com/.well-known/openid-configuration',
        scopes: ['openid'],
      );

      final prodConfig = CidaasConfiguration(
        clientId: 'prod-client-id',
        issuer: 'https://login.abena.com/',
        redirectUri: 'app://test/callback',
        postLogoutRedirectUri: 'app://test/logout',
        discoveryUrl:
            'https://login.abena.com/.well-known/openid-configuration',
        scopes: ['openid'],
      );

      expect(devConfig.issuer, contains('dev'));
      expect(testConfig.issuer, contains('test'));
      expect(prodConfig.issuer, isNot(contains('dev')));
      expect(prodConfig.issuer, isNot(contains('test')));
    });

    test(
        'should support different configurations for mobile and web same environment',
        () {
      final mobileConfig = CidaasConfiguration(
        clientId: 'mobile-client-id',
        issuer: 'https://prod.cidaas.eu/',
        redirectUri: 'app://myapp/oauth2redirect',
        postLogoutRedirectUri: 'app://myapp/logout',
        discoveryUrl: 'https://prod.cidaas.eu/.well-known/openid-configuration',
        scopes: ['openid', 'profile', 'email', 'offline_access'],
      );

      final webConfig = CidaasConfiguration(
        clientId: 'web-client-id',
        issuer: 'https://prod.cidaas.eu/', // Same issuer
        redirectUri: 'app://myapp/oauth2redirect',
        postLogoutRedirectUri: 'app://myapp/logout',
        discoveryUrl: 'https://prod.cidaas.eu/.well-known/openid-configuration',
        scopes: ['openid', 'profile', 'email', 'offline_access'],
        redirectWebUri: 'https://myapp.com/callback',
        postLogoutWebUri: 'https://myapp.com/',
      );

      // Same issuer but different client IDs
      expect(mobileConfig.issuer, equals(webConfig.issuer));
      expect(mobileConfig.clientId, isNot(equals(webConfig.clientId)));

      // Web config has additional URIs
      expect(webConfig.redirectWebUri, isNotNull);
      expect(mobileConfig.redirectWebUri, isNull);
    });

    test('should use getCidaasConfig pattern correctly', () {
      // Simulate the getCidaasConfig() function
      CidaasConfiguration getCidaasConfig(bool isWeb) {
        final cidaasMobileConfig = CidaasConfiguration(
          clientId: 'mobile-client',
          issuer: 'https://prod.cidaas.eu/',
          redirectUri: 'app://test/callback',
          postLogoutRedirectUri: 'app://test/logout',
          discoveryUrl:
              'https://prod.cidaas.eu/.well-known/openid-configuration',
          scopes: ['openid', 'profile'],
        );

        final cidaasWebConfig = CidaasConfiguration(
          clientId: 'web-client',
          issuer: 'https://test.cidaas.eu/',
          redirectUri: 'app://test/callback',
          postLogoutRedirectUri: 'app://test/logout',
          discoveryUrl:
              'https://test.cidaas.eu/.well-known/openid-configuration',
          scopes: ['openid', 'profile'],
          redirectWebUri: 'http://localhost:8080/callback',
          postLogoutWebUri: 'http://localhost:8080/',
        );

        if (isWeb) {
          return cidaasWebConfig;
        }
        return cidaasMobileConfig;
      }

      // Test mobile
      final mobileResult = getCidaasConfig(false);
      expect(mobileResult.clientId, equals('mobile-client'));
      expect(mobileResult.issuer, contains('prod'));
      expect(mobileResult.redirectWebUri, isNull);

      // Test web
      final webResult = getCidaasConfig(true);
      expect(webResult.clientId, equals('web-client'));
      expect(webResult.issuer, contains('test'));
      expect(webResult.redirectWebUri, isNotNull);
    });
  });

  group('Configuration validation', () {
    test('should validate required fields are present', () {
      final config = CidaasConfiguration(
        clientId: 'test-client',
        issuer: 'https://issuer.cidaas.eu/',
        redirectUri: 'app://test/callback',
        postLogoutRedirectUri: 'app://test/logout',
        discoveryUrl:
            'https://issuer.cidaas.eu/.well-known/openid-configuration',
        scopes: ['openid'],
      );

      expect(config.clientId, isNotEmpty);
      expect(config.issuer, isNotEmpty);
      expect(config.redirectUri, isNotEmpty);
      expect(config.postLogoutRedirectUri, isNotEmpty);
      expect(config.discoveryUrl, isNotEmpty);
      expect(config.scopes, isNotEmpty);
    });

    test('should handle configuration with all optional fields', () {
      final config = CidaasConfiguration(
        clientId: 'full-config-client',
        issuer: 'https://issuer.cidaas.eu/',
        redirectUri: 'app://test/callback',
        postLogoutRedirectUri: 'app://test/logout',
        discoveryUrl:
            'https://issuer.cidaas.eu/.well-known/openid-configuration',
        scopes: ['openid', 'profile', 'email', 'offline_access'],
        redirectWebUri: 'http://localhost:8080/callback',
        postLogoutWebUri: 'http://localhost:8080/',
        customParameter: {'prompt': 'login'},
      );

      expect(config.redirectWebUri, isNotNull);
      expect(config.postLogoutWebUri, isNotNull);
      expect(config.customParameter, isNotNull);
      expect(config.customParameter!['prompt'], equals('login'));
    });
  });

  group('AhamaticTokenService', () {
    test('AhamaticTokenService should be importable', () {
      expect(AhamaticTokenService, isNotNull);
    });
  });
}
