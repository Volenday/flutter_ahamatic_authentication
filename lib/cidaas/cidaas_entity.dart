class CidaasConfiguration {
  final String clientId;
  final String issuer;
  final String redirectUri;
  final String postLogoutRedirectUri;
  final String discoveryUrl;
  final List<String> scopes;

  CidaasConfiguration({
    required this.clientId,
    required this.issuer,
    required this.redirectUri,
    required this.postLogoutRedirectUri,
    required this.discoveryUrl,
    required this.scopes,
  });
}

typedef AuthSuccessCallback = void Function({
  String? accessToken,
  String? refreshToken,
  String? idToken,
});

typedef AuthErrorCallback = void Function(String errorMessage);
