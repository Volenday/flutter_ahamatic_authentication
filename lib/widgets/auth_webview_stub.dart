import 'package:flutter/material.dart';
import 'auth_webview.dart';

/// Stub implementation - this file is used when neither dart:html nor dart:io
/// is available (should never happen in practice).
AuthWebView createAuthWebView({
  Key? key,
  required String url,
  Function(String token)? onAuthSuccess,
  Function(String error)? onAuthError,
  VoidCallback? onClose,
}) {
  throw UnsupportedError('Cannot create AuthWebView on this platform');
}

Future<void> showWebAuthDialog(
  BuildContext context, {
  required String url,
  Function(String token)? onAuthSuccess,
  Function(String error)? onAuthError,
  VoidCallback? onClose,
  bool usePopup = true,
}) async {
  throw UnsupportedError('Web auth dialog not supported on this platform');
}

