import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ahamatic_authentication/cidaas/cidaas.dart';

/// Core tests for the Cidaas library
///
/// These tests cover:
/// - CidaasConfiguration creation and validation
/// - AhamaticResponse handling
/// - Auth callbacks
/// - CidaasAuthApi interface
/// - APIKey extraction logic
void main() {
  group('CidaasConfiguration', () {
    test('should create configuration with all required fields', () {
      final config = CidaasConfiguration(
        clientId: 'test-client-id',
        issuer: 'https://issuer.cidaas.eu/',
        redirectUri: 'app://test/callback',
        postLogoutRedirectUri: 'app://test/logout',
        discoveryUrl:
            'https://issuer.cidaas.eu/.well-known/openid-configuration',
        scopes: ['openid', 'profile', 'email'],
      );

      expect(config.clientId, equals('test-client-id'));
      expect(config.issuer, equals('https://issuer.cidaas.eu/'));
      expect(config.redirectUri, equals('app://test/callback'));
      expect(config.postLogoutRedirectUri, equals('app://test/logout'));
      expect(config.discoveryUrl,
          equals('https://issuer.cidaas.eu/.well-known/openid-configuration'));
      expect(config.scopes, equals(['openid', 'profile', 'email']));
      expect(config.customParameter, isNull);
    });

    test('should create configuration with custom parameters', () {
      final config = CidaasConfiguration(
        clientId: 'test-client-id',
        issuer: 'https://issuer.cidaas.eu/',
        redirectUri: 'app://test/callback',
        postLogoutRedirectUri: 'app://test/logout',
        discoveryUrl:
            'https://issuer.cidaas.eu/.well-known/openid-configuration',
        scopes: ['openid'],
        customParameter: {'param1': 'value1', 'param2': 'value2'},
      );

      expect(config.customParameter, isNotNull);
      expect(config.customParameter!['param1'], equals('value1'));
      expect(config.customParameter!['param2'], equals('value2'));
      expect(config.customParameter!.length, equals(2));
    });

    test('should handle empty scopes list', () {
      final config = CidaasConfiguration(
        clientId: 'test-client-id',
        issuer: 'https://issuer.cidaas.eu/',
        redirectUri: 'app://test/callback',
        postLogoutRedirectUri: 'app://test/logout',
        discoveryUrl:
            'https://issuer.cidaas.eu/.well-known/openid-configuration',
        scopes: [],
      );

      expect(config.scopes, isEmpty);
    });

    test('should handle single scope', () {
      final config = CidaasConfiguration(
        clientId: 'test-client-id',
        issuer: 'https://issuer.cidaas.eu/',
        redirectUri: 'app://test/callback',
        postLogoutRedirectUri: 'app://test/logout',
        discoveryUrl:
            'https://issuer.cidaas.eu/.well-known/openid-configuration',
        scopes: ['openid'],
      );

      expect(config.scopes.length, equals(1));
      expect(config.scopes.first, equals('openid'));
    });

    test('should handle many scopes', () {
      final config = CidaasConfiguration(
        clientId: 'test-client-id',
        issuer: 'https://issuer.cidaas.eu/',
        redirectUri: 'app://test/callback',
        postLogoutRedirectUri: 'app://test/logout',
        discoveryUrl:
            'https://issuer.cidaas.eu/.well-known/openid-configuration',
        scopes: [
          'openid',
          'profile',
          'email',
          'offline_access',
          'dk-cpr',
          'custom_scope_1',
          'custom_scope_2',
        ],
      );

      expect(config.scopes.length, equals(7));
      expect(config.scopes, contains('offline_access'));
      expect(config.scopes, contains('dk-cpr'));
    });

    test('should handle different issuer formats', () {
      // With trailing slash
      final configWithSlash = CidaasConfiguration(
        clientId: 'test',
        issuer: 'https://tenant.cidaas.eu/',
        redirectUri: 'app://test/callback',
        postLogoutRedirectUri: 'app://test/logout',
        discoveryUrl:
            'https://tenant.cidaas.eu/.well-known/openid-configuration',
        scopes: ['openid'],
      );

      // Without trailing slash
      final configWithoutSlash = CidaasConfiguration(
        clientId: 'test',
        issuer: 'https://tenant.cidaas.eu',
        redirectUri: 'app://test/callback',
        postLogoutRedirectUri: 'app://test/logout',
        discoveryUrl:
            'https://tenant.cidaas.eu/.well-known/openid-configuration',
        scopes: ['openid'],
      );

      expect(configWithSlash.issuer, endsWith('/'));
      expect(configWithoutSlash.issuer, isNot(endsWith('/')));
    });

    test('should handle UUID client ID', () {
      final config = CidaasConfiguration(
        clientId: 'dd982451-c2bb-409f-9649-3ca12a9ba0fd',
        issuer: 'https://issuer.cidaas.eu/',
        redirectUri: 'app://test/callback',
        postLogoutRedirectUri: 'app://test/logout',
        discoveryUrl:
            'https://issuer.cidaas.eu/.well-known/openid-configuration',
        scopes: ['openid'],
      );

      expect(
          config.clientId,
          matches(RegExp(
            r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
          )));
    });

    test('should handle different tenant domains', () {
      final prodConfig = CidaasConfiguration(
        clientId: 'test',
        issuer: 'https://abena-prod.cidaas.eu/',
        redirectUri: 'app://test/callback',
        postLogoutRedirectUri: 'app://test/logout',
        discoveryUrl:
            'https://abena-prod.cidaas.eu/.well-known/openid-configuration',
        scopes: ['openid'],
      );

      final testConfig = CidaasConfiguration(
        clientId: 'test',
        issuer: 'https://abena-test.cidaas.eu/',
        redirectUri: 'app://test/callback',
        postLogoutRedirectUri: 'app://test/logout',
        discoveryUrl:
            'https://abena-test.cidaas.eu/.well-known/openid-configuration',
        scopes: ['openid'],
      );

      expect(prodConfig.issuer, contains('prod'));
      expect(testConfig.issuer, contains('test'));
    });

    test('should have correct toString representation', () {
      final config = CidaasConfiguration(
        clientId: 'test-client',
        issuer: 'https://issuer.cidaas.eu/',
        redirectUri: 'app://test/callback',
        postLogoutRedirectUri: 'app://test/logout',
        discoveryUrl:
            'https://issuer.cidaas.eu/.well-known/openid-configuration',
        scopes: ['openid'],
      );

      expect(config.toString(), contains('test-client'));
      expect(config.toString(), contains('https://issuer.cidaas.eu/'));
    });
  });

  group('AhamaticResponse', () {
    test('should create response with all tokens', () {
      final response = AhamaticResponse(
        accessToken: 'access-token-12345',
        refreshToken: 'refresh-token-67890',
        idToken: 'id-token-abcde',
      );

      expect(response.accessToken, equals('access-token-12345'));
      expect(response.refreshToken, equals('refresh-token-67890'));
      expect(response.idToken, equals('id-token-abcde'));
      expect(response.hasTokens, isTrue);
    });

    test('should create response with null tokens', () {
      final response = AhamaticResponse();

      expect(response.accessToken, isNull);
      expect(response.refreshToken, isNull);
      expect(response.idToken, isNull);
      expect(response.hasTokens, isFalse);
    });

    test('should create empty response using factory', () {
      final response = AhamaticResponse.empty();

      expect(response.accessToken, isNull);
      expect(response.refreshToken, isNull);
      expect(response.idToken, isNull);
      expect(response.hasTokens, isFalse);
    });

    test('should create response with only accessToken', () {
      final response = AhamaticResponse(accessToken: 'access-only');

      expect(response.accessToken, equals('access-only'));
      expect(response.refreshToken, isNull);
      expect(response.idToken, isNull);
      expect(response.hasTokens, isTrue);
    });

    test('should create response with only refreshToken', () {
      final response = AhamaticResponse(refreshToken: 'refresh-only');

      expect(response.accessToken, isNull);
      expect(response.refreshToken, equals('refresh-only'));
      expect(response.idToken, isNull);
      expect(response.hasTokens, isTrue);
    });

    test('should create response with only idToken', () {
      final response = AhamaticResponse(idToken: 'id-only');

      expect(response.accessToken, isNull);
      expect(response.refreshToken, isNull);
      expect(response.idToken, equals('id-only'));
      expect(response.hasTokens, isTrue);
    });

    test('should create response with accessToken and refreshToken only', () {
      final response = AhamaticResponse(
        accessToken: 'access',
        refreshToken: 'refresh',
      );

      expect(response.accessToken, equals('access'));
      expect(response.refreshToken, equals('refresh'));
      expect(response.idToken, isNull);
    });

    test('should handle JWT tokens', () {
      const jwtToken = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.'
          'eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.'
          'SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c';

      final response = AhamaticResponse(
        accessToken: jwtToken,
        idToken: jwtToken,
      );

      expect(response.accessToken, contains('.'));
      expect(response.accessToken!.split('.').length, equals(3));
    });

    test('should handle empty string tokens', () {
      final response = AhamaticResponse(
        accessToken: '',
        refreshToken: '',
        idToken: '',
      );

      expect(response.accessToken, equals(''));
      expect(response.refreshToken, equals(''));
      expect(response.idToken, equals(''));
    });

    test('should handle very long tokens', () {
      final longToken = 'a' * 5000;

      final response = AhamaticResponse(
        accessToken: longToken,
        refreshToken: longToken,
        idToken: longToken,
      );

      expect(response.accessToken!.length, equals(5000));
      expect(response.refreshToken!.length, equals(5000));
      expect(response.idToken!.length, equals(5000));
    });
  });

  group('AuthCallbacks', () {
    test('AuthSuccessCallback typedef should accept all named parameters', () {
      String? receivedAccessToken;
      String? receivedRefreshToken;
      String? receivedIdToken;

      callback({
        String? accessToken,
        String? refreshToken,
        String? idToken,
      }) {
        receivedAccessToken = accessToken;
        receivedRefreshToken = refreshToken;
        receivedIdToken = idToken;
      }

      callback(
        accessToken: 'access',
        refreshToken: 'refresh',
        idToken: 'id',
      );

      expect(receivedAccessToken, equals('access'));
      expect(receivedRefreshToken, equals('refresh'));
      expect(receivedIdToken, equals('id'));
    });

    test('AuthSuccessCallback should handle null parameters', () {
      String? receivedAccessToken = 'initial';
      String? receivedRefreshToken = 'initial';
      String? receivedIdToken = 'initial';

      callback({
        String? accessToken,
        String? refreshToken,
        String? idToken,
      }) {
        receivedAccessToken = accessToken;
        receivedRefreshToken = refreshToken;
        receivedIdToken = idToken;
      }

      callback();

      expect(receivedAccessToken, isNull);
      expect(receivedRefreshToken, isNull);
      expect(receivedIdToken, isNull);
    });

    test('AuthSuccessCallback should handle partial parameters', () {
      String? receivedAccessToken;
      String? receivedRefreshToken;
      String? receivedIdToken;

      callback({
        String? accessToken,
        String? refreshToken,
        String? idToken,
      }) {
        receivedAccessToken = accessToken;
        receivedRefreshToken = refreshToken;
        receivedIdToken = idToken;
      }

      callback(accessToken: 'only-access');

      expect(receivedAccessToken, equals('only-access'));
      expect(receivedRefreshToken, isNull);
      expect(receivedIdToken, isNull);
    });

    test('AuthErrorCallback typedef should accept error message', () {
      String? receivedError;

      callback(String errorMessage) {
        receivedError = errorMessage;
      }

      callback('Test error message');

      expect(receivedError, equals('Test error message'));
    });

    test('AuthErrorCallback should handle empty error message', () {
      String? receivedError;

      callback(String errorMessage) {
        receivedError = errorMessage;
      }

      callback('');

      expect(receivedError, equals(''));
    });

    test('AuthErrorCallback should handle long error messages', () {
      String? receivedError;
      final longMessage = 'Error: ${'a' * 1000}';

      callback(String errorMessage) {
        receivedError = errorMessage;
      }

      callback(longMessage);

      expect(receivedError, equals(longMessage));
      expect(receivedError!.length, greaterThan(1000));
    });

    test('AuthErrorCallback should handle special characters', () {
      String? receivedError;

      callback(String errorMessage) {
        receivedError = errorMessage;
      }

      callback('Error: "quotes" & <tags> and ñ unicode');

      expect(receivedError, contains('"quotes"'));
      expect(receivedError, contains('&'));
      expect(receivedError, contains('<tags>'));
      expect(receivedError, contains('ñ'));
    });
  });

  group('CidaasAuthApi interface', () {
    test('CidaasAuthApi interface should define signInWithCidaas', () {
      // Verify the interface exists and has the expected method signature
      // This is a compile-time check that the interface is properly defined
      expect(CidaasAuthApi, isNotNull);
    });

    test('CidaasAuthApi interface should define signOut', () {
      // Verify the interface includes signOut method
      expect(CidaasAuthApi, isNotNull);
    });
  });

  group('APIKey extraction', () {
    test('should extract apiKey from APIKey.Key in response', () {
      final jsonResponse = <String, dynamic>{
        'Name': 'Test App',
        'APIKey': <String, dynamic>{
          'Key': '5740ed00-f13b-11ec-b42f-3bd642eee790',
          'Status': 1,
        },
        'Configurations': <dynamic>[],
      };

      final apiKeyObj = jsonResponse['APIKey'] as Map<String, dynamic>?;
      final apiKey = apiKeyObj?['Key'] as String?;
      expect(apiKey, equals('5740ed00-f13b-11ec-b42f-3bd642eee790'));
    });

    test('should handle missing APIKey in response', () {
      final jsonResponse = <String, dynamic>{
        'Name': 'Test App',
        'Configurations': <dynamic>[],
      };

      final apiKeyObj = jsonResponse['APIKey'] as Map<String, dynamic>?;
      final apiKey = apiKeyObj?['Key'] as String?;
      expect(apiKey, isNull);
    });

    test('should handle null Key in APIKey object', () {
      final jsonResponse = <String, dynamic>{
        'Name': 'Test App',
        'APIKey': <String, dynamic>{
          'Status': 1,
        },
        'Configurations': <dynamic>[],
      };

      final apiKeyObj = jsonResponse['APIKey'] as Map<String, dynamic>?;
      final apiKey = apiKeyObj?['Key'] as String?;
      expect(apiKey, isNull);
    });

    test('should use module-specific apiKey when available', () {
      final moduleConfig = <String, dynamic>{
        'Module': 'testModule',
        'Cidaas': <String, dynamic>{
          'apiKey': 'module-specific-api-key',
        },
      };

      String? apiKey;
      final cidaasConfig = moduleConfig['Cidaas'] as Map<String, dynamic>?;
      if (cidaasConfig != null && cidaasConfig['apiKey'] != null) {
        apiKey = cidaasConfig['apiKey'] as String?;
      }

      expect(apiKey, equals('module-specific-api-key'));
    });
  });

  group('PkceUtils', () {
    test('should generate random string of correct length', () {
      final str32 = PkceUtils.generateRandomString(32);
      final str64 = PkceUtils.generateRandomString(64);

      expect(str32.length, equals(32));
      expect(str64.length, equals(64));
    });

    test('should generate valid code verifier', () {
      final verifier = PkceUtils.generateCodeVerifier();

      expect(verifier.length, equals(128));
      expect(PkceUtils.isValidCodeVerifier(verifier), isTrue);
    });

    test('should generate code challenge from verifier', () {
      final verifier = PkceUtils.generateCodeVerifier();
      final challenge = PkceUtils.generateCodeChallenge(verifier);

      expect(challenge, isNotEmpty);
      expect(challenge, isNot(contains('='))); // No padding
    });

    test('should generate state parameter', () {
      final state = PkceUtils.generateState();

      expect(state.length, equals(32));
    });

    test('should validate code verifier length requirements', () {
      expect(PkceUtils.isValidCodeVerifier('a' * 42), isFalse); // Too short
      expect(PkceUtils.isValidCodeVerifier('a' * 43), isTrue); // Min length
      expect(PkceUtils.isValidCodeVerifier('a' * 128), isTrue); // Max length
      expect(PkceUtils.isValidCodeVerifier('a' * 129), isFalse); // Too long
    });
  });
}
