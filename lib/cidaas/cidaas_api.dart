/// Legacy export file for backwards compatibility.
///
/// @deprecated Use the new modular imports:
/// - `import 'package:flutter_ahamatic_authentication/cidaas/services/cidaas_auth_api.dart'`
/// - `import 'package:flutter_ahamatic_authentication/cidaas/services/cidaas_mobile_auth_service.dart'`
library cidaas_api;

export 'models/cidaas_configuration.dart';
export 'models/ahamatic_response.dart';
export 'services/cidaas_auth_api.dart';
export 'services/cidaas_mobile_auth_service.dart';

// Backwards compatibility alias
import 'services/cidaas_mobile_auth_service.dart';

/// @deprecated Use [CidaasMobileAuthService] instead.
typedef CidaasAuthApiImpl = CidaasMobileAuthService;
