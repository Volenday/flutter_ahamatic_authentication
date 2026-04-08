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

    test('launchMitIdLogin does nothing when callbacks not set', () {
      expect(
        () => controller.launchMitIdLogin(),
        returnsNormally,
      );
    });

    test('setLaunchCallbacks stores OpenIAM callback', () {
      var openIamCalled = false;
      controller.setLaunchCallbacks(() => openIamCalled = true);

      controller.launchOpenIamLogin();

      expect(openIamCalled, isTrue);
    });

    test('setLaunchCallbacks stores Cidaas callback when provided', () {
      var cidaasCalled = false;
      controller.setLaunchCallbacks(
        () {},
        cidaasLogin: () => cidaasCalled = true,
      );

      controller.launchCidaasLogin();

      expect(cidaasCalled, isTrue);
    });

    test('setLaunchCallbacks stores MitID callback when provided', () {
      var mitIdCalled = false;
      controller.setLaunchCallbacks(
        () {},
        mitIdLogin: () => mitIdCalled = true,
      );

      controller.launchMitIdLogin();

      expect(mitIdCalled, isTrue);
    });

    test('launchCidaasLogin does nothing when Cidaas callback was null', () {
      var openIamCalled = false;
      controller.setLaunchCallbacks(() => openIamCalled = true);

      controller.launchCidaasLogin();

      expect(openIamCalled, isFalse);
    });

    test('launchMitIdLogin does nothing when MitID callback was null', () {
      var openIamCalled = false;
      controller.setLaunchCallbacks(() => openIamCalled = true);

      controller.launchMitIdLogin();

      expect(openIamCalled, isFalse);
    });

    test('both callbacks can be invoked independently', () {
      var openIamCount = 0;
      var cidaasCount = 0;
      controller.setLaunchCallbacks(
        () => openIamCount++,
        cidaasLogin: () => cidaasCount++,
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
      controller.setLaunchCallbacks(() => firstCalled = true);
      controller.setLaunchCallbacks(() => secondCalled = true);

      controller.launchOpenIamLogin();

      expect(firstCalled, isFalse);
      expect(secondCalled, isTrue);
    });
  });
}
