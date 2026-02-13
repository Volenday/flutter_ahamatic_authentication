import Flutter
import UIKit
import XCTest

@testable import flutter_ahamatic_authentication

// Unit tests for the plugin. MitID custom URL flow uses launchMitIdAuth (ASWebAuthenticationSession).
//
// See https://developer.apple.com/documentation/xctest for more information about using XCTest.

class RunnerTests: XCTestCase {

  func testGetPlatformVersion() {
    let plugin = FlutterAhamaticAuthenticationPlugin()

    let call = FlutterMethodCall(methodName: "getPlatformVersion", arguments: [])

    let resultExpectation = expectation(description: "result block must be called.")
    plugin.handle(call) { result in
      XCTAssertEqual(result as! String, "iOS " + UIDevice.current.systemVersion)
      resultExpectation.fulfill()
    }
    waitForExpectations(timeout: 1)
  }

  // MARK: - MitID custom URL (launchMitIdAuth) – only used when mitIdAuthUrl is set

  func testLaunchMitIdAuth_withMissingAuthUrl_returnsInvalidArgs() {
    let plugin = FlutterAhamaticAuthenticationPlugin()
    let args: [String: Any] = [
      "callbackUrlScheme": "app",
    ]
    let call = FlutterMethodCall(methodName: "launchMitIdAuth", arguments: args)

    let resultExpectation = expectation(description: "result with error")
    plugin.handle(call) { result in
      guard let error = result as? FlutterError else {
        XCTFail("Expected FlutterError")
        resultExpectation.fulfill()
        return
      }
      XCTAssertEqual(error.code, "INVALID_ARGS")
      resultExpectation.fulfill()
    }
    waitForExpectations(timeout: 1)
  }

  func testLaunchMitIdAuth_withEmptyCallbackUrlScheme_returnsInvalidArgs() {
    let plugin = FlutterAhamaticAuthenticationPlugin()
    let args: [String: Any] = [
      "authUrl": "https://test-login.abena.com/authz-srv/authz?client_id=mitid",
      "callbackUrlScheme": "",
    ]
    let call = FlutterMethodCall(methodName: "launchMitIdAuth", arguments: args)

    let resultExpectation = expectation(description: "result with error")
    plugin.handle(call) { result in
      guard let error = result as? FlutterError else {
        XCTFail("Expected FlutterError")
        resultExpectation.fulfill()
        return
      }
      XCTAssertEqual(error.code, "INVALID_ARGS")
      resultExpectation.fulfill()
    }
    waitForExpectations(timeout: 1)
  }
}
