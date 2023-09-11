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
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();
  bool _isPINTextboxShowing = false;

  void _trySubmit() {
    final bool? isValid = _formKey.currentState?.validate();

    if (isValid == null || !isValid) {
      return;
    }

    String username = _usernameController.text;
    String password = _passwordController.text;

    debugPrint('valid login: $isValid');
    debugPrint('$username $password');

    setState(() => _isPINTextboxShowing = true);
  }

  void _trySubmitPIN() {
    final isValid = _formKey.currentState!.validate();
    if (!isValid) {
      return;
    }
    String pin = _pinController.text;
    debugPrint(pin);

    _pinController.text = "";
    _usernameController.text = "";
    _passwordController.text = "";
    _formKey.currentState!.reset();
    setState(() => _isPINTextboxShowing = false);
  }

  String? _validateOTP(String? value) {
    // must be 6-digits
    if (value == null) return null;
    if (value.isEmpty || value.length < 6) {
      return "Invalid Input";
    }
    return null;
  }

  String? _validateUsername(String? value) {
    if (value == null) return null;
    if (value.isEmpty) return "Invalid Input";
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null) return null;
    if (value.isEmpty) return "Invalid Input";
    return null;
  }

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
            child: Center(
              child: FlutterAhaAuthentication(
                projectName: 'Flutter Aha Authentication',
                projectLogoAsset: 'assets/images/sample_logo.png',
                enableAzureLogin: true,
                onPressedAzureLogin: () => print('Azure Login'),
                onPressedGoogleLogin: () {
                  print('Google Login');
                },
                enableOpenIAMLogin: true,
                usernameController:
                    _usernameController, // enableOpenIAmLogin? _usernameController:null,
                passwordController:
                    _passwordController, // enableOpenIAmLogin? _passwordController:null,
                pinController:
                    _pinController, // enableOpenIAmLogin? _pinController:null,
                otpValidator:
                    _validateOTP, // enableOpenIAmLogin? _validateOTP:null,
                usernameValidator:
                    _validateUsername, // enableOpenIAmLogin? _validateUsername:null,
                passwordValidator:
                    _validatePassword, // enableOpenIAmLogin? _validatePassword:null,
                onSignIn: _trySubmit,
                onCodeSubmit: _trySubmitPIN,
                isPINTextboxShowing: _isPINTextboxShowing,
                formKey: _formKey,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
