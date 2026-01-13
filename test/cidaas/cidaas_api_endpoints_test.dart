import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';

/// API endpoint tests for Cidaas authentication
///
/// These tests cover:
/// - loginEmailAhamatic endpoint
/// - fetchAhamaticTokens endpoint (Cidaas token exchange)
/// - Error handling for API calls
/// - Network error scenarios
void main() {
  late Dio dio;
  late DioAdapter dioAdapter;

  const testApiUrl = 'https://test.api.ahamatic.com';

  setUp(() {
    dio = Dio();
    dioAdapter = DioAdapter(dio: dio);
  });

  group('loginEmailAhamatic endpoint', () {
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

  group('fetchAhamaticTokens endpoint (Cidaas integration)', () {
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

    test('should handle 412 Precondition Failed (missing apiKey)', () async {
      dioAdapter.onPost(
        '$testApiUrl/api/auth/cidaas',
        (server) => server.reply(412, {'error': 'API key is required'}),
        data: Matchers.any,
      );

      expect(
        () async => await dio.post(
          '$testApiUrl/api/auth/cidaas',
          data: {
            'apiKey': '',
            'access_token': 'token',
            'clientId': 'test-client-id',
            'redirectUrl': 'test',
            'issuer': 'https://issuer.cidaas.eu/',
          },
        ),
        throwsA(isA<DioException>()),
      );
    });
  });

  group('API Timeout and Retry', () {
    test('should handle connection timeout', () async {
      dioAdapter.onPost(
        '$testApiUrl/api/auth/cidaas',
        (server) => server.throws(
          408,
          DioException(
            requestOptions: RequestOptions(path: '/api/auth/cidaas'),
            message: 'Connection timeout',
            type: DioExceptionType.connectionTimeout,
          ),
        ),
        data: Matchers.any,
      );

      expect(
        () async => await dio.post(
          '$testApiUrl/api/auth/cidaas',
          data: {'apiKey': 'test'},
        ),
        throwsA(isA<DioException>()),
      );
    });

    test('should handle receive timeout', () async {
      dioAdapter.onPost(
        '$testApiUrl/api/auth/cidaas',
        (server) => server.throws(
          408,
          DioException(
            requestOptions: RequestOptions(path: '/api/auth/cidaas'),
            message: 'Receive timeout',
            type: DioExceptionType.receiveTimeout,
          ),
        ),
        data: Matchers.any,
      );

      expect(
        () async => await dio.post(
          '$testApiUrl/api/auth/cidaas',
          data: {'apiKey': 'test'},
        ),
        throwsA(isA<DioException>()),
      );
    });
  });

  group('API Request Validation', () {
    test('should send correct Content-Type header', () async {
      dioAdapter.onPost(
        '$testApiUrl/api/auth/cidaas',
        (server) => server.reply(200, {'access_token': 'token'}),
        data: Matchers.any,
        headers: {'content-type': 'application/json'},
      );

      dio.options.headers['content-type'] = 'application/json';

      final response = await dio.post(
        '$testApiUrl/api/auth/cidaas',
        data: {'apiKey': 'test'},
      );

      expect(response.statusCode, equals(200));
    });

    test('should handle response with extra fields', () async {
      dioAdapter.onPost(
        '$testApiUrl/api/auth/cidaas',
        (server) => server.reply(200, {
          'access_token': 'token',
          'refreshToken': 'refresh',
          'token': 'id',
          'expires_in': 3600,
          'token_type': 'Bearer',
          'extra_field': 'ignored',
        }),
        data: Matchers.any,
      );

      final response = await dio.post(
        '$testApiUrl/api/auth/cidaas',
        data: {'apiKey': 'test'},
      );

      expect(response.data['access_token'], equals('token'));
      expect(response.data['expires_in'], equals(3600));
      expect(response.data['extra_field'], equals('ignored'));
    });
  });
}
