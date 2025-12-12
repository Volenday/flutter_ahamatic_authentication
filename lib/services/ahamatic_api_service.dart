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
      final configurations = jsonData['Configurations'] as List<dynamic>?;
      if (configurations == null) {
        return ModuleAuthConfig.empty();
      }

      Map<String, dynamic>? authConfig;
      for (var config in configurations) {
        if (config['Key'] == 'AuthConfig') {
          authConfig = config;
          break;
        }
      }

      if (authConfig == null || authConfig['Value'] is! List<dynamic>) {
        return ModuleAuthConfig.empty();
      }

      final authConfigList = authConfig['Value'] as List<dynamic>;
      Map<String, dynamic>? moduleConfig;

      for (var config in authConfigList) {
        if (config['Module'] == moduleName) {
          moduleConfig = config;
          break;
        }
      }

      if (moduleConfig == null) {
        debugPrint('AhamaticApiService: Module $moduleName not found');
        return ModuleAuthConfig.empty();
      }

      // Extract apiKey from Cidaas
      String? apiKey;
      if (moduleConfig['Cidaas'] != null &&
          moduleConfig['Cidaas']['apiKey'] != null) {
        apiKey = moduleConfig['Cidaas']['apiKey'];
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
      if (isOpeniamEnabled && moduleConfig['OpenIAMConfig'] != null) {
        openIamLogo = moduleConfig['OpenIAMConfig']['logo'];
        openIamTitle = moduleConfig['OpenIAMConfig']['title'];
      }

      // Get HostName
      final hostName = moduleConfig['HostName'] as String?;

      debugPrint('AhamaticApiService: Module config parsed successfully');
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
