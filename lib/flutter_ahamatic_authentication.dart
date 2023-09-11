import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FlutterAhaAuthentication extends StatefulWidget {
  final String projectName;
  final String? projectLogoAsset;
  final bool enableAzureLogin;
  final bool enableOpenIAMLogin;
  final VoidCallback? onPressedAzureLogin;
  final VoidCallback? onPressedGoogleLogin;
  final GlobalKey<FormState>? formKey;
  final TextEditingController? usernameController;
  final TextEditingController? passwordController;
  final TextEditingController? pinController;
  final FocusNode? usernameFocusNode;
  final FocusNode? passwordFocusNode;
  final String? Function(String?)? usernameValidator;
  final String? Function(String?)? otpValidator;
  final void Function(String?)? onSavedUserName;
  final void Function(String?)? onSavedPassword;
  final void Function(String?)? onSavedOtp;
  final VoidCallback onSignIn;
  final bool isPINTextboxShowing;
  final void Function(String)? onPinSubmittedField;
  final VoidCallback? onCodeSubmit;
  final VoidCallback? onResendCode;
  final bool isResendAvailable;
  final int? resendCooldown;
  final bool loading;
  final bool block;
  final String? loadingText;
  final String? Function(String?)? passwordValidator;
  final void Function(String?)? onUsernameSubmittedField;
  final void Function(String?)? onPasswordSubmittedField;

  const FlutterAhaAuthentication(
      {Key? key,
      this.projectLogoAsset,
      required this.projectName,
      this.enableAzureLogin = false,
      this.onPressedAzureLogin,
      this.onPressedGoogleLogin,
      this.enableOpenIAMLogin = true,
      this.usernameController,
      this.passwordController,
      this.usernameFocusNode,
      this.passwordFocusNode,
      this.usernameValidator,
      this.onSavedUserName,
      this.onSavedPassword,
      required this.onSignIn,
      this.isPINTextboxShowing = false,
      this.pinController,
      this.onPinSubmittedField,
      this.otpValidator,
      this.onSavedOtp,
      this.onCodeSubmit,
      this.onResendCode,
      this.isResendAvailable = false,
      this.resendCooldown,
      this.loading = false,
      this.block = false,
      this.loadingText,
      this.passwordValidator,
      this.onUsernameSubmittedField,
      this.onPasswordSubmittedField,
      this.formKey})
      : super(key: key);

  @override
  State<FlutterAhaAuthentication> createState() =>
      _FlutterAhaAuthenticationState();
}

class _FlutterAhaAuthenticationState extends State<FlutterAhaAuthentication> {
  bool _obscureText = true;

  void _toggle() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;

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
                    if (widget.enableOpenIAMLogin)
                      Column(
                        children: [
                          if (widget.isPINTextboxShowing) ...[
                            TextFormField(
                              controller: widget.pinController,
                              onFieldSubmitted: widget.onPinSubmittedField,
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
                              validator: widget.otpValidator,
                              onSaved: widget.onSavedOtp,
                            ),
                            const SizedBox(height: 10),
                            _CustomOutlineButton(
                              label: "Submit",
                              onPressed: widget.onCodeSubmit,
                              block: widget.block,
                              loading: widget.loading,
                              loadingText: widget.loadingText,
                            ),
                            const SizedBox(height: 5),
                            _ResendButton(
                              tryLogin: widget.onCodeSubmit,
                              isResendAvailable: widget.isResendAvailable,
                              onPressed: widget.onResendCode,
                              resendCooldown: widget.resendCooldown,
                            )
                          ],
                          const SizedBox(height: 20),
                          if (!widget.isPINTextboxShowing) ...[
                            Text(
                              widget.projectName,
                              style: const TextStyle(
                                  fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              height: 50,
                              child: TextFormField(
                                controller: widget.usernameController,
                                focusNode: widget.usernameFocusNode,
                                validator: widget.usernameValidator,
                                onSaved: widget.onSavedUserName,
                                onFieldSubmitted:
                                    widget.onUsernameSubmittedField,
                                decoration: InputDecoration(
                                    contentPadding: EdgeInsets.zero,
                                    hintText: 'Username',
                                    border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(10)),
                                    prefixIcon: const Icon(Icons.person)),
                              ),
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              height: 50,
                              child: TextFormField(
                                controller: widget.passwordController,
                                focusNode: widget.passwordFocusNode,
                                validator: widget.passwordValidator,
                                onSaved: widget.onSavedPassword,
                                onFieldSubmitted:
                                    widget.onPasswordSubmittedField,
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
                                        borderRadius:
                                            BorderRadius.circular(5))),
                                child: const Text(
                                  'SIGN IN',
                                  style: TextStyle(fontSize: 20),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    const SizedBox(height: 20),
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
                        _SignInAlternatives(
                            name: 'Google',
                            assetImage:
                                'packages/flutter_ahamatic_authentication/assets/images/google.png',
                            onPressed: widget.onPressedGoogleLogin ?? () {}),
                        const SizedBox(width: 20),
                        if (widget.enableAzureLogin)
                          _SignInAlternatives(
                            name: 'Azure',
                            assetImage:
                                'packages/flutter_ahamatic_authentication/assets/images/azure.png',
                            onPressed: widget.onPressedAzureLogin ?? () {},
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
  final String assetImage;
  final String name;
  final VoidCallback onPressed;

  const _SignInAlternatives({
    Key? key,
    required this.assetImage,
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
            child: Image(
              image: AssetImage(assetImage),
              width: 60,
              height: 60,
              fit: BoxFit.fill,
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
  final String? loadingText;

  const _CustomOutlineButton({
    Key? key,
    required this.label,
    required this.onPressed,
    this.block = false,
    this.loading = false,
    this.loadingText,
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

            return Colors.white;
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
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              overflow: TextOverflow.ellipsis,
            ),
          )
        ],
      ),
    );
  }
}
