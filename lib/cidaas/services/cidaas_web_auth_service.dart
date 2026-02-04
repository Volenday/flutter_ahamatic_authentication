import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:universal_html/html.dart' as html;

import '../models/models.dart';
import '../utils/error_handler.dart';
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

  static const String _sessionStorageClientIdKey = 'cidaas_client_id_override';
  static const String _sessionStorageIssuerOverrideKey =
      'cidaas_issuer_override';

  /// Client ID to use for this flow. Reads override from sessionStorage if set
  /// (when user chose classic Cidaas or MitID); otherwise [config.effectiveClientId].
  String _getClientIdForFlow() {
    final stored = html.window.sessionStorage[_sessionStorageClientIdKey];
    return (stored != null && stored.isNotEmpty)
        ? stored
        : config.effectiveClientId;
  }

  /// Issuer to use for token exchange. When MitID custom URL was used, we stored the issuer in session.
  String _getIssuerForFlow() {
    final stored = html.window.sessionStorage[_sessionStorageIssuerOverrideKey];
    if (stored != null && stored.isNotEmpty) return stored;
    return config.issuer;
  }

  /// Initiates the OAuth2 authorization flow for web.
  ///
  /// This will redirect the user to the Cidaas login page.
  /// [returnUrl] - Optional custom redirect URL (defaults to config.redirectWebUri)
  /// [clientIdOverride] - Optional client ID (e.g. classic [clientId] or MitID [cidaasClientIdMitID])
  void initiateAuthFlow({String? returnUrl, String? clientIdOverride}) {
    final clientId = clientIdOverride?.trim().isNotEmpty == true
        ? clientIdOverride!
        : config.effectiveClientId;
    html.window.sessionStorage[_sessionStorageClientIdKey] = clientId;

    debugPrint(
        'CidaasWebAuthService: [DEBUG] initiateAuthFlow clientIdOverride=${clientIdOverride ?? "(none)"} → clientId=$clientId');
    debugPrint(
        'CidaasWebAuthService: [DEBUG] config issuer=${config.issuer} redirectWebUri=${config.redirectWebUri}');
    debugPrint(
        'CidaasWebAuthService: [DEBUG] sessionStorage[$_sessionStorageClientIdKey] stored');

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

    // MitID: use custom URL when configured (e.g. https://test-login.abena.com/authz-srv/authz?client_id=...&preferred_login=mitid)
    final isMitIdFlow = config.cidaasClientIdMitID?.trim().isNotEmpty == true &&
        clientId == config.cidaasClientIdMitID?.trim();
    final customMitIdUrl = config.mitIdAuthUrl?.trim();

    if (isMitIdFlow && customMitIdUrl != null && customMitIdUrl.isNotEmpty) {
      final mitIdIssuer = config.mitIdEffectiveIssuer;
      if (mitIdIssuer != null) {
        html.window.sessionStorage[_sessionStorageIssuerOverrideKey] =
            mitIdIssuer;
      }
      final baseUri = Uri.parse(customMitIdUrl);
      final params = Map<String, String>.from(baseUri.queryParameters)
        ..['state'] = state
        ..['code_challenge'] = codeChallenge
        ..['code_challenge_method'] = 'S256';
      if (!params.containsKey('scope') || params['scope']!.isEmpty) {
        params['scope'] = scopes;
      }
      final authUrl = baseUri.replace(queryParameters: params);
      debugPrint(
          'CidaasWebAuthService: [DEBUG] MitID custom authUrl (redirect): ${authUrl.origin}${authUrl.path}?...');
      debugPrint('CidaasWebAuthService: Redirecting to MitID login...');
      html.window.location.href = authUrl.toString();
      return;
    }

    final authUrl = Uri.parse('${config.issuer}/authz-srv/authz').replace(
      queryParameters: {
        'client_id': clientId,
        'redirect_uri': redirectUri,
        'response_type': 'code',
        'scope': scopes,
        'state': state,
        'code_challenge': codeChallenge,
        'code_challenge_method': 'S256',
      },
    );

    debugPrint(
        'CidaasWebAuthService: [DEBUG] authUrl (redirect): ${authUrl.origin}${authUrl.path}?client_id=...&redirect_uri=...');
    debugPrint('CidaasWebAuthService: Redirecting to Cidaas login...');

    // Redirect to authorization URL
    html.window.location.href = authUrl.toString();
  }

  /// Opens the OAuth2 flow in a popup window.
  ///
  /// Returns a Future that completes when authentication is done.
  Future<CidaasWebAuthResult?> initiateAuthFlowPopup(
      {String? returnUrl, String? clientIdOverride}) async {
    final clientId = clientIdOverride?.trim().isNotEmpty == true
        ? clientIdOverride!
        : config.effectiveClientId;
    html.window.sessionStorage[_sessionStorageClientIdKey] = clientId;

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
        'client_id': clientId,
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
        } catch (e, stack) {
          CidaasErrorHandler.logError(
            e,
            stack,
            'Error parsing OAuth callback message',
            serviceName: 'CidaasWebAuthService',
          );
        }
      }
    };

    html.window.addEventListener('message', messageListener);

    // Check if popup was closed without completing auth
    Timer.periodic(const Duration(milliseconds: 500), (timer) {
      final bool isClosed = popup?.closed ?? false;
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
    debugPrint('CidaasWebAuthService: [DEBUG] handleCallback');

    final uri = Uri.parse(html.window.location.href);
    final code = uri.queryParameters['code'];
    final state = uri.queryParameters['state'];
    final error = uri.queryParameters['error'];
    final storedClientId =
        html.window.sessionStorage[_sessionStorageClientIdKey];

    debugPrint(
        'CidaasWebAuthService: [DEBUG] callback code=${code != null ? "${code.length} chars" : "null"} state=${state != null ? "present" : "null"} error=$error storedClientId=${storedClientId ?? "(none)"}');

    if (error != null) {
      debugPrint('CidaasWebAuthService: [ERROR] Auth error received: $error');
      return null;
    }

    final storedState = html.window.sessionStorage['cidaas_state'];
    final storedVerifier = html.window.sessionStorage['cidaas_code_verifier'];

    if (state != storedState) {
      debugPrint(
          'CidaasWebAuthService: [ERROR] State mismatch (possible CSRF) expected=${storedState != null ? "present" : "null"} got=${state != null ? "present" : "null"}');
      return null;
    }

    if (code == null || storedVerifier == null) {
      debugPrint(
          'CidaasWebAuthService: [ERROR] Missing code or verifier code=${code != null} verifier=${storedVerifier != null}');
      return null;
    }

    // Clean up stored values
    html.window.sessionStorage.remove('cidaas_state');
    html.window.sessionStorage.remove('cidaas_code_verifier');

    debugPrint(
        'CidaasWebAuthService: [DEBUG] Authorization code extracted successfully');

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
    final clientId = _getClientIdForFlow();
    final issuer = _getIssuerForFlow();
    debugPrint(
        'CidaasWebAuthService: [DEBUG] exchangeCodeForTokens clientId=$clientId tokenUrl=$issuer/token-srv/token');

    final tokenUrl = '$issuer/token-srv/token';

    try {
      final response = await _dio.post(
        tokenUrl,
        data: {
          'grant_type': 'authorization_code',
          'client_id': clientId,
          'code': authResult.authorizationCode,
          'redirect_uri': config.redirectWebUri,
          'code_verifier': authResult.codeVerifier,
        },
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
        ),
      );

      debugPrint(
          'CidaasWebAuthService: [DEBUG] Token exchange successful (access_token received)');

      return CidaasTokenResponse(
        accessToken: response.data['access_token'],
        refreshToken: response.data['refresh_token'],
        idToken: response.data['id_token'],
        expiresIn: response.data['expires_in'],
        tokenType: response.data['token_type'],
      );
    } catch (e, stack) {
      CidaasErrorHandler.logError(
        e,
        stack,
        'Token exchange failed',
        serviceName: 'CidaasWebAuthService',
      );
      rethrow;
    }
  }

  /// Complete sign-in flow for web, including Ahamatic token exchange.
  Future<AhamaticResponse> signInComplete(
    String apiKey,
    String apiUrl,
    CidaasWebAuthResult authResult,
  ) async {
    debugPrint('CidaasWebAuthService: [DEBUG] signInComplete apiUrl=$apiUrl');

    // 1. Exchange code for Cidaas tokens
    final tokenResponse = await exchangeCodeForTokens(authResult);
    debugPrint(
        'CidaasWebAuthService: [DEBUG] Cidaas tokens received (accessToken: ${tokenResponse.accessToken != null})');

    // 2. Login to Ahamatic
    debugPrint('CidaasWebAuthService: [DEBUG] Logging into Ahamatic...');
    final ahamaticLoginToken =
        await _ahamaticService.loginEmail(apiKey, apiUrl);
    debugPrint('CidaasWebAuthService: [DEBUG] Ahamatic login successful');

    // 3. Exchange Cidaas token for Ahamatic tokens
    final clientId = _getClientIdForFlow();
    final issuer = _getIssuerForFlow();
    debugPrint(
        'CidaasWebAuthService: [DEBUG] fetchTokens clientId=$clientId issuer=$issuer');
    final result = await _ahamaticService.fetchTokens(
      accessToken: tokenResponse.accessToken!,
      apiUrl: apiUrl,
      apiKey: apiKey,
      ahamaticToken: ahamaticLoginToken,
      clientId: clientId,
      redirectUrl: config.redirectWebUri ?? config.redirectUri,
      issuer: issuer,
    );

    html.window.sessionStorage.remove(_sessionStorageClientIdKey);
    html.window.sessionStorage.remove(_sessionStorageIssuerOverrideKey);
    debugPrint(
        'CidaasWebAuthService: [DEBUG] signInComplete done, sessionStorage[$_sessionStorageClientIdKey] cleared');
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
      'client_id': _getClientIdForFlow(),
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
