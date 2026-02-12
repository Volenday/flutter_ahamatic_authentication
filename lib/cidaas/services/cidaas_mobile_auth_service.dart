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
    debugPrint('CidaasMobileAuthService: ═══ Starting sign-in process ═══');

    // Log all input values for debugging
    debugPrint('CidaasMobileAuthService: [INPUT] apiKey: ${apiKey.isEmpty ? "(empty)" : "${apiKey.substring(0, apiKey.length > 8 ? 8 : apiKey.length)}..."}');
    debugPrint('CidaasMobileAuthService: [INPUT] apiUrl: $apiUrl');
    debugPrint('CidaasMobileAuthService: [CONFIG] clientId: ${config.clientId}');
    debugPrint('CidaasMobileAuthService: [CONFIG] cidaasClientIdMitID: ${config.cidaasClientIdMitID ?? "(null)"}');
    debugPrint('CidaasMobileAuthService: [CONFIG] effectiveClientId: ${config.effectiveClientId}');
    debugPrint('CidaasMobileAuthService: [CONFIG] issuer: ${config.issuer}');
    debugPrint('CidaasMobileAuthService: [CONFIG] redirectUri: ${config.redirectUri}');
    debugPrint('CidaasMobileAuthService: [CONFIG] discoveryUrl: ${config.discoveryUrl}');
    debugPrint('CidaasMobileAuthService: [CONFIG] scopes: ${config.scopes}');
    debugPrint('CidaasMobileAuthService: [CONFIG] postLogoutRedirectUri: ${config.postLogoutRedirectUri}');

    final List<String> cidaasScopes = config.scopes.isNotEmpty
        ? config.scopes
        : ['openid', 'profile', 'email'];
    debugPrint('CidaasMobileAuthService: [PROCESS] Using scopes: $cidaasScopes');

    try {
      // 1. Authorization Request
      debugPrint('CidaasMobileAuthService: [STEP 1/4] Building AuthorizationRequest...');
      final AuthorizationRequest authRequest = AuthorizationRequest(
        config.effectiveClientId,
        config.redirectUri,
        discoveryUrl: config.discoveryUrl,
        scopes: cidaasScopes,
        nonce: null,
      );

      debugPrint('CidaasMobileAuthService: [STEP 1/4] Sending authorization request (clientId: ${config.effectiveClientId})...');

      final AuthorizationResponse authResponse = await _appAuth.authorize(
        authRequest,
      );

      debugPrint('CidaasMobileAuthService: [STEP 1/4] Authorization successful (code received: ${authResponse.authorizationCode != null})');

      // 2. Token Exchange Request
      debugPrint('CidaasMobileAuthService: [STEP 2/4] Building TokenRequest...');
      final TokenRequest tokenRequest = TokenRequest(
        config.effectiveClientId,
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

      debugPrint('CidaasMobileAuthService: [STEP 2/4] Exchanging authorization code for tokens...');

      final TokenResponse tokenResponse = await _appAuth.token(tokenRequest);

      debugPrint('CidaasMobileAuthService: [STEP 2/4] Token exchange successful (accessToken: ${tokenResponse.accessToken != null})');

      // 3. Login to Ahamatic
      debugPrint('CidaasMobileAuthService: [STEP 3/4] Logging in to Ahamatic (apiUrl: $apiUrl)...');
      final ahamaticLoginResponse = await _ahamaticService.loginEmail(
        apiKey,
        apiUrl!,
      );

      debugPrint('CidaasMobileAuthService: [STEP 3/4] Ahamatic login successful (token length: ${ahamaticLoginResponse.length})');

      // 4. Exchange tokens with Ahamatic
      debugPrint('CidaasMobileAuthService: [STEP 4/4] Fetching Ahamatic tokens (clientId: ${config.effectiveClientId}, issuer: ${config.issuer})...');
      final ahamaticResponse = await _ahamaticService.fetchTokens(
        accessToken: tokenResponse.accessToken!,
        apiUrl: apiUrl,
        apiKey: apiKey,
        ahamaticToken: ahamaticLoginResponse,
        clientId: config.effectiveClientId,
        redirectUrl: config.redirectUri,
        issuer: config.issuer,
      );

      debugPrint('CidaasMobileAuthService: [STEP 4/4] Ahamatic tokens received successfully');
      debugPrint('CidaasMobileAuthService: ═══ Sign-in completed successfully ═══');

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
      debugPrint('CidaasMobileAuthService: [ERROR] PlatformException code=${e.code} message=${e.message}');
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
      debugPrint('CidaasMobileAuthService: [ERROR] Unexpected error: $e');
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
    debugPrint('CidaasMobileAuthService: ═══ Starting sign-out process ═══');
    debugPrint('CidaasMobileAuthService: [CONFIG] postLogoutRedirectUri: ${config.postLogoutRedirectUri} discoveryUrl: ${config.discoveryUrl}');
    debugPrint('CidaasMobileAuthService: [INPUT] idToken: ${idToken != null ? "${idToken.length} chars" : "(null)"}');

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
