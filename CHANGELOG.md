## 0.0.3

- Migrated Android plugin to Built-in Kotlin: removed explicit Kotlin Gradle Plugin from `build.gradle` (Flutter applies it when needed; compatible with AGP < 9 and AGP >= 9).
- Added Swift Package Manager support for iOS while keeping CocoaPods support.
- Note: Swift Package Manager with `FlutterFramework` requires Flutter **≥ 3.41** in consumer apps with SPM enabled. The package minimum in `pubspec.yaml` remains **3.3.0** for Dart/API.

## 0.0.1

- Initial release.
