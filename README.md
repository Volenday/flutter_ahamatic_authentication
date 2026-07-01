# Flutter Ahamatic Authentication

[![Flutter](https://img.shields.io/badge/Flutter-3.3+-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.1+-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Web-lightgrey)](https://flutter.dev)

A Flutter plugin that provides a seamless authentication interface for Ahamatic-powered applications. Supports multiple authentication providers including **OpenIAM** and **Cidaas**.

---

## ✨ Features

- 🔐 **OpenIAM Authentication** - Native deep link integration
- 🌐 **Cidaas OAuth2** - Full PKCE flow support for mobile and web
- 🎨 **Customizable UI** - Project logo and name
- 📱 **Mobile Ready** - Android & iOS support
- 🌍 **Web Support** - OAuth2 redirect flow with PKCE
- 🔄 **Token Management** - Access, Refresh, and ID tokens
- 🚪 **Logout Support** - Session invalidation on Cidaas
- ⚡ **Easy Integration** - Simple widget-based API

---

## Native platform requirements

| Platform | Package minimum | Recommended for new integrations |
|----------|-----------------|----------------------------------|
| Dart / Flutter API | Flutter **≥ 3.3.0**, Dart **≥ 3.1.0** | Latest stable Flutter |
| Android | Built-in Kotlin migration (no explicit `kotlin-android` in plugin `build.gradle`; works with AGP &lt; 9 and AGP ≥ 9) | [Built-in Kotlin guide](https://docs.flutter.dev/release/breaking-changes/migrate-to-built-in-kotlin/for-app-developers) |
| iOS (CocoaPods) | iOS 12.0+ | Default Flutter iOS setup |
| iOS (Swift Package Manager) | Flutter **≥ 3.41** in the app with SPM enabled | [SPM for app developers](https://docs.flutter.dev/packages-and-plugins/swift-package-manager/for-app-developers) |

### Upgrading consumer apps (0.0.4+)

1. Update the dependency: `flutter_ahamatic_authentication: ^0.0.4`
2. Run `flutter pub upgrade` and rebuild.
3. **Android:** After upgrade, `flutter_ahamatic_authentication` should no longer appear in the Built-in Kotlin / KGP plugin warning. The unused `fluttertoast` dependency was removed in 0.0.4, and `webview_flutter`/`webview_flutter_android` now resolve to a Built-in Kotlin–compatible version. `device_info_plus` (a real dependency of this plugin) still applies the Kotlin Gradle Plugin upstream as of its latest release, so it will keep showing up in the warning until its maintainers migrate — this is outside our control.
4. **iOS:** With `flutter config --enable-swift-package-manager`, this plugin should no longer appear in the SPM unsupported-plugins warning. Third-party plugins without SPM may still be listed until they migrate or you disable SPM.

---

## 📦 Installation

Add this to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_ahamatic_authentication:
    git:
      url: https://github.com/Volenday/flutter_ahamatic_authentication.git
```

Then run:

```bash
flutter pub get
```

---

## 🚀 Quick Start

```dart
import 'package:flutter_ahamatic_authentication/flutter_ahamatic_authentication.dart';

FlutterAhaAuthentication(
  applicationCode: 'your-app-code',
  environment: 'production', // 'development', 'sandbox', 'production'
  europe: true,
  moduleName: 'your-module',
  onAuthSuccess: ({accessToken, refreshToken, idToken}) {
    print('Authenticated! Token: $accessToken');
  },
  onAuthError: (error) {
    print('Error: $error');
  },
)
```

---

## 📱 Mobile Configuration

### OpenIAM Authentication

For OpenIAM, configure deep links in your native projects:

#### Android (`android/app/src/main/AndroidManifest.xml`)

```xml
<intent-filter>
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="app" android:host="yourAppHost" />
</intent-filter>
```

#### iOS (`ios/Runner/Info.plist`)

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>yourAppHost</string>
        </array>
    </dict>
</array>
```

---

### Cidaas Authentication (Mobile)

For Cidaas OAuth2 on mobile, provide the `CidaasConfiguration`:

```dart
FlutterAhaAuthentication(
  applicationCode: 'your-app-code',
  environment: 'production',
  europe: true,
  moduleName: 'your-module',
  cidaasConfiguration: CidaasConfiguration(
    clientId: 'your-client-id',
    issuer: 'https://your-tenant.cidaas.eu',
    redirectUri: 'app://yourApp/oauth2redirect',
    postLogoutRedirectUri: 'app://yourApp/logout',
    discoveryUrl: 'https://your-tenant.cidaas.eu/.well-known/openid-configuration',
    scopes: ['openid', 'profile', 'email', 'offline_access'],
  ),
  onAuthSuccess: ({accessToken, refreshToken, idToken}) {
    print('Access Token: $accessToken');
  },
  onAuthError: (error) {
    print('Authentication failed: $error');
  },
)
```

#### Android Deep Link Setup

Add to `android/app/build.gradle`:

```gradle
android {
    defaultConfig {
        manifestPlaceholders += [
            'appAuthRedirectScheme': 'app'
        ]
    }
}
```

#### MitID on Android (Chrome Custom Tabs)

On Android, MitID uses **Chrome Custom Tabs** (not an in-app WebView) to avoid keyboard reload issues on physical devices. You must:

1. **Add an intent-filter** for your OAuth redirect URI in `AndroidManifest.xml` (inside your main `<activity>`):

```xml
<intent-filter>
    <action android:name="android.intent.action.VIEW"/>
    <category android:name="android.intent.category.DEFAULT"/>
    <category android:name="android.intent.category.BROWSABLE"/>
    <data android:scheme="app" android:host="yourHost" android:pathPrefix="/oauth2redirect"/>
</intent-filter>
```

Use the same `scheme`, `host`, and path as in your `redirectUri` (e.g. `app://yourHost/oauth2redirect`).

2. **Call `deliverRedirectUri`** from your `MainActivity` when the app receives the redirect (so the plugin can complete the login):

**Kotlin** (`MainActivity.kt`):

```kotlin
import com.volenday.flutter_ahamatic_authentication.FlutterAhamaticAuthenticationPlugin

override fun onNewIntent(intent: Intent) {
  super.onNewIntent(intent)
  intent.data?.toString()?.takeIf { it.startsWith("app://") }?.let { url ->
    FlutterAhamaticAuthenticationPlugin.deliverRedirectUri(url)
  }
}

override fun onCreate(savedInstanceState: Bundle?) {
  super.onCreate(savedInstanceState)
  intent?.data?.toString()?.takeIf { it.startsWith("app://") }?.let { url ->
    FlutterAhamaticAuthenticationPlugin.deliverRedirectUri(url)
  }
}
```

---

## 🌐 Web Configuration

### Setup

1. **Use path URL strategy** (required for OAuth callbacks):

```dart
import 'package:flutter_web_plugins/url_strategy.dart';

void main() {
  usePathUrlStrategy(); // Important for OAuth callbacks
  runApp(const MyApp());
}
```

2. **Configure CidaasConfiguration with web URIs**:

```dart
final cidaasWebConfig = CidaasConfiguration(
  clientId: 'your-web-client-id',
  issuer: 'https://your-tenant.cidaas.eu',
  redirectUri: 'app://yourApp/oauth2redirect', // For mobile fallback
  postLogoutRedirectUri: 'app://yourApp/logout',
  discoveryUrl: 'https://your-tenant.cidaas.eu/.well-known/openid-configuration',
  scopes: ['openid', 'profile', 'email', 'offline_access'],
  // Web-specific URIs
  redirectWebUri: 'http://localhost:8080/callback',
  postLogoutWebUri: 'http://localhost:8080/',
);
```

### Manual Web Authentication Flow

For web, you need to handle the OAuth callback manually:

```dart
import 'package:go_router/go_router.dart';
import 'package:flutter_ahamatic_authentication/cidaas/cidaas_web_auth.dart';
import 'package:flutter_ahamatic_authentication/services/ahamatic_api_service.dart';

// Router setup
final router = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (_, __) => const LoginPage()),
    GoRoute(path: '/callback', builder: (_, __) => const CallbackPage()),
    GoRoute(path: '/home', builder: (_, __) => const HomePage()),
  ],
);

// Callback page to handle OAuth redirect
class CallbackPage extends StatefulWidget {
  const CallbackPage({super.key});

  @override
  State<CallbackPage> createState() => _CallbackPageState();
}

class _CallbackPageState extends State<CallbackPage> {
  @override
  void initState() {
    super.initState();
    _handleCallback();
  }

  Future<void> _handleCallback() async {
    try {
      // 1. Get apiKey from module config
      final ahamaticApiService = AhamaticApiServiceImpl(dio: dio, apiUrl: apiURL);
      final moduleConfig = await ahamaticApiService.getModuleConfig(
        'your-app-code',
        'your-module',
      );
      final apiKey = moduleConfig.apiKey ?? '';

      // 2. Handle OAuth callback
      final cidaasWebAuth = CidaasWebAuth(dio, cidaasConfig, devAccount);
      final authResult = cidaasWebAuth.handleCallback();

      if (authResult == null) {
        // Handle error - no auth code or state mismatch
        return;
      }

      // 3. Exchange code for tokens
      final response = await cidaasWebAuth.signInComplete(
        apiKey,
        apiURL,
        authResult,
      );

      // 4. Use tokens
      final accessToken = response.accessToken;
      final refreshToken = response.refreshToken;
      final idToken = response.idToken;

      context.go('/home');
    } catch (e) {
      print('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
```

### Web Logout

```dart
void logout(String? idToken) {
  final cidaasWebAuth = CidaasWebAuth(dio, cidaasConfig, devAccount);
  cidaasWebAuth.signOut(idToken: idToken);
  // This redirects to Cidaas logout endpoint, then back to postLogoutWebUri
}
```

### Cidaas Admin Configuration

Ensure these URIs are registered in your Cidaas client:

| Setting | Value |
|---------|-------|
| Redirect URIs | `http://localhost:8080/callback` (dev), `https://yourapp.com/callback` (prod) |
| Post Logout Redirect URIs | `http://localhost:8080/` (dev), `https://yourapp.com/` (prod) |

---

## ⚙️ Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `applicationCode` | `String` | ✅ | Your Ahamatic application code |
| `environment` | `String` | ✅ | `'development'`, `'sandbox'`, or `'production'` |
| `europe` | `bool` | ✅ | Use European servers |
| `moduleName` | `String?` | ❌ | Module name for native apps |
| `moduleWebName` | `String?` | ❌ | Module name for web apps |
| `projectName` | `String?` | ❌ | Display name for the project |
| `projectLogoAsset` | `String?` | ❌ | Asset path for project logo |
| `cidaasConfiguration` | `CidaasConfiguration?` | ❌ | Cidaas OAuth2 configuration |
| `onAuthSuccess` | `AuthSuccessCallback?` | ❌ | Called on successful authentication |
| `onAuthError` | `AuthErrorCallback?` | ❌ | Called on authentication error |
| `isLoginButtonOnly` | `bool?` | ❌ | Show only a login button |
| `externalBrowserLogin` | `bool?` | ❌ | Open login in external browser |

### CidaasConfiguration

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `clientId` | `String` | ✅ | OAuth2 client ID |
| `issuer` | `String` | ✅ | Cidaas issuer URL |
| `discoveryUrl` | `String` | ✅ | OpenID Connect discovery URL |
| `scopes` | `List<String>` | ✅ | OAuth2 scopes |
| `redirectUri` | `String` | ✅ | Redirect URI for mobile |
| `postLogoutRedirectUri` | `String` | ✅ | Post logout URI for mobile |
| `redirectWebUri` | `String?` | 🌐 | Redirect URI for web |
| `postLogoutWebUri` | `String?` | 🌐 | Post logout URI for web |
| `customParameter` | `Map<String, String>?` | ❌ | Additional OAuth2 parameters |

---

## 🔄 Authentication Flow

### Mobile Flow (flutter_appauth)

```
1. User taps login button
2. flutter_appauth opens system browser
3. User authenticates on Cidaas
4. Cidaas redirects to app://yourApp/oauth2redirect
5. App receives authorization code
6. App exchanges code for Cidaas tokens
7. App exchanges Cidaas tokens for Ahamatic tokens
8. onAuthSuccess callback with tokens
```

### Web Flow (OAuth2 with PKCE)

```
1. User clicks login button
2. App generates code_verifier and code_challenge
3. App redirects to Cidaas authorization endpoint
4. User authenticates on Cidaas
5. Cidaas redirects to /callback with code
6. CallbackPage exchanges code for Cidaas tokens
7. App exchanges Cidaas tokens for Ahamatic tokens
8. Navigate to authenticated page
```

---

## 🔧 Troubleshooting

### Cidaas: "User cancelled the authentication flow"

This occurs when the user closes the authentication dialog. Handle it in `onAuthError`.

### Deep links not working on Android

Ensure you have added the `appAuthRedirectScheme` to your `build.gradle`:

```gradle
manifestPlaceholders += ['appAuthRedirectScheme': 'app']
```

### Deep links not working on iOS

Verify your URL scheme is correctly added to `Info.plist` and matches your `redirectUri`.

### Web: "State mismatch" error

This occurs when:
- Session storage was cleared between redirect and callback
- User opened multiple login tabs
- The callback URL was bookmarked

Solution: Ensure users complete the flow in a single tab.

### Web: Error 412 on Ahamatic API

This indicates the `apiKey` is missing or invalid. Ensure you're fetching it from `getModuleConfig()` before calling `signInComplete()`.

### Web: Logout doesn't invalidate session

Ensure `http://localhost:8080/` (or your production URL) is registered as a Post Logout Redirect URI in Cidaas.

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

---

<p align="center">
  Made with ❤️ by <a href="https://ahastudio.io">ahaStudio</a>
</p>
