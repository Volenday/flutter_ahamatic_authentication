/// Cidaas Authentication Library
///
/// This library provides OAuth2 authentication with Cidaas for Flutter
/// applications on both mobile and web platforms.
///
/// ## Structure
///
/// - **models/** - Data models and entities
///   - [CidaasConfiguration] - OAuth2 configuration
///   - [AhamaticResponse] - Token response from Ahamatic
///   - [CidaasTokenResponse] - Token response from Cidaas
///   - [CidaasWebAuthResult] - Web auth flow result
///   - [AuthSuccessCallback], [AuthErrorCallback] - Callback types
///
/// - **services/** - Authentication services
///   - [CidaasAuthApi] - Abstract interface for auth operations
///   - [CidaasMobileAuthService] - Mobile implementation (flutter_appauth)
///   - [CidaasWebAuthService] - Web implementation (OAuth2 + PKCE)
///   - [AhamaticTokenService] - Ahamatic token operations
///
/// - **utils/** - Utility functions
///   - [PkceUtils] - PKCE code generation utilities
///
/// ## Usage
///
/// ```dart
/// import 'package:flutter_ahamatic_authentication/cidaas/cidaas.dart';
///
/// final config = CidaasConfiguration(
///   clientId: 'your-client-id',
///   issuer: 'https://your-tenant.cidaas.eu',
///   redirectUri: 'app://callback',
///   postLogoutRedirectUri: 'app://logout',
///   discoveryUrl: 'https://your-tenant.cidaas.eu/.well-known/openid-configuration',
///   scopes: ['openid', 'profile', 'email'],
/// );
/// ```
library cidaas;

// Models
export 'models/models.dart';

// Services (non-web)
export 'services/cidaas_auth_api.dart';
export 'services/cidaas_mobile_auth_service.dart';
export 'services/ahamatic_token_service.dart';

// Utils
export 'utils/utils.dart';

// Web service is exported conditionally - import directly when needed:
// import 'package:flutter_ahamatic_authentication/cidaas/services/cidaas_web_auth_service.dart';
