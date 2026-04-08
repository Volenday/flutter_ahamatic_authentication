import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

/// Interface for the authentication logging service
abstract class AuthLoggingService {
  /// Logs a login event
  Future<void> logLoginEvent({
    required String token,
    required String loginUrl,
    required String? moduleName,
    required String? appVersion,
  });
}

/// Implementation of the authentication logging service
class AuthLoggingServiceImpl implements AuthLoggingService {
  final Dio _dio;
  final String apiUrl;
  final DeviceInfoPlugin _deviceInfo;

  AuthLoggingServiceImpl({
    required Dio dio,
    required this.apiUrl,
    DeviceInfoPlugin? deviceInfo,
  })  : _dio = dio,
        _deviceInfo = deviceInfo ?? DeviceInfoPlugin();

  @override
  Future<void> logLoginEvent({
    required String token,
    required String loginUrl,
    required String? moduleName,
    required String? appVersion,
  }) async {
    debugPrint('AuthLoggingService: Logging login event');

    if (token.isEmpty) {
      debugPrint('AuthLoggingService: Token is empty, skipping log');
      return;
    }

    try {
      final deviceModel = await _getDeviceModel();
      final personId = _extractPersonId(token);

      if (personId == null) {
        debugPrint('AuthLoggingService: Could not extract PersonId from token');
        return;
      }

      _dio.options.headers['authorization'] = token;

      final params = {
        'Action': 'Abena Id Login Button Tapped',
        'Description': 'User logged in via $loginUrl',
        'Person': personId,
        'Entity': moduleName,
        'AppVersion': appVersion,
        'Device': deviceModel,
      };

      final response = await _dio.post(
        '$apiUrl/api/e/_logs',
        data: params,
      );

      if (response.statusCode == 200) {
        debugPrint('AuthLoggingService: Log sent successfully');
      } else {
        debugPrint(
            'AuthLoggingService: Failed to send log: ${response.statusCode}');
      }
    } on DioException catch (e) {
      debugPrint('AuthLoggingService: DioException: ${e.message}');
    } catch (e) {
      debugPrint('AuthLoggingService: Error logging event: $e');
    }
  }

  /// Gets the device model
  Future<String> _getDeviceModel() async {
    if (kIsWeb) {
      return 'Web Browser';
    }

    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        return androidInfo.model;
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        return iosInfo.model;
      }
    } catch (e) {
      debugPrint('AuthLoggingService: Error getting device info: $e');
    }

    return 'Unknown';
  }

  /// Extracts the PersonId from the JWT token
  int? _extractPersonId(String token) {
    try {
      final decoded = JwtDecoder.decode(token);
      return decoded['account']?['PersonId'] as int?;
    } catch (e) {
      debugPrint('AuthLoggingService: Error decoding token: $e');
      return null;
    }
  }
}
