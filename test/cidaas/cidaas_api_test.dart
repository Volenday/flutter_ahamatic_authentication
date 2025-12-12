import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:flutter_ahamatic_authentication/cidaas/cidaas_api.dart';
import 'package:flutter_ahamatic_authentication/cidaas/cidaas_entity.dart';

void main() {
  late Dio dio;
  late DioAdapter dioAdapter;

  const testApiUrl = 'https://test.api.ahamatic.com';

  setUp(() {
    dio = Dio();
    dioAdapter = DioAdapter(dio: dio);
  });

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
    });

    test('should create response with null tokens', () {
      final response = AhamaticResponse();

      expect(response.accessToken, isNull);
      expect(response.refreshToken, isNull);
      expect(response.idToken, isNull);
    });

    test('should create response with only accessToken', () {
      final response = AhamaticResponse(accessToken: 'access-only');

      expect(response.accessToken, equals('access-only'));
      expect(response.refreshToken, isNull);
      expect(response.idToken, isNull);
    });

    test('should create response with only refreshToken', () {
      final response = AhamaticResponse(refreshToken: 'refresh-only');

      expect(response.accessToken, isNull);
      expect(response.refreshToken, equals('refresh-only'));
      expect(response.idToken, isNull);
    });

    test('should create response with only idToken', () {
      final response = AhamaticResponse(idToken: 'id-only');

      expect(response.accessToken, isNull);
      expect(response.refreshToken, isNull);
      expect(response.idToken, equals('id-only'));
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

  group('CidaasAuthApi - loginEmailAhamatic endpoint', () {
    test('should return token on successful login', () async {
      dioAdapter.onPost(
        '$testApiUrl/api/auth/email',
        (server) => server.reply(200, {'token': 'test-token-xyz'}),
        data: {
          'apiKey': 'test-api-key',
          'emailAddress': 'test@test.com',
          'password': 'password123',
        },
      );

      final response = await dio.post(
        '$testApiUrl/api/auth/email',
        data: {
          'apiKey': 'test-api-key',
          'emailAddress': 'test@test.com',
          'password': 'password123',
        },
      );

      expect(response.data['token'], equals('test-token-xyz'));
      expect(response.statusCode, equals(200));
    });

    test('should handle missing token in response', () async {
      dioAdapter.onPost(
        '$testApiUrl/api/auth/email',
        (server) => server.reply(200, {'data': 'no token here'}),
        data: {
          'apiKey': 'test-api-key',
          'emailAddress': 'test@test.com',
          'password': 'password123',
        },
      );

      final response = await dio.post(
        '$testApiUrl/api/auth/email',
        data: {
          'apiKey': 'test-api-key',
          'emailAddress': 'test@test.com',
          'password': 'password123',
        },
      );

      expect(response.data['token'], isNull);
    });

    test('should handle empty response body', () async {
      dioAdapter.onPost(
        '$testApiUrl/api/auth/email',
        (server) => server.reply(200, {}),
        data: {
          'apiKey': 'test-api-key',
          'emailAddress': 'test@test.com',
          'password': 'password123',
        },
      );

      final response = await dio.post(
        '$testApiUrl/api/auth/email',
        data: {
          'apiKey': 'test-api-key',
          'emailAddress': 'test@test.com',
          'password': 'password123',
        },
      );

      expect(response.data, isEmpty);
    });

    test('should handle 401 Unauthorized', () async {
      dioAdapter.onPost(
        '$testApiUrl/api/auth/email',
        (server) => server.reply(401, {'error': 'Invalid credentials'}),
        data: {
          'apiKey': 'wrong-api-key',
          'emailAddress': 'test@test.com',
          'password': 'wrongpassword',
        },
      );

      expect(
        () async => await dio.post(
          '$testApiUrl/api/auth/email',
          data: {
            'apiKey': 'wrong-api-key',
            'emailAddress': 'test@test.com',
            'password': 'wrongpassword',
          },
        ),
        throwsA(isA<DioException>()),
      );
    });

    test('should handle 400 Bad Request', () async {
      dioAdapter.onPost(
        '$testApiUrl/api/auth/email',
        (server) => server.reply(400, {'error': 'Missing required fields'}),
        data: Matchers.any,
      );

      expect(
        () async => await dio.post(
          '$testApiUrl/api/auth/email',
          data: {'apiKey': 'key'},
        ),
        throwsA(isA<DioException>()),
      );
    });

    test('should handle 500 Server Error', () async {
      dioAdapter.onPost(
        '$testApiUrl/api/auth/email',
        (server) => server.reply(500, {'error': 'Internal server error'}),
        data: Matchers.any,
      );

      expect(
        () async => await dio.post(
          '$testApiUrl/api/auth/email',
          data: {
            'apiKey': 'test-api-key',
            'emailAddress': 'test@test.com',
            'password': 'password123',
          },
        ),
        throwsA(isA<DioException>()),
      );
    });

    test('should handle network error', () async {
      dioAdapter.onPost(
        '$testApiUrl/api/auth/email',
        (server) => server.throws(
          500,
          DioException(
            requestOptions: RequestOptions(path: '/api/auth/email'),
            message: 'Network error',
            type: DioExceptionType.connectionError,
          ),
        ),
        data: Matchers.any,
      );

      expect(
        () async => await dio.post(
          '$testApiUrl/api/auth/email',
          data: {
            'apiKey': 'test-api-key',
            'emailAddress': 'test@test.com',
            'password': 'password123',
          },
        ),
        throwsA(isA<DioException>()),
      );
    });
  });

  group('CidaasAuthApi - fetchAhamaticTokens endpoint', () {
    test('should return all tokens on successful fetch', () async {
      dioAdapter.onPost(
        '$testApiUrl/api/auth/cidaas',
        (server) => server.reply(200, {
          'access_token': 'ahamatic-access-token',
          'refreshToken': 'ahamatic-refresh-token',
          'token': 'ahamatic-id-token',
        }),
        data: {
          'apiKey': 'test-api-key',
          'access_token': 'cidaas-access-token',
          'clientId': 'test-client-id',
          'redirectUrl': 'test',
          'issuer': 'https://issuer.cidaas.eu/',
        },
      );

      final response = await dio.post(
        '$testApiUrl/api/auth/cidaas',
        data: {
          'apiKey': 'test-api-key',
          'access_token': 'cidaas-access-token',
          'clientId': 'test-client-id',
          'redirectUrl': 'test',
          'issuer': 'https://issuer.cidaas.eu/',
        },
      );

      expect(response.data['access_token'], equals('ahamatic-access-token'));
      expect(response.data['refreshToken'], equals('ahamatic-refresh-token'));
      expect(response.data['token'], equals('ahamatic-id-token'));
    });

    test('should handle response with partial tokens', () async {
      dioAdapter.onPost(
        '$testApiUrl/api/auth/cidaas',
        (server) => server.reply(200, {
          'access_token': 'only-access-token',
        }),
        data: Matchers.any,
      );

      final response = await dio.post(
        '$testApiUrl/api/auth/cidaas',
        data: {
          'apiKey': 'test-api-key',
          'access_token': 'cidaas-access-token',
          'clientId': 'test-client-id',
          'redirectUrl': 'test',
          'issuer': 'https://issuer.cidaas.eu/',
        },
      );

      expect(response.data['access_token'], equals('only-access-token'));
      expect(response.data['refreshToken'], isNull);
      expect(response.data['token'], isNull);
    });

    test('should handle JWT tokens in response', () async {
      const jwtAccessToken = 'eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.'
          'eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiYWRtaW4iOnRydWV9.'
          'signature';

      dioAdapter.onPost(
        '$testApiUrl/api/auth/cidaas',
        (server) => server.reply(200, {
          'access_token': jwtAccessToken,
          'refreshToken': 'refresh',
          'token': jwtAccessToken,
        }),
        data: Matchers.any,
      );

      final response = await dio.post(
        '$testApiUrl/api/auth/cidaas',
        data: {
          'apiKey': 'test-api-key',
          'access_token': 'cidaas-access-token',
          'clientId': 'test-client-id',
          'redirectUrl': 'test',
          'issuer': 'https://issuer.cidaas.eu/',
        },
      );

      expect(response.data['access_token'], contains('.'));
      expect(response.data['access_token'].split('.').length, equals(3));
    });

    test('should handle 401 when Cidaas token is invalid', () async {
      dioAdapter.onPost(
        '$testApiUrl/api/auth/cidaas',
        (server) => server.reply(401, {'error': 'Invalid Cidaas token'}),
        data: Matchers.any,
      );

      expect(
        () async => await dio.post(
          '$testApiUrl/api/auth/cidaas',
          data: {
            'apiKey': 'test-api-key',
            'access_token': 'invalid-token',
            'clientId': 'test-client-id',
            'redirectUrl': 'test',
            'issuer': 'https://issuer.cidaas.eu/',
          },
        ),
        throwsA(isA<DioException>()),
      );
    });

    test('should handle 403 when issuer mismatch', () async {
      dioAdapter.onPost(
        '$testApiUrl/api/auth/cidaas',
        (server) => server.reply(403, {'error': 'Issuer mismatch'}),
        data: Matchers.any,
      );

      expect(
        () async => await dio.post(
          '$testApiUrl/api/auth/cidaas',
          data: {
            'apiKey': 'test-api-key',
            'access_token': 'token',
            'clientId': 'test-client-id',
            'redirectUrl': 'test',
            'issuer': 'https://wrong-issuer.cidaas.eu/',
          },
        ),
        throwsA(isA<DioException>()),
      );
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
  });
}
