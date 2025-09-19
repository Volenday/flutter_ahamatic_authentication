// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_ahamatic_authentication/cidaas/cidaas_entity.dart';
import 'package:flutter_ahamatic_authentication/cidaas/cidaas_api.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:collection/collection.dart';
import 'package:universal_html/html.dart' as html;

enum LoginType { azure, mitId, openIAM, cidaas }

// ignore: must_be_immutable
class FlutterAhaAuthentication extends StatefulWidget {
  final bool? isLoginButtonOnly;
  final String? projectName;
  final String? projectLogoAsset;
  final bool enableGoogleLogin;
  final VoidCallback? onPressedGoogleLogin;
  final GlobalKey<FormState>? formKey;
  final String? moduleName;
  final String applicationCode;
  final String environment;
  final bool europe;
  final String? moduleWebName;
  final String? authenticationStatus;
  final String? token;
  final String? appVersion;
  final bool? externalBrowserLogin;
  final CidaasConfiguration? cidaasConfiguration;
  final AuthSuccessCallback? onAuthSuccess;
  final AuthErrorCallback? onAuthError;

  const FlutterAhaAuthentication({
    super.key,
    this.isLoginButtonOnly,
    this.projectName,
    this.projectLogoAsset,
    this.enableGoogleLogin = false,
    this.onPressedGoogleLogin,
    this.formKey,
    this.moduleName,
    this.moduleWebName,
    this.authenticationStatus,
    this.token,
    this.appVersion,
    this.externalBrowserLogin = false,
    this.cidaasConfiguration,
    this.onAuthSuccess,
    this.onAuthError,
    required this.applicationCode,
    required this.environment,
    required this.europe,
  });

  @override
  State<FlutterAhaAuthentication> createState() =>
      _FlutterAhaAuthenticationState();
}

class _FlutterAhaAuthenticationState extends State<FlutterAhaAuthentication> {
  final _dio = Dio();
  String projectNameFromModule = '';
  String apiKey = '';
  bool refreshTokenFound = false;
  bool isOpeniamEnabled = false;
  bool isCidaasEnabled = false;
  String openIAMLogo = '';
  String openIAMTitle = '';
  final _key = UniqueKey();
  int loadingPercentage = 0;
  String? openiamLoginUrl;
  String? openiamToken;

  late String env = widget.environment;
  String url = kIsWeb ? html.window.location.href : '';

  late final apiUrl = {
    'development': 'https://dev.api.ahamatic.com',
    'sandbox': 'https://test.api.ahamatic.com',
    'production': 'https://api-eu.ahamatic.com'
  }[env];

  late final devAccount = {
    'emailAddress': 'developers@volenday.com',
    'password': 'V0l3nd@yP@ssw0rd',
  };

  late final ahaPortal = widget.europe
      ? {
          'development': 'https://dev.auth-eu.ahamatic.com',
          'sandbox': 'https://test.auth-eu.ahamatic.com',
          'production': 'https://auth-eu.ahamatic.com'
        }[env]
      : {
          'development': 'https://dev.auth.ahamatic.com',
          'sandbox': 'https://test.auth.ahamatic.com',
          'production': 'https://auth.ahamatic.com'
        }[env];

  final Set<Factory<OneSequenceGestureRecognizer>> gestureRecognizers = {
    Factory(() => EagerGestureRecognizer())
  };

  late final WebViewController _webViewController;

  @override
  void initState() {
    super.initState();
    debugPrint('initState: Initializing state.');
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            debugPrint('onProgress: WebView loading: $progress%');
            setState(() {
              loadingPercentage = progress;
            });
          },
          onPageStarted: (String url) {
            debugPrint('onPageStarted: Page started loading: $url');
            setState(() {
              loadingPercentage = 0;
            });
          },
          onPageFinished: (String url) {
            debugPrint('onPageFinished: Page finished loading: $url');
            setState(() {
              loadingPercentage = 100;
            });
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('''
Page resource error:
  Code: ${error.errorCode}
  Description: ${error.description}
  For URL: ${error.url}
  ErrorType: ${error.errorType}
            ''');
          },
          onNavigationRequest: (NavigationRequest request) async {
            debugPrint('onNavigationRequest: Requesting URL: ${request.url}');
            Uri uri = Uri.parse(request.url);

            if (uri.queryParameters.containsKey('refreshToken')) {
              debugPrint('onNavigationRequest: Found refreshToken in URL.');
              openiamToken = uri.queryParameters['token'];

              logs(openiamToken ?? '');

              if (await canLaunchUrl(uri)) {
                debugPrint(
                    'onNavigationRequest: Launching URL in external app: $uri');
                await launchUrl(uri).then((_) {
                  if (!context.mounted) {
                    return;
                  }
                  debugPrint(
                      'onNavigationRequest: Popping dialog after URL launch.');
                  Navigator.pop(context);
                });
              } else {
                debugPrint('Could not launch $uri');
              }
              return NavigationDecision.prevent;
            }
            debugPrint(
                'onNavigationRequest: Navigating to URL: ${request.url}');
            return NavigationDecision.navigate;
          },
        ),
      );

    WebViewCookieManager().clearCookies();
    debugPrint('initState: Cleared WebView cookies.');

    fetchData();
    fetchLoginUrl(LoginType.openIAM);
  }

  Future<void> fetchData() async {
    debugPrint('fetchData: Fetching application data.');
    try {
      debugPrint('fetchData: Sending API request...');
      final response = await _dio
          .get('$apiUrl/api/validate/app?value=${widget.applicationCode}');
      debugPrint('fetchData: API response status code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonData = response.data;
        debugPrint('fetchData: Successfully fetched JSON data.');

        List<dynamic> configurations = jsonData['Configurations'];

        Map<String, dynamic>? authConfig;
        for (var config in configurations) {
          if (config['Key'] == 'AuthConfig') {
            authConfig = config;
            break;
          }
        }

        if (authConfig != null && authConfig['Value'] is List<dynamic>) {
          debugPrint('fetchData: Found AuthConfig.');
          Map<String, dynamic>? moduleConfig;
          for (var config in authConfig['Value']) {
            if (config['Module'] == widget.moduleName) {
              moduleConfig = config;
              debugPrint(
                  'fetchData: Found module config for ${widget.moduleName}.');
              break;
            }
          }

          debugPrint('fetchData: Module config: $moduleConfig');

          // Extrae apiKey correctamente desde moduleConfig si existe
          apiKey = moduleConfig != null &&
                  moduleConfig['Cidaas'] != null &&
                  moduleConfig['Cidaas']['apiKey'] != null
              ? moduleConfig['Cidaas']['apiKey']
              : '';
          debugPrint('fetchData: Cidaas apiKey from moduleConfig: $apiKey');

          isCidaasEnabled = moduleConfig != null &&
              moduleConfig['Portal Authentication']['Cidaas'] == true;
          debugPrint('fetchData: Cidaas enabled status: $isCidaasEnabled');

          isOpeniamEnabled = moduleConfig != null &&
              moduleConfig['Portal Authentication']['OpenIAmAuth'] == true;
          debugPrint('fetchData: OpenIAM enabled status: $isOpeniamEnabled');

          openIAMLogo = moduleConfig != null && isOpeniamEnabled
              ? moduleConfig['OpenIAMConfig']['logo']
              : '';
          openIAMTitle = moduleConfig != null && isOpeniamEnabled
              ? moduleConfig['OpenIAMConfig']['title']
              : '';
          debugPrint(
              'fetchData: OpenIAM logo: $openIAMLogo, title: $openIAMTitle');
        }

        final name = jsonData['Name'];
        debugPrint('fetchData: Project name from module: $name');

        if (mounted) {
          setState(() {
            projectNameFromModule = name;
          });
        }
      } else {
        debugPrint(
            'fetchData: Failed to load data with status code: ${response.statusCode}');
        throw Exception('Failed to load data');
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  String? getOpenIAMLoginUrlFromJson(Map<String, dynamic> jsonData) {
    debugPrint(
        'getOpenIAMLoginUrlFromJson: Retrieving login URL for native app.');
    try {
      final bool isAndroid = Platform.isAndroid;

      final configurations = jsonData['Configurations'] as List<dynamic>;

      for (final config in configurations) {
        if (config['Key'] == 'AuthConfig') {
          final authConfigList = config['Value'] as List<dynamic>;
          final moduleConfig = authConfigList.firstWhereOrNull(
            (item) => item['Module'] == widget.moduleName,
          );

          if (moduleConfig != null) {
            final openIAMHost = moduleConfig['HostName'];
            final scheme = isAndroid ? 'app://$openIAMHost' : '$openIAMHost://';
            final loginUrl =
                '$ahaPortal/client/${widget.applicationCode}?redirect=$scheme/callback&origin=website&module=${widget.moduleName}';

            debugPrint(
                'getOpenIAMLoginUrlFromJson: Generated login URL: $loginUrl');
            setState(() {
              openiamLoginUrl = loginUrl;
            });
            return loginUrl;
          }
        }
      }
    } catch (error) {
      debugPrint('Error retrieving OpenIAM login URL: $error');
    }
    return null;
  }

  String? getOpenIAMLoginForWeb(Map<String, dynamic> jsonData) {
    debugPrint('getOpenIAMLoginForWeb: Retrieving login URL for web.');
    try {
      final configurations = jsonData['Configurations'] as List<dynamic>;

      for (final config in configurations) {
        if (config['Key'] == 'AuthConfig') {
          final authConfigList = config['Value'] as List<dynamic>;
          final moduleConfig = authConfigList.firstWhereOrNull(
            (item) => item['Module'] == widget.moduleWebName,
          );

          if (moduleConfig != null) {
            final openIAMHost = moduleConfig['HostName'];
            final uri = Uri.parse(url);
            final baseUrl = '${uri.scheme}://${uri.host}:${uri.port}';
            final callback =
                url.contains('localhost') ? baseUrl : "https://$openIAMHost";

            String loginUrl;
            if (widget.authenticationStatus == "unauthenticated") {
              loginUrl =
                  "$ahaPortal/logout/${widget.applicationCode}?redirect=$callback/callback?redirect=&origin=website&logout=true";
              debugPrint(
                  'getOpenIAMLoginForWeb: Generated logout URL: $loginUrl');
            } else {
              loginUrl =
                  '$ahaPortal/client/${widget.applicationCode}?redirect=$callback/callback?redirect=&origin=website&module=${widget.moduleWebName}';
              debugPrint(
                  'getOpenIAMLoginForWeb: Generated login URL: $loginUrl');
            }
            return loginUrl;
          }
        }
      }
    } catch (error) {
      debugPrint('Error retrieving OpenIAM login URL: $error');
    }
    return null;
  }

  Future<String?> fetchLoginUrl(LoginType loginType) async {
    debugPrint('fetchLoginUrl: Fetching login URL for type: $loginType');
    try {
      final response = await _dio
          .get('$apiUrl/api/validate/app?value=${widget.applicationCode}');

      if (response.statusCode == 200) {
        final jsonData = response.data;
        String? loginUrl;

        if (loginType == LoginType.openIAM) {
          loginUrl = kIsWeb
              ? getOpenIAMLoginForWeb(jsonData)
              : getOpenIAMLoginUrlFromJson(jsonData);
        }

        debugPrint('fetchLoginUrl: Retrieved login URL: $loginUrl');
        return loginUrl;
      } else {
        debugPrint('Failed to fetch JSON data: ${response.statusCode}');
        return null;
      }
    } catch (error) {
      debugPrint('Error fetching JSON data: $error');
      return null;
    }
  }

  Widget _buildWebView(BuildContext context) {
    debugPrint('_buildWebView: Building WebView widget.');
    return WebViewWidget(
      key: _key,
      controller: _webViewController,
      gestureRecognizers: gestureRecognizers,
    );
  }

  Future<void> _launchLogin(BuildContext context, LoginType loginType) async {
    debugPrint('_launchLogin: Attempting to launch login for type: $loginType');
    fetchLoginUrl(loginType).then((url) async {
      if (!context.mounted) return;

      if (widget.externalBrowserLogin == true) {
        debugPrint('_launchLogin: Using external browser for login.');
        if (url != null) {
          debugPrint('_launchLogin: Launching URL externally: $url');
          await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
        } else {
          debugPrint('Login URL is null.');
        }
      } else {
        if (url != null) {
          debugPrint('_launchLogin: Loading URL in WebView: $url');
          _webViewController.loadRequest(Uri.parse(url));
        }

        kIsWeb
            ? html.window.open(url!, '_self')
            : showDialog(
                context: context,
                barrierDismissible: false,
                builder: (BuildContext context) {
                  debugPrint('_launchLogin: Showing WebView dialog.');
                  return StatefulBuilder(
                    builder: (context, setState) {
                      return Scaffold(
                        backgroundColor: Colors.transparent,
                        body: Stack(
                          children: [
                            AlertDialog(
                              contentPadding:
                                  const EdgeInsets.fromLTRB(5, 5, 5, 10),
                              insetPadding:
                                  const EdgeInsets.fromLTRB(20, 10, 20, 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5),
                              ),
                              content: Column(
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      debugPrint('Closing login dialog.');
                                      Navigator.pop(context);
                                    },
                                    child: const Align(
                                      alignment: Alignment.topRight,
                                      child: Icon(
                                        Icons.close,
                                        color: Colors.red,
                                        size: 30,
                                        textDirection: TextDirection.rtl,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: SizedBox(
                                      width: MediaQuery.of(context).size.width,
                                      height:
                                          MediaQuery.of(context).size.height *
                                              0.9,
                                      child: Stack(
                                        children: [
                                          if (url != null)
                                            _buildWebView(context),
                                          if (loadingPercentage < 100)
                                            const Center(
                                              child: CircularProgressIndicator(
                                                color: Color(0xFF003D7F),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              );
      }
    });
  }

  // _launchCidaasLogin()
  Future<void> _launchCidaasLogin() async {
    debugPrint('_launchCidaasLogin: Initiating Cidaas login flow.');

    final CidaasConfiguration? config = widget.cidaasConfiguration;
    if (config == null) {
      debugPrint('Error: CidaasConfiguration not provided.');
      // Llama al callback de error si la configuración no existe
      if (widget.onAuthError != null) {
        widget.onAuthError!('Cidaas configuration not provided.');
      }
      return;
    }

    try {
      final cidaasAuthApi = CidaasAuthApiImpl(
        _dio,
        const FlutterAppAuth(),
        config,
        devAccount,
      );

      final TokenResponse tokenResponse = await cidaasAuthApi.signInWithCidaas(
        apiKey,
        apiUrl,
      );

      if (tokenResponse.accessToken != null) {
        debugPrint('_launchCidaasLogin: Login successful!');

        // Llama al callback de éxito que el cliente pasó
        if (widget.onAuthSuccess != null) {
          widget.onAuthSuccess!(
            accessToken: tokenResponse.accessToken,
            refreshToken: tokenResponse.refreshToken,
            idToken: tokenResponse.idToken,
          );
        }
      } else {
        debugPrint('_launchCidaasLogin: Login failed, no access token.');
        // Llama al callback de error
        if (widget.onAuthError != null) {
          widget.onAuthError!('Login failed, no access token.');
        }
      }
    } on PlatformException catch (e) {
      debugPrint('CidaasAuthApi: PlatformException: ${e.message}');
      // Llama al callback de error en caso de excepción
      if (widget.onAuthError != null) {
        widget.onAuthError!(e.message ?? 'An unknown platform error occurred.');
      }
    } catch (e) {
      debugPrint('CidaasAuthApi: An unexpected error occurred: $e');
      // Llama al callback de error en caso de excepción inesperada
      if (widget.onAuthError != null) {
        widget.onAuthError!('An unexpected error occurred: $e');
      }
    }
  }

  Future<void> logs(String token) async {
    debugPrint('logs: Sending log data to API.');
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();

    String deviceModel = '';

    try {
      if (Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        deviceModel = androidInfo.model;
        debugPrint('logs: Device model (Android): $deviceModel');
      } else if (Platform.isIOS) {
        IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        deviceModel = iosInfo.model;
        debugPrint('logs: Device model (iOS): $deviceModel');
      }
    } catch (e) {
      debugPrint('logs: Error getting device info: $e');
    }

    _dio.options.headers['authorization'] = token;
    debugPrint('logs: Setting authorization header with token.');

    final Map<String, dynamic> tokenDecode = JwtDecoder.decode(token);
    final int personId = tokenDecode['account']['PersonId'];
    debugPrint('logs: Decoded PersonId from token: $personId');

    final params = {
      "Action": "Abena Id Login Button Tapped",
      "Description": "User logged in via $openiamLoginUrl",
      "Person": personId,
      "Entity": widget.moduleName,
      "AppVersion": widget.appVersion,
      "Device": deviceModel,
    };

    try {
      final response = await _dio.post('$apiUrl/api/e/_logs', data: params);
      if (response.statusCode == 200) {
        debugPrint('Logs: Successfully sent logs. Response: ${response.data}');
      } else {
        debugPrint('Failed to send logs: ${response.statusCode}');
      }
    } on DioError catch (e) {
      debugPrint('Dio Error when sending logs: ${e.message}');
    } catch (e) {
      debugPrint('Error when sending logs: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('build: Building widget tree.');
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    bool isPhone = MediaQuery.of(context).size.width < 600;

    final bool isLoginButtonOnly = widget.isLoginButtonOnly ?? false;

    return SizedBox(
      child: isLoginButtonOnly
          ? ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(
                    horizontal: isPhone ? 25 : 40, vertical: isPhone ? 4 : 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              onPressed: () {
                debugPrint('Login button pressed.');
                _launchLogin(context, LoginType.openIAM);
              },
              child: Text('Log in',
                  style: TextStyle(
                    color: const Color(0xFF173A78),
                    fontSize: isPhone ? 16 : 18,
                    fontWeight: FontWeight.bold,
                  )),
            )
          : Center(
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    widget.projectLogoAsset == null
                        ? const SizedBox.shrink()
                        : Image.asset(widget.projectLogoAsset!,
                            width: width / 4, height: height / 6),
                    Container(
                        margin: EdgeInsets.only(top: isPhone ? 10 : 20),
                        padding: EdgeInsets.symmetric(
                            horizontal: isPhone ? 20 : 50,
                            vertical: isPhone ? 8 : 20),
                        width: isPhone ? width * 0.9 : width * 0.5,
                        decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: const [
                              BoxShadow(
                                  color: Colors.grey,
                                  offset: Offset(0, 1),
                                  blurRadius: 1,
                                  spreadRadius: 1)
                            ]),
                        child: Form(
                          key: widget.formKey,
                          child: Column(
                            children: [
                              const SizedBox(height: 20),
                              Text(
                                widget.projectName ?? projectNameFromModule,
                                style: TextStyle(
                                    fontSize: isPhone ? 18 : 24,
                                    fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (isCidaasEnabled)
                                    _SignInAlternatives(
                                      name: 'Cidaas',
                                      logo:
                                          'https://brandfetch.com/cidaas.com?view=library&library=default&collection=logos&asset=idSp1mW6xT&utm_source=https%253A%252F%252Fbrandfetch.com%252Fcidaas.com&utm_medium=copyAction&utm_campaign=brandPageReferral',
                                      onPressed: () {
                                        debugPrint('Cidaas button pressed.');
                                        _launchCidaasLogin();
                                      },
                                    ),
                                  if (isOpeniamEnabled)
                                    _SignInAlternatives(
                                        name: openIAMTitle,
                                        logo: openIAMLogo,
                                        onPressed: () {
                                          debugPrint('OpenIAM button pressed.');
                                          if (widget.environment !=
                                              'production') {
                                            SnackBar snackBar = SnackBar(
                                                content:
                                                    Text('$openiamLoginUrl'));
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(snackBar);
                                          }
                                          _launchLogin(
                                              context, LoginType.openIAM);
                                        }),
                                  if (widget.enableGoogleLogin)
                                    _SignInAlternatives(
                                      name: 'Google',
                                      logo: 'google',
                                      onPressed: () {
                                        debugPrint(
                                            'Google login button pressed.');
                                        widget.onPressedGoogleLogin!();
                                      },
                                    ),
                                ],
                              )
                            ],
                          ),
                        ))
                  ]),
            ),
    );
  }
}

class _SignInAlternatives extends StatelessWidget {
  final String logo;
  final String name;
  final VoidCallback onPressed;

  const _SignInAlternatives({
    required this.logo,
    required this.name,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    debugPrint('build: Building _SignInAlternatives widget for $name.');
    bool isPhone = MediaQuery.of(context).size.width < 600;

    return Column(
      children: [
        ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            elevation: 0,
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: const BorderSide(color: Colors.grey),
            ),
          ),
          child: Container(
            width: isPhone ? 50 : 60,
            height: isPhone ? 50 : 60,
            padding: const EdgeInsets.all(10),
            child: CachedNetworkImage(
              imageUrl: logo,
              placeholder: (context, url) {
                debugPrint('CachedNetworkImage: Placeholder for $url.');
                return const CircularProgressIndicator();
              },
              errorWidget: (context, url, error) {
                debugPrint(
                    'CachedNetworkImage: Error loading image from $url. Error: $error');
                if (logo.startsWith('assets/')) {
                  return Image.asset(
                    logo,
                    width: isPhone ? 50 : 60,
                    height: isPhone ? 50 : 60,
                    fit: BoxFit.contain,
                  );
                }
                return const Icon(Icons.error);
              },
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(name, style: TextStyle(fontSize: isPhone ? 12 : 14)),
      ],
    );
  }
}
