import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// Utility class for PKCE (Proof Key for Code Exchange) operations.
///
/// Provides methods for generating secure random strings, code verifiers,
/// and code challenges as defined in RFC 7636.
class PkceUtils {
  /// Character set for generating random strings (RFC 7636 compliant)
  static const String _charset =
      'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';

  /// Generates a cryptographically secure random string.
  ///
  /// [length] - The desired length of the string (default: 32)
  static String generateRandomString([int length = 32]) {
    final random = Random.secure();
    return List.generate(
      length,
      (_) => _charset[random.nextInt(_charset.length)],
    ).join();
  }

  /// Generates a PKCE code verifier.
  ///
  /// The code verifier is a high-entropy random string between 43 and 128
  /// characters as defined in RFC 7636.
  static String generateCodeVerifier() {
    return generateRandomString(128);
  }

  /// Generates a PKCE code challenge from a code verifier.
  ///
  /// Uses the S256 method (SHA-256 hash, base64url encoded without padding).
  static String generateCodeChallenge(String codeVerifier) {
    final bytes = utf8.encode(codeVerifier);
    final digest = sha256.convert(bytes);
    return base64Url.encode(digest.bytes).replaceAll('=', '');
  }

  /// Generates a random state parameter for OAuth2.
  ///
  /// The state parameter is used to prevent CSRF attacks.
  static String generateState() {
    return generateRandomString(32);
  }

  /// Validates that a code verifier meets PKCE requirements.
  ///
  /// Returns true if the verifier is between 43 and 128 characters
  /// and contains only allowed characters.
  static bool isValidCodeVerifier(String verifier) {
    if (verifier.length < 43 || verifier.length > 128) {
      return false;
    }
    return verifier.split('').every((char) => _charset.contains(char));
  }
}
