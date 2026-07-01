import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Utility class for consistent error handling across Cidaas services.
///
/// Provides methods to:
/// - Log detailed error information to console (including stack traces)
/// - Generate user-friendly error messages
/// - Handle DioException and PlatformException specifically
class CidaasErrorHandler {
  /// Error code used when the user manually cancels the authentication flow.
  /// This should NOT trigger error callbacks - it's a normal user action.
  static const String userCancelledCode = 'user_cancelled';
  /// Logs detailed error information to the console.
  ///
  /// [error] - The error object
  /// [stackTrace] - The stack trace
  /// [context] - A description of where the error occurred
  /// [serviceName] - The name of the service where the error occurred
  static void logError(
    Object error,
    StackTrace stackTrace,
    String context, {
    String serviceName = 'CidaasService',
  }) {
    debugPrint('');
    debugPrint('╔══════════════════════════════════════════════════════════════');
    debugPrint('║ ❌ ERROR: $context');
    debugPrint('║ Service: $serviceName');
    debugPrint('╠══════════════════════════════════════════════════════════════');
    debugPrint('║ Type: ${error.runtimeType}');
    debugPrint('║ Message: $error');

    // Log HTTP details for DioException
    if (error is DioException) {
      _logDioException(error);
    }

    // Log PlatformException details
    if (error is PlatformException) {
      _logPlatformException(error);
    }

    debugPrint('╠══════════════════════════════════════════════════════════════');
    debugPrint('║ STACK TRACE:');
    debugPrint('╠══════════════════════════════════════════════════════════════');

    // Print stack trace line by line for better readability
    final stackLines = stackTrace.toString().split('\n');
    for (final line in stackLines.take(15)) {
      if (line.trim().isNotEmpty) {
        debugPrint('║ $line');
      }
    }
    if (stackLines.length > 15) {
      debugPrint('║ ... (${stackLines.length - 15} more lines)');
    }
    debugPrint('╚══════════════════════════════════════════════════════════════');
    debugPrint('');
  }

  /// Logs DioException specific details.
  static void _logDioException(DioException error) {
    debugPrint('╠══════════════════════════════════════════════════════════════');
    debugPrint('║ HTTP DETAILS:');
    debugPrint('╠══════════════════════════════════════════════════════════════');
    debugPrint('║ Exception Type: ${error.type}');
    debugPrint('║ Request URL: ${error.requestOptions.uri}');
    debugPrint('║ Request Method: ${error.requestOptions.method}');

    if (error.response != null) {
      debugPrint('║ Status Code: ${error.response?.statusCode}');
      debugPrint('║ Status Message: ${error.response?.statusMessage}');
      debugPrint('║ Response Headers:');
      error.response?.headers.forEach((name, values) {
        debugPrint('║   $name: ${values.join(", ")}');
      });
      debugPrint('║ Response Body:');
      final responseData = error.response?.data;
      if (responseData != null) {
        final bodyStr = responseData.toString();
        // Truncate if too long
        if (bodyStr.length > 500) {
          debugPrint('║   ${bodyStr.substring(0, 500)}...');
          debugPrint('║   (truncated, ${bodyStr.length} total characters)');
        } else {
          debugPrint('║   $bodyStr');
        }
      }
    } else {
      debugPrint('║ No response received from server');
    }
  }

  /// Logs PlatformException specific details.
  static void _logPlatformException(PlatformException error) {
    debugPrint('╠══════════════════════════════════════════════════════════════');
    debugPrint('║ PLATFORM DETAILS:');
    debugPrint('╠══════════════════════════════════════════════════════════════');
    debugPrint('║ Code: ${error.code}');
    debugPrint('║ Message: ${error.message}');
    if (error.details != null) {
      debugPrint('║ Details: ${error.details}');
    }
  }

  /// Returns a user-friendly error message based on the error type.
  ///
  /// [error] - The error object
  /// [fallbackMessage] - Message to use if no specific handler matches
  static String getUserFriendlyMessage(
    Object error, {
    String fallbackMessage = 'An unexpected error occurred. Please try again.',
  }) {
    if (error is DioException) {
      return _getDioErrorMessage(error);
    }

    if (error is PlatformException) {
      return _getPlatformErrorMessage(error);
    }

    if (error is FormatException) {
      return 'Invalid data format received. Please try again.';
    }

    if (error is TypeError) {
      return 'Error processing server response. Please try again.';
    }

    if (error is ArgumentError) {
      return 'Invalid configuration. Please contact support.';
    }

    final errorStr = error.toString().toLowerCase();

    if (errorStr.contains('timeout') || errorStr.contains('timed out')) {
      return 'Connection timed out. Please check your internet connection and try again.';
    }

    if (errorStr.contains('socket') ||
        errorStr.contains('network') ||
        errorStr.contains('connection')) {
      return 'Connection error. Please check your internet connection and try again.';
    }

    if (errorStr.contains('unauthorized') || errorStr.contains('401')) {
      return 'Invalid session. Please sign in again.';
    }

    if (errorStr.contains('forbidden') || errorStr.contains('403')) {
      return 'You do not have permission to perform this action.';
    }

    if (errorStr.contains('cancelled') || errorStr.contains('canceled')) {
      return 'The operation was cancelled.';
    }

    return fallbackMessage;
  }

  /// Get user-friendly message for Dio errors.
  static String _getDioErrorMessage(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return 'Connection timed out. Please check your internet connection and try again.';

      case DioExceptionType.connectionError:
        return 'Could not connect to the server. Please check your internet connection.';

      case DioExceptionType.badCertificate:
        return 'Security error in connection. Please contact technical support.';

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        switch (statusCode) {
          case 400:
            return 'Invalid request. Please verify the data and try again.';
          case 401:
            return 'Session expired or invalid credentials. Please sign in again.';
          case 403:
            return 'You do not have permission to perform this action.';
          case 404:
            return 'The requested resource was not found.';
          case 500:
            return 'Internal server error. Please try again later.';
          case 502:
            return 'Bad gateway. The server is temporarily unavailable.';
          case 503:
            return 'Service unavailable. Please try again later.';
          case 504:
            return 'Gateway timeout. The server took too long to respond.';
          default:
            return 'Server error (code: $statusCode). Please try again later.';
        }

      case DioExceptionType.cancel:
        return 'The operation was cancelled.';

      case DioExceptionType.unknown:
        if (error.message?.contains('SocketException') == true) {
          return 'Could not connect to the server. Please check your internet connection.';
        }
        return 'A connection error occurred. Please try again.';
    }
  }

  /// Get user-friendly message for Platform errors.
  static String _getPlatformErrorMessage(PlatformException error) {
    final code = error.code.toLowerCase();
    final details = error.details?.toString().toLowerCase() ?? '';

    // User cancellation
    if (code.contains('cancel') ||
        details.contains('user cancelled') ||
        details.contains('user canceled')) {
      return 'Authentication was cancelled.';
    }

    // Authorization failures
    if (code.contains('authorize_failed')) {
      return 'Authorization failed. Please try again.';
    }

    // Sign-out failures
    if (code.contains('end_session_failed') ||
        code.contains('signout_error')) {
      return 'Sign out failed. Please try again.';
    }

    // Invalid response
    if (code.contains('invalid_response')) {
      return 'Invalid response from server. Please try again.';
    }

    // Token errors
    if (code.contains('token')) {
      return 'Authentication error. Please sign in again.';
    }

    // Network/connection errors
    if (code.contains('network') || code.contains('connection')) {
      return 'Network error. Please check your internet connection.';
    }

    return error.message ?? 'An authentication error occurred. Please try again.';
  }

  /// Creates a PlatformException with proper error logging.
  ///
  /// Use this when you need to throw a PlatformException but also want
  /// to log the error details first.
  static PlatformException createAndLogException({
    required String code,
    required String message,
    required Object originalError,
    required StackTrace stackTrace,
    required String context,
    String serviceName = 'CidaasService',
    dynamic details,
  }) {
    logError(originalError, stackTrace, context, serviceName: serviceName);

    return PlatformException(
      code: code,
      message: message,
      details: details,
      stacktrace: stackTrace.toString(),
    );
  }
}

