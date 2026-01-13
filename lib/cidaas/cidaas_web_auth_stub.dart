/// Legacy export file for backwards compatibility.
///
/// @deprecated Use `import 'package:flutter_ahamatic_authentication/cidaas/services/cidaas_web_auth_service_stub.dart'` instead.
library cidaas_web_auth_stub;

export 'models/cidaas_configuration.dart';
export 'models/ahamatic_response.dart';
export 'models/cidaas_token_response.dart';
export 'models/cidaas_web_auth_result.dart';
export 'services/cidaas_web_auth_service_stub.dart';

// Backwards compatibility alias
import 'services/cidaas_web_auth_service_stub.dart';

/// @deprecated Use [CidaasWebAuthService] instead.
typedef CidaasWebAuth = CidaasWebAuthService;
