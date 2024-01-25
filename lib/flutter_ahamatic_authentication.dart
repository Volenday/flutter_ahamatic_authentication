import 'dart:async';
import 'dart:io';

import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:collection/collection.dart';

enum LoginType { azure, mitId, openIAM }

// ignore: must_be_immutable
class FlutterAhaAuthentication extends StatefulWidget {
  final String? projectLogoAsset;
  final bool enableGoogleLogin;
  final VoidCallback? onPressedGoogleLogin;
  final GlobalKey<FormState>? formKey;
  final String? moduleName;
  final String apiUrlConfig;
  final String portalUrlConfig;
  final String applicationCode;

  const FlutterAhaAuthentication({
    Key? key,
    this.projectLogoAsset,
    this.enableGoogleLogin = false,
    this.onPressedGoogleLogin,
    this.formKey,
    this.moduleName,
    required this.apiUrlConfig,
    required this.portalUrlConfig,
    required this.applicationCode,
  }) : super(key: key);

  @override
  State<FlutterAhaAuthentication> createState() =>
      _FlutterAhaAuthenticationState();
}

class _FlutterAhaAuthenticationState extends State<FlutterAhaAuthentication> {
  final _dio = Dio();
  String projectName = '';
  bool isLoading = true;
  bool refreshTokenFound = false;
  bool isAzureAuthEnabled = false;
  bool isMitIdAuthEnabled = false;
  bool isOpeniamEnabled = false;

  final Set<Factory<OneSequenceGestureRecognizer>> gestureRecognizers = {
    Factory(() => EagerGestureRecognizer())
  };

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    try {
      final response = await _dio.get(
          '${widget.apiUrlConfig}/marketplace/applications/validate/${widget.applicationCode}');

      if (response.statusCode == 200) {
        final jsonData = response.data;

        List<dynamic> configurations = jsonData['Configurations'];

        Map<String, dynamic>? authConfig;
        for (var config in configurations) {
          if (config['Key'] == 'AuthConfig') {
            authConfig = config;
            break;
          }
        }

        if (authConfig != null && authConfig['Value'] is List<dynamic>) {
          Map<String, dynamic>? moduleConfig;
          for (var config in authConfig['Value']) {
            if (config['Module'] == widget.moduleName) {
              moduleConfig = config;
              break;
            }
          }

          isAzureAuthEnabled = moduleConfig != null &&
              moduleConfig['Portal Authentication']['AzureAuth'] == true;

          isMitIdAuthEnabled = moduleConfig != null &&
              moduleConfig['Portal Authentication']['MitIdAuth'] == true;

          isOpeniamEnabled = moduleConfig != null &&
              moduleConfig['Portal Authentication']['OpenIAmAuth'] == true;
        }

        final name = jsonData['Name'];

        if (mounted) {
          setState(() {
            projectName = name;
          });
        }
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  String? getAzureLoginUrlFromJson(Map<String, dynamic> jsonData) {
    try {
      final configurations = jsonData['Configurations'] as List<dynamic>;

      for (final config in configurations) {
        if (config['Key'] == 'AuthConfig') {
          final authConfigList = config['Value'] as List<dynamic>;
          final reducnAppConfig = authConfigList.firstWhere(
            (item) => item['Module'] == widget.moduleName,
            orElse: () => null,
          );

          if (reducnAppConfig != null) {
            final openIamAuthAzureConfig =
                reducnAppConfig['OpenIAmAuthAzureConfig'];
            if (openIamAuthAzureConfig != null &&
                openIamAuthAzureConfig is Map<String, dynamic>) {
              final loginUrl = openIamAuthAzureConfig['loginUrl'] as String?;
              return loginUrl;
            }
          }
        }
      }
    } catch (error) {
      debugPrint('Error retrieving loginUrl: $error');
    }

    return null;
  }

  String? getOpenIAMLoginUrlFromJson(Map<String, dynamic> jsonData) {
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
            final sandboxEnv = widget.apiUrlConfig.contains('test') ||
                widget.apiUrlConfig.contains('dev');
            final openIamAuthConfig = sandboxEnv
                ? moduleConfig['HostName'] + 'SandBox'
                : moduleConfig['HostName'];

            final scheme = isAndroid
                ? 'app://$openIamAuthConfig'
                : '$openIamAuthConfig://';

            final loginUrl =
                '${widget.portalUrlConfig}/client/${widget.applicationCode}?redirect=$scheme/callback&origin=website&module=${widget.moduleName}';

            return loginUrl;
          }
        }
      }
    } catch (error) {
      debugPrint('Error retrieving OpenIAM login URL: $error');
    }

    return null;
  }

  String? getMitIdLoginUrlFromJson(
    Map<String, dynamic> jsonData,
  ) {
    try {
      final configurations = jsonData['Configurations'] as List<dynamic>;

      for (final config in configurations) {
        if (config['Key'] == 'AuthConfig') {
          final authConfigList = config['Value'] as List<dynamic>;
          final reducnAppConfig = authConfigList.firstWhere(
            (item) => item['Module'] == widget.moduleName,
            orElse: () => null,
          );

          if (reducnAppConfig != null) {
            final openIamAuthAzureConfig =
                reducnAppConfig['OpenIAmAuthMitIdConfig'];
            if (openIamAuthAzureConfig != null &&
                openIamAuthAzureConfig is Map<String, dynamic>) {
              final loginUrl = openIamAuthAzureConfig['loginUrl'] as String?;
              return loginUrl;
            }
          }
        }
      }
    } catch (error) {
      debugPrint('Error retrieving loginUrl: $error');
    }

    return null;
  }

  Future<String?> fetchLoginUrl(LoginType loginType) async {
    try {
      final response = await _dio.get(
          '${widget.apiUrlConfig}/marketplace/applications/validate/${widget.applicationCode}');

      if (response.statusCode == 200) {
        final jsonData = response.data;
        String? loginUrl;

        if (loginType == LoginType.azure) {
          loginUrl = getAzureLoginUrlFromJson(jsonData);
        } else if (loginType == LoginType.mitId) {
          loginUrl = getMitIdLoginUrlFromJson(jsonData);
        } else if (loginType == LoginType.openIAM) {
          loginUrl = getOpenIAMLoginUrlFromJson(jsonData);
        }

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

  Future<void> _launchLogin(BuildContext context, LoginType loginType) async {
    final WebViewController controller =
        WebViewController.fromPlatformCreationParams(
            const PlatformWebViewControllerCreationParams());

    fetchLoginUrl(loginType).then((url) {
      controller
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) async {
            Uri uri = Uri.parse(request.url);
            if (uri.queryParameters.containsKey('refreshToken')) {
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri).then((_) {
                  Navigator.pop(context);
                });
              } else {
                print(' could not launch $uri');
              }

              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ))
        ..loadRequest(Uri.parse(url ?? ''));

      if (url != null) {
        AwesomeDialog(
          context: context,
          bodyHeaderDistance: 5,
          dialogType: DialogType.noHeader,
          dismissOnTouchOutside: false,
          keyboardAware: false,
          autoDismiss: true,
          isDense: true,
          headerAnimationLoop: false,
          btnCancel: ElevatedButton(
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.red,
            ),
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          body: SizedBox(
            height: MediaQuery.of(context).size.height * 0.8,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: FutureBuilder(
                  future: Future.delayed(const Duration(seconds: 3)),
                  builder: (BuildContext context, AsyncSnapshot snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    } else {
                      return WebViewWidget(
                        controller: controller,
                      );
                    }
                  }),
            ),
          ),
        ).show();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to launch $loginType login'),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    bool isPhone = MediaQuery.of(context).size.width < 600;

    return SingleChildScrollView(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        widget.projectLogoAsset == null
            ? const SizedBox.shrink()
            : Image.asset(widget.projectLogoAsset!,
                width: width / 4, height: height / 6),
        Container(
            margin: EdgeInsets.only(top: isPhone ? 10 : 20),
            padding: EdgeInsets.symmetric(
                horizontal: isPhone ? 20 : 50, vertical: isPhone ? 8 : 20),
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
                    projectName,
                    style: TextStyle(
                        fontSize: isPhone ? 18 : 24,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (isOpeniamEnabled)
                        _SignInAlternatives(
                          name: 'OpenIAM',
                          logoName: 'openIAm',
                          onPressed: () =>
                              _launchLogin(context, LoginType.openIAM),
                        ),
                      if (widget.enableGoogleLogin)
                        _SignInAlternatives(
                          name: 'Google',
                          logoName: 'google',
                          onPressed: widget.onPressedGoogleLogin ?? () {},
                        ),
                      if (isAzureAuthEnabled)
                        _SignInAlternatives(
                            name: 'Azure',
                            logoName: 'azure',
                            onPressed: () =>
                                _launchLogin(context, LoginType.azure)),
                      if (isMitIdAuthEnabled)
                        _SignInAlternatives(
                          name: 'MitId',
                          logoName: 'mitId',
                          onPressed: () =>
                              _launchLogin(context, LoginType.mitId),
                        ),
                    ],
                  )
                ],
              ),
            ))
      ]),
    );
  }
}

class _SignInAlternatives extends StatelessWidget {
  final String logoName;
  final String name;
  final VoidCallback onPressed;

  const _SignInAlternatives({
    Key? key,
    required this.logoName,
    required this.name,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
              imageUrl: "https://test.auth.ahamatic.com/images/$logoName.png",
              placeholder: (context, url) => const CircularProgressIndicator(),
              errorWidget: (context, url, error) => const Icon(Icons.error),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(name, style: TextStyle(fontSize: isPhone ? 12 : 14)),
      ],
    );
  }
}
