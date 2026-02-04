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

  /// Optional full authorization URL for MitID login.
  /// When set, this URL is used for MitID instead of building from [issuer].
  /// - **Web**: redirects to this URL with PKCE params (code_challenge, code_challenge_method, state) added.
  /// - **Mobile**: the issuer for discovery is derived from this URL origin (e.g. https://test-login.abena.com).
  /// Example: https://test-login.abena.com/authz-srv/authz?client_id=...&redirect_uri=...&response_type=code&preferred_login=mitid
  final String? mitIdAuthUrl;

  /// Optional issuer for MitID when using a different auth server (e.g. https://test-login.abena.com).
  /// When [mitIdAuthUrl] is set and this is null, the issuer is derived from [mitIdAuthUrl] (URL origin).
  /// Used on mobile for discovery URL and token exchange.
  final String? mitIdIssuer;

  /// Client ID used in the Cidaas flow. If [cidaasClientIdMitID] is non-empty,
  /// that value is used (MitID); otherwise [clientId].
  String get effectiveClientId {
    final mitId = cidaasClientIdMitID?.trim();
    return (mitId != null && mitId.isNotEmpty) ? mitId : clientId;
  }

  /// Whether MitID flow should use a custom auth URL (web) or issuer (mobile).
  bool get useMitIdCustomUrl =>
      (mitIdAuthUrl?.trim().isNotEmpty ?? false) ||
      (mitIdIssuer?.trim().isNotEmpty ?? false);

  /// Issuer to use for MitID flow. Prefers [mitIdIssuer], else derived from [mitIdAuthUrl] origin.
  String? get mitIdEffectiveIssuer {
    if (mitIdIssuer?.trim().isNotEmpty == true) return mitIdIssuer!.trim();
    final url = mitIdAuthUrl?.trim();
    if (url == null || url.isEmpty) return null;
    try {
      final uri = Uri.parse(url);
      return uri.origin;
    } catch (_) {
      return null;
    }
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
    this.mitIdAuthUrl,
    this.mitIdIssuer,
  });

  @override
  String toString() {
    return 'CidaasConfiguration(clientId: $clientId, issuer: $issuer, '
        'redirectUri: $redirectUri, scopes: $scopes)';
  }
}
