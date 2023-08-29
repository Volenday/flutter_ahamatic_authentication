import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ahamatic_authentication/flutter_ahamatic_authentication.dart';
import 'package:flutter_ahamatic_authentication/flutter_ahamatic_authentication_platform_interface.dart';
import 'package:flutter_ahamatic_authentication/flutter_ahamatic_authentication_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockFlutterAhamaticAuthenticationPlatform
    with MockPlatformInterfaceMixin
    implements FlutterAhamaticAuthenticationPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final FlutterAhamaticAuthenticationPlatform initialPlatform = FlutterAhamaticAuthenticationPlatform.instance;

  test('$MethodChannelFlutterAhamaticAuthentication is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelFlutterAhamaticAuthentication>());
  });

  test('getPlatformVersion', () async {
    FlutterAhamaticAuthentication flutterAhamaticAuthenticationPlugin = FlutterAhamaticAuthentication();
    MockFlutterAhamaticAuthenticationPlatform fakePlatform = MockFlutterAhamaticAuthenticationPlatform();
    FlutterAhamaticAuthenticationPlatform.instance = fakePlatform;

    expect(await flutterAhamaticAuthenticationPlugin.getPlatformVersion(), '42');
  });
}
