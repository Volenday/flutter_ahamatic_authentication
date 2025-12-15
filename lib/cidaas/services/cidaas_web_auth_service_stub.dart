import 'package:dio/dio.dart';

import '../models/models.dart';

/// Stub implementation of CidaasWebAuthService for non-web platforms.
///
/// This class provides the same interface as CidaasWebAuthService but throws
/// UnsupportedError on all methods. It's used for conditional imports to
/// prevent web-specific code from being compiled on mobile platforms.
class CidaasWebAuthService {
  CidaasWebAuthService(
    Dio dio,
    CidaasConfiguration config,
    Map<String, String> devAccount,
  ) {
    throw UnsupportedError(
      'CidaasWebAuthService is only available on web platforms',
    );
  }

  void initiateAuthFlow({String? returnUrl}) {
    throw UnsupportedError(
      'CidaasWebAuthService is only available on web platforms',
    );
  }

  Future<CidaasWebAuthResult?> initiateAuthFlowPopup({String? returnUrl}) {
    throw UnsupportedError(
      'CidaasWebAuthService is only available on web platforms',
    );
  }

  CidaasWebAuthResult? handleCallback() {
    throw UnsupportedError(
      'CidaasWebAuthService is only available on web platforms',
    );
  }

  Future<CidaasTokenResponse> exchangeCodeForTokens(
    CidaasWebAuthResult authResult,
  ) {
    throw UnsupportedError(
      'CidaasWebAuthService is only available on web platforms',
    );
  }

  Future<AhamaticResponse> signInComplete(
    String apiKey,
    String apiUrl,
    CidaasWebAuthResult authResult,
  ) {
    throw UnsupportedError(
      'CidaasWebAuthService is only available on web platforms',
    );
  }

  void signOut({String? idToken}) {
    throw UnsupportedError(
      'CidaasWebAuthService is only available on web platforms',
    );
  }
}
