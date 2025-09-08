# flutter_ahamatic_authentication

The Ahamatic Login Page Flutter plugin provides a simple and convenient way to integrate a login page into your Flutter apps developed using the Flutter framework. With this plugin, you can effortlessly add a user-friendly login interface to your Ahamatic-powered applications, enhancing the authentication experience for your users.

## Example

```dart
import 'package:flutter_ahamatic_authentication/flutter_ahamatic_authentication.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    // Only for Cidaas configuration
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

      // You can add your logic here. For example, navigate to a new screen or save the tokens.
      debugPrint('Authentication successful. Access Token: $_accessToken');
      debugPrint('Refresh Token: $_refreshToken');
      debugPrint('ID Token: $_idToken');
    }

    // Callback function for an authentication error
    void _handleAuthError(String errorMessage) {
      // You can display an error message to the user here.
      debugPrint('Authentication error: $errorMessage');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Authentication error: $errorMessage')),
        );  
    }

    return MaterialApp(
      home: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: Colors.grey[300],
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: SafeArea(
          child: SizedBox(
            height: MediaQuery.of(context).size.height,
            child: const Center(
              child: FlutterAhaAuthentication(
                projectName: 'Flutter Aha Authentication', // project name
                projectLogoAsset: 'assets/images/sample_logo.png', // optional, project logo from your asset file
                enableAzureLogin: true, // optional
                azureLoginUrl: () {}, // optional, pass a callback function
                googleLoginUrl: () {}, //  optional, pass a callback function
                onAuthSuccess: _handleAuthSuccess,
                onAuthError: _handleAuthError,
                // optional, Cidaas login configuration
                cidaasConfiguration: CidaasConfiguration(
                  clientId: '', // Provided by the service provider
                  issuer: '', // Provided by the service provider
                  redirectUri: 'app://yourApp/oauth2redirect',
                  postLogoutRedirectUri: 'app://yourApp/logout',
                  discoveryUrl:
                      'https://youtApp/.well-known/openid-configuration',
                  scopes: [
                    'openid',
                    'profile',
                    'email',
                    'offline_access',
                    // You can add more scopes by checking discoveryUrl to see what's available.
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

```
