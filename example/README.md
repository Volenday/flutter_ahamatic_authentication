# Flutter Ahamatic Authentication - Example

This example demonstrates how to use the `flutter_ahamatic_authentication` plugin with Cidaas OAuth2 authentication on both **mobile** and **web** platforms.

## 🚀 Running the Example

### Web

```bash
cd example
flutter run -d chrome --web-port=8080
```

> **Important:** Use `--web-port=8080` to match the configured `redirectWebUri`.

### Android

```bash
cd example
flutter run -d android
```

### iOS

```bash
cd example
flutter run -d ios
```

---

## 📁 Project Structure

```
example/
├── lib/
│   └── main.dart          # Main example with login, callback, and home pages
├── android/
│   └── app/
│       └── build.gradle   # Android config with appAuthRedirectScheme
└── ios/
    └── Runner/
        └── Info.plist     # iOS URL scheme configuration
```

---

## 🔑 Configuration

### Environment Variables

The example uses these configurations in `main.dart`:

```dart
const environment = "development";  // development, sandbox, production
const apiURL = 'https://api-eu.ahamatic.com';

// Dev account for Ahamatic API authentication
const devAccount = {
  'emailAddress': 'developers@volenday.com',
  'password': 'your-password',
};
```

### Cidaas Configuration

```dart
// Mobile configuration
final cidaasMobileConfig = CidaasConfiguration(
  clientId: 'your-mobile-client-id',
  issuer: 'https://your-tenant.cidaas.eu',
  redirectUri: 'app://yourApp/oauth2redirect',
  postLogoutRedirectUri: 'app://yourApp/logout',
  discoveryUrl: 'https://your-tenant.cidaas.eu/.well-known/openid-configuration',
  scopes: ['openid', 'profile', 'email', 'offline_access'],
);

// Web configuration
final cidaasWebConfig = CidaasConfiguration(
  clientId: 'your-web-client-id',
  issuer: 'https://your-tenant.cidaas.eu',
  redirectUri: 'app://yourApp/oauth2redirect',
  postLogoutRedirectUri: 'app://yourApp/logout',
  discoveryUrl: 'https://your-tenant.cidaas.eu/.well-known/openid-configuration',
  scopes: ['openid', 'profile', 'email', 'offline_access'],
  redirectWebUri: 'http://localhost:8080/callback',
  postLogoutWebUri: 'http://localhost:8080/',
);
```

---

## 📱 Features Demonstrated

### 1. Platform-Aware Configuration

```dart
CidaasConfiguration getCidaasConfig() {
  return PlatformService.isWeb ? cidaasWebConfig : cidaasMobileConfig;
}
```

### 2. Login Page with FlutterAhaAuthentication Widget

```dart
FlutterAhaAuthentication(
  moduleName: 'abenaRestock',
  applicationCode: 'abenadata',
  environment: 'development',
  europe: true,
  cidaasConfiguration: getCidaasConfig(),
  onAuthSuccess: ({accessToken, refreshToken, idToken}) {
    // Handle success
  },
  onAuthError: (error) {
    // Handle error
  },
)
```

### 3. OAuth Callback Handling (Web)

```dart
class CallbackPage extends StatefulWidget {
  // Handles OAuth redirect with:
  // - Progress indicators with status messages
  // - Token exchange
  // - Error handling
}
```

### 4. Logout with Session Invalidation

```dart
void _handleLogout(BuildContext context) {
  if (PlatformService.isWeb) {
    final cidaasWebAuth = CidaasWebAuth(dio, config, devAccount);
    cidaasWebAuth.signOut(idToken: savedIdToken);
  } else {
    // Mobile logout
    context.go('/');
  }
}
```

### 5. Asset Preloading

```dart
Future<void> _precacheAssets() async {
  await Future.wait([
    precacheImage(
      const AssetImage(
        'assets/cidaas/cidaas_logo.png',
        package: 'flutter_ahamatic_authentication',
      ),
      context,
    ),
    precacheImage(
      const AssetImage(
        'assets/openiam/abena_logo.png',
        package: 'flutter_ahamatic_authentication',
      ),
      context,
    ),
  ]);
}
```

---

## 🔄 Authentication Flow

### Login Flow (Web)

```
LoginPage → Click Cidaas → Redirect to Cidaas → 
Authenticate → Redirect to /callback → 
CallbackPage processes tokens → Navigate to /home
```

### Logout Flow (Web)

```
HomePage → Click logout → Clear local tokens → 
Redirect to Cidaas end_session → 
Cidaas invalidates session → Redirect to /
```

---

## 📋 Callback Page Status Messages

The callback page shows progress with animated messages:

| Step | Emoji | Message |
|------|-------|---------|
| 1 | 🔐 | Starting authentication... |
| 2 | ⚙️ | Getting configuration... |
| 3 | 🔑 | Validating authorization code... |
| 4 | 🔄 | Exchanging code for tokens... |
| 5 | 🌐 | Connecting to Ahamatic... |
| 6 | ✅ | Tokens received, preparing session... |
| 7 | 🚀 | Done! Redirecting... |

---

## 🔧 Troubleshooting

### "State mismatch" error

This occurs after a hot restart during OAuth flow. Solution: Complete the login flow without restarting.

### Error 412 on callback

The `apiKey` is missing. Ensure the module is correctly configured in Ahamatic and the `APIKey.Key` exists in the app validation response.

### Logout doesn't invalidate session

Register `http://localhost:8080/` as a Post Logout Redirect URI in your Cidaas client configuration.

---

## 📚 Resources

- [Flutter Documentation](https://docs.flutter.dev/)
- [go_router Package](https://pub.dev/packages/go_router)
- [Cidaas Documentation](https://docs.cidaas.com/)
- [OAuth 2.0 with PKCE](https://oauth.net/2/pkce/)
