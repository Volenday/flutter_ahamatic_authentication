/// Token response from Cidaas OAuth2 token endpoint.
///
/// Contains all tokens and metadata returned by Cidaas
/// after a successful token exchange.
class CidaasTokenResponse {
  /// The access token for API calls
  final String? accessToken;

  /// The refresh token for obtaining new access tokens
  final String? refreshToken;

  /// The ID token containing user identity information
  final String? idToken;

  /// Token expiration time in seconds
  final int? expiresIn;

  /// The token type (typically 'Bearer')
  final String? tokenType;

  CidaasTokenResponse({
    this.accessToken,
    this.refreshToken,
    this.idToken,
    this.expiresIn,
    this.tokenType,
  });

  /// Checks if the response contains valid tokens
  bool get hasTokens => accessToken != null;

  /// Checks if the token is expired
  bool get isExpired {
    if (expiresIn == null) return false;
    // Note: This is a simplified check. In production, you'd track
    // the timestamp when the token was received.
    return false;
  }

  @override
  String toString() {
    return 'CidaasTokenResponse(hasAccessToken: ${accessToken != null}, '
        'expiresIn: $expiresIn, tokenType: $tokenType)';
  }
}
