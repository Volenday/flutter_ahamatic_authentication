import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_ahamatic_authentication/models/app_config.dart';

/// Interface for the Ahamatic API service
abstract class AhamaticApiService {
  /// Validates the application and gets its configuration
  Future<AppValidationResponse> validateApp(String applicationCode);

  /// Gets the configuration for a specific module
  Future<ModuleAuthConfig> getModuleConfig(
    String applicationCode,
    String moduleName,
  );
}

/// Implementation of the Ahamatic API service
class AhamaticApiServiceImpl implements AhamaticApiService {
  final Dio _dio;
  final String apiUrl;

  AhamaticApiServiceImpl({
    required Dio dio,
    required this.apiUrl,
  }) : _dio = dio;

  @override
  Future<AppValidationResponse> validateApp(String applicationCode) async {
    debugPrint('AhamaticApiService: Validating app $applicationCode');

    try {
      final response = await _dio.get(
        '$apiUrl/api/validate/app?value=$applicationCode',
      );

      if (response.statusCode == 200) {
        final jsonData = response.data;
        final name = jsonData['Name'] as String? ?? '';

        debugPrint(
            'AhamaticApiService: App validated successfully. Name: $name');

        return AppValidationResponse(
          name: name,
          moduleConfig: ModuleAuthConfig.empty(),
        );
      } else {
        throw AhamaticApiException(
          'Failed to validate app',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      debugPrint('AhamaticApiService: DioException: ${e.message}');
      throw AhamaticApiException(
        'Network error: ${e.message}',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<ModuleAuthConfig> getModuleConfig(
    String applicationCode,
    String moduleName,
  ) async {
    debugPrint('AhamaticApiService: Getting module config for $moduleName');

    try {
      final response = await _dio.get(
        '$apiUrl/api/validate/app?value=$applicationCode',
      );

      if (response.statusCode == 200) {
        final jsonData = response.data;
        return _parseModuleConfig(jsonData, moduleName);
      } else {
        throw AhamaticApiException(
          'Failed to get module config',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      debugPrint('AhamaticApiService: DioException: ${e.message}');
      throw AhamaticApiException(
        'Network error: ${e.message}',
        statusCode: e.response?.statusCode,
      );
    }
  }

  /// Parses the module configuration from the JSON response
  ModuleAuthConfig _parseModuleConfig(
    Map<String, dynamic> jsonData,
    String moduleName,
  ) {
    try {
      // 1. Extract apiKey from root level APIKey.Key (global for the application)
      String? apiKey;
      if (jsonData['APIKey'] != null && jsonData['APIKey']['Key'] != null) {
        apiKey = jsonData['APIKey']['Key'];
        debugPrint('AhamaticApiService: Found apiKey at APIKey.Key');
      }

      final configurations = jsonData['Configurations'] as List<dynamic>?;
      if (configurations == null) {
        debugPrint('AhamaticApiService: No Configurations found');
        return ModuleAuthConfig(apiKey: apiKey);
      }

      // 2. Get Portal Authentication from root level (fallback)
      Map<String, dynamic>? rootPortalAuth;
      Map<String, dynamic>? rootOpenIamConfig;
      for (var config in configurations) {
        if (config['Key'] == 'Portal Authentication') {
          rootPortalAuth = config['Value'];
        }
        if (config['Key'] == 'OpenIAM') {
          rootOpenIamConfig = config['Value'];
        }
      }

      // 3. Find AuthConfig
      Map<String, dynamic>? authConfig;
      for (var config in configurations) {
        if (config['Key'] == 'AuthConfig') {
          authConfig = config;
          break;
        }
      }

      if (authConfig == null || authConfig['Value'] is! List<dynamic>) {
        debugPrint(
            'AhamaticApiService: No AuthConfig found, using root config');
        return ModuleAuthConfig(
          apiKey: apiKey,
          isCidaasEnabled: rootPortalAuth?['Cidaas'] == true,
          isOpeniamEnabled: rootPortalAuth?['OpenIAmAuth'] == true,
          openIamLogo: rootOpenIamConfig?['logo'],
          openIamTitle: rootOpenIamConfig?['title'],
        );
      }

      final authConfigList = authConfig['Value'] as List<dynamic>;

      // 4. Find specific module config
      Map<String, dynamic>? moduleConfig;
      for (var config in authConfigList) {
        if (config['Module'] == moduleName) {
          moduleConfig = config;
          break;
        }
      }

      // 5. If module not found, use root level config with global apiKey
      if (moduleConfig == null) {
        debugPrint(
            'AhamaticApiService: Module $moduleName not found, using root config');
        return ModuleAuthConfig(
          apiKey: apiKey,
          isCidaasEnabled: rootPortalAuth?['Cidaas'] == true,
          isOpeniamEnabled: rootPortalAuth?['OpenIAmAuth'] == true,
          openIamLogo: rootOpenIamConfig?['logo'],
          openIamTitle: rootOpenIamConfig?['title'],
        );
      }

      debugPrint('AhamaticApiService: Found module $moduleName');

      // 6. Check if module has its own apiKey in Cidaas config (override)
      if (moduleConfig['Cidaas'] != null &&
          moduleConfig['Cidaas']['apiKey'] != null) {
        apiKey = moduleConfig['Cidaas']['apiKey'];
        debugPrint(
            'AhamaticApiService: Using module-specific apiKey from Cidaas');
      }

      // Check if Cidaas is enabled
      final isCidaasEnabled =
          moduleConfig['Portal Authentication']?['Cidaas'] == true;

      // Check if OpenIAM is enabled
      final isOpeniamEnabled =
          moduleConfig['Portal Authentication']?['OpenIAmAuth'] == true;

      // Get OpenIAM configuration
      String? openIamLogo;
      String? openIamTitle;
      if (moduleConfig['OpenIAMConfig'] != null) {
        openIamLogo = moduleConfig['OpenIAMConfig']['logo'];
        openIamTitle = moduleConfig['OpenIAMConfig']['title'];
      }

      // Get HostName
      final hostName = moduleConfig['HostName'] as String?;

      debugPrint('AhamaticApiService: Module config parsed successfully');
      debugPrint('  - ApiKey: ${apiKey != null ? "found" : "not found"}');
      debugPrint('  - Cidaas enabled: $isCidaasEnabled');
      debugPrint('  - OpenIAM enabled: $isOpeniamEnabled');

      return ModuleAuthConfig(
        apiKey: apiKey,
        isCidaasEnabled: isCidaasEnabled,
        isOpeniamEnabled: isOpeniamEnabled,
        openIamLogo: openIamLogo,
        openIamTitle: openIamTitle,
        hostName: hostName,
      );
    } catch (e) {
      debugPrint('AhamaticApiService: Error parsing module config: $e');
      return ModuleAuthConfig.empty();
    }
  }
}

/// Custom exception for Ahamatic API errors
class AhamaticApiException implements Exception {
  final String message;
  final int? statusCode;

  AhamaticApiException(this.message, {this.statusCode});

  @override
  String toString() => 'AhamaticApiException: $message (status: $statusCode)';
}
