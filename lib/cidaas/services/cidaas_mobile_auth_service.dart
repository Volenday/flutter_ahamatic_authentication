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
    String apiUrl, {
    String? clientIdOverride,
  }) async {
    final effectiveClientId =
        clientIdOverride?.trim().isNotEmpty == true
            ? clientIdOverride!
            : config.effectiveClientId;

    debugPrint('CidaasMobileAuthService: ═══ Starting sign-in process ═══');
    debugPrint(
        'CidaasMobileAuthService: [INPUT] clientIdOverride: ${clientIdOverride ?? "(none)"} → effectiveClientId: $effectiveClientId');

    // Log all input values for debugging
    debugPrint(
        'CidaasMobileAuthService: [INPUT] apiKey: ${apiKey.isEmpty ? "(empty)" : "${apiKey.substring(0, apiKey.length > 8 ? 8 : apiKey.length)}..."}');
    debugPrint('CidaasMobileAuthService: [INPUT] apiUrl: $apiUrl');
    debugPrint(
        'CidaasMobileAuthService: [CONFIG] clientId: ${config.clientId}');
    debugPrint(
        'CidaasMobileAuthService: [CONFIG] cidaasClientIdMitID: ${config.cidaasClientIdMitID ?? "(null)"}');
    debugPrint(
        'CidaasMobileAuthService: [CONFIG] effectiveClientId (config): ${config.effectiveClientId}');
    debugPrint('CidaasMobileAuthService: [CONFIG] issuer: ${config.issuer}');
    debugPrint(
        'CidaasMobileAuthService: [CONFIG] redirectUri: ${config.redirectUri}');
    debugPrint(
        'CidaasMobileAuthService: [CONFIG] discoveryUrl: ${config.discoveryUrl}');
    debugPrint('CidaasMobileAuthService: [CONFIG] scopes: ${config.scopes}');
    debugPrint(
        'CidaasMobileAuthService: [CONFIG] postLogoutRedirectUri: ${config.postLogoutRedirectUri}');

    final List<String> cidaasScopes = config.scopes.isNotEmpty
        ? config.scopes
        : ['openid', 'profile', 'email'];
    debugPrint(
        'CidaasMobileAuthService: [PROCESS] Using scopes: $cidaasScopes');

    // MitID: use custom issuer when configured (e.g. https://test-login.abena.com)
    final isMitIdFlow = config.cidaasClientIdMitID?.trim().isNotEmpty == true &&
        effectiveClientId == config.cidaasClientIdMitID?.trim();
    final mitIdIssuer = config.mitIdEffectiveIssuer;
    final effectiveDiscoveryUrl = (isMitIdFlow && mitIdIssuer != null)
        ? '$mitIdIssuer/.well-known/openid-configuration'
        : config.discoveryUrl;
    final effectiveIssuer = (isMitIdFlow && mitIdIssuer != null)
        ? mitIdIssuer
        : config.issuer;
    if (isMitIdFlow && mitIdIssuer != null) {
      debugPrint(
          'CidaasMobileAuthService: [CONFIG] MitID flow using issuer=$effectiveIssuer discoveryUrl=$effectiveDiscoveryUrl');
    }

    try {
      // 1. Authorization Request
      // Do NOT pass code_challenge_method in additionalParameters - AppAuth (Android) rejects it;
      // PKCE is handled by the library via the builder.
      debugPrint(
          'CidaasMobileAuthService: [STEP 1/4] Building AuthorizationRequest (clientId: $effectiveClientId)...');
      final Map<String, String>? authAdditionalParams = isMitIdFlow
          ? {'preferred_login': 'mitid'}
          : null;
      final AuthorizationRequest authRequest = AuthorizationRequest(
        effectiveClientId,
        config.redirectUri,
        discoveryUrl: effectiveDiscoveryUrl,
        scopes: cidaasScopes,
        nonce: null,
        additionalParameters: authAdditionalParams,
      );

      debugPrint(
          'CidaasMobileAuthService: [STEP 1/4] Sending authorization request...');

      final AuthorizationResponse authResponse = await _appAuth.authorize(
        authRequest,
      );

      debugPrint(
          'CidaasMobileAuthService: [STEP 1/4] Authorization successful (code received: ${authResponse.authorizationCode != null})');
      debugPrint(
          'CidaasMobileAuthService: [STEP 1/4] authResponse: codeLen=${authResponse.authorizationCode?.length ?? 0} hasCodeVerifier=${authResponse.codeVerifier != null} hasNonce=${authResponse.nonce != null}');

      // 2. Token Exchange Request
      debugPrint(
          'CidaasMobileAuthService: [STEP 2/4] Building TokenRequest...');
      final TokenRequest tokenRequest = TokenRequest(
        effectiveClientId,
        config.redirectUri,
        discoveryUrl: effectiveDiscoveryUrl,
        scopes: config.scopes,
        authorizationCode: authResponse.authorizationCode,
        codeVerifier: authResponse.codeVerifier,
        nonce: authResponse.nonce,
        allowInsecureConnections: true,
      );

      debugPrint(
          'CidaasMobileAuthService: [STEP 2/4] Exchanging authorization code for tokens...');

      final TokenResponse tokenResponse = await _appAuth.token(tokenRequest);

      debugPrint(
          'CidaasMobileAuthService: [STEP 2/4] Token exchange successful (accessToken: ${tokenResponse.accessToken != null})');
      debugPrint(
          'CidaasMobileAuthService: [STEP 2/4] tokenResponse: accessTokenLen=${tokenResponse.accessToken?.length ?? 0} refreshTokenLen=${tokenResponse.refreshToken?.length ?? 0} idTokenLen=${tokenResponse.idToken?.length ?? 0}');

      // 3. Login to Ahamatic
      debugPrint(
          'CidaasMobileAuthService: [STEP 3/4] Logging in to Ahamatic (apiUrl: $apiUrl)...');
      final ahamaticLoginResponse = await _ahamaticService.loginEmail(
        apiKey,
        apiUrl,
      );

      debugPrint(
          'CidaasMobileAuthService: [STEP 3/4] Ahamatic login successful (token length: ${ahamaticLoginResponse.length})');

      // 4. Exchange tokens with Ahamatic
      debugPrint(
          'CidaasMobileAuthService: [STEP 4/4] Fetching Ahamatic tokens (clientId: $effectiveClientId, issuer: ${config.issuer})...');
      final ahamaticResponse = await _ahamaticService.fetchTokens(
        accessToken: tokenResponse.accessToken!,
        apiUrl: apiUrl,
        apiKey: apiKey,
        ahamaticToken: ahamaticLoginResponse,
        clientId: effectiveClientId,
        redirectUrl: config.redirectUri,
        issuer: effectiveIssuer,
      );

      debugPrint(
          'CidaasMobileAuthService: [STEP 4/4] Ahamatic tokens received successfully');
      debugPrint(
          'CidaasMobileAuthService: ═══ Sign-in completed successfully ═══');

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
      debugPrint(
          'CidaasMobileAuthService: [ERROR] PlatformException code=${e.code} message=${e.message} details=${e.details}');
      CidaasErrorHandler.logError(
        e,
        stack,
        'Sign-in with Cidaas (PlatformException)',
        serviceName: 'CidaasMobileAuthService',
      );

      // Specific handling for user cancellation - use special code to indicate manual cancellation
      if (e.code == 'authorize_failed' &&
          (e.details?.toString().contains('User cancelled flow') ?? false)) {
        debugPrint('CidaasMobileAuthService: User manually cancelled authentication');
        throw PlatformException(
          code: CidaasErrorHandler.userCancelledCode,
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

  /// Completes MitID sign-in when the authorization code was obtained from the
  /// full [mitIdAuthUrl] flow (e.g. WebView). Exchanges [code] for Cidaas tokens,
  /// then Ahamatic login and token exchange.
  ///
  /// [clientId] - MitID client ID (e.g. [CidaasConfiguration.cidaasClientIdMitID]).
  /// [issuer] - Issuer base URL (e.g. from [CidaasConfiguration.mitIdEffectiveIssuer]).
  Future<TokenResponse> signInWithCidaasCode(
    String apiKey,
    String apiUrl,
    String code,
    String codeVerifier,
    String clientId,
    String issuer,
  ) async {
    debugPrint(
        'CidaasMobileAuthService: ═══ MitID sign-in with code (full URL flow) ═══');
    final tokenUrl = '$issuer/token-srv/token';
    debugPrint(
        'CidaasMobileAuthService: [STEP 1/4] Exchanging code at $tokenUrl');

    try {
      final response = await _dio.post(
        tokenUrl,
        data: {
          'grant_type': 'authorization_code',
          'client_id': clientId,
          'code': code,
          'redirect_uri': config.redirectUri,
          'code_verifier': codeVerifier,
        },
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
        ),
      );

      final accessToken = response.data['access_token'] as String?;
      if (accessToken == null) {
        throw PlatformException(
          code: 'invalid_response',
          message: 'No access_token in token response',
          details: response.data,
        );
      }

      debugPrint(
          'CidaasMobileAuthService: [STEP 2/4] Logging in to Ahamatic...');
      final ahamaticLoginResponse = await _ahamaticService.loginEmail(
        apiKey,
        apiUrl,
      );

      debugPrint(
          'CidaasMobileAuthService: [STEP 3/4] Fetching Ahamatic tokens...');
      final ahamaticResponse = await _ahamaticService.fetchTokens(
        accessToken: accessToken,
        apiUrl: apiUrl,
        apiKey: apiKey,
        ahamaticToken: ahamaticLoginResponse,
        clientId: clientId,
        redirectUrl: config.redirectUri,
        issuer: issuer,
      );

      debugPrint(
          'CidaasMobileAuthService: [STEP 4/4] MitID sign-in with code completed');
      return TokenResponse(
        ahamaticResponse.accessToken,
        ahamaticResponse.refreshToken,
        null,
        ahamaticResponse.idToken,
        null,
        null,
        null,
      );
    } catch (e, stack) {
      CidaasErrorHandler.logError(
        e,
        stack,
        'MitID sign-in with code',
        serviceName: 'CidaasMobileAuthService',
      );
      if (e is PlatformException) rethrow;
      final userMessage = CidaasErrorHandler.getUserFriendlyMessage(e);
      throw PlatformException(
        code: 'ahamatic_login_error',
        message: userMessage,
        details: null,
        stacktrace: stack.toString(),
      );
    }
  }

  @override
  Future<void> signOut(String? idToken) async {
    debugPrint('CidaasMobileAuthService: ═══ Starting sign-out process ═══');
    debugPrint(
        'CidaasMobileAuthService: [CONFIG] postLogoutRedirectUri: ${config.postLogoutRedirectUri} discoveryUrl: ${config.discoveryUrl}');
    debugPrint(
        'CidaasMobileAuthService: [INPUT] idToken: ${idToken != null ? "${idToken.length} chars" : "(null)"}');

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
