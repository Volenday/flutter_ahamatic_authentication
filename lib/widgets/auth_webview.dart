import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Conditional imports
import 'auth_webview_stub.dart'
    if (dart.library.html) 'auth_webview_web.dart'
    if (dart.library.io) 'auth_webview_mobile.dart';

/// Abstract interface for authentication WebView widget.
///
/// This provides a platform-agnostic interface for showing authentication
/// web content. The actual implementation differs between web and mobile.
abstract class AuthWebView extends StatefulWidget {
  /// The URL to load for authentication
  final String url;

  /// Callback when authentication succeeds with a token
  final Function(String token)? onAuthSuccess;

  /// Callback when authentication fails
  final Function(String error)? onAuthError;

  /// Callback when the user closes the auth flow
  final VoidCallback? onClose;

  const AuthWebView({
    super.key,
    required this.url,
    this.onAuthSuccess,
    this.onAuthError,
    this.onClose,
  });

  /// Factory constructor that returns the appropriate platform implementation
  factory AuthWebView.create({
    Key? key,
    required String url,
    Function(String token)? onAuthSuccess,
    Function(String error)? onAuthError,
    VoidCallback? onClose,
  }) {
    return createAuthWebView(
      key: key,
      url: url,
      onAuthSuccess: onAuthSuccess,
      onAuthError: onAuthError,
      onClose: onClose,
    );
  }
}

/// Shows an authentication dialog appropriate for the current platform.
///
/// On mobile, this shows a WebView in a dialog.
/// On web, this opens the URL in a popup or redirects.
Future<void> showAuthDialog(
  BuildContext context, {
  required String url,
  Function(String token)? onAuthSuccess,
  Function(String error)? onAuthError,
  VoidCallback? onClose,
  bool usePopup = true,
}) async {
  if (kIsWeb) {
    // On web, we handle differently based on usePopup
    await showWebAuthDialog(
      context,
      url: url,
      onAuthSuccess: onAuthSuccess,
      onAuthError: onAuthError,
      onClose: onClose,
      usePopup: usePopup,
    );
  } else {
    // On mobile, show a dialog with WebView
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.85,
            child: Column(
              children: [
                _buildDialogHeader(context, onClose),
                Expanded(
                  child: AuthWebView.create(
                    url: url,
                    onAuthSuccess: (token) {
                      Navigator.of(context).pop();
                      onAuthSuccess?.call(token);
                    },
                    onAuthError: (error) {
                      Navigator.of(context).pop();
                      onAuthError?.call(error);
                    },
                    onClose: () {
                      Navigator.of(context).pop();
                      onClose?.call();
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Widget _buildDialogHeader(BuildContext context, VoidCallback? onClose) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      border: Border(
        bottom: BorderSide(
          color: Theme.of(context).dividerColor,
        ),
      ),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Sign In',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        IconButton(
          icon: const Icon(Icons.close, color: Colors.red),
          onPressed: () {
            Navigator.of(context).pop();
            onClose?.call();
          },
        ),
      ],
    ),
  );
}

