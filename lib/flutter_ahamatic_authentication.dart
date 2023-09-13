import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

enum LoginType {
  azure,
  mitId,
}

// ignore: must_be_immutable
class FlutterAhaAuthentication extends StatefulWidget {
  final String projectName;
  final String? projectLogoAsset;
  final bool enableAzureLogin;
  final bool enableMitIdLogin;
  final bool enableGoogleLogin;
  final bool isPinTextboxShowing;
  final VoidCallback? onPressedGoogleLogin;
  final VoidCallback onSignIn;
  final VoidCallback? onCodeSubmit;
  final VoidCallback? onResendCode;
  final bool isCodeSubmitBlock;
  final bool isCodeSubmitLoading;
  final bool isResendCodeAvailable;
  final int? resendCodeCooldown;
  bool isRememberCreds;
  final GlobalKey<FormState>? formKey;
  final TextEditingController? usernameController;
  final TextEditingController? passwordController;
  final TextEditingController? pinController;
  final String? moduleName;
  bool isAzurePressed;
  bool isConsent;
  String consentMessage;
  final VoidCallback? onAcceptConsent;
  final VoidCallback? onDeclineConsent;

  FlutterAhaAuthentication({
    Key? key,
    this.projectLogoAsset,
    required this.projectName,
    this.enableAzureLogin = false,
    this.enableMitIdLogin = false,
    this.enableGoogleLogin = false,
    this.isPinTextboxShowing = false,
    this.onPressedGoogleLogin,
    required this.onSignIn,
    this.onCodeSubmit,
    this.onResendCode,
    this.isCodeSubmitBlock = false,
    this.isCodeSubmitLoading = false,
    this.isResendCodeAvailable = false,
    this.resendCodeCooldown,
    this.isRememberCreds = false,
    this.formKey,
    this.usernameController,
    this.passwordController,
    this.pinController,
    this.moduleName,
    this.isAzurePressed = false,
    this.isConsent = false,
    this.consentMessage = '',
    this.onAcceptConsent,
    this.onDeclineConsent,
  }) : super(key: key);

  @override
  State<FlutterAhaAuthentication> createState() =>
      _FlutterAhaAuthenticationState();
}

class _FlutterAhaAuthenticationState extends State<FlutterAhaAuthentication> {
  final _dio = Dio();
  final FocusNode _usernameFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  bool _obscureText = true;

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
          'https://test.api.ahamatic.com/marketplace/applications/validate/reducn');

      if (response.statusCode == 200) {
        final jsonData = response.data;
        String? loginUrl;

        if (loginType == LoginType.azure) {
          loginUrl = getAzureLoginUrlFromJson(jsonData);
        } else if (loginType == LoginType.mitId) {
          loginUrl = getMitIdLoginUrlFromJson(jsonData);
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

  Future<void> _onPressedAzureLogin() async {
    final loginUrl = await fetchLoginUrl(LoginType.azure);

    try {
      if (!await launchUrl(Uri.parse(loginUrl!),
          mode: LaunchMode.externalApplication)) {
        throw 'Could not launch $loginUrl';
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> _onPressedMitIdLogin() async {
    final loginUrl = await fetchLoginUrl(LoginType.mitId);

    try {
      if (!await launchUrl(Uri.parse(loginUrl!),
          mode: LaunchMode.externalApplication)) {
        throw 'Could not launch $loginUrl';
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  void _onUsernameSubmittedField(String? value) {
    widget.usernameController!.text = value!;
    FocusScope.of(context).requestFocus(_passwordFocusNode);
  }

  void _onPasswordSubmittedField(String? value) {
    widget.passwordController!.text = value!;
    widget.onSignIn();
  }

  void _onPinSubmittedField(String value) {
    widget.pinController!.text = value;
    widget.onCodeSubmit!();
  }

  String? _validateUsername(String? value) {
    if (value == null) return null;

    if (value.isEmpty) {
      return 'Enter your username';
    }

    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null) return null;

    if (value.isEmpty) {
      return 'Enter your password';
    }

    return null;
  }

  void _toggle() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    final themeColor = Theme.of(context).colorScheme;

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          widget.projectLogoAsset == null
              ? const SizedBox.shrink()
              : Image.asset(widget.projectLogoAsset!,
                  width: width / 4, height: height / 6),
          Container(
              margin: const EdgeInsets.only(top: 20),
              padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
              width: width * 0.5,
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
                    if (widget.isPinTextboxShowing && !widget.isConsent) ...[
                      Column(
                        children: [
                          TextFormField(
                            controller: widget.pinController,
                            onFieldSubmitted: _onPinSubmittedField,
                            style: const TextStyle(fontSize: 20),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly
                            ],
                            maxLength: 6,
                            decoration: const InputDecoration(
                              border: UnderlineInputBorder(),
                              labelText: "Code",
                            ),
                            onSaved: (value) =>
                                widget.pinController!.text = value!,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _CustomOutlineButton(
                        label: "SUBMIT",
                        onPressed: widget.onCodeSubmit,
                        block: widget.isCodeSubmitBlock,
                        loading: widget.isCodeSubmitLoading,
                      ),
                      const SizedBox(height: 5),
                      _ResendButton(
                        tryLogin: widget.onCodeSubmit,
                        isResendAvailable: widget.isResendCodeAvailable,
                        onPressed: widget.onResendCode,
                        resendCooldown: widget.resendCodeCooldown,
                      )
                    ],
                    const SizedBox(height: 20),
                    if (!widget.isPinTextboxShowing && !widget.isConsent) ...[
                      Text(
                        widget.projectName,
                        style: const TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        child: TextFormField(
                          controller: widget.usernameController,
                          focusNode: _usernameFocusNode,
                          validator: _validateUsername,
                          onSaved: (value) =>
                              widget.usernameController!.text = value!,
                          onFieldSubmitted: _onUsernameSubmittedField,
                          decoration: InputDecoration(
                            contentPadding: EdgeInsets.zero,
                            hintText: 'Username',
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10)),
                            prefixIcon: const Icon(Icons.person),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        child: TextFormField(
                          controller: widget.passwordController,
                          focusNode: _passwordFocusNode,
                          validator: _validatePassword,
                          onSaved: (value) =>
                              widget.passwordController!.text = value!,
                          onFieldSubmitted: _onPasswordSubmittedField,
                          decoration: InputDecoration(
                            contentPadding: EdgeInsets.zero,
                            hintText: 'Password',
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10)),
                            prefixIcon: const Icon(Icons.lock),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureText
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: Colors.grey,
                              ),
                              onPressed: _toggle,
                            ),
                          ),
                          obscureText: _obscureText,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          'Forgot Password?',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 50,
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: widget.onSignIn,
                          style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xffDC7242),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(5))),
                          child: const Text(
                            'SIGN IN',
                            style: TextStyle(fontSize: 20),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (widget.enableAzureLogin ||
                          widget.enableMitIdLogin ||
                          widget.enableGoogleLogin)
                        const Text(
                          'OR SIGN IN WITH',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey),
                        ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (widget.enableGoogleLogin)
                            _SignInAlternatives(
                                name: 'Google',
                                logoName: 'google',
                                onPressed:
                                    widget.onPressedGoogleLogin ?? () {}),
                          const SizedBox(width: 20),
                          if (widget.enableAzureLogin)
                            _SignInAlternatives(
                              name: 'Azure',
                              logoName: 'azure',
                              onPressed: () => _onPressedAzureLogin(),
                            ),
                          const SizedBox(width: 20),
                          if (widget.enableMitIdLogin)
                            _SignInAlternatives(
                                name: 'MitId',
                                logoName: 'mitId',
                                onPressed: () => _onPressedMitIdLogin()),
                        ],
                      )
                    ],
                    if (widget.isConsent) ...[
                      Column(
                        children: [
                          const Text('Abena Data',
                              style: TextStyle(
                                  fontSize: 24, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 20),
                          Text(
                            widget.consentMessage,
                            style: const TextStyle(fontSize: 18),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _CustomOutlineButton(
                                  label: "ACCEPT",
                                  onPressed: widget.onAcceptConsent,
                                  buttonBackgroundColor: themeColor.primary,
                                  labelColor: Colors.white),
                              const SizedBox(
                                width: 20,
                              ),
                              _CustomOutlineButton(
                                  label: "DECLINE",
                                  onPressed: widget.onDeclineConsent,
                                  buttonBackgroundColor: Colors.grey),
                            ],
                          )
                        ],
                      ),
                    ]
                  ],
                ),
              ))
        ]),
      ),
    );
  }
}

class _ResendButton extends StatelessWidget {
  final Function? tryLogin;
  final bool isResendAvailable;
  final VoidCallback? onPressed;
  final int? resendCooldown;
  const _ResendButton(
      {Key? key,
      required this.tryLogin,
      required this.isResendAvailable,
      required this.onPressed,
      this.resendCooldown})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeColor = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          "Did not receive OTP?",
          style: TextStyle(fontSize: 18),
        ),
        isResendAvailable
            ? TextButton(
                onPressed: onPressed,
                child: Text(
                  'Resend OTP',
                  style: TextStyle(
                    color: themeColor.primary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            : Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 34,
                ),
                child: Text(
                  '00:${resendCooldown.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    color: themeColor.primary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
      ],
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
            width: 60,
            height: 60,
            padding: const EdgeInsets.all(10),
            child: CachedNetworkImage(
              imageUrl: "https://test.auth.ahamatic.com/images/$logoName.png",
              placeholder: (context, url) => const CircularProgressIndicator(),
              errorWidget: (context, url, error) => const Icon(Icons.error),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(name),
      ],
    );
  }
}

class _CustomOutlineButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool block;
  final bool loading;
  final Color? buttonBackgroundColor;
  final Color? labelColor;

  const _CustomOutlineButton({
    Key? key,
    required this.label,
    required this.onPressed,
    this.block = false,
    this.loading = false,
    this.buttonBackgroundColor = Colors.white,
    this.labelColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeColor = Theme.of(context).colorScheme;
    const disabledAlpha = 100;

    return OutlinedButton(
      onPressed: !loading ? onPressed : null,
      style: ButtonStyle(
        minimumSize: MaterialStateProperty.all<Size>(const Size(150, 40)),
        padding: MaterialStateProperty.all<EdgeInsets>(
          const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
        ),
        shape: MaterialStateProperty.all<RoundedRectangleBorder>(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        side: MaterialStateBorderSide.resolveWith(
          (states) {
            if (states.contains(MaterialState.disabled)) {
              return BorderSide(
                width: 1.5,
                color: themeColor.primary.withAlpha(disabledAlpha),
              );
            }

            return BorderSide(width: 1.5, color: themeColor.primary);
          },
        ),
        foregroundColor: MaterialStateProperty.resolveWith(
          (states) {
            if (states.contains(MaterialState.pressed)) {
              return themeColor.tertiary;
            }

            if (states.contains(MaterialState.disabled)) {
              return themeColor.primary.withAlpha(disabledAlpha);
            }

            return themeColor.primary;
          },
        ),
        backgroundColor: MaterialStateColor.resolveWith(
          (states) {
            if (states.contains(MaterialState.pressed)) {
              return themeColor.primary;
            }

            return buttonBackgroundColor!;
          },
        ),
      ),
      child: Row(
        mainAxisSize: block ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (loading) ...[
            SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                color: themeColor.primary.withAlpha(disabledAlpha),
              ),
            ),
            const SizedBox(width: 15),
          ],
          Text(
            loading ? "Loading.." : label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              overflow: TextOverflow.ellipsis,
              color: labelColor,
            ),
          )
        ],
      ),
    );
  }
}
