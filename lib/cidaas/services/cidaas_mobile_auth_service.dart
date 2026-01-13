import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_appauth/flutter_appauth.dart';

import '../models/models.dart';
import '../utils/error_handler.dart';
import 'cidaas_auth_api.dart';
import 'ahamatic_token_service.dart';

/// Mobile implementation of Cidaas authentication using flutter_appauth.
///
/// This implementation uses the native OAuth2 flow with PKCE
/// through the flutter_appauth library.
class CidaasMobileAuthService implements CidaasAuthApi {
  final FlutterAppAuth _appAuth;
  final CidaasConfiguration config;
  final Dio _dio;
  final Map<String, String> devAccount;
  late final AhamaticTokenService _ahamaticService;

  CidaasMobileAuthService(
    this._dio,
    this._appAuth,
    this.config,
    this.devAccount,
  ) {
    _ahamaticService = AhamaticTokenService(_dio, devAccount);
  }

  @override
  Future<TokenResponse> signInWithCidaas(
    String apiKey,
    String? apiUrl,
  ) async {
    debugPrint('CidaasMobileAuthService: Starting sign-in process...');

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

      debugPrint('CidaasMobileAuthService: Sending authorization request...');

      final AuthorizationResponse authResponse = await _appAuth.authorize(
        authRequest,
      );

      debugPrint('CidaasMobileAuthService: Authorization successful');

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

      debugPrint('CidaasMobileAuthService: Exchanging authorization code...');

      final TokenResponse tokenResponse = await _appAuth.token(tokenRequest);

      debugPrint('CidaasMobileAuthService: Token exchange successful');

      // 3. Login to Ahamatic
      debugPrint('CidaasMobileAuthService: Logging in to Ahamatic...');
      final ahamaticLoginResponse = await _ahamaticService.loginEmail(
        apiKey,
        apiUrl!,
      );

      debugPrint('CidaasMobileAuthService: Ahamatic login successful');

      // 4. Exchange tokens with Ahamatic
      debugPrint('CidaasMobileAuthService: Fetching Ahamatic tokens...');
      final ahamaticResponse = await _ahamaticService.fetchTokens(
        accessToken: tokenResponse.accessToken!,
        apiUrl: apiUrl,
        apiKey: apiKey,
        ahamaticToken: ahamaticLoginResponse,
        clientId: config.clientId,
        redirectUrl: config.redirectUri,
        issuer: config.issuer,
      );

      debugPrint('CidaasMobileAuthService: Sign-in completed successfully');

      return TokenResponse(
        ahamaticResponse.accessToken,
        ahamaticResponse.refreshToken,
        null, // accessTokenExpirationDateTime
        ahamaticResponse.idToken,
        null, // tokenType
        null, // scopes
        null, // tokenAdditionalParameters
      );
    } on PlatformException catch (e, stack) {
      CidaasErrorHandler.logError(
        e,
        stack,
        'Sign-in with Cidaas (PlatformException)',
        serviceName: 'CidaasMobileAuthService',
      );

      // Specific handling for user cancellation
      if (e.code == 'authorize_failed' &&
          (e.details?.toString().contains('User cancelled flow') ?? false)) {
        throw PlatformException(
          code: e.code,
          message: 'User cancelled the authentication flow.',
          details: e.details,
        );
      }

      final userMessage = CidaasErrorHandler.getUserFriendlyMessage(e);
      throw PlatformException(
        code: e.code,
        message: userMessage,
        details: e.details,
        stacktrace: stack.toString(),
      );
    } catch (e, stack) {
      CidaasErrorHandler.logError(
        e,
        stack,
        'Sign-in with Cidaas (unexpected error)',
        serviceName: 'CidaasMobileAuthService',
      );

      final userMessage = CidaasErrorHandler.getUserFriendlyMessage(e);
      throw PlatformException(
        code: 'unexpected_error',
        message: userMessage,
        details: null,
        stacktrace: stack.toString(),
      );
    }
  }

  @override
  Future<void> signOut(String? idToken) async {
    debugPrint('CidaasMobileAuthService: Starting sign-out process...');

    try {
      final EndSessionRequest endSessionRequest = EndSessionRequest(
        idTokenHint: idToken,
        postLogoutRedirectUrl: config.postLogoutRedirectUri,
        discoveryUrl: config.discoveryUrl,
      );

      debugPrint('CidaasMobileAuthService: Sending end session request...');

      final EndSessionResponse? response =
          await _appAuth.endSession(endSessionRequest);

      if (response != null) {
        debugPrint('CidaasMobileAuthService: Sign-out successful');
      } else {
        debugPrint('CidaasMobileAuthService: Sign-out completed');
      }
    } on PlatformException catch (e, stack) {
      // User cancellation is not an error
      if (e.code == 'end_session_failed' &&
          (e.details?.toString().contains('User cancelled') ?? false)) {
        debugPrint('CidaasMobileAuthService: User cancelled sign-out');
        return;
      }

      CidaasErrorHandler.logError(
        e,
        stack,
        'Sign-out from Cidaas (PlatformException)',
        serviceName: 'CidaasMobileAuthService',
      );

      final userMessage = CidaasErrorHandler.getUserFriendlyMessage(e);
      throw PlatformException(
        code: e.code,
        message: userMessage,
        details: e.details,
        stacktrace: stack.toString(),
      );
    } catch (e, stack) {
      CidaasErrorHandler.logError(
        e,
        stack,
        'Sign-out from Cidaas (unexpected error)',
        serviceName: 'CidaasMobileAuthService',
      );

      final userMessage = CidaasErrorHandler.getUserFriendlyMessage(e);
      throw PlatformException(
        code: 'signout_error',
        message: userMessage,
        details: null,
        stacktrace: stack.toString(),
      );
    }
  }
}
