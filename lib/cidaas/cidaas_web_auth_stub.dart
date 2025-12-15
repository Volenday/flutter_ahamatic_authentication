import 'package:dio/dio.dart';
import 'package:flutter_ahamatic_authentication/cidaas/cidaas_entity.dart';

/// Stub implementation of CidaasWebAuth for non-web platforms.
/// This class should never be instantiated on mobile platforms.
class CidaasWebAuth {
  CidaasWebAuth(Dio dio, CidaasConfiguration config, Map<String, String> devAccount) {
    throw UnsupportedError('CidaasWebAuth is only available on web platforms');
  }

  void initiateAuthFlow({String? returnUrl}) {
    throw UnsupportedError('CidaasWebAuth is only available on web platforms');
  }

  Future<CidaasWebAuthResult?> initiateAuthFlowPopup({String? returnUrl}) {
    throw UnsupportedError('CidaasWebAuth is only available on web platforms');
  }

  CidaasWebAuthResult? handleCallback() {
    throw UnsupportedError('CidaasWebAuth is only available on web platforms');
  }

  Future<CidaasTokenResponse> exchangeCodeForTokens(CidaasWebAuthResult authResult) {
    throw UnsupportedError('CidaasWebAuth is only available on web platforms');
  }

  Future<AhamaticResponse> signInComplete(String apiKey, String apiUrl, CidaasWebAuthResult authResult) {
    throw UnsupportedError('CidaasWebAuth is only available on web platforms');
  }
}

/// Stub for CidaasWebAuthResult
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

/// Stub for CidaasTokenResponse
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

