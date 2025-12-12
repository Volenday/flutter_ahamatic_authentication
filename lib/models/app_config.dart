/// Application environment configuration
class EnvironmentConfig {
  final String apiUrl;
  final String portalUrl;

  const EnvironmentConfig({
    required this.apiUrl,
    required this.portalUrl,
  });

  /// Gets the configuration based on the environment
  factory EnvironmentConfig.fromEnvironment(String environment, bool europe) {
    final apiUrls = {
      'development': 'https://dev.api.ahamatic.com',
      'sandbox': 'https://test.api.ahamatic.com',
      'production': 'https://api-eu.ahamatic.com',
    };

    final portalUrlsEurope = {
      'development': 'https://dev.auth-eu.ahamatic.com',
      'sandbox': 'https://test.auth-eu.ahamatic.com',
      'production': 'https://auth-eu.ahamatic.com',
    };

    final portalUrlsNonEurope = {
      'development': 'https://dev.auth.ahamatic.com',
      'sandbox': 'https://test.auth.ahamatic.com',
      'production': 'https://auth.ahamatic.com',
    };

    final portalUrls = europe ? portalUrlsEurope : portalUrlsNonEurope;

    return EnvironmentConfig(
      apiUrl: apiUrls[environment] ?? apiUrls['production']!,
      portalUrl: portalUrls[environment] ?? portalUrls['production']!,
    );
  }
}

/// Module authentication configuration
class ModuleAuthConfig {
  final String? apiKey;
  final bool isCidaasEnabled;
  final bool isOpeniamEnabled;
  final String? openIamLogo;
  final String? openIamTitle;
  final String? hostName;

  const ModuleAuthConfig({
    this.apiKey,
    this.isCidaasEnabled = false,
    this.isOpeniamEnabled = false,
    this.openIamLogo,
    this.openIamTitle,
    this.hostName,
  });

  /// Creates an empty/default configuration
  factory ModuleAuthConfig.empty() => const ModuleAuthConfig();
}

/// Application validation response
class AppValidationResponse {
  final String name;
  final ModuleAuthConfig moduleConfig;

  const AppValidationResponse({
    required this.name,
    required this.moduleConfig,
  });
}

/// Parameters to generate OpenIAM login URL
class OpenIamLoginParams {
  final String applicationCode;
  final String? moduleName;
  final String? moduleWebName;
  final String? hostName;
  final String portalUrl;
  final String? authenticationStatus;
  final String? currentWebUrl;

  const OpenIamLoginParams({
    required this.applicationCode,
    this.moduleName,
    this.moduleWebName,
    this.hostName,
    required this.portalUrl,
    this.authenticationStatus,
    this.currentWebUrl,
  });
}
