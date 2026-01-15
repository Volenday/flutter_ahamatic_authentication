import UIKit
import Flutter

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    
    // Check if app was launched from a URL
    if let url = launchOptions?[.url] as? URL {
      NSLog("🔗 App launched with URL: %@", url.absoluteString)
    }
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // Handle deep links for OAuth callbacks (when app is already running)
  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
    NSLog("🔗 AppDelegate received URL: %@", url.absoluteString)
    NSLog("🔗 URL scheme: %@", url.scheme ?? "nil")
    NSLog("🔗 URL host: %@", url.host ?? "nil")
    NSLog("🔗 URL path: %@", url.path)
    
    let result = super.application(app, open: url, options: options)
    NSLog("🔗 Super returned: %@", result ? "true" : "false")
    return result
  }
  
  // Handle Universal Links (if configured)
  override func application(
    _ application: UIApplication,
    continue userActivity: NSUserActivity,
    restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void
  ) -> Bool {
    NSLog("🔗 Universal Link received")
    if let url = userActivity.webpageURL {
      NSLog("🔗 Universal Link URL: %@", url.absoluteString)
    }
    return super.application(application, continue: userActivity, restorationHandler: restorationHandler)
  }
}
