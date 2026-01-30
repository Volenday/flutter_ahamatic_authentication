/// Configuration for Cidaas OAuth2 authentication.
///
/// Contains all the necessary parameters to configure the Cidaas
/// authentication flow for both mobile and web platforms.
class CidaasConfiguration {
  /// The client ID registered in Cidaas
  final String clientId;

  /// The issuer URL (e.g., 'https://your-tenant.cidaas.eu')
  final String issuer;

  /// Redirect URI for mobile platforms (custom scheme)
  final String redirectUri;

  /// Post-logout redirect URI for mobile platforms
  final String postLogoutRedirectUri;

  /// OpenID Connect discovery URL
  final String discoveryUrl;

  /// OAuth2 scopes to request
  final List<String> scopes;

  /// Redirect URI for web platforms (http/https)
  final String? redirectWebUri;

  /// Post-logout redirect URI for web platforms
  final String? postLogoutWebUri;

  /// Additional custom parameters for the authorization request
  final Map<String, String>? customParameter;

  /// Optional Cidaas client ID for MitID. When non-empty, this value is used
  /// instead of [clientId] for the Cidaas flow. When null or empty, [clientId] is used.
  final String? cidaasClientIdMitID;

  /// Client ID used in the Cidaas flow. If [cidaasClientIdMitID] is non-empty,
  /// that value is used (MitID); otherwise [clientId].
  String get effectiveClientId {
    final mitId = cidaasClientIdMitID?.trim();
    return (mitId != null && mitId.isNotEmpty) ? mitId : clientId;
  }

  CidaasConfiguration({
    required this.clientId,
    required this.issuer,
    required this.redirectUri,
    required this.postLogoutRedirectUri,
    required this.discoveryUrl,
    required this.scopes,
    this.redirectWebUri,
    this.postLogoutWebUri,
    this.customParameter,
    this.cidaasClientIdMitID,
  });

  @override
  String toString() {
    return 'CidaasConfiguration(clientId: $clientId, issuer: $issuer, '
        'redirectUri: $redirectUri, scopes: $scopes)';
  }
}
