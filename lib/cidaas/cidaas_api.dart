import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_ahamatic_authentication/cidaas/cidaas_entity.dart';
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
      );

      debugPrint(
          'CidaasAuthApi: Prepared token request. Exchanging authorization code for tokens...');

      final TokenResponse tokenResponse = await _appAuth.token(tokenRequest);

      debugPrint('CidaasAuthApi: TokenResponse details');

      debugPrint('CidaasAuthApi: Token exchange successful!');

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
}
