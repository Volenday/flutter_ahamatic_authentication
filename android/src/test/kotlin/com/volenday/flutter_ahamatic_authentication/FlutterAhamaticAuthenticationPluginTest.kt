package com.volenday.flutter_ahamatic_authentication

import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlin.test.Test
import org.mockito.ArgumentMatchers
import org.mockito.Mockito

/*
 * Unit tests for the plugin. MitID custom URL flow uses launchMitIdAuth (Chrome Custom Tabs).
 *
 * Run from plugin root: cd android && ./gradlew testDebugUnitTest
 * Or from example: cd example/android && ../gradlew testDebugUnitTest
 */

internal class FlutterAhamaticAuthenticationPluginTest {
  @Test
  fun onMethodCall_getPlatformVersion_returnsExpectedValue() {
    val plugin = FlutterAhamaticAuthenticationPlugin()

    val call = MethodCall("getPlatformVersion", null)
    val mockResult: MethodChannel.Result = Mockito.mock(MethodChannel.Result::class.java)
    plugin.onMethodCall(call, mockResult)

    Mockito.verify(mockResult).success("Android " + android.os.Build.VERSION.RELEASE)
  }

  @Test
  fun launchMitIdAuth_withMissingAuthUrl_returnsInvalidArgs() {
    val plugin = FlutterAhamaticAuthenticationPlugin()
    val args = mapOf(
      "callbackUrlScheme" to "app",
    )
    val call = MethodCall("launchMitIdAuth", args)
    val mockResult: MethodChannel.Result = Mockito.mock(MethodChannel.Result::class.java)

    plugin.onMethodCall(call, mockResult)

    Mockito.verify(mockResult).error(
      ArgumentMatchers.eq("INVALID_ARGS"),
      ArgumentMatchers.any(),
      ArgumentMatchers.any(),
    )
  }

  @Test
  fun launchMitIdAuth_withEmptyCallbackUrlScheme_returnsInvalidArgs() {
    val plugin = FlutterAhamaticAuthenticationPlugin()
    val args = mapOf(
      "authUrl" to "https://test-login.abena.com/authz-srv/authz?client_id=mitid",
      "callbackUrlScheme" to "",
    )
    val call = MethodCall("launchMitIdAuth", args)
    val mockResult: MethodChannel.Result = Mockito.mock(MethodChannel.Result::class.java)

    plugin.onMethodCall(call, mockResult)

    Mockito.verify(mockResult).error(
      ArgumentMatchers.eq("INVALID_ARGS"),
      ArgumentMatchers.any(),
      ArgumentMatchers.any(),
    )
  }

  @Test
  fun launchMitIdAuth_withoutActivity_returnsNoActivity() {
    val plugin = FlutterAhamaticAuthenticationPlugin()
    // Do not attach to Activity
    val args = mapOf(
      "authUrl" to "https://test-login.abena.com/authz-srv/authz?client_id=mitid",
      "callbackUrlScheme" to "app",
    )
    val call = MethodCall("launchMitIdAuth", args)
    val mockResult: MethodChannel.Result = Mockito.mock(MethodChannel.Result::class.java)

    plugin.onMethodCall(call, mockResult)

    Mockito.verify(mockResult).error(
      ArgumentMatchers.eq("NO_ACTIVITY"),
      ArgumentMatchers.any(),
      ArgumentMatchers.any(),
    )
  }
}
