import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:flutter_ahamatic_authentication/services/ahamatic_api_service.dart';
import 'package:flutter_ahamatic_authentication/models/app_config.dart';

void main() {
  late Dio dio;
  late DioAdapter dioAdapter;
  late AhamaticApiServiceImpl service;
  
  const testApiUrl = 'https://test.api.ahamatic.com';
  const testAppCode = 'testApp';

  setUp(() {
    dio = Dio();
    dioAdapter = DioAdapter(dio: dio);
    service = AhamaticApiServiceImpl(dio: dio, apiUrl: testApiUrl);
  });

  group('AhamaticApiService', () {
    group('validateApp', () {
      test('should return AppValidationResponse on successful validation', () async {
        const expectedName = 'Test Application';
        dioAdapter.onGet(
          RegExp(r'/api/validate/app'),
          (server) => server.reply(200, {
            'Name': expectedName,
            'Configurations': [],
          }),
        );

        final result = await service.validateApp(testAppCode);

        expect(result.name, equals(expectedName));
        expect(result.moduleConfig, isNotNull);
      });

      test('should handle app name with special characters', () async {
        const expectedName = 'Test App™ - Ñoño & More (2024)';
        dioAdapter.onGet(
          RegExp(r'/api/validate/app'),
          (server) => server.reply(200, {
            'Name': expectedName,
            'Configurations': [],
          }),
        );

        final result = await service.validateApp(testAppCode);

        expect(result.name, equals(expectedName));
      });

      test('should handle empty app name', () async {
        dioAdapter.onGet(
          RegExp(r'/api/validate/app'),
          (server) => server.reply(200, {
            'Name': '',
            'Configurations': [],
          }),
        );

        final result = await service.validateApp(testAppCode);

        expect(result.name, equals(''));
      });

      test('should handle null app name', () async {
        dioAdapter.onGet(
          RegExp(r'/api/validate/app'),
          (server) => server.reply(200, {
            'Name': null,
            'Configurations': [],
          }),
        );

        final result = await service.validateApp(testAppCode);

        expect(result.name, equals(''));
      });

      test('should handle missing Name field', () async {
        dioAdapter.onGet(
          RegExp(r'/api/validate/app'),
          (server) => server.reply(200, {
            'Configurations': [],
          }),
        );

        final result = await service.validateApp(testAppCode);

        expect(result.name, equals(''));
      });

      test('should throw AhamaticApiException on 400 Bad Request', () async {
        dioAdapter.onGet(
          RegExp(r'/api/validate/app'),
          (server) => server.reply(400, {'error': 'Bad request'}),
        );

        expect(
          () => service.validateApp(testAppCode),
          throwsA(isA<AhamaticApiException>()),
        );
      });

      test('should throw AhamaticApiException on 401 Unauthorized', () async {
        dioAdapter.onGet(
          RegExp(r'/api/validate/app'),
          (server) => server.reply(401, {'error': 'Unauthorized'}),
        );

        expect(
          () => service.validateApp(testAppCode),
          throwsA(isA<AhamaticApiException>()),
        );
      });

      test('should throw AhamaticApiException on 403 Forbidden', () async {
        dioAdapter.onGet(
          RegExp(r'/api/validate/app'),
          (server) => server.reply(403, {'error': 'Forbidden'}),
        );

        expect(
          () => service.validateApp(testAppCode),
          throwsA(isA<AhamaticApiException>()),
        );
      });

      test('should throw AhamaticApiException on 404 Not Found', () async {
        dioAdapter.onGet(
          RegExp(r'/api/validate/app'),
          (server) => server.reply(404, {'error': 'Not found'}),
        );

        expect(
          () => service.validateApp(testAppCode),
          throwsA(isA<AhamaticApiException>()),
        );
      });

      test('should throw AhamaticApiException on 500 Internal Server Error', () async {
        dioAdapter.onGet(
          RegExp(r'/api/validate/app'),
          (server) => server.reply(500, {'error': 'Internal server error'}),
        );

        expect(
          () => service.validateApp(testAppCode),
          throwsA(isA<AhamaticApiException>()),
        );
      });

      test('should throw AhamaticApiException on 502 Bad Gateway', () async {
        dioAdapter.onGet(
          RegExp(r'/api/validate/app'),
          (server) => server.reply(502, {'error': 'Bad gateway'}),
        );

        expect(
          () => service.validateApp(testAppCode),
          throwsA(isA<AhamaticApiException>()),
        );
      });

      test('should throw AhamaticApiException on 503 Service Unavailable', () async {
        dioAdapter.onGet(
          RegExp(r'/api/validate/app'),
          (server) => server.reply(503, {'error': 'Service unavailable'}),
        );

        expect(
          () => service.validateApp(testAppCode),
          throwsA(isA<AhamaticApiException>()),
        );
      });

      test('should throw AhamaticApiException on network error', () async {
        dioAdapter.onGet(
          RegExp(r'/api/validate/app'),
          (server) => server.throws(
            500,
            DioException(
              requestOptions: RequestOptions(path: '/api/validate/app'),
              message: 'Network error',
              type: DioExceptionType.connectionError,
            ),
          ),
        );

        expect(
          () => service.validateApp(testAppCode),
          throwsA(isA<AhamaticApiException>()),
        );
      });

      test('should throw AhamaticApiException on connection timeout', () async {
        dioAdapter.onGet(
          RegExp(r'/api/validate/app'),
          (server) => server.throws(
            500,
            DioException(
              requestOptions: RequestOptions(path: '/api/validate/app'),
              message: 'Connection timeout',
              type: DioExceptionType.connectionTimeout,
            ),
          ),
        );

        expect(
          () => service.validateApp(testAppCode),
          throwsA(isA<AhamaticApiException>()),
        );
      });

      test('should throw AhamaticApiException on receive timeout', () async {
        dioAdapter.onGet(
          RegExp(r'/api/validate/app'),
          (server) => server.throws(
            500,
            DioException(
              requestOptions: RequestOptions(path: '/api/validate/app'),
              message: 'Receive timeout',
              type: DioExceptionType.receiveTimeout,
            ),
          ),
        );

        expect(
          () => service.validateApp(testAppCode),
          throwsA(isA<AhamaticApiException>()),
        );
      });
    });

    group('getModuleConfig', () {
      test('should return ModuleAuthConfig with Cidaas enabled', () async {
        const moduleName = 'testModule';
        dioAdapter.onGet(
          RegExp(r'/api/validate/app'),
          (server) => server.reply(200, {
            'Name': 'Test App',
            'Configurations': [
              {
                'Key': 'AuthConfig',
                'Value': [
                  {
                    'Module': moduleName,
                    'Cidaas': {'apiKey': 'test-api-key'},
                    'Portal Authentication': {
                      'Cidaas': true,
                      'OpenIAmAuth': false,
                    },
                    'HostName': 'test.host.com',
                  }
                ],
              }
            ],
          }),
        );

        final result = await service.getModuleConfig(testAppCode, moduleName);

        expect(result.isCidaasEnabled, isTrue);
        expect(result.isOpeniamEnabled, isFalse);
        expect(result.apiKey, equals('test-api-key'));
        expect(result.hostName, equals('test.host.com'));
      });

      test('should return ModuleAuthConfig with OpenIAM enabled', () async {
        const moduleName = 'testModule';
        dioAdapter.onGet(
          RegExp(r'/api/validate/app'),
          (server) => server.reply(200, {
            'Name': 'Test App',
            'Configurations': [
              {
                'Key': 'AuthConfig',
                'Value': [
                  {
                    'Module': moduleName,
                    'Portal Authentication': {
                      'Cidaas': false,
                      'OpenIAmAuth': true,
                    },
                    'OpenIAMConfig': {
                      'logo': 'https://logo.url/image.png',
                      'title': 'OpenIAM Title',
                    },
                    'HostName': 'openiam.host.com',
                  }
                ],
              }
            ],
          }),
        );

        final result = await service.getModuleConfig(testAppCode, moduleName);

        expect(result.isOpeniamEnabled, isTrue);
        expect(result.isCidaasEnabled, isFalse);
        expect(result.openIamLogo, equals('https://logo.url/image.png'));
        expect(result.openIamTitle, equals('OpenIAM Title'));
        expect(result.hostName, equals('openiam.host.com'));
      });

      test('should return ModuleAuthConfig with both Cidaas and OpenIAM enabled', () async {
        const moduleName = 'testModule';
        dioAdapter.onGet(
          RegExp(r'/api/validate/app'),
          (server) => server.reply(200, {
            'Name': 'Test App',
            'Configurations': [
              {
                'Key': 'AuthConfig',
                'Value': [
                  {
                    'Module': moduleName,
                    'Cidaas': {'apiKey': 'both-enabled-api-key'},
                    'Portal Authentication': {
                      'Cidaas': true,
                      'OpenIAmAuth': true,
                    },
                    'OpenIAMConfig': {
                      'logo': 'https://both.logo.url',
                      'title': 'Both Enabled',
                    },
                    'HostName': 'both.host.com',
                  }
                ],
              }
            ],
          }),
        );

        final result = await service.getModuleConfig(testAppCode, moduleName);

        expect(result.isCidaasEnabled, isTrue);
        expect(result.isOpeniamEnabled, isTrue);
        expect(result.apiKey, equals('both-enabled-api-key'));
        expect(result.openIamLogo, equals('https://both.logo.url'));
        expect(result.openIamTitle, equals('Both Enabled'));
      });

      test('should return empty config when module not found', () async {
        const moduleName = 'nonExistentModule';
        dioAdapter.onGet(
          RegExp(r'/api/validate/app'),
          (server) => server.reply(200, {
            'Name': 'Test App',
            'Configurations': [
              {
                'Key': 'AuthConfig',
                'Value': [
                  {
                    'Module': 'differentModule',
                    'Portal Authentication': {'Cidaas': true},
                  }
                ],
              }
            ],
          }),
        );

        final result = await service.getModuleConfig(testAppCode, moduleName);

        expect(result.isCidaasEnabled, isFalse);
        expect(result.isOpeniamEnabled, isFalse);
        expect(result.apiKey, isNull);
        expect(result.hostName, isNull);
      });

      test('should return empty config when AuthConfig not found', () async {
        const moduleName = 'testModule';
        dioAdapter.onGet(
          RegExp(r'/api/validate/app'),
          (server) => server.reply(200, {
            'Name': 'Test App',
            'Configurations': [
              {
                'Key': 'OtherConfig',
                'Value': 'something',
              }
            ],
          }),
        );

        final result = await service.getModuleConfig(testAppCode, moduleName);

        expect(result.isCidaasEnabled, isFalse);
        expect(result.isOpeniamEnabled, isFalse);
      });

      test('should return empty config when Configurations is null', () async {
        const moduleName = 'testModule';
        dioAdapter.onGet(
          RegExp(r'/api/validate/app'),
          (server) => server.reply(200, {
            'Name': 'Test App',
            'Configurations': null,
          }),
        );

        final result = await service.getModuleConfig(testAppCode, moduleName);

        expect(result.isCidaasEnabled, isFalse);
        expect(result.isOpeniamEnabled, isFalse);
      });

      test('should return empty config when Configurations is empty', () async {
        const moduleName = 'testModule';
        dioAdapter.onGet(
          RegExp(r'/api/validate/app'),
          (server) => server.reply(200, {
            'Name': 'Test App',
            'Configurations': [],
          }),
        );

        final result = await service.getModuleConfig(testAppCode, moduleName);

        expect(result.isCidaasEnabled, isFalse);
        expect(result.isOpeniamEnabled, isFalse);
      });

      test('should return empty config when AuthConfig Value is not a list', () async {
        const moduleName = 'testModule';
        dioAdapter.onGet(
          RegExp(r'/api/validate/app'),
          (server) => server.reply(200, {
            'Name': 'Test App',
            'Configurations': [
              {
                'Key': 'AuthConfig',
                'Value': 'not-a-list',
              }
            ],
          }),
        );

        final result = await service.getModuleConfig(testAppCode, moduleName);

        expect(result.isCidaasEnabled, isFalse);
        expect(result.isOpeniamEnabled, isFalse);
      });

      test('should handle missing Cidaas config object', () async {
        const moduleName = 'testModule';
        dioAdapter.onGet(
          RegExp(r'/api/validate/app'),
          (server) => server.reply(200, {
            'Name': 'Test App',
            'Configurations': [
              {
                'Key': 'AuthConfig',
                'Value': [
                  {
                    'Module': moduleName,
                    'Portal Authentication': {
                      'Cidaas': true,
                      'OpenIAmAuth': false,
                    },
                    'HostName': 'test.host.com',
                  }
                ],
              }
            ],
          }),
        );

        final result = await service.getModuleConfig(testAppCode, moduleName);

        expect(result.isCidaasEnabled, isTrue);
        expect(result.apiKey, isNull);
      });

      test('should handle missing apiKey in Cidaas config', () async {
        const moduleName = 'testModule';
        dioAdapter.onGet(
          RegExp(r'/api/validate/app'),
          (server) => server.reply(200, {
            'Name': 'Test App',
            'Configurations': [
              {
                'Key': 'AuthConfig',
                'Value': [
                  {
                    'Module': moduleName,
                    'Cidaas': {},
                    'Portal Authentication': {
                      'Cidaas': true,
                    },
                  }
                ],
              }
            ],
          }),
        );

        final result = await service.getModuleConfig(testAppCode, moduleName);

        expect(result.isCidaasEnabled, isTrue);
        expect(result.apiKey, isNull);
      });

      test('should handle missing OpenIAMConfig when OpenIAM is enabled', () async {
        const moduleName = 'testModule';
        dioAdapter.onGet(
          RegExp(r'/api/validate/app'),
          (server) => server.reply(200, {
            'Name': 'Test App',
            'Configurations': [
              {
                'Key': 'AuthConfig',
                'Value': [
                  {
                    'Module': moduleName,
                    'Portal Authentication': {
                      'OpenIAmAuth': true,
                    },
                  }
                ],
              }
            ],
          }),
        );

        final result = await service.getModuleConfig(testAppCode, moduleName);

        expect(result.isOpeniamEnabled, isTrue);
        expect(result.openIamLogo, isNull);
        expect(result.openIamTitle, isNull);
      });

      test('should handle missing Portal Authentication object', () async {
        const moduleName = 'testModule';
        dioAdapter.onGet(
          RegExp(r'/api/validate/app'),
          (server) => server.reply(200, {
            'Name': 'Test App',
            'Configurations': [
              {
                'Key': 'AuthConfig',
                'Value': [
                  {
                    'Module': moduleName,
                    'Cidaas': {'apiKey': 'test-key'},
                    'HostName': 'test.com',
                  }
                ],
              }
            ],
          }),
        );

        final result = await service.getModuleConfig(testAppCode, moduleName);

        expect(result.isCidaasEnabled, isFalse);
        expect(result.isOpeniamEnabled, isFalse);
      });

      test('should handle multiple modules and find correct one', () async {
        const targetModule = 'targetModule';
        dioAdapter.onGet(
          RegExp(r'/api/validate/app'),
          (server) => server.reply(200, {
            'Name': 'Test App',
            'Configurations': [
              {
                'Key': 'AuthConfig',
                'Value': [
                  {
                    'Module': 'firstModule',
                    'Cidaas': {'apiKey': 'first-api-key'},
                    'Portal Authentication': {'Cidaas': true},
                  },
                  {
                    'Module': targetModule,
                    'Cidaas': {'apiKey': 'target-api-key'},
                    'Portal Authentication': {'Cidaas': true, 'OpenIAmAuth': true},
                  },
                  {
                    'Module': 'lastModule',
                    'Cidaas': {'apiKey': 'last-api-key'},
                    'Portal Authentication': {'OpenIAmAuth': true},
                  }
                ],
              }
            ],
          }),
        );

        final result = await service.getModuleConfig(testAppCode, targetModule);

        expect(result.apiKey, equals('target-api-key'));
        expect(result.isCidaasEnabled, isTrue);
        expect(result.isOpeniamEnabled, isTrue);
      });

      test('should handle module name with special characters', () async {
        const moduleName = 'test-module_v2.0';
        dioAdapter.onGet(
          RegExp(r'/api/validate/app'),
          (server) => server.reply(200, {
            'Name': 'Test App',
            'Configurations': [
              {
                'Key': 'AuthConfig',
                'Value': [
                  {
                    'Module': moduleName,
                    'Portal Authentication': {'Cidaas': true},
                  }
                ],
              }
            ],
          }),
        );

        final result = await service.getModuleConfig(testAppCode, moduleName);

        expect(result.isCidaasEnabled, isTrue);
      });

      test('should handle very long hostName', () async {
        const moduleName = 'testModule';
        const longHostName = 'very-long-subdomain.another-subdomain.deep.nested.domain.example.com';
        dioAdapter.onGet(
          RegExp(r'/api/validate/app'),
          (server) => server.reply(200, {
            'Name': 'Test App',
            'Configurations': [
              {
                'Key': 'AuthConfig',
                'Value': [
                  {
                    'Module': moduleName,
                    'Portal Authentication': {'Cidaas': true},
                    'HostName': longHostName,
                  }
                ],
              }
            ],
          }),
        );

        final result = await service.getModuleConfig(testAppCode, moduleName);

        expect(result.hostName, equals(longHostName));
      });

      test('should throw AhamaticApiException on network error', () async {
        const moduleName = 'testModule';
        dioAdapter.onGet(
          RegExp(r'/api/validate/app'),
          (server) => server.throws(
            500,
            DioException(
              requestOptions: RequestOptions(path: '/api/validate/app'),
              message: 'Network error',
            ),
          ),
        );

        expect(
          () => service.getModuleConfig(testAppCode, moduleName),
          throwsA(isA<AhamaticApiException>()),
        );
      });

      test('should throw AhamaticApiException on non-200 response', () async {
        const moduleName = 'testModule';
        dioAdapter.onGet(
          RegExp(r'/api/validate/app'),
          (server) => server.reply(500, {'error': 'Server error'}),
        );

        expect(
          () => service.getModuleConfig(testAppCode, moduleName),
          throwsA(isA<AhamaticApiException>()),
        );
      });
    });
  });

  group('ModuleAuthConfig', () {
    test('empty() should return default values', () {
      final config = ModuleAuthConfig.empty();

      expect(config.apiKey, isNull);
      expect(config.isCidaasEnabled, isFalse);
      expect(config.isOpeniamEnabled, isFalse);
      expect(config.openIamLogo, isNull);
      expect(config.openIamTitle, isNull);
      expect(config.hostName, isNull);
    });

    test('should create with all values', () {
      const config = ModuleAuthConfig(
        apiKey: 'api-key',
        isCidaasEnabled: true,
        isOpeniamEnabled: true,
        openIamLogo: 'logo.png',
        openIamTitle: 'Title',
        hostName: 'host.com',
      );

      expect(config.apiKey, equals('api-key'));
      expect(config.isCidaasEnabled, isTrue);
      expect(config.isOpeniamEnabled, isTrue);
      expect(config.openIamLogo, equals('logo.png'));
      expect(config.openIamTitle, equals('Title'));
      expect(config.hostName, equals('host.com'));
    });

    test('should have default false for boolean values', () {
      const config = ModuleAuthConfig();

      expect(config.isCidaasEnabled, isFalse);
      expect(config.isOpeniamEnabled, isFalse);
    });
  });

  group('EnvironmentConfig', () {
    group('development environment', () {
      test('should return correct URLs for europe', () {
        final config = EnvironmentConfig.fromEnvironment('development', true);

        expect(config.apiUrl, equals('https://dev.api.ahamatic.com'));
        expect(config.portalUrl, equals('https://dev.auth-eu.ahamatic.com'));
      });

      test('should return correct URLs for non-europe', () {
        final config = EnvironmentConfig.fromEnvironment('development', false);

        expect(config.apiUrl, equals('https://dev.api.ahamatic.com'));
        expect(config.portalUrl, equals('https://dev.auth.ahamatic.com'));
      });
    });

    group('sandbox environment', () {
      test('should return correct URLs for europe', () {
        final config = EnvironmentConfig.fromEnvironment('sandbox', true);

        expect(config.apiUrl, equals('https://test.api.ahamatic.com'));
        expect(config.portalUrl, equals('https://test.auth-eu.ahamatic.com'));
      });

      test('should return correct URLs for non-europe', () {
        final config = EnvironmentConfig.fromEnvironment('sandbox', false);

        expect(config.apiUrl, equals('https://test.api.ahamatic.com'));
        expect(config.portalUrl, equals('https://test.auth.ahamatic.com'));
      });
    });

    group('production environment', () {
      test('should return correct URLs for europe', () {
        final config = EnvironmentConfig.fromEnvironment('production', true);

        expect(config.apiUrl, equals('https://api-eu.ahamatic.com'));
        expect(config.portalUrl, equals('https://auth-eu.ahamatic.com'));
      });

      test('should return correct URLs for non-europe', () {
        final config = EnvironmentConfig.fromEnvironment('production', false);

        expect(config.apiUrl, equals('https://api-eu.ahamatic.com'));
        expect(config.portalUrl, equals('https://auth.ahamatic.com'));
      });
    });

    group('unknown environment', () {
      test('should default to production for unknown environment', () {
        final config = EnvironmentConfig.fromEnvironment('unknown', true);

        expect(config.apiUrl, equals('https://api-eu.ahamatic.com'));
        expect(config.portalUrl, equals('https://auth-eu.ahamatic.com'));
      });

      test('should default to production for empty string', () {
        final config = EnvironmentConfig.fromEnvironment('', true);

        expect(config.apiUrl, equals('https://api-eu.ahamatic.com'));
        expect(config.portalUrl, equals('https://auth-eu.ahamatic.com'));
      });

      test('should default to production for null-like string', () {
        final config = EnvironmentConfig.fromEnvironment('null', true);

        expect(config.apiUrl, equals('https://api-eu.ahamatic.com'));
      });

      test('should handle case sensitivity', () {
        // Upper case treated as unknown, defaults to production
        final configUpper = EnvironmentConfig.fromEnvironment('PRODUCTION', true);
        // Lower case recognized as production
        final configLower = EnvironmentConfig.fromEnvironment('production', true);

        // Both should return production URLs (case-sensitive means PRODUCTION is unknown)
        expect(configUpper.apiUrl, equals('https://api-eu.ahamatic.com'));
        expect(configLower.apiUrl, equals('https://api-eu.ahamatic.com'));
      });
    });

    test('direct constructor should set values', () {
      const config = EnvironmentConfig(
        apiUrl: 'https://custom.api.com',
        portalUrl: 'https://custom.portal.com',
      );

      expect(config.apiUrl, equals('https://custom.api.com'));
      expect(config.portalUrl, equals('https://custom.portal.com'));
    });
  });

  group('AhamaticApiException', () {
    test('should format message correctly with status code', () {
      final exception = AhamaticApiException('Test error', statusCode: 404);

      expect(
        exception.toString(),
        equals('AhamaticApiException: Test error (status: 404)'),
      );
    });

    test('should handle null status code', () {
      final exception = AhamaticApiException('Test error');

      expect(
        exception.toString(),
        equals('AhamaticApiException: Test error (status: null)'),
      );
    });

    test('should handle empty message', () {
      final exception = AhamaticApiException('', statusCode: 500);

      expect(
        exception.toString(),
        equals('AhamaticApiException:  (status: 500)'),
      );
    });

    test('should store statusCode correctly', () {
      final exception = AhamaticApiException('Error', statusCode: 401);

      expect(exception.statusCode, equals(401));
    });

    test('should store message correctly', () {
      final exception = AhamaticApiException('Custom error message');

      expect(exception.message, equals('Custom error message'));
    });

    test('should handle various HTTP status codes', () {
      final codes = [200, 201, 301, 400, 401, 403, 404, 500, 502, 503];
      
      for (final code in codes) {
        final exception = AhamaticApiException('Error', statusCode: code);
        expect(exception.statusCode, equals(code));
      }
    });
  });

  group('AppValidationResponse', () {
    test('should create with name and moduleConfig', () {
      const moduleConfig = ModuleAuthConfig(apiKey: 'key');
      const response = AppValidationResponse(
        name: 'App Name',
        moduleConfig: moduleConfig,
      );

      expect(response.name, equals('App Name'));
      expect(response.moduleConfig.apiKey, equals('key'));
    });

    test('should accept empty name', () {
      const response = AppValidationResponse(
        name: '',
        moduleConfig: ModuleAuthConfig(),
      );

      expect(response.name, isEmpty);
    });
  });

  group('OpenIamLoginParams', () {
    test('should create with required fields only', () {
      const params = OpenIamLoginParams(
        applicationCode: 'app',
        portalUrl: 'https://portal.com',
      );

      expect(params.applicationCode, equals('app'));
      expect(params.portalUrl, equals('https://portal.com'));
      expect(params.moduleName, isNull);
      expect(params.moduleWebName, isNull);
      expect(params.hostName, isNull);
      expect(params.authenticationStatus, isNull);
      expect(params.currentWebUrl, isNull);
    });

    test('should create with all fields', () {
      const params = OpenIamLoginParams(
        applicationCode: 'app',
        portalUrl: 'https://portal.com',
        moduleName: 'module',
        moduleWebName: 'webModule',
        hostName: 'host.com',
        authenticationStatus: 'authenticated',
        currentWebUrl: 'https://current.url',
      );

      expect(params.applicationCode, equals('app'));
      expect(params.portalUrl, equals('https://portal.com'));
      expect(params.moduleName, equals('module'));
      expect(params.moduleWebName, equals('webModule'));
      expect(params.hostName, equals('host.com'));
      expect(params.authenticationStatus, equals('authenticated'));
      expect(params.currentWebUrl, equals('https://current.url'));
    });
  });
}
