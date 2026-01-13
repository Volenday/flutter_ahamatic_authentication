/// Callback type for successful authentication.
///
/// Called when authentication completes successfully with the received tokens.
typedef AuthSuccessCallback = void Function({
  String? accessToken,
  String? refreshToken,
  String? idToken,
});

/// Callback type for authentication errors.
///
/// Called when an error occurs during authentication.
typedef AuthErrorCallback = void Function(String errorMessage);
