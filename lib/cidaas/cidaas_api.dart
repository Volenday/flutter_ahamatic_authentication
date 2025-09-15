import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:flutter_ahamatic_authentication/cidaas/cidaas_entity.dart';

abstract interface class CidaasAuthApi {
  Future<TokenResponse> signInWithCidaas(String apikey, String apiUrl);
}

class CidaasAuthApiImpl implements CidaasAuthApi {
  final FlutterAppAuth _appAuth;
  final CidaasConfiguration config;
  final Dio _dio;

  CidaasAuthApiImpl(
    this._dio,
    this._appAuth,
    this.config,
  );

  @override
  Future<TokenResponse> signInWithCidaas(
    String apikey,
    String apiUrl,
  ) async {
    if (kDebugMode) {
      debugPrint('CidaasAuthApi: Starting sign-in process...');
      debugPrint('CidaasAuthApi: Client ID: ${config.clientId}');
      debugPrint('CidaasAuthApi: Redirect URI: ${config.redirectUri}');
      debugPrint('CidaasAuthApi: Discovery URL: ${config.discoveryUrl}');
      debugPrint('CidaasAuthApi: Scopes: ${config.scopes.join(", ")}');
    }

    final List<String> cidaasScopes = config.scopes.isNotEmpty
        ? config.scopes
        : ['openid', 'profile', 'email'];

    try {
      // 1. Authorization Request
      final AuthorizationRequest authRequest = AuthorizationRequest(
        config.clientId,
        config.redirectUri,
        discoveryUrl: config.discoveryUrl,
        scopes: cidaasScopes,
        nonce: null,
      );

      debugPrint('CidaasAuthApi: Prepared authorization request.');

      final AuthorizationResponse authResponse = await _appAuth.authorize(
        authRequest,
      );

      debugPrint('CidaasAuthApi: Authorization Response');

      debugPrint(
          'CidaasAuthApi: Authorization successful. Received auth code.');

      // 2. Token Exchange Request
      final TokenRequest tokenRequest = TokenRequest(
        config.clientId,
        config.redirectUri,
        discoveryUrl: config.discoveryUrl,
        scopes: config.scopes,
        authorizationCode: authResponse.authorizationCode,
        codeVerifier: authResponse.codeVerifier,
        nonce: authResponse.nonce,
        allowInsecureConnections: true,
        additionalParameters: {
          'code_challenge_method': 'S256',
        },
      );

      debugPrint(
          'CidaasAuthApi: Prepared token request. Exchanging authorization code for tokens...');

      final TokenResponse tokenResponse = await _appAuth.token(tokenRequest);

      debugPrint('CidaasAuthApi: TokenResponse details');

      debugPrint('CidaasAuthApi: Token exchange successful!');

      debugPrint('CidaasAuthApi: Starting Ahamatic token fetch...');

      final ahamaticResponse =
          await fetchAhamaticTokens(tokenResponse.accessToken!, apiUrl, apikey);
      return tokenResponse;
    } on PlatformException catch (e, stack) {
      debugPrint(
          'CidaasAuthApi: PlatformException during sign-in: ${e.code} - ${e.message}');
      debugPrint('CidaasAuthApi: Stack trace: $stack');
      // Manejo específico para cancelación por el usuario
      if (e.code == 'authorize_failed' &&
          (e.details?.toString().contains('User cancelled flow') ?? false)) {
        throw PlatformException(
          code: e.code,
          message: 'User cancelled the authentication flow.',
          details: e.details,
        );
      }
      throw PlatformException(
        code: e.code,
        message: 'Platform authentication error: ${e.message}',
        details: e.details,
        stacktrace: stack.toString(),
      );
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint(
            'CidaasAuthApi: An unexpected error occurred during sign in: $e');
        debugPrint('CidaasAuthApi: Stack trace: $stack');
      }
      throw PlatformException(
        code: 'unexpected_error',
        message: 'An unexpected error occurred during sign in: $e',
        details: null,
        stacktrace: stack.toString(),
      );
    }
  }

  // Necesitamos hacer una llamada a ahamatic para validar la información y enviar los nuevos tokens al cliente
  Future<AhamaticResponse> fetchAhamaticTokens(
    String accessToken,
    String apiUrl,
    String apiKey,
  ) async {
    debugPrint('CidaasAuthApi: Fetching Ahamatic tokens...');
    debugPrint('CidaasAuthApi: Access Token: $accessToken');
    debugPrint('CidaasAuthApi: API URL: $apiUrl');
    debugPrint('CidaasAuthApi: API Key: $apiKey');

    if (accessToken.isEmpty || apiUrl.isEmpty || apiKey.isEmpty) {
      throw ArgumentError(
          'Access token, API URL, and API Key must not be null or empty');
    }

    try {
      final response = await _dio.post(
        '$apiUrl/api/auth/cidaas',
        data: {
          'apiKey': apiKey,
          'access_token': accessToken,
          'clientId': config.clientId,
          'redirectUrl': 'test',
        },
      );
      debugPrint('CidaasAuthApi: Ahamatic token response: ${response.data}');
      return AhamaticResponse(
        accessToken: response.data['access_token'],
        refreshToken: response.data['refresh_token'],
        idToken: response.data['id_token'],
      );
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint('CidaasAuthApi: Error fetching Ahamatic tokens: $e');
        debugPrint('CidaasAuthApi: Stack trace: $stack');
      }
      throw PlatformException(
        code: 'ahamatic_token_error',
        message: 'Error fetching Ahamatic tokens: $e',
        details: null,
        stacktrace: stack.toString(),
      );
    }
  }
}
