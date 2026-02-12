import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/models.dart';
import '../utils/error_handler.dart';

/// Service for handling Ahamatic token operations.
///
/// This service is responsible for:
/// - Logging in to Ahamatic with email credentials
/// - Exchanging Cidaas tokens for Ahamatic tokens
class AhamaticTokenService {
  final Dio _dio;
  final Map<String, String> devAccount;

  AhamaticTokenService(this._dio, this.devAccount);

  /// Logs in to Ahamatic using email credentials.
  ///
  /// [apiKey] - The API key for authentication
  /// [apiUrl] - The base URL of the Ahamatic API
  ///
  /// Returns the authentication token from Ahamatic.
  Future<String> loginEmail(String apiKey, String apiUrl) async {
    debugPrint('AhamaticTokenService: Starting email login...');

    if (apiKey.isEmpty ||
        devAccount['emailAddress']?.isEmpty == true ||
        devAccount['password']?.isEmpty == true) {
      throw ArgumentError(
        'API Key, email address, and password must not be null or empty',
      );
    }

    try {
      debugPrint(
        'AhamaticTokenService: [REQUEST] POST $apiUrl/api/auth/email '
        'with apiKey=${apiKey.isNotEmpty ? "${apiKey.substring(0, apiKey.length > 6 ? 6 : apiKey.length)}..." : "(empty)"} '
        'and email=${devAccount['emailAddress']}',
      );
      final response = await _dio.post(
        '$apiUrl/api/auth/email',
        data: {
          'apiKey': apiKey,
          'emailAddress': devAccount['emailAddress'],
          'password': devAccount['password'],
        },
      );

      if (response.data != null && response.data['token'] != null) {
        debugPrint('AhamaticTokenService: Email login successful');
        return response.data['token'];
      }

      throw PlatformException(
        code: 'invalid_response',
        message: 'No token found in Ahamatic login response',
        details: response.data,
      );
    } catch (e, stack) {
      CidaasErrorHandler.logError(
        e,
        stack,
        'Email login to Ahamatic',
        serviceName: 'AhamaticTokenService',
      );

      if (e is PlatformException) rethrow;

      final userMessage = CidaasErrorHandler.getUserFriendlyMessage(
        e,
        fallbackMessage: 'Failed to authenticate with Ahamatic. Please try again.',
      );
      throw PlatformException(
        code: 'ahamatic_login_error',
        message: userMessage,
        details: null,
        stacktrace: stack.toString(),
      );
    }
  }

  /// Exchanges Cidaas tokens for Ahamatic tokens.
  ///
  /// [accessToken] - The Cidaas access token
  /// [apiUrl] - The base URL of the Ahamatic API
  /// [apiKey] - The API key for authentication
  /// [ahamaticToken] - The token from Ahamatic login
  /// [clientId] - The Cidaas client ID
  /// [redirectUrl] - The redirect URL used in OAuth flow
  /// [issuer] - The Cidaas issuer URL
  ///
  /// Returns an [AhamaticResponse] with the exchanged tokens.
  Future<AhamaticResponse> fetchTokens({
    required String accessToken,
    required String apiUrl,
    required String apiKey,
    required String ahamaticToken,
    required String clientId,
    required String redirectUrl,
    required String issuer,
  }) async {
    debugPrint('AhamaticTokenService: Fetching Ahamatic tokens...');

    if (accessToken.isEmpty ||
        apiKey.isEmpty ||
        ahamaticToken.isEmpty ||
        issuer.isEmpty) {
      throw ArgumentError(
        'Access token, API Key, Ahamatic token and Issuer must not be empty',
      );
    }

    try {
      final response = await _dio.post(
        '$apiUrl/api/auth/cidaas',
        data: {
          'apiKey': apiKey,
          'access_token': accessToken,
          'clientId': clientId,
          'redirectUrl': redirectUrl,
          'issuer': issuer,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $ahamaticToken',
          },
        ),
      );

      debugPrint('AhamaticTokenService: Tokens fetched successfully');

      return AhamaticResponse(
        accessToken: response.data['access_token'],
        refreshToken: response.data['refreshToken'],
        idToken: response.data['token'],
      );
    } catch (e, stack) {
      CidaasErrorHandler.logError(
        e,
        stack,
        'Fetching Ahamatic tokens',
        serviceName: 'AhamaticTokenService',
      );

      final userMessage = CidaasErrorHandler.getUserFriendlyMessage(
        e,
        fallbackMessage: 'Failed to retrieve authentication tokens. Please try again.',
      );
      throw PlatformException(
        code: 'ahamatic_token_error',
        message: userMessage,
        details: null,
        stacktrace: stack.toString(),
      );
    }
  }
}
