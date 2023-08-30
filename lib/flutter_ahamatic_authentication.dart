import 'package:flutter/material.dart';

class FlutterAhaAuthentication extends StatefulWidget {
  final String projectName;
  final String projectLogoAsset;
  final bool openiamAzureLogin;

  const FlutterAhaAuthentication({
    Key? key,
    required this.projectLogoAsset,
    required this.projectName,
    this.openiamAzureLogin = false,
  }) : super(key: key);

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

    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Image.asset(widget.projectLogoAsset,
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
          child: Column(
            children: [
              const SizedBox(height: 20),
              Text(
                widget.projectName,
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 50,
                child: TextFormField(
                  decoration: InputDecoration(
                      contentPadding: EdgeInsets.zero,
                      hintText: 'Username',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                      prefixIcon: const Icon(Icons.person)),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 50,
                child: TextFormField(
                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.zero,
                    hintText: 'Password',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureText ? Icons.visibility : Icons.visibility_off,
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
                  onPressed: () {},
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
                  const _SignInAlternatives(
                      name: 'Google',
                      assetImage:
                          'packages/flutter_ahamatic_authentication/assets/images/google.png'),
                  const SizedBox(width: 20),
                  if (widget.openiamAzureLogin)
                    const _SignInAlternatives(
                        name: 'Azure',
                        assetImage:
                            'packages/flutter_ahamatic_authentication/assets/images/azure.png'),
                ],
              )
            ],
          ))
    ]);
  }
}

class _SignInAlternatives extends StatelessWidget {
  final String assetImage;
  final String name;

  const _SignInAlternatives({
    Key? key,
    required this.assetImage,
    required this.name,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: () {
            // Handle onPressed action here
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent, // Set button background color
            elevation: 0, // No shadow
            padding: EdgeInsets.zero, // No padding
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
