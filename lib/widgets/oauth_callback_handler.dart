import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_ahamatic_authentication/cidaas/cidaas_entity.dart';
import 'package:flutter_ahamatic_authentication/cidaas/cidaas_web_auth.dart';
import 'package:universal_html/html.dart' as html;

/// Widget to handle OAuth callback on web.
///
/// Place this widget in your callback route to handle the OAuth response.
///
/// Example usage with go_router:
/// ```dart
/// GoRoute(
///   path: '/callback',
///   builder: (context, state) => OAuthCallbackHandler(
///     cidaasConfiguration: yourCidaasConfig,
///     onSuccess: (response) {
///       // Handle successful authentication
///       context.go('/home');
///     },
///     onError: (error) {
///       // Handle error
///       context.go('/login');
///     },
///   ),
/// ),
/// ```
class OAuthCallbackHandler extends StatefulWidget {
  /// Cidaas configuration
  final CidaasConfiguration cidaasConfiguration;

  /// API URL for Ahamatic
  final String apiUrl;

  /// API key for your module
  final String apiKey;

  /// Development account credentials
  final Map<String, String> devAccount;

  /// Called when authentication is successful
  final Function(AhamaticResponse response)? onSuccess;

  /// Called when authentication fails
  final Function(String error)? onError;

  /// Custom loading widget
  final Widget? loadingWidget;

  const OAuthCallbackHandler({
    super.key,
    required this.cidaasConfiguration,
    required this.apiUrl,
    required this.apiKey,
    required this.devAccount,
    this.onSuccess,
    this.onError,
    this.loadingWidget,
  });

  @override
  State<OAuthCallbackHandler> createState() => _OAuthCallbackHandlerState();
}

class _OAuthCallbackHandlerState extends State<OAuthCallbackHandler> {
  bool _isProcessing = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      _handleCallback();
    } else {
      _error = 'OAuth callback only works on web';
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _handleCallback() async {
    try {
      final dio = Dio();
      final cidaasWebAuth = CidaasWebAuth(
        dio,
        widget.cidaasConfiguration,
        widget.devAccount,
      );

      // Handle the OAuth callback
      final authResult = cidaasWebAuth.handleCallback();

      if (authResult == null) {
        // Check for error in URL
        final uri = Uri.parse(html.window.location.href);
        final error = uri.queryParameters['error'];
        final errorDescription = uri.queryParameters['error_description'];

        setState(() {
          _error = errorDescription ?? error ?? 'Authentication failed';
          _isProcessing = false;
        });

        widget.onError?.call(_error!);
        return;
      }

      // Exchange code for tokens
      final response = await cidaasWebAuth.signInComplete(
        widget.apiKey,
        widget.apiUrl,
        authResult,
      );

      widget.onSuccess?.call(response);
    } catch (e) {
      debugPrint('OAuth callback error: $e');
      setState(() {
        _error = e.toString();
        _isProcessing = false;
      });
      widget.onError?.call(_error!);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isProcessing) {
      return widget.loadingWidget ??
          Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 24),
                  Text(
                    'Completing authentication...',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
          );
    }

    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 24),
              Text(
                'Authentication Failed',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  // Navigate back to login or retry
                  Navigator.of(context).pop();
                },
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}

/// Helper function to check if current URL is an OAuth callback
bool isOAuthCallback() {
  if (!kIsWeb) return false;

  try {
    final uri = Uri.parse(html.window.location.href);
    return uri.queryParameters.containsKey('code') ||
        uri.queryParameters.containsKey('error');
  } catch (e) {
    return false;
  }
}

/// Helper function to send auth result to parent window (for popup flow)
void sendAuthResultToParent(String code, String state) {
  if (!kIsWeb) return;

  try {
    html.window.opener?.postMessage(
      {
        'type': 'cidaas_auth_callback',
        'code': code,
        'state': state,
      },
      '*',
    );
    html.window.close();
  } catch (e) {
    debugPrint('Error sending auth result to parent: $e');
  }
}

