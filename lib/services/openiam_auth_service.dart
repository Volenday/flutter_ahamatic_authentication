import 'package:flutter/foundation.dart';
import 'package:flutter_ahamatic_authentication/models/app_config.dart';
import 'package:flutter_ahamatic_authentication/services/platform_service.dart';

/// Interface for the OpenIAM authentication service
abstract class OpenIamAuthService {
  /// Generates the login URL for native apps (Android/iOS)
  String? generateNativeLoginUrl(OpenIamLoginParams params);

  /// Generates the login URL for web
  String? generateWebLoginUrl(OpenIamLoginParams params);

  /// Generates the login URL based on the platform
  String? generateLoginUrl(OpenIamLoginParams params, {required bool isWeb});
}

/// Implementation of the OpenIAM authentication service
class OpenIamAuthServiceImpl implements OpenIamAuthService {
  OpenIamAuthServiceImpl();

  @override
  String? generateLoginUrl(OpenIamLoginParams params, {required bool isWeb}) {
    if (isWeb) {
      return generateWebLoginUrl(params);
    } else {
      return generateNativeLoginUrl(params);
    }
  }

  @override
  String? generateNativeLoginUrl(OpenIamLoginParams params) {
    debugPrint('OpenIamAuthService: Generating native login URL');

    if (params.hostName == null || params.moduleName == null) {
      debugPrint('OpenIamAuthService: Missing hostName or moduleName');
      return null;
    }

    try {
      final scheme = PlatformService.isAndroid
          ? 'app://${params.hostName}'
          : '${params.hostName}://';

      final loginUrl = '${params.portalUrl}/client/${params.applicationCode}'
          '?redirect=$scheme/callback'
          '&origin=website'
          '&module=${params.moduleName}';

      debugPrint('OpenIamAuthService: Generated native URL: $loginUrl');
      return loginUrl;
    } catch (e) {
      debugPrint('OpenIamAuthService: Error generating native URL: $e');
      return null;
    }
  }

  @override
  String? generateWebLoginUrl(OpenIamLoginParams params) {
    debugPrint('OpenIamAuthService: Generating web login URL');

    if (params.hostName == null ||
        params.moduleWebName == null ||
        params.currentWebUrl == null) {
      debugPrint('OpenIamAuthService: Missing required params for web URL');
      return null;
    }

    try {
      final uri = Uri.parse(params.currentWebUrl!);
      final baseUrl = '${uri.scheme}://${uri.host}:${uri.port}';
      final callback = params.currentWebUrl!.contains('localhost')
          ? baseUrl
          : 'https://${params.hostName}';

      String loginUrl;

      if (params.authenticationStatus == 'unauthenticated') {
        // Logout URL
        loginUrl = '${params.portalUrl}/logout/${params.applicationCode}'
            '?redirect=$callback/callback?redirect='
            '&origin=website'
            '&logout=true';
        debugPrint('OpenIamAuthService: Generated logout URL');
      } else {
        // Login URL
        loginUrl = '${params.portalUrl}/client/${params.applicationCode}'
            '?redirect=$callback/callback?redirect='
            '&origin=website'
            '&module=${params.moduleWebName}';
        debugPrint('OpenIamAuthService: Generated login URL');
      }

      debugPrint('OpenIamAuthService: Generated web URL: $loginUrl');
      return loginUrl;
    } catch (e) {
      debugPrint('OpenIamAuthService: Error generating web URL: $e');
      return null;
    }
  }
}
