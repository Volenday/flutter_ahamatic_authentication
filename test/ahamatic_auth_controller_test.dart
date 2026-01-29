import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ahamatic_authentication/flutter_ahamatic_authentication.dart';

void main() {
  group('AhamaticAuthController', () {
    late AhamaticAuthController controller;

    setUp(() {
      controller = AhamaticAuthController();
    });

    test('launchOpenIamLogin does nothing when callbacks not set', () {
      expect(
        () => controller.launchOpenIamLogin(),
        returnsNormally,
      );
    });

    test('launchCidaasLogin does nothing when callbacks not set', () {
      expect(
        () => controller.launchCidaasLogin(),
        returnsNormally,
      );
    });

    test('setLaunchCallbacks stores OpenIAM callback', () {
      var openIamCalled = false;
      controller.setLaunchCallbacks(() => openIamCalled = true, null);

      controller.launchOpenIamLogin();

      expect(openIamCalled, isTrue);
    });

    test('setLaunchCallbacks stores Cidaas callback when provided', () {
      var cidaasCalled = false;
      controller.setLaunchCallbacks(
        () {},
        () => cidaasCalled = true,
      );

      controller.launchCidaasLogin();

      expect(cidaasCalled, isTrue);
    });

    test('launchCidaasLogin does nothing when Cidaas callback was null', () {
      var openIamCalled = false;
      controller.setLaunchCallbacks(() => openIamCalled = true, null);

      controller.launchCidaasLogin();

      expect(openIamCalled, isFalse);
    });

    test('both callbacks can be invoked independently', () {
      var openIamCount = 0;
      var cidaasCount = 0;
      controller.setLaunchCallbacks(
        () => openIamCount++,
        () => cidaasCount++,
      );

      controller.launchOpenIamLogin();
      controller.launchOpenIamLogin();
      controller.launchCidaasLogin();

      expect(openIamCount, 2);
      expect(cidaasCount, 1);
    });

    test('setLaunchCallbacks overwrites previous callbacks', () {
      var firstCalled = false;
      var secondCalled = false;
      controller.setLaunchCallbacks(() => firstCalled = true, null);
      controller.setLaunchCallbacks(() => secondCalled = true, null);

      controller.launchOpenIamLogin();

      expect(firstCalled, isFalse);
      expect(secondCalled, isTrue);
    });
  });
}
