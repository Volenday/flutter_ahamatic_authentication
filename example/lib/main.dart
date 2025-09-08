import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ahamatic_authentication/cidaas/cidaas_entity.dart';
import 'package:flutter_ahamatic_authentication/flutter_ahamatic_authentication.dart';

// config
const environment = "sandbox";

const ahaAPI = {
  'development': 'https://dev.api.ahamatic.com',
  'sandbox': 'https://test.api.ahamatic.com',
  'production': 'https://api-eu.ahamatic.com'
};

const ahaPortal = {
  "development": 'https://dev.auth.ahamatic.com',
  "sandbox": 'https://test.auth.ahamatic.com',
  "production": 'https://auth.ahamatic.com'
};

final apiURL = ahaAPI[environment] as String;
final portalURL = ahaPortal[environment] as String;
const apiKey = '5740ed00-f13b-11ec-b42f-3bd642eee790';
final dio = Dio();

Map<String, String>? initialQueryParameters;
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
  String? openIAmAuthToken;
  String? openIAmCookie;
  String? recipient;

  String? token;
  String? refreshToken;
  User? user;

  String? _accessToken;
  String? _refreshToken;
  String? _idToken;

  // Callback function for a successful authentication
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
    debugPrint('Autenticación exitosa. Access Token: $_accessToken');
    debugPrint('Refresh Token: $_refreshToken');
    debugPrint('ID Token: $_idToken');
  }

  // Callback function for an authentication error
  void _handleAuthError(String errorMessage) {
    // You can display an error message to the user here.
    debugPrint('Error de autenticación: $errorMessage');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error de autenticación: $errorMessage')),
    );
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
                moduleName: 'b2bScanner',
                moduleWebName: 'b2bScannerWeb',
                projectLogoAsset: 'assets/images/sample_logo.png',
                applicationCode: 'abenadata',
                environment: 'production',
                europe: true,
                onAuthSuccess: _handleAuthSuccess,
                onAuthError: _handleAuthError,
                cidaasConfiguration: CidaasConfiguration(
                  clientId: 'dd982451-c2bb-409f-9649-3ca12a9ba0fd',
                  issuer: 'https://abena-prod.cidaas.eu/',
                  redirectUri: 'app://abenaRestock/oauth2redirect',
                  postLogoutRedirectUri: 'app://abenaRestock/logout',
                  discoveryUrl:
                      'https://abena-prod.cidaas.eu/.well-known/openid-configuration',
                  scopes: [
                    'openid',
                    'profile',
                    'email',
                    'offline_access',
                    'dk-cpr',
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
