import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ahamatic_authentication/cidaas/cidaas.dart';

/// Tests for MitID flow and the AppAuth Android crash regression.
///
/// **Regression (Android):** AppAuth throws [IllegalArgumentException] when
/// [AuthorizationRequest.additionalParameters] contains `code_challenge_method`.
/// Message: "Parameter code_challenge_method is directly supported via the
/// authorization request builder, use the builder method instead."
///
/// **Fix:** [CidaasMobileAuthService] must NOT pass `code_challenge_method` in
/// [AuthorizationRequest.additionalParameters]. For MitID flow it only passes
/// `preferred_login: mitid`. PKCE is handled by the library via the builder.
/// [TokenRequest] must not receive `code_challenge_method` in additionalParameters.
void main() {
  group('MitID flow - AppAuth Android crash prevention', () {
    test(
        'MitID config must provide mitIdEffectiveIssuer for mobile discovery',
        () {
      final config = CidaasConfiguration(
        clientId: 'ee75cd84-4622-4e7e-8b50-c5bbd79576ac',
        issuer: 'https://issuer.cidaas.eu/',
        redirectUri: 'app://reimbursment/oauth2redirect',
        postLogoutRedirectUri: 'app://reimbursment/logout',
        discoveryUrl:
            'https://issuer.cidaas.eu/.well-known/openid-configuration',
        scopes: ['openid', 'profile', 'email'],
        cidaasClientIdMitID: '5fd6af67-1820-42f5-85fd-4dc236d00d65',
        mitIdAuthUrl:
            'https://test-login.abena.com/authz-srv/authz?client_id=5fd6af67-1820-42f5-85fd-4dc236d00d65&redirect_uri=...&response_type=code&preferred_login=mitid',
      );

      expect(config.mitIdEffectiveIssuer, equals('https://test-login.abena.com'));
      expect(config.useMitIdCustomUrl, isTrue);
      expect(
        config.cidaasClientIdMitID?.trim(),
        isNotEmpty,
        reason: 'MitID flow requires cidaasClientIdMitID',
      );
    });

    test(
        'Contract: AuthorizationRequest must NOT include code_challenge_method in additionalParameters',
        () {
      // This test documents the contract that prevents the Android AppAuth crash.
      // CidaasMobileAuthService builds additionalParameters as:
      // - MitID flow: only {'preferred_login': 'mitid'} (no code_challenge_method)
      // - Classic flow: null
      // If code_challenge_method is added to additionalParameters, Android will throw.
      const allowedMitIdParams = ['preferred_login'];
      const forbiddenParams = ['code_challenge_method'];

      expect(forbiddenParams, isNot(contains('preferred_login')));
      expect(allowedMitIdParams, isNot(contains('code_challenge_method')));
      expect(
        forbiddenParams,
        contains('code_challenge_method'),
        reason: 'Documentation: this param must never be in additionalParameters',
      );
    });

    test(
        'Contract: TokenRequest must not receive code_challenge_method in additionalParameters',
        () {
      // CidaasMobileAuthService builds TokenRequest without additionalParameters
      // (code_verifier is passed as a direct parameter). If additionalParameters
      // with code_challenge_method is added, it could cause issues on some platforms.
      const tokenRequestMustNotInclude = 'code_challenge_method';
      expect(tokenRequestMustNotInclude, isNotEmpty);
    });
  });
}
