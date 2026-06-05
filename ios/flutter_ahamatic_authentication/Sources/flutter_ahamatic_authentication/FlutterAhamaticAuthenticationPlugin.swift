import Flutter
import UIKit
import AuthenticationServices

public class FlutterAhamaticAuthenticationPlugin: NSObject, FlutterPlugin, ASWebAuthenticationPresentationContextProviding {
  private var currentSession: ASWebAuthenticationSession?

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "flutter_ahamatic_authentication", binaryMessenger: registrar.messenger())
    let instance = FlutterAhamaticAuthenticationPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getPlatformVersion":
      result("iOS " + UIDevice.current.systemVersion)
    case "launchMitIdAuth":
      launchMitIdAuth(call: call, result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func launchMitIdAuth(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let authUrlString = args["authUrl"] as? String,
          let callbackUrlScheme = args["callbackUrlScheme"] as? String,
          !callbackUrlScheme.isEmpty,
          let url = URL(string: authUrlString) else {
      result(FlutterError(code: "INVALID_ARGS", message: "authUrl and callbackUrlScheme are required", details: nil))
      return
    }

    // Release any previous session before starting a new one
    currentSession = nil

    let session = ASWebAuthenticationSession(
      url: url,
      callbackURLScheme: callbackUrlScheme,
      completionHandler: { [weak self] callbackURL, error in
        self?.currentSession = nil
        DispatchQueue.main.async {
          if let error = error as? ASWebAuthenticationSessionError {
            if error.code == .canceledLogin {
              result(FlutterError(code: "CANCELED", message: "User canceled login", details: nil))
              return
            }
          }
          if let error = error {
            result(FlutterError(code: "AUTH_ERROR", message: error.localizedDescription, details: nil))
            return
          }
          if let callbackURL = callbackURL {
            result(callbackURL.absoluteString)
          } else {
            result(FlutterError(code: "NO_CALLBACK", message: "No callback URL received", details: nil))
          }
        }
      }
    )
    session.presentationContextProvider = self
    currentSession = session

    if !session.start() {
      currentSession = nil
      result(FlutterError(code: "START_FAILED", message: "Failed to start authentication session", details: nil))
    }
  }

  public func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
    guard let windowScene = UIApplication.shared.connectedScenes
      .compactMap({ $0 as? UIWindowScene })
      .first(where: { $0.activationState == .foregroundActive }),
      let window = windowScene.windows.first(where: { $0.isKeyWindow }) ?? windowScene.windows.first else {
      return UIApplication.shared.windows.first { $0.isKeyWindow } ?? UIWindow()
    }
    return window
  }
}
