import 'package:flutter/material.dart';

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
          child: SingleChildScrollView(
            child: SizedBox(
              height: MediaQuery.of(context).size.height,
              child: const Center(
                child: FlutterAhaAuthentication(
                  projectName: 'Flutter Aha Authentication',
                  projectLogoAsset: 'assets/images/sample_logo.png',
                  openiamAzureLogin: true,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
