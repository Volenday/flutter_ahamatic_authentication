import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_ahamatic_authentication/cidaas/cidaas.dart';
import 'package:flutter_appauth/flutter_appauth.dart';

abstract interface class CidaasAuthApi {
  Future<TokenResponse> signInWithCidaas();
}

class CidaasAuthApiImpl implements CidaasAuthApi {
  final FlutterAppAuth _appAuth;
  final CidaasConfiguration config;

  CidaasAuthApiImpl(this._appAuth, this.config);

  @override
  Future<TokenResponse> signInWithCidaas() async {
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

      if (kDebugMode) {
        debugPrint('CidaasAuthApi: Prepared authorization request.');
      }

      if (kDebugMode) {
        debugPrint('CidaasAuthApi: AuthorizationRequest details:');
        debugPrint('  clientId: ${authRequest.clientId}');
        debugPrint('  redirectUrl: ${authRequest.redirectUrl}');
        debugPrint('  discoveryUrl: ${authRequest.discoveryUrl}');
        debugPrint('  scopes: ${authRequest.scopes}');
        debugPrint('  nonce: ${authRequest.nonce}');
      }

      final AuthorizationResponse authResponse = await _appAuth.authorize(
        authRequest,
      );

      if (kDebugMode) {
        debugPrint('CidaasAuthApi: Authorization Response: $authResponse');
      }

      debugPrint('Authorization Response: $authResponse');

      if (kDebugMode) {
        debugPrint(
            'CidaasAuthApi: Authorization successful. Received auth code.');
        debugPrint(
            'CidaasAuthApi: Authorization Code: ${authResponse.authorizationCode}');
        debugPrint(
            'CidaasAuthApi: Code Verifier: ${authResponse.codeVerifier}');
      }

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
      );

      if (kDebugMode) {
        debugPrint(
            'CidaasAuthApi: Prepared token request. Exchanging authorization code for tokens...');
      }

      final TokenResponse tokenResponse = await _appAuth.token(tokenRequest);

      if (kDebugMode) {
        debugPrint('CidaasAuthApi: TokenResponse details: $tokenResponse');
        debugPrint('  accessToken: ${tokenResponse.accessToken}');
        debugPrint('  refreshToken: ${tokenResponse.refreshToken}');
        debugPrint('  idToken: ${tokenResponse.idToken}');
        debugPrint('  tokenType: ${tokenResponse.tokenType}');
        debugPrint(
            '  expiresIn: ${tokenResponse.accessTokenExpirationDateTime}');
        debugPrint('  scopes: ${tokenResponse.scopes}');
      }

      if (kDebugMode) {
        debugPrint('CidaasAuthApi: Token exchange successful!');
        debugPrint('CidaasAuthApi: Access Token: ${tokenResponse.accessToken}');
        debugPrint(
            'CidaasAuthApi: Refresh Token: ${tokenResponse.refreshToken}');
        debugPrint('CidaasAuthApi: ID Token: ${tokenResponse.idToken}');
      }

      return tokenResponse;
    } on PlatformException catch (e, stack) {
      if (kDebugMode) {
        debugPrint(
            'CidaasAuthApi: PlatformException during sign-in: ${e.code} - ${e.message}');
        debugPrint('CidaasAuthApi: Stack trace: $stack');
      }
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
}
