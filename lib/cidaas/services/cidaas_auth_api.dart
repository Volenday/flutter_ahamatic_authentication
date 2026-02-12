import 'package:flutter_appauth/flutter_appauth.dart';

/// Abstract interface for Cidaas authentication operations.
///
/// Defines the contract for authentication implementations
/// that can be used across different platforms.
abstract interface class CidaasAuthApi {
  /// Signs in the user using Cidaas OAuth2 flow.
  ///
  /// [apiKey] - The API key for Ahamatic authentication
  /// [apiUrl] - The base URL of the Ahamatic API
  /// [clientIdOverride] - Optional client ID to use instead of config's effective client ID
  ///   (e.g. [CidaasConfiguration.clientId] for classic, [CidaasConfiguration.cidaasClientIdMitID] for MitID).
  ///
  /// Returns a [TokenResponse] containing the authentication tokens.
  Future<TokenResponse> signInWithCidaas(
    String apiKey,
    String apiUrl, {
    String? clientIdOverride,
  });

  /// Signs out the user from Cidaas.
  ///
  /// [idToken] - The ID token from the current session (optional but recommended)
  Future<void> signOut(String? idToken);
}
