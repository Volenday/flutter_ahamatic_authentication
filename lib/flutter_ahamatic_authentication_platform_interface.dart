import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'flutter_ahamatic_authentication_method_channel.dart';

abstract class FlutterAhamaticAuthenticationPlatform extends PlatformInterface {
  /// Constructs a FlutterAhamaticAuthenticationPlatform.
  FlutterAhamaticAuthenticationPlatform() : super(token: _token);

  static final Object _token = Object();

  static FlutterAhamaticAuthenticationPlatform _instance = MethodChannelFlutterAhamaticAuthentication();

  /// The default instance of [FlutterAhamaticAuthenticationPlatform] to use.
  ///
  /// Defaults to [MethodChannelFlutterAhamaticAuthentication].
  static FlutterAhamaticAuthenticationPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [FlutterAhamaticAuthenticationPlatform] when
  /// they register themselves.
  static set instance(FlutterAhamaticAuthenticationPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
