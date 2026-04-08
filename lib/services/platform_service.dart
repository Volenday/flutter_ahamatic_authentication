import 'package:flutter/foundation.dart';

/// Platform detection service that works on all platforms including web.
///
/// This service provides platform detection without using dart:io,
/// which is not available on web.
class PlatformService {
  /// Returns true if running on web
  static bool get isWeb => kIsWeb;

  /// Returns true if running on Android (false on web)
  static bool get isAndroid {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android;
  }

  /// Returns true if running on iOS (false on web)
  static bool get isIOS {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.iOS;
  }

  /// Returns true if running on macOS (false on web)
  static bool get isMacOS {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.macOS;
  }

  /// Returns true if running on Windows (false on web)
  static bool get isWindows {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.windows;
  }

  /// Returns true if running on Linux (false on web)
  static bool get isLinux {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.linux;
  }

  /// Returns true if running on a mobile platform (Android or iOS)
  static bool get isMobile => isAndroid || isIOS;

  /// Returns true if running on a desktop platform
  static bool get isDesktop => isMacOS || isWindows || isLinux;

  /// Returns the current platform name
  static String get platformName {
    if (isWeb) return 'web';
    if (isAndroid) return 'android';
    if (isIOS) return 'ios';
    if (isMacOS) return 'macos';
    if (isWindows) return 'windows';
    if (isLinux) return 'linux';
    return 'unknown';
  }
}

