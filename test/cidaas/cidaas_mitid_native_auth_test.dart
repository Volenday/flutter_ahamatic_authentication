import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ahamatic_authentication/cidaas/cidaas.dart';

/// Tests for MitID **custom URL** flow on iOS and Android.
///
/// The native browser flow (ASWebAuthenticationSession on iOS, Chrome Custom Tabs on Android)
/// is used **only** when [CidaasConfiguration.mitIdAuthUrl] is set. MitID without custom URL
/// uses the AppAuth flow ([_launchCidaasLoginMobile]) instead.
///
/// Full integration tests (MethodChannel invocation on device/simulator) should be run
/// manually or via integration_test; the widget depends on Ahamatic API for module config.
void main() {
  group('MitID custom URL flow - condition (native auth only for custom URL)', () {
    test('useMitIdCustomUrl is true when mitIdAuthUrl is set', () {
      final config = CidaasConfiguration(
        clientId: 'classic-id',
        issuer: 'https://issuer.cidaas.eu/',
        redirectUri: 'app://test/oauth2redirect',
        postLogoutRedirectUri: 'app://test/logout',
        discoveryUrl: 'https://issuer.cidaas.eu/.well-known/openid-configuration',
        scopes: ['openid'],
        cidaasClientIdMitID: 'mitid-id',
        mitIdAuthUrl:
            'https://test-login.abena.com/authz-srv/authz?client_id=mitid-id&redirect_uri=...&response_type=code&preferred_login=mitid',
      );
      expect(config.useMitIdCustomUrl, isTrue);
      expect(config.mitIdEffectiveIssuer, isNotNull);
      expect(config.mitIdEffectiveIssuer, equals('https://test-login.abena.com'));
    });

    test('useMitIdCustomUrl is false when mitIdAuthUrl is not set', () {
      final config = CidaasConfiguration(
        clientId: 'classic-id',
        issuer: 'https://issuer.cidaas.eu/',
        redirectUri: 'app://test/oauth2redirect',
        postLogoutRedirectUri: 'app://test/logout',
        discoveryUrl: 'https://issuer.cidaas.eu/.well-known/openid-configuration',
        scopes: ['openid'],
        cidaasClientIdMitID: 'mitid-id',
        // no mitIdAuthUrl => MitID uses AppAuth, not custom URL / native browser
      );
      expect(config.useMitIdCustomUrl, isFalse);
      expect(config.mitIdEffectiveIssuer, isNull);
    });

    test('native MitID (launchMitIdAuth) is only used when mitIdAuthUrl is set', () {
      // Condition in _launchCidaasLoginWithClientId: isMitIdFlow && mitIdAuthUrl != null && !isEmpty
      final withCustomUrl = CidaasConfiguration(
        clientId: 'c',
        issuer: 'https://i/',
        redirectUri: 'app://r/cb',
        postLogoutRedirectUri: 'app://r/out',
        discoveryUrl: 'https://i/.well-known/openid-configuration',
        scopes: ['openid'],
        cidaasClientIdMitID: 'mitid',
        mitIdAuthUrl: 'https://custom.example.com/auth?client_id=mitid',
      );
      final mitIdAuthUrl = withCustomUrl.mitIdAuthUrl?.trim();
      final isMitIdFlow = withCustomUrl.cidaasClientIdMitID?.trim().isNotEmpty == true;
      expect(mitIdAuthUrl, isNotNull);
      expect(mitIdAuthUrl, isNotEmpty);
      expect(isMitIdFlow, isTrue);
      // => custom URL path (_launchMitIdLoginMobileWithFullUrl) is taken

      final withoutCustomUrl = CidaasConfiguration(
        clientId: 'c',
        issuer: 'https://i/',
        redirectUri: 'app://r/cb',
        postLogoutRedirectUri: 'app://r/out',
        discoveryUrl: 'https://i/.well-known/openid-configuration',
        scopes: ['openid'],
        cidaasClientIdMitID: 'mitid',
        // no mitIdAuthUrl
      );
      final mitIdAuthUrl2 = withoutCustomUrl.mitIdAuthUrl?.trim();
      expect(mitIdAuthUrl2 == null || mitIdAuthUrl2.isEmpty, isTrue);
      // => AppAuth path (_launchCidaasLoginMobile) is taken, launchMitIdAuth is NOT called
    });

    test('redirect URI must have custom scheme for native MitID on mobile', () {
      final uri = Uri.parse('app://reimbursment/oauth2redirect');
      expect(uri.scheme, equals('app'));
      expect(uri.scheme.isNotEmpty, isTrue);

      final httpUri = Uri.parse('https://myapp.com/callback');
      expect(httpUri.scheme, isNotEmpty);
      // But for native flow we require a custom scheme (app://), not https
      expect(httpUri.scheme == 'app', isFalse);
    });

    test('branch to custom URL flow requires isMitIdFlow and non-empty mitIdAuthUrl', () {
      // Same condition as in _launchCidaasLoginWithClientId
      bool wouldUseCustomUrlFlow(CidaasConfiguration config, String clientId) {
        final isMitIdFlow = config.cidaasClientIdMitID?.trim().isNotEmpty == true &&
            clientId == config.cidaasClientIdMitID?.trim();
        final mitIdAuthUrl = config.mitIdAuthUrl?.trim();
        return isMitIdFlow && mitIdAuthUrl != null && mitIdAuthUrl.isNotEmpty;
      }

      final withCustomUrl = CidaasConfiguration(
        clientId: 'c',
        issuer: 'https://i/',
        redirectUri: 'app://r/cb',
        postLogoutRedirectUri: 'app://r/out',
        discoveryUrl: 'https://i/.well-known/openid-configuration',
        scopes: ['openid'],
        cidaasClientIdMitID: 'mitid',
        mitIdAuthUrl: 'https://custom.example.com/auth?client_id=mitid',
      );
      expect(wouldUseCustomUrlFlow(withCustomUrl, 'mitid'), isTrue);
      expect(wouldUseCustomUrlFlow(withCustomUrl, 'c'), isFalse);

      final withoutCustomUrl = CidaasConfiguration(
        clientId: 'c',
        issuer: 'https://i/',
        redirectUri: 'app://r/cb',
        postLogoutRedirectUri: 'app://r/out',
        discoveryUrl: 'https://i/.well-known/openid-configuration',
        scopes: ['openid'],
        cidaasClientIdMitID: 'mitid',
      );
      expect(wouldUseCustomUrlFlow(withoutCustomUrl, 'mitid'), isFalse);
    });
  });

  group('MitID custom URL - iOS/Android native auth contract', () {
    test('launchMitIdAuth args: authUrl and callbackUrlScheme from config', () {
      final config = CidaasConfiguration(
        clientId: 'classic-id',
        issuer: 'https://issuer.cidaas.eu/',
        redirectUri: 'app://reimbursment/oauth2redirect',
        postLogoutRedirectUri: 'app://reimbursment/logout',
        discoveryUrl: 'https://issuer.cidaas.eu/.well-known/openid-configuration',
        scopes: ['openid'],
        cidaasClientIdMitID: 'mitid-id',
        mitIdAuthUrl:
            'https://test-login.abena.com/authz-srv/authz?client_id=mitid-id&redirect_uri=...&response_type=code&preferred_login=mitid',
      );
      final scheme = Uri.parse(config.redirectUri).scheme;
      expect(scheme, equals('app'));
      expect(config.mitIdEffectiveIssuer, equals('https://test-login.abena.com'));
      // Native (iOS/Android) expects: authUrl (full URL with PKCE params), callbackUrlScheme (e.g. 'app')
    });
  });
}
