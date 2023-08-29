
import 'flutter_ahamatic_authentication_platform_interface.dart';

class FlutterAhamaticAuthentication {
  Future<String?> getPlatformVersion() {
    return FlutterAhamaticAuthenticationPlatform.instance.getPlatformVersion();
  }
}
