import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'auth_webview.dart';

/// Mobile implementation of AuthWebView using webview_flutter.
class AuthWebViewMobile extends AuthWebView {
  const AuthWebViewMobile({
    super.key,
    required super.url,
    super.onAuthSuccess,
    super.onAuthError,
    super.onClose,
  });

  @override
  State<AuthWebViewMobile> createState() => _AuthWebViewMobileState();
}

class _AuthWebViewMobileState extends State<AuthWebViewMobile> {
  late final WebViewController _controller;
  int _loadingProgress = 0;
  bool _isLoading = true;

  final Set<Factory<OneSequenceGestureRecognizer>> _gestureRecognizers = {
    Factory(() => EagerGestureRecognizer())
  };

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  void _initWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) {
            setState(() => _loadingProgress = progress);
          },
          onPageStarted: (_) {
            setState(() {
              _isLoading = true;
              _loadingProgress = 0;
            });
          },
          onPageFinished: (_) {
            setState(() {
              _isLoading = false;
              _loadingProgress = 100;
            });
          },
          onWebResourceError: (error) {
            debugPrint('WebView error: ${error.errorCode} - ${error.description}');
            widget.onAuthError?.call(error.description);
          },
          onNavigationRequest: _handleNavigation,
        ),
      )
      ..loadRequest(Uri.parse(widget.url));

    // Clear cookies for fresh login
    WebViewCookieManager().clearCookies();
  }

  NavigationDecision _handleNavigation(NavigationRequest request) {
    final uri = Uri.parse(request.url);

    // Check for token in callback URL
    if (uri.queryParameters.containsKey('token') ||
        uri.queryParameters.containsKey('refreshToken')) {
      final token = uri.queryParameters['token'];
      if (token != null) {
        widget.onAuthSuccess?.call(token);
        return NavigationDecision.prevent;
      }
    }

    // Check for error
    if (uri.queryParameters.containsKey('error')) {
      widget.onAuthError?.call(
        uri.queryParameters['error_description'] ??
            uri.queryParameters['error'] ??
            'Authentication failed',
      );
      return NavigationDecision.prevent;
    }

    return NavigationDecision.navigate;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        WebViewWidget(
          controller: _controller,
          gestureRecognizers: _gestureRecognizers,
        ),
        if (_isLoading)
          Container(
            color: Colors.white.withValues(alpha: 0.8),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    value: _loadingProgress > 0 ? _loadingProgress / 100 : null,
                    color: const Color(0xFF003D7F),
                  ),
                  const SizedBox(height: 16),
                  Text('Loading... $_loadingProgress%'),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// Creates the mobile implementation of AuthWebView
AuthWebView createAuthWebView({
  Key? key,
  required String url,
  Function(String token)? onAuthSuccess,
  Function(String error)? onAuthError,
  VoidCallback? onClose,
}) {
  return AuthWebViewMobile(
    key: key,
    url: url,
    onAuthSuccess: onAuthSuccess,
    onAuthError: onAuthError,
    onClose: onClose,
  );
}

/// Mobile version - not used, included for API compatibility
Future<void> showWebAuthDialog(
  BuildContext context, {
  required String url,
  Function(String token)? onAuthSuccess,
  Function(String error)? onAuthError,
  VoidCallback? onClose,
  bool usePopup = true,
}) async {
  // On mobile, we use the standard showAuthDialog which uses WebView
  // This function shouldn't be called on mobile
  debugPrint('showWebAuthDialog called on mobile - using standard dialog');
}

