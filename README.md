# Flutter Ahamatic Authentication

[![Flutter](https://img.shields.io/badge/Flutter-3.3+-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.1+-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-lightgrey)](https://flutter.dev)

A Flutter plugin that provides a seamless authentication interface for Ahamatic-powered applications. Supports multiple authentication providers including **OpenIAM** and **Cidaas**.

---

## ✨ Features

- 🔐 **OpenIAM Authentication** - Native deep link integration
- 🌐 **Cidaas OAuth2** - Full PKCE flow support
- 🎨 **Customizable UI** - Project logo and name
- 📱 **Mobile Ready** - Android & iOS support
- 🔄 **Token Management** - Access, Refresh, and ID tokens
- ⚡ **Easy Integration** - Simple widget-based API

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

### Cidaas Authentication

For Cidaas OAuth2, provide the `CidaasConfiguration`:

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
    scopes: [
      'openid',
      'profile',
      'email',
      'offline_access',
    ],
  ),
  onAuthSuccess: ({accessToken, refreshToken, idToken}) {
    // Handle successful authentication
    print('Access Token: $accessToken');
    print('Refresh Token: $refreshToken');
    print('ID Token: $idToken');
  },
  onAuthError: (error) {
    // Handle authentication error
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
| `redirectUri` | `String?` | 📱 | Redirect URI for mobile |
| `postLogoutRedirectUri` | `String?` | 📱 | Post logout URI for mobile |
| `redirectWebUri` | `String?` | 🌐 | Redirect URI for web |
| `postLogoutWebUri` | `String?` | 🌐 | Post logout URI for web |

---

## 📋 Complete Example

```dart
import 'package:flutter/material.dart';
import 'package:flutter_ahamatic_authentication/flutter_ahamatic_authentication.dart';

void main() => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String? _accessToken;
  String? _refreshToken;
  String? _idToken;

  void _handleAuthSuccess({
    String? accessToken,
    String? refreshToken,
    String? idToken,
  }) {
    setState(() {
      _accessToken = accessToken;
      _refreshToken = refreshToken;
      _idToken = idToken;
    });
    debugPrint('✅ Authentication successful!');
  }

  void _handleAuthError(String errorMessage) {
    debugPrint('❌ Authentication error: $errorMessage');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $errorMessage')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.grey[300],
        appBar: AppBar(title: const Text('Auth Example')),
        body: Center(
          child: FlutterAhaAuthentication(
            applicationCode: 'your-app-code',
            environment: 'production',
            europe: true,
            moduleName: 'your-module',
            projectName: 'My App',
            projectLogoAsset: 'assets/images/logo.png',
            cidaasConfiguration: CidaasConfiguration(
              clientId: 'your-client-id',
              issuer: 'https://your-tenant.cidaas.eu',
              redirectUri: 'app://yourApp/oauth2redirect',
              postLogoutRedirectUri: 'app://yourApp/logout',
              discoveryUrl: 'https://your-tenant.cidaas.eu/.well-known/openid-configuration',
              scopes: ['openid', 'profile', 'email', 'offline_access'],
            ),
            onAuthSuccess: _handleAuthSuccess,
            onAuthError: _handleAuthError,
          ),
        ),
      ),
    );
  }
}
```

---

## 🌐 Web Support

> ⚠️ **Work in Progress**
>
> Web support is currently under development. The following features are being implemented:
>
> - OAuth2 Authorization Code flow with PKCE
> - Popup and redirect authentication modes
> - Session storage for PKCE state management
>
> **Coming soon!**

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
