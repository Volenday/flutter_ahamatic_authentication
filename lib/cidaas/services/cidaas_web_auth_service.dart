import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:universal_html/html.dart' as html;

import '../models/models.dart';
import '../utils/pkce_utils.dart';
import 'ahamatic_token_service.dart';

/// Web implementation of Cidaas OAuth2 authentication.
///
/// Uses standard OAuth2 Authorization Code flow with PKCE for web browsers.
/// This service handles:
/// - Initiating the OAuth2 flow (redirect or popup)
/// - Handling callbacks and extracting authorization codes
/// - Exchanging codes for tokens
/// - Signing out
class CidaasWebAuthService {
  final Dio _dio;
  final CidaasConfiguration config;
  final Map<String, String> devAccount;
  late final AhamaticTokenService _ahamaticService;

  CidaasWebAuthService(this._dio, this.config, this.devAccount) {
    _ahamaticService = AhamaticTokenService(_dio, devAccount);
  }

  /// Initiates the OAuth2 authorization flow for web.
  ///
  /// This will redirect the user to the Cidaas login page.
  /// [returnUrl] - Optional custom redirect URL (defaults to config.redirectWebUri)
  void initiateAuthFlow({String? returnUrl}) {
    debugPrint('CidaasWebAuthService: Initiating auth flow...');

    final codeVerifier = PkceUtils.generateCodeVerifier();
    final codeChallenge = PkceUtils.generateCodeChallenge(codeVerifier);
    final state = PkceUtils.generateState();

    // Store PKCE values in session storage for later use
    html.window.sessionStorage['cidaas_code_verifier'] = codeVerifier;
    html.window.sessionStorage['cidaas_state'] = state;

    final scopes = config.scopes.isNotEmpty
        ? config.scopes.join(' ')
        : 'openid profile email';

    final redirectUri = returnUrl ?? config.redirectWebUri;

    final authUrl = Uri.parse('${config.issuer}/authz-srv/authz').replace(
      queryParameters: {
        'client_id': config.clientId,
        'redirect_uri': redirectUri,
        'response_type': 'code',
        'scope': scopes,
        'state': state,
        'code_challenge': codeChallenge,
        'code_challenge_method': 'S256',
      },
    );

    debugPrint('CidaasWebAuthService: Redirecting to Cidaas login...');

    // Redirect to authorization URL
    html.window.location.href = authUrl.toString();
  }

  /// Opens the OAuth2 flow in a popup window.
  ///
  /// Returns a Future that completes when authentication is done.
  Future<CidaasWebAuthResult?> initiateAuthFlowPopup(
      {String? returnUrl}) async {
    debugPrint('CidaasWebAuthService: Opening auth popup...');

    final codeVerifier = PkceUtils.generateCodeVerifier();
    final codeChallenge = PkceUtils.generateCodeChallenge(codeVerifier);
    final state = PkceUtils.generateState();

    final scopes = config.scopes.isNotEmpty
        ? config.scopes.join(' ')
        : 'openid profile email';

    final redirectUri = returnUrl ?? config.redirectWebUri;

    final authUrl = Uri.parse('${config.issuer}/authz-srv/authz').replace(
      queryParameters: {
        'client_id': config.clientId,
        'redirect_uri': redirectUri,
        'response_type': 'code',
        'scope': scopes,
        'state': state,
        'code_challenge': codeChallenge,
        'code_challenge_method': 'S256',
      },
    );

    final completer = Completer<CidaasWebAuthResult?>();

    // Open popup
    final popup = html.window.open(
      authUrl.toString(),
      'cidaas_auth',
      'width=500,height=600,scrollbars=yes',
    );

    // Listen for messages from popup
    late final html.EventListener messageListener;
    messageListener = (html.Event event) {
      if (event is html.MessageEvent) {
        try {
          final data = jsonDecode(event.data as String);
          if (data['type'] == 'cidaas_auth_callback') {
            final code = data['code'] as String?;
            final returnedState = data['state'] as String?;

            html.window.removeEventListener('message', messageListener);

            if (returnedState != state) {
              debugPrint('CidaasWebAuthService: State mismatch - auth failed');
              completer.complete(null);
              return;
            }

            if (code != null) {
              debugPrint('CidaasWebAuthService: Authorization code received');
              completer.complete(CidaasWebAuthResult(
                authorizationCode: code,
                codeVerifier: codeVerifier,
                state: state,
              ));
            } else {
              debugPrint(
                  'CidaasWebAuthService: No authorization code received');
              completer.complete(null);
            }
          }
        } catch (e) {
          debugPrint('CidaasWebAuthService: Error parsing callback message');
        }
      }
    };

    html.window.addEventListener('message', messageListener);

    // Check if popup was closed without completing auth
    Timer.periodic(const Duration(milliseconds: 500), (timer) {
      final isClosed = popup?.closed == true;
      if (isClosed) {
        timer.cancel();
        html.window.removeEventListener('message', messageListener);
        if (!completer.isCompleted) {
          debugPrint(
              'CidaasWebAuthService: Popup closed without completing auth');
          completer.complete(null);
        }
      }
    });

    return completer.future;
  }

  /// Handles the OAuth2 callback and extracts the authorization code.
  ///
  /// Call this method on the callback page to extract auth code from URL.
  CidaasWebAuthResult? handleCallback() {
    debugPrint('CidaasWebAuthService: Handling callback...');

    final uri = Uri.parse(html.window.location.href);
    final code = uri.queryParameters['code'];
    final state = uri.queryParameters['state'];
    final error = uri.queryParameters['error'];

    if (error != null) {
      debugPrint('CidaasWebAuthService: Auth error received');
      return null;
    }

    final storedState = html.window.sessionStorage['cidaas_state'];
    final storedVerifier = html.window.sessionStorage['cidaas_code_verifier'];

    if (state != storedState) {
      debugPrint('CidaasWebAuthService: State mismatch - possible CSRF attack');
      return null;
    }

    if (code == null || storedVerifier == null) {
      debugPrint('CidaasWebAuthService: Missing code or verifier');
      return null;
    }

    // Clean up stored values
    html.window.sessionStorage.remove('cidaas_state');
    html.window.sessionStorage.remove('cidaas_code_verifier');

    debugPrint(
        'CidaasWebAuthService: Authorization code extracted successfully');

    return CidaasWebAuthResult(
      authorizationCode: code,
      codeVerifier: storedVerifier,
      state: state ?? '',
    );
  }

  /// Exchanges the authorization code for tokens.
  Future<CidaasTokenResponse> exchangeCodeForTokens(
    CidaasWebAuthResult authResult,
  ) async {
    debugPrint('CidaasWebAuthService: Exchanging code for tokens...');

    final tokenUrl = '${config.issuer}/token-srv/token';

    try {
      final response = await _dio.post(
        tokenUrl,
        data: {
          'grant_type': 'authorization_code',
          'client_id': config.clientId,
          'code': authResult.authorizationCode,
          'redirect_uri': config.redirectWebUri,
          'code_verifier': authResult.codeVerifier,
        },
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
        ),
      );

      debugPrint('CidaasWebAuthService: Token exchange successful');

      return CidaasTokenResponse(
        accessToken: response.data['access_token'],
        refreshToken: response.data['refresh_token'],
        idToken: response.data['id_token'],
        expiresIn: response.data['expires_in'],
        tokenType: response.data['token_type'],
      );
    } catch (e) {
      debugPrint('CidaasWebAuthService: Token exchange failed');
      rethrow;
    }
  }

  /// Complete sign-in flow for web, including Ahamatic token exchange.
  Future<AhamaticResponse> signInComplete(
    String apiKey,
    String apiUrl,
    CidaasWebAuthResult authResult,
  ) async {
    debugPrint('CidaasWebAuthService: Starting complete sign-in flow...');

    // 1. Exchange code for Cidaas tokens
    final tokenResponse = await exchangeCodeForTokens(authResult);
    debugPrint('CidaasWebAuthService: Cidaas tokens received');

    // 2. Login to Ahamatic
    debugPrint('CidaasWebAuthService: Logging into Ahamatic...');
    final ahamaticLoginToken =
        await _ahamaticService.loginEmail(apiKey, apiUrl);
    debugPrint('CidaasWebAuthService: Ahamatic login successful');

    // 3. Exchange Cidaas token for Ahamatic tokens
    debugPrint('CidaasWebAuthService: Exchanging for Ahamatic tokens...');
    final result = await _ahamaticService.fetchTokens(
      accessToken: tokenResponse.accessToken!,
      apiUrl: apiUrl,
      apiKey: apiKey,
      ahamaticToken: ahamaticLoginToken,
      clientId: config.clientId,
      redirectUrl: config.redirectWebUri ?? config.redirectUri,
      issuer: config.issuer,
    );

    debugPrint('CidaasWebAuthService: Sign-in completed successfully');
    return result;
  }

  /// Signs out the user from Cidaas on web.
  ///
  /// Redirects to the Cidaas end_session endpoint which will:
  /// 1. Invalidate the session on Cidaas
  /// 2. Redirect back to postLogoutWebUri (or postLogoutRedirectUri)
  ///
  /// [idToken] - The ID token from the current session (optional but recommended)
  void signOut({String? idToken}) {
    debugPrint('CidaasWebAuthService: Starting sign-out process...');

    final postLogoutUri =
        config.postLogoutWebUri ?? config.postLogoutRedirectUri;

    // Build the end_session URL
    final endSessionUrl = StringBuffer('${config.issuer}/session/end_session?');

    final params = <String, String>{
      'post_logout_redirect_uri': postLogoutUri,
      'client_id': config.clientId,
    };

    if (idToken != null && idToken.isNotEmpty) {
      params['id_token_hint'] = idToken;
    }

    endSessionUrl.write(params.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&'));

    debugPrint('CidaasWebAuthService: Redirecting to Cidaas logout...');

    // Redirect the browser to the logout URL
    html.window.location.href = endSessionUrl.toString();
  }
}
