import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ahamatic_authentication/flutter_ahamatic_authentication.dart';

// config
const environment = "sandbox";
const ahaAPI = {
  'development': 'https://dev.api.ahamatic.com',
  'sandbox': 'https://test.api.ahamatic.com',
  // 'production': 'https://api.ahamatic.com',
  'production': 'https://api-eu.ahamatic.com'
};
final apiURL = ahaAPI[environment] as String;
const apiKey = '5740ed00-f13b-11ec-b42f-3bd642eee790';
final dio = Dio();

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
  String? openIAmAuthToken;
  String? openIAmCookie;
  String? recipient;

  String? token;
  String? refreshToken;
  User? user;

  void _trySubmit() async {
    final bool? isValid = _formKey.currentState?.validate();

    if (isValid == null || !isValid) {
      return;
    }

    String username = _usernameController.text;
    String password = _passwordController.text;
    try {
      final String url = "$apiURL/api/auth/openIAmUsername";

      final response = await dio.post(url,
          data: {'apiKey': apiKey, "username": username, "password": password});
      final data = response.data;
      setState(() {
        openIAmAuthToken = data["openIAmAuthToken"];
        openIAmCookie = data["openIAmCookie"];
        recipient = data["recipient"];
        _isPINTextboxShowing = true;
      });
    } on DioError catch (err) {
      debugPrint(err.toString());
    }
  }

  void _trySubmitPIN() async {
    final isValid = _formKey.currentState!.validate();
    if (!isValid) {
      return;
    }
    String pin = _pinController.text;
    try {
      final String url = '$apiURL/api/auth/openIAmUsername/verify';

      final response = await dio.post(
        url,
        data: {
          'apiKey': apiKey,
          'code': pin,
          'recipient': recipient,
          'openIAmCookie': openIAmCookie,
          'openIAmAuthToken': openIAmAuthToken,
        },
      );
      final data = response.data;
      debugPrint('token: ${data['token']}');
      debugPrint('refresh-token: ${data['refreshToken']}');
      debugPrint('user: ${data['account']['Username']}');
      setState(() {
        token = data['token'];
        refreshToken = data['refreshToken'];
        user = User.fromJSON(data['account']);
        _isPINTextboxShowing = false;
      });
    } on DioError catch (err) {
      debugPrint(err.toString());
    }

    _pinController.text = "";
    _usernameController.text = "";
    _passwordController.text = "";
    _formKey.currentState!.reset();
    setState(() => _isPINTextboxShowing = false);
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
                formKey: _formKey,
                moduleName: 'reducnApp',
                projectLogoAsset: 'assets/images/sample_logo.png',
                pinController: _pinController,
                usernameController: _usernameController,
                passwordController: _passwordController,
                enableAzureLogin: true,
                onCodeSubmit: _trySubmitPIN,
                onSignIn: _trySubmit,
                isPinTextboxShowing: _isPINTextboxShowing,
                enableGoogleLogin: true,
                enableMitIdLogin: true,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class User {
  final int personID;
  final int userID;
  final String emailAddress;
  final String username;
  final String firstName;
  final String? middleName;
  final String lastName;
  final UserType userType;
  final UserPhoto? photo;

  User({
    required this.personID,
    required this.userID,
    required this.emailAddress,
    required this.username,
    required this.firstName,
    this.middleName,
    required this.lastName,
    required this.userType,
    this.photo,
  });
  static User fromJSON(dynamic data) {
    return User(
      personID: data['PersonId'],
      userID: data['UserId'],
      username: data['Username'],
      emailAddress: data['EmailAddress'],
      firstName: data['FirstName'],
      middleName: data['MiddleName'],
      lastName: data['LastName'],
      userType: UserType.fromJSON(data['UserTypes']),
      photo: UserPhoto.fromJSON(data['Photo']),
    );
  }
}

class UserType {
  final int id;
  final int level;
  final String name;

  const UserType({
    required this.id,
    required this.level,
    required this.name,
  });

  static UserType fromJSON(dynamic data) {
    return UserType(
      id: data['Id'],
      name: data['Name'],
      level: data['Level'],
    );
  }
}

class UserPhoto {
  final int? size;
  final int? thumbSize;
  final String fileName;
  final String thumbFileName;
  final String url;
  final String thumbUrl;
  final String mimeType;

  const UserPhoto({
    required this.fileName,
    required this.url,
    this.size,
    required this.thumbFileName,
    required this.thumbUrl,
    this.thumbSize,
    required this.mimeType,
  });

  static UserPhoto fromJSON(dynamic data) {
    return UserPhoto(
      fileName: data['fileName'],
      url: data['url'],
      size: data['size'],
      thumbFileName: data['thumbFileName'],
      thumbUrl: data['thumbUrl'],
      thumbSize: data['thumbSize'],
      mimeType: data['mimeType'],
    );
  }
}
