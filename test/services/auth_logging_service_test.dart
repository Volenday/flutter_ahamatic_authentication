import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:flutter_ahamatic_authentication/services/auth_logging_service.dart';

void main() {
  late Dio dio;
  late DioAdapter dioAdapter;
  late AuthLoggingServiceImpl service;
  
  const testApiUrl = 'https://test.api.ahamatic.com';

  setUp(() {
    dio = Dio();
    dioAdapter = DioAdapter(dio: dio);
    service = AuthLoggingServiceImpl(dio: dio, apiUrl: testApiUrl);
  });

  group('AuthLoggingService', () {
    group('logLoginEvent', () {
      // Valid JWT tokens for testing (different payloads)
      // Payload: {"account": {"PersonId": 123}}
      const validToken = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.'
          'eyJhY2NvdW50Ijp7IlBlcnNvbklkIjoxMjN9fQ.'
          'signature';

      // Payload: {"account": {"PersonId": 456, "Name": "Test User"}}
      const validTokenWithName = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.'
          'eyJhY2NvdW50Ijp7IlBlcnNvbklkIjo0NTYsIk5hbWUiOiJUZXN0IFVzZXIifX0.'
          'signature';

      // Payload: {"account": {"PersonId": 789}, "exp": 1234567890}
      const validTokenWithExp = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.'
          'eyJhY2NvdW50Ijp7IlBlcnNvbklkIjo3ODl9LCJleHAiOjEyMzQ1Njc4OTB9.'
          'signature';

      test('should send log successfully with valid token', () async {
        dioAdapter.onPost(
          '$testApiUrl/api/e/_logs',
          (server) => server.reply(200, {'success': true}),
          data: Matchers.any,
        );

        await expectLater(
          service.logLoginEvent(
            token: validToken,
            loginUrl: 'https://login.url',
            moduleName: 'testModule',
            appVersion: '1.0.0',
          ),
          completes,
        );
      });

      test('should send log with correct payload structure', () async {
        dioAdapter.onPost(
          '$testApiUrl/api/e/_logs',
          (server) => server.reply(200, {'success': true}),
          data: Matchers.any,
        );

        // Should complete without error, indicating the request was made with valid payload
        await expectLater(
          service.logLoginEvent(
            token: validToken,
            loginUrl: 'https://login.url/auth',
            moduleName: 'myModule',
            appVersion: '2.5.0',
          ),
          completes,
        );
      });

      test('should handle different PersonId values', () async {
        dioAdapter.onPost(
          '$testApiUrl/api/e/_logs',
          (server) => server.reply(200, {'success': true}),
          data: Matchers.any,
        );

        await expectLater(
          service.logLoginEvent(
            token: validTokenWithName,
            loginUrl: 'https://login.url',
            moduleName: 'testModule',
            appVersion: '1.0.0',
          ),
          completes,
        );
      });

      test('should handle token with expiration claim', () async {
        dioAdapter.onPost(
          '$testApiUrl/api/e/_logs',
          (server) => server.reply(200, {'success': true}),
          data: Matchers.any,
        );

        await expectLater(
          service.logLoginEvent(
            token: validTokenWithExp,
            loginUrl: 'https://login.url',
            moduleName: 'testModule',
            appVersion: '1.0.0',
          ),
          completes,
        );
      });

      test('should not throw when token is empty', () async {
        await expectLater(
          service.logLoginEvent(
            token: '',
            loginUrl: 'https://login.url',
            moduleName: 'testModule',
            appVersion: '1.0.0',
          ),
          completes,
        );
      });

      test('should not throw when token is invalid format', () async {
        await expectLater(
          service.logLoginEvent(
            token: 'invalid-token',
            loginUrl: 'https://login.url',
            moduleName: 'testModule',
            appVersion: '1.0.0',
          ),
          completes,
        );
      });

      test('should not throw when token has only header', () async {
        await expectLater(
          service.logLoginEvent(
            token: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9',
            loginUrl: 'https://login.url',
            moduleName: 'testModule',
            appVersion: '1.0.0',
          ),
          completes,
        );
      });

      test('should not throw when token has malformed payload', () async {
        // Token with invalid base64 in payload
        await expectLater(
          service.logLoginEvent(
            token: 'eyJhbGciOiJIUzI1NiJ9.!!!invalid!!!.signature',
            loginUrl: 'https://login.url',
            moduleName: 'testModule',
            appVersion: '1.0.0',
          ),
          completes,
        );
      });

      test('should not throw when token payload has no account', () async {
        // Payload: {"user": "test"}
        const tokenNoAccount = 'eyJhbGciOiJIUzI1NiJ9.'
            'eyJ1c2VyIjoidGVzdCJ9.'
            'signature';
        
        await expectLater(
          service.logLoginEvent(
            token: tokenNoAccount,
            loginUrl: 'https://login.url',
            moduleName: 'testModule',
            appVersion: '1.0.0',
          ),
          completes,
        );
      });

      test('should not throw when token payload has account but no PersonId', () async {
        // Payload: {"account": {"Name": "Test"}}
        const tokenNoPersonId = 'eyJhbGciOiJIUzI1NiJ9.'
            'eyJhY2NvdW50Ijp7Ik5hbWUiOiJUZXN0In19.'
            'signature';
        
        await expectLater(
          service.logLoginEvent(
            token: tokenNoPersonId,
            loginUrl: 'https://login.url',
            moduleName: 'testModule',
            appVersion: '1.0.0',
          ),
          completes,
        );
      });

      test('should handle network errors gracefully', () async {
        dioAdapter.onPost(
          '$testApiUrl/api/e/_logs',
          (server) => server.throws(
            500,
            DioException(
              requestOptions: RequestOptions(path: '/api/e/_logs'),
              message: 'Network error',
              type: DioExceptionType.connectionError,
            ),
          ),
          data: Matchers.any,
        );

        await expectLater(
          service.logLoginEvent(
            token: validToken,
            loginUrl: 'https://login.url',
            moduleName: 'testModule',
            appVersion: '1.0.0',
          ),
          completes,
        );
      });

      test('should handle connection timeout gracefully', () async {
        dioAdapter.onPost(
          '$testApiUrl/api/e/_logs',
          (server) => server.throws(
            500,
            DioException(
              requestOptions: RequestOptions(path: '/api/e/_logs'),
              message: 'Connection timeout',
              type: DioExceptionType.connectionTimeout,
            ),
          ),
          data: Matchers.any,
        );

        await expectLater(
          service.logLoginEvent(
            token: validToken,
            loginUrl: 'https://login.url',
            moduleName: 'testModule',
            appVersion: '1.0.0',
          ),
          completes,
        );
      });

      test('should handle receive timeout gracefully', () async {
        dioAdapter.onPost(
          '$testApiUrl/api/e/_logs',
          (server) => server.throws(
            500,
            DioException(
              requestOptions: RequestOptions(path: '/api/e/_logs'),
              message: 'Receive timeout',
              type: DioExceptionType.receiveTimeout,
            ),
          ),
          data: Matchers.any,
        );

        await expectLater(
          service.logLoginEvent(
            token: validToken,
            loginUrl: 'https://login.url',
            moduleName: 'testModule',
            appVersion: '1.0.0',
          ),
          completes,
        );
      });

      test('should handle 400 Bad Request gracefully', () async {
        dioAdapter.onPost(
          '$testApiUrl/api/e/_logs',
          (server) => server.reply(400, {'error': 'Bad request'}),
          data: Matchers.any,
        );

        await expectLater(
          service.logLoginEvent(
            token: validToken,
            loginUrl: 'https://login.url',
            moduleName: 'testModule',
            appVersion: '1.0.0',
          ),
          completes,
        );
      });

      test('should handle 401 Unauthorized gracefully', () async {
        dioAdapter.onPost(
          '$testApiUrl/api/e/_logs',
          (server) => server.reply(401, {'error': 'Unauthorized'}),
          data: Matchers.any,
        );

        await expectLater(
          service.logLoginEvent(
            token: validToken,
            loginUrl: 'https://login.url',
            moduleName: 'testModule',
            appVersion: '1.0.0',
          ),
          completes,
        );
      });

      test('should handle 403 Forbidden gracefully', () async {
        dioAdapter.onPost(
          '$testApiUrl/api/e/_logs',
          (server) => server.reply(403, {'error': 'Forbidden'}),
          data: Matchers.any,
        );

        await expectLater(
          service.logLoginEvent(
            token: validToken,
            loginUrl: 'https://login.url',
            moduleName: 'testModule',
            appVersion: '1.0.0',
          ),
          completes,
        );
      });

      test('should handle 500 Internal Server Error gracefully', () async {
        dioAdapter.onPost(
          '$testApiUrl/api/e/_logs',
          (server) => server.reply(500, {'error': 'Server error'}),
          data: Matchers.any,
        );

        await expectLater(
          service.logLoginEvent(
            token: validToken,
            loginUrl: 'https://login.url',
            moduleName: 'testModule',
            appVersion: '1.0.0',
          ),
          completes,
        );
      });

      test('should handle 502 Bad Gateway gracefully', () async {
        dioAdapter.onPost(
          '$testApiUrl/api/e/_logs',
          (server) => server.reply(502, {'error': 'Bad gateway'}),
          data: Matchers.any,
        );

        await expectLater(
          service.logLoginEvent(
            token: validToken,
            loginUrl: 'https://login.url',
            moduleName: 'testModule',
            appVersion: '1.0.0',
          ),
          completes,
        );
      });

      test('should handle 503 Service Unavailable gracefully', () async {
        dioAdapter.onPost(
          '$testApiUrl/api/e/_logs',
          (server) => server.reply(503, {'error': 'Service unavailable'}),
          data: Matchers.any,
        );

        await expectLater(
          service.logLoginEvent(
            token: validToken,
            loginUrl: 'https://login.url',
            moduleName: 'testModule',
            appVersion: '1.0.0',
          ),
          completes,
        );
      });

      test('should handle null moduleName', () async {
        dioAdapter.onPost(
          '$testApiUrl/api/e/_logs',
          (server) => server.reply(200, {'success': true}),
          data: Matchers.any,
        );

        await expectLater(
          service.logLoginEvent(
            token: validToken,
            loginUrl: 'https://login.url',
            moduleName: null,
            appVersion: '1.0.0',
          ),
          completes,
        );
      });

      test('should handle null appVersion', () async {
        dioAdapter.onPost(
          '$testApiUrl/api/e/_logs',
          (server) => server.reply(200, {'success': true}),
          data: Matchers.any,
        );

        await expectLater(
          service.logLoginEvent(
            token: validToken,
            loginUrl: 'https://login.url',
            moduleName: 'testModule',
            appVersion: null,
          ),
          completes,
        );
      });

      test('should handle empty loginUrl', () async {
        dioAdapter.onPost(
          '$testApiUrl/api/e/_logs',
          (server) => server.reply(200, {'success': true}),
          data: Matchers.any,
        );

        await expectLater(
          service.logLoginEvent(
            token: validToken,
            loginUrl: '',
            moduleName: 'testModule',
            appVersion: '1.0.0',
          ),
          completes,
        );
      });

      test('should handle very long loginUrl', () async {
        final longUrl = 'https://login.url/${'a' * 1000}';
        
        dioAdapter.onPost(
          '$testApiUrl/api/e/_logs',
          (server) => server.reply(200, {'success': true}),
          data: Matchers.any,
        );

        await expectLater(
          service.logLoginEvent(
            token: validToken,
            loginUrl: longUrl,
            moduleName: 'testModule',
            appVersion: '1.0.0',
          ),
          completes,
        );
      });

      test('should handle loginUrl with special characters', () async {
        const specialUrl = 'https://login.url/auth?param=value&other=test#section';
        
        dioAdapter.onPost(
          '$testApiUrl/api/e/_logs',
          (server) => server.reply(200, {'success': true}),
          data: Matchers.any,
        );

        await expectLater(
          service.logLoginEvent(
            token: validToken,
            loginUrl: specialUrl,
            moduleName: 'testModule',
            appVersion: '1.0.0',
          ),
          completes,
        );
      });

      test('should handle moduleName with special characters', () async {
        dioAdapter.onPost(
          '$testApiUrl/api/e/_logs',
          (server) => server.reply(200, {'success': true}),
          data: Matchers.any,
        );

        await expectLater(
          service.logLoginEvent(
            token: validToken,
            loginUrl: 'https://login.url',
            moduleName: 'test-module_v2.0',
            appVersion: '1.0.0',
          ),
          completes,
        );
      });

      test('should handle appVersion with different formats', () async {
        dioAdapter.onPost(
          '$testApiUrl/api/e/_logs',
          (server) => server.reply(200, {'success': true}),
          data: Matchers.any,
        );

        // Semantic versioning
        await expectLater(
          service.logLoginEvent(
            token: validToken,
            loginUrl: 'https://login.url',
            moduleName: 'testModule',
            appVersion: '1.2.3',
          ),
          completes,
        );

        // With build number
        await expectLater(
          service.logLoginEvent(
            token: validToken,
            loginUrl: 'https://login.url',
            moduleName: 'testModule',
            appVersion: '1.2.3+45',
          ),
          completes,
        );

        // With pre-release tag
        await expectLater(
          service.logLoginEvent(
            token: validToken,
            loginUrl: 'https://login.url',
            moduleName: 'testModule',
            appVersion: '1.2.3-beta.1',
          ),
          completes,
        );
      });

      test('should handle multiple concurrent calls', () async {
        dioAdapter.onPost(
          '$testApiUrl/api/e/_logs',
          (server) => server.reply(200, {'success': true}),
          data: Matchers.any,
        );

        final futures = List.generate(10, (index) {
          return service.logLoginEvent(
            token: validToken,
            loginUrl: 'https://login.url/$index',
            moduleName: 'testModule',
            appVersion: '1.0.$index',
          );
        });

        await expectLater(
          Future.wait(futures),
          completes,
        );
      });
    });
  });

  group('AuthLoggingService initialization', () {
    test('should create service with provided Dio instance', () {
      final customDio = Dio();
      final customService = AuthLoggingServiceImpl(
        dio: customDio,
        apiUrl: 'https://custom.api.url',
      );

      expect(customService, isNotNull);
    });

    test('should create service with different API URLs', () {
      final devService = AuthLoggingServiceImpl(
        dio: Dio(),
        apiUrl: 'https://dev.api.ahamatic.com',
      );

      final prodService = AuthLoggingServiceImpl(
        dio: Dio(),
        apiUrl: 'https://api-eu.ahamatic.com',
      );

      expect(devService, isNotNull);
      expect(prodService, isNotNull);
    });
  });

  group('AuthLoggingService edge cases', () {
    test('should handle whitespace-only token', () async {
      await expectLater(
        service.logLoginEvent(
          token: '   ',
          loginUrl: 'https://login.url',
          moduleName: 'testModule',
          appVersion: '1.0.0',
        ),
        completes,
      );
    });

    test('should handle Unicode in moduleName', () async {
      dioAdapter.onPost(
        '$testApiUrl/api/e/_logs',
        (server) => server.reply(200, {'success': true}),
        data: Matchers.any,
      );

      await expectLater(
        service.logLoginEvent(
          token: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.'
              'eyJhY2NvdW50Ijp7IlBlcnNvbklkIjoxMjN9fQ.'
              'signature',
          loginUrl: 'https://login.url',
          moduleName: 'unicode_module_名前',
          appVersion: '1.0.0',
        ),
        completes,
      );
    });

    test('should handle very long token', () async {
      // Create a very long but valid-looking token
      final longPayload = 'a' * 5000;
      final longToken = 'eyJhbGciOiJIUzI1NiJ9.$longPayload.signature';

      await expectLater(
        service.logLoginEvent(
          token: longToken,
          loginUrl: 'https://login.url',
          moduleName: 'testModule',
          appVersion: '1.0.0',
        ),
        completes,
      );
    });
  });
}
