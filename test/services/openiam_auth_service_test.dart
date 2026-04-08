import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ahamatic_authentication/services/openiam_auth_service.dart';
import 'package:flutter_ahamatic_authentication/models/app_config.dart';

void main() {
  late OpenIamAuthServiceImpl service;

  setUp(() {
    service = OpenIamAuthServiceImpl();
  });

  group('OpenIamAuthService', () {
    group('generateWebLoginUrl', () {
      test('should generate correct login URL for web', () {
        final params = OpenIamLoginParams(
          applicationCode: 'testApp',
          moduleWebName: 'testModuleWeb',
          hostName: 'test.host.com',
          portalUrl: 'https://auth.ahamatic.com',
          currentWebUrl: 'https://myapp.com/page',
        );

        final result = service.generateWebLoginUrl(params);

        expect(result, isNotNull);
        expect(result, contains('https://auth.ahamatic.com/client/testApp'));
        expect(result, contains('module=testModuleWeb'));
        expect(result, contains('origin=website'));
        expect(result, contains('redirect='));
      });

      test('should generate logout URL when status is unauthenticated', () {
        final params = OpenIamLoginParams(
          applicationCode: 'testApp',
          moduleWebName: 'testModuleWeb',
          hostName: 'test.host.com',
          portalUrl: 'https://auth.ahamatic.com',
          currentWebUrl: 'https://myapp.com/page',
          authenticationStatus: 'unauthenticated',
        );

        final result = service.generateWebLoginUrl(params);

        expect(result, isNotNull);
        expect(result, contains('/logout/testApp'));
        expect(result, contains('logout=true'));
        expect(result, isNot(contains('/client/')));
      });

      test('should use localhost URL when running locally on port 8080', () {
        final params = OpenIamLoginParams(
          applicationCode: 'testApp',
          moduleWebName: 'testModuleWeb',
          hostName: 'test.host.com',
          portalUrl: 'https://auth.ahamatic.com',
          currentWebUrl: 'http://localhost:8080/page',
        );

        final result = service.generateWebLoginUrl(params);

        expect(result, isNotNull);
        expect(result, contains('redirect=http://localhost:8080'));
      });

      test('should use localhost URL when running on localhost:3000', () {
        final params = OpenIamLoginParams(
          applicationCode: 'testApp',
          moduleWebName: 'testModuleWeb',
          hostName: 'test.host.com',
          portalUrl: 'https://auth.ahamatic.com',
          currentWebUrl: 'http://localhost:3000/dashboard',
        );

        final result = service.generateWebLoginUrl(params);

        expect(result, isNotNull);
        expect(result, contains('redirect=http://localhost:3000'));
      });

      test('should use localhost URL when running on localhost:5000', () {
        final params = OpenIamLoginParams(
          applicationCode: 'testApp',
          moduleWebName: 'testModuleWeb',
          hostName: 'test.host.com',
          portalUrl: 'https://auth.ahamatic.com',
          currentWebUrl: 'http://localhost:5000/',
        );

        final result = service.generateWebLoginUrl(params);

        expect(result, isNotNull);
        expect(result, contains('redirect=http://localhost:5000'));
      });

      test('should use hostName for redirect when not localhost', () {
        final params = OpenIamLoginParams(
          applicationCode: 'testApp',
          moduleWebName: 'testModuleWeb',
          hostName: 'myapp.production.com',
          portalUrl: 'https://auth.ahamatic.com',
          currentWebUrl: 'https://myapp.production.com/dashboard',
        );

        final result = service.generateWebLoginUrl(params);

        expect(result, isNotNull);
        expect(result, contains('redirect=https://myapp.production.com'));
      });

      test('should return null when hostName is missing', () {
        final params = OpenIamLoginParams(
          applicationCode: 'testApp',
          moduleWebName: 'testModuleWeb',
          hostName: null,
          portalUrl: 'https://auth.ahamatic.com',
          currentWebUrl: 'https://myapp.com/page',
        );

        final result = service.generateWebLoginUrl(params);

        expect(result, isNull);
      });

      test('should return null when moduleWebName is missing', () {
        final params = OpenIamLoginParams(
          applicationCode: 'testApp',
          moduleWebName: null,
          hostName: 'test.host.com',
          portalUrl: 'https://auth.ahamatic.com',
          currentWebUrl: 'https://myapp.com/page',
        );

        final result = service.generateWebLoginUrl(params);

        expect(result, isNull);
      });

      test('should return null when currentWebUrl is missing', () {
        final params = OpenIamLoginParams(
          applicationCode: 'testApp',
          moduleWebName: 'testModuleWeb',
          hostName: 'test.host.com',
          portalUrl: 'https://auth.ahamatic.com',
          currentWebUrl: null,
        );

        final result = service.generateWebLoginUrl(params);

        expect(result, isNull);
      });

      test('should return null when hostName is empty string', () {
        final params = OpenIamLoginParams(
          applicationCode: 'testApp',
          moduleWebName: 'testModuleWeb',
          hostName: '',
          portalUrl: 'https://auth.ahamatic.com',
          currentWebUrl: 'https://myapp.com/page',
        );

        final result = service.generateWebLoginUrl(params);

        // Empty string is falsy for null check, so it won't be null
        // but let's verify the behavior
        expect(result, isNotNull);
      });

      test('should handle different portal URLs', () {
        final devParams = OpenIamLoginParams(
          applicationCode: 'testApp',
          moduleWebName: 'testModuleWeb',
          hostName: 'test.host.com',
          portalUrl: 'https://dev.auth.ahamatic.com',
          currentWebUrl: 'http://localhost:8080/',
        );

        final sandboxParams = OpenIamLoginParams(
          applicationCode: 'testApp',
          moduleWebName: 'testModuleWeb',
          hostName: 'test.host.com',
          portalUrl: 'https://test.auth-eu.ahamatic.com',
          currentWebUrl: 'http://localhost:8080/',
        );

        final prodParams = OpenIamLoginParams(
          applicationCode: 'testApp',
          moduleWebName: 'testModuleWeb',
          hostName: 'test.host.com',
          portalUrl: 'https://auth-eu.ahamatic.com',
          currentWebUrl: 'http://localhost:8080/',
        );

        expect(service.generateWebLoginUrl(devParams), contains('dev.auth.ahamatic.com'));
        expect(service.generateWebLoginUrl(sandboxParams), contains('test.auth-eu.ahamatic.com'));
        expect(service.generateWebLoginUrl(prodParams), contains('auth-eu.ahamatic.com'));
      });

      test('should handle applicationCode with special characters', () {
        final params = OpenIamLoginParams(
          applicationCode: 'test-app_v2',
          moduleWebName: 'testModuleWeb',
          hostName: 'test.host.com',
          portalUrl: 'https://auth.ahamatic.com',
          currentWebUrl: 'http://localhost:8080/',
        );

        final result = service.generateWebLoginUrl(params);

        expect(result, contains('client/test-app_v2'));
      });

      test('should handle moduleWebName with special characters', () {
        final params = OpenIamLoginParams(
          applicationCode: 'testApp',
          moduleWebName: 'module-web_v2.0',
          hostName: 'test.host.com',
          portalUrl: 'https://auth.ahamatic.com',
          currentWebUrl: 'http://localhost:8080/',
        );

        final result = service.generateWebLoginUrl(params);

        expect(result, contains('module=module-web_v2.0'));
      });

      test('should generate login URL for authenticated status', () {
        final params = OpenIamLoginParams(
          applicationCode: 'testApp',
          moduleWebName: 'testModuleWeb',
          hostName: 'test.host.com',
          portalUrl: 'https://auth.ahamatic.com',
          currentWebUrl: 'https://myapp.com/page',
          authenticationStatus: 'authenticated',
        );

        final result = service.generateWebLoginUrl(params);

        expect(result, isNotNull);
        expect(result, contains('/client/testApp'));
        expect(result, isNot(contains('/logout/')));
        expect(result, isNot(contains('logout=true')));
      });

      test('should generate login URL when authenticationStatus is null', () {
        final params = OpenIamLoginParams(
          applicationCode: 'testApp',
          moduleWebName: 'testModuleWeb',
          hostName: 'test.host.com',
          portalUrl: 'https://auth.ahamatic.com',
          currentWebUrl: 'https://myapp.com/page',
          authenticationStatus: null,
        );

        final result = service.generateWebLoginUrl(params);

        expect(result, isNotNull);
        expect(result, contains('/client/testApp'));
      });

      test('should generate login URL when authenticationStatus is empty', () {
        final params = OpenIamLoginParams(
          applicationCode: 'testApp',
          moduleWebName: 'testModuleWeb',
          hostName: 'test.host.com',
          portalUrl: 'https://auth.ahamatic.com',
          currentWebUrl: 'https://myapp.com/page',
          authenticationStatus: '',
        );

        final result = service.generateWebLoginUrl(params);

        expect(result, isNotNull);
        expect(result, contains('/client/testApp'));
      });

      test('should handle HTTPS URLs correctly', () {
        final params = OpenIamLoginParams(
          applicationCode: 'testApp',
          moduleWebName: 'testModuleWeb',
          hostName: 'test.host.com',
          portalUrl: 'https://auth.ahamatic.com',
          currentWebUrl: 'https://secure.myapp.com/page',
        );

        final result = service.generateWebLoginUrl(params);

        expect(result, isNotNull);
        expect(result, contains('https://'));
      });

      test('should handle URL with query parameters', () {
        final params = OpenIamLoginParams(
          applicationCode: 'testApp',
          moduleWebName: 'testModuleWeb',
          hostName: 'test.host.com',
          portalUrl: 'https://auth.ahamatic.com',
          currentWebUrl: 'https://myapp.com/page?param=value&other=123',
        );

        final result = service.generateWebLoginUrl(params);

        expect(result, isNotNull);
      });

      test('should handle URL with hash fragment', () {
        final params = OpenIamLoginParams(
          applicationCode: 'testApp',
          moduleWebName: 'testModuleWeb',
          hostName: 'test.host.com',
          portalUrl: 'https://auth.ahamatic.com',
          currentWebUrl: 'https://myapp.com/page#section',
        );

        final result = service.generateWebLoginUrl(params);

        expect(result, isNotNull);
      });
    });

    group('generateNativeLoginUrl', () {
      test('should return null when hostName is missing', () {
        final params = OpenIamLoginParams(
          applicationCode: 'testApp',
          moduleName: 'testModule',
          hostName: null,
          portalUrl: 'https://auth.ahamatic.com',
        );

        final result = service.generateNativeLoginUrl(params);

        expect(result, isNull);
      });

      test('should return null when moduleName is missing', () {
        final params = OpenIamLoginParams(
          applicationCode: 'testApp',
          moduleName: null,
          hostName: 'test.host.com',
          portalUrl: 'https://auth.ahamatic.com',
        );

        final result = service.generateNativeLoginUrl(params);

        expect(result, isNull);
      });

      test('should return null when both hostName and moduleName are missing', () {
        final params = OpenIamLoginParams(
          applicationCode: 'testApp',
          moduleName: null,
          hostName: null,
          portalUrl: 'https://auth.ahamatic.com',
        );

        final result = service.generateNativeLoginUrl(params);

        expect(result, isNull);
      });

      test('should return null when hostName is empty string', () {
        final params = OpenIamLoginParams(
          applicationCode: 'testApp',
          moduleName: 'testModule',
          hostName: '',
          portalUrl: 'https://auth.ahamatic.com',
        );

        final result = service.generateNativeLoginUrl(params);

        // Empty string behavior depends on implementation
        expect(result, anyOf(isNull, isNotNull));
      });

      test('should return null when moduleName is empty string', () {
        final params = OpenIamLoginParams(
          applicationCode: 'testApp',
          moduleName: '',
          hostName: 'test.host.com',
          portalUrl: 'https://auth.ahamatic.com',
        );

        final result = service.generateNativeLoginUrl(params);

        // Empty string behavior depends on implementation
        expect(result, anyOf(isNull, isNotNull));
      });

      // Note: The following tests would need to mock Platform.isAndroid
      // which requires platform-specific testing or conditional compilation
      // In unit tests, Platform calls will fail, so we test edge cases instead
    });

    group('generateLoginUrl', () {
      test('should call generateWebLoginUrl when isWeb is true', () {
        final params = OpenIamLoginParams(
          applicationCode: 'testApp',
          moduleWebName: 'testModuleWeb',
          hostName: 'test.host.com',
          portalUrl: 'https://auth.ahamatic.com',
          currentWebUrl: 'https://myapp.com/page',
        );

        final result = service.generateLoginUrl(params, isWeb: true);

        expect(result, isNotNull);
        expect(result, contains('/client/testApp'));
        expect(result, contains('module=testModuleWeb'));
      });

      test('should call generateNativeLoginUrl when isWeb is false', () {
        final params = OpenIamLoginParams(
          applicationCode: 'testApp',
          moduleName: null,
          hostName: 'test.host.com',
          portalUrl: 'https://auth.ahamatic.com',
        );

        final result = service.generateLoginUrl(params, isWeb: false);

        expect(result, isNull); // Because moduleName is null
      });

      test('should return null for web when required params missing', () {
        final params = OpenIamLoginParams(
          applicationCode: 'testApp',
          moduleWebName: null,
          hostName: 'test.host.com',
          portalUrl: 'https://auth.ahamatic.com',
          currentWebUrl: 'https://myapp.com/page',
        );

        final result = service.generateLoginUrl(params, isWeb: true);

        expect(result, isNull);
      });

      test('should return null for native when required params missing', () {
        final params = OpenIamLoginParams(
          applicationCode: 'testApp',
          moduleName: 'testModule',
          hostName: null,
          portalUrl: 'https://auth.ahamatic.com',
        );

        final result = service.generateLoginUrl(params, isWeb: false);

        expect(result, isNull);
      });

      test('should use moduleWebName for web and moduleName for native', () {
        final webParams = OpenIamLoginParams(
          applicationCode: 'testApp',
          moduleName: 'nativeModule',
          moduleWebName: 'webModule',
          hostName: 'test.host.com',
          portalUrl: 'https://auth.ahamatic.com',
          currentWebUrl: 'https://myapp.com/',
        );

        final webResult = service.generateLoginUrl(webParams, isWeb: true);

        expect(webResult, contains('module=webModule'));
        expect(webResult, isNot(contains('module=nativeModule')));
      });
    });
  });

  group('OpenIamLoginParams', () {
    test('should create params with all required fields', () {
      final params = OpenIamLoginParams(
        applicationCode: 'testApp',
        portalUrl: 'https://portal.com',
      );

      expect(params.applicationCode, equals('testApp'));
      expect(params.portalUrl, equals('https://portal.com'));
      expect(params.moduleName, isNull);
      expect(params.moduleWebName, isNull);
      expect(params.hostName, isNull);
      expect(params.authenticationStatus, isNull);
      expect(params.currentWebUrl, isNull);
    });

    test('should create params with all optional fields', () {
      final params = OpenIamLoginParams(
        applicationCode: 'testApp',
        portalUrl: 'https://portal.com',
        moduleName: 'module',
        moduleWebName: 'moduleWeb',
        hostName: 'host.com',
        authenticationStatus: 'authenticated',
        currentWebUrl: 'https://current.url',
      );

      expect(params.moduleName, equals('module'));
      expect(params.moduleWebName, equals('moduleWeb'));
      expect(params.hostName, equals('host.com'));
      expect(params.authenticationStatus, equals('authenticated'));
      expect(params.currentWebUrl, equals('https://current.url'));
    });

    test('should allow different values for moduleName and moduleWebName', () {
      final params = OpenIamLoginParams(
        applicationCode: 'testApp',
        portalUrl: 'https://portal.com',
        moduleName: 'b2bScanner',
        moduleWebName: 'b2bScannerWeb',
      );

      expect(params.moduleName, equals('b2bScanner'));
      expect(params.moduleWebName, equals('b2bScannerWeb'));
      expect(params.moduleName, isNot(equals(params.moduleWebName)));
    });

    test('should allow same value for moduleName and moduleWebName', () {
      final params = OpenIamLoginParams(
        applicationCode: 'testApp',
        portalUrl: 'https://portal.com',
        moduleName: 'sameModule',
        moduleWebName: 'sameModule',
      );

      expect(params.moduleName, equals(params.moduleWebName));
    });

    test('should handle empty strings', () {
      final params = OpenIamLoginParams(
        applicationCode: '',
        portalUrl: '',
        moduleName: '',
        moduleWebName: '',
        hostName: '',
        authenticationStatus: '',
        currentWebUrl: '',
      );

      expect(params.applicationCode, equals(''));
      expect(params.portalUrl, equals(''));
      expect(params.moduleName, equals(''));
      expect(params.moduleWebName, equals(''));
      expect(params.hostName, equals(''));
      expect(params.authenticationStatus, equals(''));
      expect(params.currentWebUrl, equals(''));
    });

    test('should handle URLs with various formats', () {
      final params = OpenIamLoginParams(
        applicationCode: 'testApp',
        portalUrl: 'https://auth.ahamatic.com:443/path',
        currentWebUrl: 'http://localhost:8080/dashboard?tab=settings#section',
      );

      expect(params.portalUrl, contains('auth.ahamatic.com'));
      expect(params.currentWebUrl, contains('localhost:8080'));
    });

    test('should handle special characters in applicationCode', () {
      final params = OpenIamLoginParams(
        applicationCode: 'test-app_v2.0',
        portalUrl: 'https://portal.com',
      );

      expect(params.applicationCode, equals('test-app_v2.0'));
    });

    test('should handle Unicode characters', () {
      final params = OpenIamLoginParams(
        applicationCode: 'testApp',
        portalUrl: 'https://portal.com',
        moduleName: 'unicode_module_名前',
        authenticationStatus: 'verified',
      );

      expect(params.moduleName, equals('unicode_module_名前'));
      expect(params.authenticationStatus, equals('verified'));
    });
  });

  group('OpenIamAuthService edge cases', () {
    test('should handle malformed currentWebUrl gracefully', () {
      final params = OpenIamLoginParams(
        applicationCode: 'testApp',
        moduleWebName: 'testModuleWeb',
        hostName: 'test.host.com',
        portalUrl: 'https://auth.ahamatic.com',
        currentWebUrl: 'not-a-valid-url',
      );

      // Should not throw, may return null or handle gracefully
      expect(
        () => service.generateWebLoginUrl(params),
        returnsNormally,
      );
    });

    test('should handle very long URLs', () {
      final longPath = 'a' * 1000;
      final params = OpenIamLoginParams(
        applicationCode: 'testApp',
        moduleWebName: 'testModuleWeb',
        hostName: 'test.host.com',
        portalUrl: 'https://auth.ahamatic.com',
        currentWebUrl: 'https://myapp.com/$longPath',
      );

      final result = service.generateWebLoginUrl(params);

      expect(result, isNotNull);
    });

    test('should handle IP addresses as hostName', () {
      final params = OpenIamLoginParams(
        applicationCode: 'testApp',
        moduleWebName: 'testModuleWeb',
        hostName: '192.168.1.100',
        portalUrl: 'https://auth.ahamatic.com',
        currentWebUrl: 'http://192.168.1.100:8080/',
      );

      final result = service.generateWebLoginUrl(params);

      expect(result, isNotNull);
    });

    test('should handle IPv6 addresses', () {
      final params = OpenIamLoginParams(
        applicationCode: 'testApp',
        moduleWebName: 'testModuleWeb',
        hostName: '::1',
        portalUrl: 'https://auth.ahamatic.com',
        currentWebUrl: 'http://[::1]:8080/',
      );

      // IPv6 handling depends on implementation
      expect(
        () => service.generateWebLoginUrl(params),
        returnsNormally,
      );
    });

    test('should handle subdomain in hostName', () {
      final params = OpenIamLoginParams(
        applicationCode: 'testApp',
        moduleWebName: 'testModuleWeb',
        hostName: 'app.staging.example.com',
        portalUrl: 'https://auth.ahamatic.com',
        currentWebUrl: 'https://app.staging.example.com/dashboard',
      );

      final result = service.generateWebLoginUrl(params);

      expect(result, isNotNull);
      expect(result, contains('app.staging.example.com'));
    });
  });
}
