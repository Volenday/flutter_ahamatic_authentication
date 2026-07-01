## 0.0.4

- Removed the unused `fluttertoast` dependency (it applied the Kotlin Gradle Plugin on Android and had no Swift Package Manager support on iOS, and was never referenced anywhere in the plugin's code).
- Refreshed the lockfile-resolvable `webview_flutter`/`webview_flutter_android` transitive dependency so it resolves to a Built-in Kotlin–compatible version (was pinned at an older version that still applied the Kotlin Gradle Plugin).
- Remaining note: `device_info_plus` still applies the Kotlin Gradle Plugin in its latest upstream release, so it will continue to appear in Flutter's "plugins that apply KGP" warning until its maintainers migrate.

## 0.0.3

- Migrated Android plugin to Built-in Kotlin: removed explicit Kotlin Gradle Plugin from `build.gradle` (Flutter applies it when needed; compatible with AGP < 9 and AGP >= 9).
- Added Swift Package Manager support for iOS while keeping CocoaPods support.
- Note: Swift Package Manager with `FlutterFramework` requires Flutter **≥ 3.41** in consumer apps with SPM enabled. The package minimum in `pubspec.yaml` remains **3.3.0** for Dart/API.

## 0.0.1

- Initial release.
