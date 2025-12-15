import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_ahamatic_authentication/cidaas/cidaas_entity.dart';
import 'package:universal_html/html.dart' as html;
import 'package:crypto/crypto.dart';

/// Web implementation of Cidaas OAuth2 authentication.
///
/// Uses standard OAuth2 Authorization Code flow with PKCE for web browsers.
class CidaasWebAuth {
  final Dio _dio;
  final CidaasConfiguration config;
  final Map<String, String> devAccount;

  CidaasWebAuth(this._dio, this.config, this.devAccount);

  /// Generates a cryptographically secure random string for PKCE
  String _generateRandomString(int length) {
    const charset =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)])
        .join();
  }

  /// Generates PKCE code verifier
  String generateCodeVerifier() {
    return _generateRandomString(128);
  }

  /// Generates PKCE code challenge from verifier
  String generateCodeChallenge(String codeVerifier) {
    final bytes = utf8.encode(codeVerifier);
    final digest = sha256.convert(bytes);
    return base64Url.encode(digest.bytes).replaceAll('=', '');
  }

  /// Generates a random state parameter for OAuth2
  String generateState() {
    return _generateRandomString(32);
  }

  /// Initiates the OAuth2 authorization flow for web.
  ///
  /// This will redirect the user to the Cidaas login page.
  /// The [returnUrl] is where Cidaas will redirect after authentication.
  void initiateAuthFlow({String? returnUrl}) {
    final codeVerifier = generateCodeVerifier();
    debugPrint('CidaasWebAuth: Code verifier: $codeVerifier');
    final codeChallenge = generateCodeChallenge(codeVerifier);
    debugPrint('CidaasWebAuth: Code challenge: $codeChallenge');
    final state = generateState();
    debugPrint('CidaasWebAuth: State: $state');

    // Store PKCE values in session storage for later use
    html.window.sessionStorage['cidaas_code_verifier'] = codeVerifier;
    html.window.sessionStorage['cidaas_state'] = state;

    final scopes = config.scopes.isNotEmpty
        ? config.scopes.join(' ')
        : 'openid profile email';

    debugPrint('CidaasWebAuth: Scopes: $scopes');

    final redirectUri = returnUrl ?? config.redirectWebUri;

    debugPrint('CidaasWebAuth: Redirect URI: $redirectUri');

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

    debugPrint('CidaasWebAuth: Redirecting to: $authUrl');

    // Redirect to authorization URL
    html.window.location.href = authUrl.toString();
  }

  /// Opens the OAuth2 flow in a popup window.
  ///
  /// Returns a Future that completes when authentication is done.
  Future<CidaasWebAuthResult?> initiateAuthFlowPopup(
      {String? returnUrl}) async {
    final codeVerifier = generateCodeVerifier();
    final codeChallenge = generateCodeChallenge(codeVerifier);
    final state = generateState();

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

    debugPrint('CidaasWebAuth: Opening popup: $authUrl');

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
              debugPrint('CidaasWebAuth: State mismatch');
              completer.complete(null);
              return;
            }

            if (code != null) {
              completer.complete(CidaasWebAuthResult(
                authorizationCode: code,
                codeVerifier: codeVerifier,
                state: state,
              ));
            } else {
              completer.complete(null);
            }
          }
        } catch (e) {
          debugPrint('CidaasWebAuth: Error parsing message: $e');
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
    final uri = Uri.parse(html.window.location.href);
    final code = uri.queryParameters['code'];
    final state = uri.queryParameters['state'];
    final error = uri.queryParameters['error'];

    if (error != null) {
      debugPrint('CidaasWebAuth: Auth error: $error');
      return null;
    }

    final storedState = html.window.sessionStorage['cidaas_state'];
    final storedVerifier = html.window.sessionStorage['cidaas_code_verifier'];

    if (state != storedState) {
      debugPrint('CidaasWebAuth: State mismatch');
      return null;
    }

    if (code == null || storedVerifier == null) {
      debugPrint('CidaasWebAuth: Missing code or verifier');
      return null;
    }

    // Clean up stored values
    html.window.sessionStorage.remove('cidaas_state');
    html.window.sessionStorage.remove('cidaas_code_verifier');

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
    debugPrint('CidaasWebAuth: Exchanging code for tokens');

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

      debugPrint('CidaasWebAuth: Token response received');

      return CidaasTokenResponse(
        accessToken: response.data['access_token'],
        refreshToken: response.data['refresh_token'],
        idToken: response.data['id_token'],
        expiresIn: response.data['expires_in'],
        tokenType: response.data['token_type'],
      );
    } catch (e) {
      debugPrint('CidaasWebAuth: Token exchange error: $e');
      rethrow;
    }
  }

  /// Complete sign-in flow for web, including Ahamatic token exchange.
  Future<AhamaticResponse> signInComplete(
    String apiKey,
    String apiUrl,
    CidaasWebAuthResult authResult,
  ) async {
    // 1. Exchange code for Cidaas tokens
    final tokenResponse = await exchangeCodeForTokens(authResult);

    // 2. Login to Ahamatic
    final ahamaticLoginToken = await _loginEmailAhamatic(apiKey, apiUrl);

    // 3. Exchange Cidaas token for Ahamatic tokens
    return await _fetchAhamaticTokens(
      tokenResponse.accessToken!,
      apiUrl,
      apiKey,
      ahamaticLoginToken,
    );
  }

  Future<String> _loginEmailAhamatic(String apiKey, String apiUrl) async {
    final response = await _dio.post(
      '$apiUrl/api/auth/email',
      data: {
        'apiKey': apiKey,
        'emailAddress': devAccount['emailAddress'],
        'password': devAccount['password'],
      },
    );

    if (response.data != null && response.data['token'] != null) {
      return response.data['token'];
    }
    throw Exception('No token found in Ahamatic login response');
  }

  Future<AhamaticResponse> _fetchAhamaticTokens(
    String accessToken,
    String apiUrl,
    String apiKey,
    String ahamaticToken,
  ) async {
    final response = await _dio.post(
      '$apiUrl/api/auth/cidaas',
      data: {
        'apiKey': apiKey,
        'access_token': accessToken,
        'clientId': config.clientId,
        'redirectUrl': config.redirectWebUri,
        'issuer': config.issuer,
      },
      options: Options(
        headers: {'Authorization': 'Bearer $ahamaticToken'},
      ),
    );

    return AhamaticResponse(
      accessToken: response.data['access_token'],
      refreshToken: response.data['refreshToken'],
      idToken: response.data['token'],
    );
  }
}

/// Result from the web OAuth2 authorization flow.
class CidaasWebAuthResult {
  final String authorizationCode;
  final String codeVerifier;
  final String state;

  CidaasWebAuthResult({
    required this.authorizationCode,
    required this.codeVerifier,
    required this.state,
  });
}

/// Token response from Cidaas.
class CidaasTokenResponse {
  final String? accessToken;
  final String? refreshToken;
  final String? idToken;
  final int? expiresIn;
  final String? tokenType;

  CidaasTokenResponse({
    this.accessToken,
    this.refreshToken,
    this.idToken,
    this.expiresIn,
    this.tokenType,
  });
}
