import 'dart:async';

import 'package:flutter/material.dart';
import 'package:universal_html/html.dart' as html;
import 'auth_webview.dart';

/// Web implementation of AuthWebView.
///
/// On web, we can't use a native WebView, so we redirect or use a popup.
class AuthWebViewWeb extends AuthWebView {
  const AuthWebViewWeb({
    super.key,
    required super.url,
    super.onAuthSuccess,
    super.onAuthError,
    super.onClose,
  });

  @override
  State<AuthWebViewWeb> createState() => _AuthWebViewWebState();
}

class _AuthWebViewWebState extends State<AuthWebViewWeb> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // On web, we typically redirect instead of embedding
    // This widget shows a loading state and instructions
    _checkForCallback();
  }

  void _checkForCallback() {
    // Check if we're on a callback URL
    final uri = Uri.parse(html.window.location.href);
    if (uri.queryParameters.containsKey('token') ||
        uri.queryParameters.containsKey('refreshToken')) {
      final token = uri.queryParameters['token'];
      if (token != null) {
        widget.onAuthSuccess?.call(token);
      }
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.open_in_browser,
            size: 64,
            color: Colors.blue,
          ),
          const SizedBox(height: 24),
          Text(
            'Authentication',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          const Text(
            'Click the button below to open the login page.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              // Open in same window (redirect)
              html.window.location.href = widget.url;
            },
            icon: const Icon(Icons.login),
            label: const Text('Open Login Page'),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: widget.onClose,
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}

/// Creates the web implementation of AuthWebView
AuthWebView createAuthWebView({
  Key? key,
  required String url,
  Function(String token)? onAuthSuccess,
  Function(String error)? onAuthError,
  VoidCallback? onClose,
}) {
  return AuthWebViewWeb(
    key: key,
    url: url,
    onAuthSuccess: onAuthSuccess,
    onAuthError: onAuthError,
    onClose: onClose,
  );
}

/// Shows web authentication dialog using popup or redirect
Future<void> showWebAuthDialog(
  BuildContext context, {
  required String url,
  Function(String token)? onAuthSuccess,
  Function(String error)? onAuthError,
  VoidCallback? onClose,
  bool usePopup = true,
}) async {
  if (usePopup) {
    // Open in popup
    final popup = html.window.open(
      url,
      'auth_popup',
      'width=500,height=700,scrollbars=yes,resizable=yes',
    );

    // Poll for popup close or success
    final completer = Completer<void>();

    Timer.periodic(const Duration(milliseconds: 500), (timer) {
      try {
        final isClosed = popup.closed == true;
        if (isClosed) {
          timer.cancel();
          if (!completer.isCompleted) {
            onClose?.call();
            completer.complete();
          }
        }
      } catch (e) {
        // Cross-origin access might throw
      }
    });

    // Listen for postMessage from popup
    late final html.EventListener messageListener;
    messageListener = (html.Event event) {
      if (event is html.MessageEvent) {
        try {
          final data = event.data;
          if (data is Map && data['type'] == 'auth_success') {
            final token = data['token'] as String?;
            if (token != null) {
              html.window.removeEventListener('message', messageListener);
              popup.close();
              onAuthSuccess?.call(token);
              if (!completer.isCompleted) {
                completer.complete();
              }
            }
          }
        } catch (e) {
          debugPrint('Error parsing auth message: $e');
        }
      }
    };

    html.window.addEventListener('message', messageListener);

    await completer.future;
    html.window.removeEventListener('message', messageListener);
  } else {
    // Redirect in same window
    html.window.location.href = url;
  }
}

