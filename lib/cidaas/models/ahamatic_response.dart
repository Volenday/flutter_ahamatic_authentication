/// Response containing tokens from Ahamatic authentication.
///
/// This class holds the tokens received after successfully
/// authenticating with the Ahamatic API.
class AhamaticResponse {
  /// The access token for API calls
  final String? accessToken;

  /// The refresh token for obtaining new access tokens
  final String? refreshToken;

  /// The ID token containing user identity information
  final String? idToken;

  AhamaticResponse({
    this.accessToken,
    this.refreshToken,
    this.idToken,
  });

  /// Creates an empty response with all null tokens
  factory AhamaticResponse.empty() => AhamaticResponse();

  /// Checks if the response contains valid tokens
  bool get hasTokens =>
      accessToken != null || refreshToken != null || idToken != null;

  @override
  String toString() {
    return 'AhamaticResponse(hasAccessToken: ${accessToken != null}, '
        'hasRefreshToken: ${refreshToken != null}, '
        'hasIdToken: ${idToken != null})';
  }
}
