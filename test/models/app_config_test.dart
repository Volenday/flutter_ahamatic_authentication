import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ahamatic_authentication/models/app_config.dart';

void main() {
  group('EnvironmentConfig', () {
    group('fromEnvironment', () {
      test('development + europe should return correct URLs', () {
        final config = EnvironmentConfig.fromEnvironment('development', true);
        
        expect(config.apiUrl, equals('https://dev.api.ahamatic.com'));
        expect(config.portalUrl, equals('https://dev.auth-eu.ahamatic.com'));
      });

      test('development + non-europe should return correct URLs', () {
        final config = EnvironmentConfig.fromEnvironment('development', false);
        
        expect(config.apiUrl, equals('https://dev.api.ahamatic.com'));
        expect(config.portalUrl, equals('https://dev.auth.ahamatic.com'));
      });

      test('sandbox + europe should return correct URLs', () {
        final config = EnvironmentConfig.fromEnvironment('sandbox', true);
        
        expect(config.apiUrl, equals('https://test.api.ahamatic.com'));
        expect(config.portalUrl, equals('https://test.auth-eu.ahamatic.com'));
      });

      test('sandbox + non-europe should return correct URLs', () {
        final config = EnvironmentConfig.fromEnvironment('sandbox', false);
        
        expect(config.apiUrl, equals('https://test.api.ahamatic.com'));
        expect(config.portalUrl, equals('https://test.auth.ahamatic.com'));
      });

      test('production + europe should return correct URLs', () {
        final config = EnvironmentConfig.fromEnvironment('production', true);
        
        expect(config.apiUrl, equals('https://api-eu.ahamatic.com'));
        expect(config.portalUrl, equals('https://auth-eu.ahamatic.com'));
      });

      test('production + non-europe should return correct URLs', () {
        final config = EnvironmentConfig.fromEnvironment('production', false);
        
        expect(config.apiUrl, equals('https://api-eu.ahamatic.com'));
        expect(config.portalUrl, equals('https://auth.ahamatic.com'));
      });

      test('unknown environment should default to production', () {
        final config = EnvironmentConfig.fromEnvironment('unknown', true);
        
        expect(config.apiUrl, equals('https://api-eu.ahamatic.com'));
        expect(config.portalUrl, equals('https://auth-eu.ahamatic.com'));
      });

      test('empty environment should default to production', () {
        final config = EnvironmentConfig.fromEnvironment('', true);
        
        expect(config.apiUrl, equals('https://api-eu.ahamatic.com'));
        expect(config.portalUrl, equals('https://auth-eu.ahamatic.com'));
      });
    });

    test('direct constructor should set values', () {
      final config = EnvironmentConfig(
        apiUrl: 'https://custom.api.com',
        portalUrl: 'https://custom.portal.com',
      );
      
      expect(config.apiUrl, equals('https://custom.api.com'));
      expect(config.portalUrl, equals('https://custom.portal.com'));
    });
  });

  group('ModuleAuthConfig', () {
    test('empty() should return all defaults', () {
      final config = ModuleAuthConfig.empty();
      
      expect(config.apiKey, isNull);
      expect(config.isCidaasEnabled, isFalse);
      expect(config.isOpeniamEnabled, isFalse);
      expect(config.openIamLogo, isNull);
      expect(config.openIamTitle, isNull);
      expect(config.hostName, isNull);
    });

    test('should create with all parameters', () {
      final config = ModuleAuthConfig(
        apiKey: 'test-api-key',
        isCidaasEnabled: true,
        isOpeniamEnabled: true,
        openIamLogo: 'https://logo.url',
        openIamTitle: 'Test Title',
        hostName: 'test.host.com',
      );
      
      expect(config.apiKey, equals('test-api-key'));
      expect(config.isCidaasEnabled, isTrue);
      expect(config.isOpeniamEnabled, isTrue);
      expect(config.openIamLogo, equals('https://logo.url'));
      expect(config.openIamTitle, equals('Test Title'));
      expect(config.hostName, equals('test.host.com'));
    });

    test('should have default values for boolean fields', () {
      const config = ModuleAuthConfig(apiKey: 'key');
      
      expect(config.isCidaasEnabled, isFalse);
      expect(config.isOpeniamEnabled, isFalse);
    });
  });

  group('AppValidationResponse', () {
    test('should create with required parameters', () {
      final response = AppValidationResponse(
        name: 'Test App',
        moduleConfig: ModuleAuthConfig.empty(),
      );
      
      expect(response.name, equals('Test App'));
      expect(response.moduleConfig.isCidaasEnabled, isFalse);
    });

    test('should preserve module config', () {
      final moduleConfig = ModuleAuthConfig(
        apiKey: 'key',
        isCidaasEnabled: true,
      );
      
      final response = AppValidationResponse(
        name: 'Test App',
        moduleConfig: moduleConfig,
      );
      
      expect(response.moduleConfig.apiKey, equals('key'));
      expect(response.moduleConfig.isCidaasEnabled, isTrue);
    });
  });

  group('OpenIamLoginParams', () {
    test('should create with required parameters only', () {
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

    test('should create with all parameters', () {
      final params = OpenIamLoginParams(
        applicationCode: 'testApp',
        portalUrl: 'https://portal.com',
        moduleName: 'nativeModule',
        moduleWebName: 'webModule',
        hostName: 'host.com',
        authenticationStatus: 'authenticated',
        currentWebUrl: 'https://current.url/page',
      );
      
      expect(params.applicationCode, equals('testApp'));
      expect(params.portalUrl, equals('https://portal.com'));
      expect(params.moduleName, equals('nativeModule'));
      expect(params.moduleWebName, equals('webModule'));
      expect(params.hostName, equals('host.com'));
      expect(params.authenticationStatus, equals('authenticated'));
      expect(params.currentWebUrl, equals('https://current.url/page'));
    });

    test('should allow different module names for native and web', () {
      final params = OpenIamLoginParams(
        applicationCode: 'app',
        portalUrl: 'https://portal.com',
        moduleName: 'b2bScanner',
        moduleWebName: 'b2bScannerWeb',
      );
      
      expect(params.moduleName, equals('b2bScanner'));
      expect(params.moduleWebName, equals('b2bScannerWeb'));
      expect(params.moduleName, isNot(equals(params.moduleWebName)));
    });
  });
}

