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
                projectLogoAsset: 'assets/images/sample_logo.png', // project logo from your asset file
                enableAzureLogin: true, // optional
                azureLoginUrl: 'https://azure.microsoft.com', // pass a String url
                googleLoginUrl: 'https://google.com', // pass a String url
              ),
            ),
          ),
        ),
      ),
    );
  }
}

```
