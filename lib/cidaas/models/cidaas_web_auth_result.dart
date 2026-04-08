/// Result from the web OAuth2 authorization flow.
///
/// Contains the authorization code and PKCE parameters
/// needed to complete the token exchange.
class CidaasWebAuthResult {
  /// The authorization code received from Cidaas
  final String authorizationCode;

  /// The PKCE code verifier used for this auth flow
  final String codeVerifier;

  /// The state parameter used for CSRF protection
  final String state;

  CidaasWebAuthResult({
    required this.authorizationCode,
    required this.codeVerifier,
    required this.state,
  });

  @override
  String toString() {
    return 'CidaasWebAuthResult(code: ${authorizationCode.substring(0, 10)}..., '
        'state: $state)';
  }
}
