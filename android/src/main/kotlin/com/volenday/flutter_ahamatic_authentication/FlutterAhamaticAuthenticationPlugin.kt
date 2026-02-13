package com.volenday.flutter_ahamatic_authentication

import android.app.Activity
import android.content.Intent
import android.net.Uri
import androidx.browser.customtabs.CustomTabsIntent
import androidx.lifecycle.DefaultLifecycleObserver
import androidx.lifecycle.LifecycleOwner
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry

/** Flutter plugin for Ahamatic authentication. Supports MitID via Chrome Custom Tabs on Android. */
class FlutterAhamaticAuthenticationPlugin : FlutterPlugin, MethodCallHandler, ActivityAware {

  private lateinit var channel: MethodChannel
  private var activity: Activity? = null
  private var activityBinding: ActivityPluginBinding? = null

  companion object {
    private var pendingMitIdResult: Result? = null
    private var redirectReceived = false
    private var mitIdActivity: Activity? = null
    private val mitIdResumeObserver = object : DefaultLifecycleObserver {
      override fun onResume(owner: LifecycleOwner) {
        if (pendingMitIdResult != null && !redirectReceived) {
          pendingMitIdResult?.error("CANCELED", "User canceled login", null)
          pendingMitIdResult = null
          owner.lifecycle.removeObserver(this)
          mitIdActivity = null
        }
      }
    }

    /**
     * Call this from your MainActivity's onNewIntent (and onCreate when launched with the redirect intent)
     * when the app receives the OAuth redirect URI (e.g. app://...?code=...&state=...).
     * Required for MitID login when using Chrome Custom Tabs on Android.
     *
     * Example in MainActivity.kt:
     * override fun onNewIntent(intent: Intent) {
     *   super.onNewIntent(intent)
     *   intent.data?.toString()?.takeIf { it.startsWith("app://") }?.let { url ->
     *     FlutterAhamaticAuthenticationPlugin.deliverRedirectUri(url)
     *   }
     * }
     */
    @JvmStatic
    fun deliverRedirectUri(url: String?) {
      if (url != null && url.isNotEmpty()) {
        redirectReceived = true
        pendingMitIdResult?.success(url)
        pendingMitIdResult = null
        (mitIdActivity as? LifecycleOwner)?.lifecycle?.removeObserver(mitIdResumeObserver)
        mitIdActivity = null
      }
    }
  }

  override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "flutter_ahamatic_authentication")
    channel.setMethodCallHandler(this)
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
    pendingMitIdResult?.error("DETACHED", "Plugin detached", null)
    pendingMitIdResult = null
  }

  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    activity = binding.activity
    activityBinding = binding
    binding.addActivityResultListener(activityResultListener)
  }

  override fun onDetachedFromActivityForConfigChanges() {
    activityBinding?.removeActivityResultListener(activityResultListener)
    activityBinding = null
    activity = null
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    activity = binding.activity
    activityBinding = binding
    binding.addActivityResultListener(activityResultListener)
  }

  override fun onDetachedFromActivity() {
    activityBinding?.removeActivityResultListener(activityResultListener)
    activityBinding = null
    activity = null
  }

  private val activityResultListener = PluginRegistry.ActivityResultListener { _, resultCode, _ ->
    // Not used for Custom Tabs; we rely on onResume and deliverRedirectUri
    false
  }

  override fun onMethodCall(call: MethodCall, result: Result) {
    when (call.method) {
      "getPlatformVersion" -> result.success("Android ${android.os.Build.VERSION.RELEASE}")
      "launchMitIdAuth" -> launchMitIdAuth(call, result)
      else -> result.notImplemented()
    }
  }

  private fun launchMitIdAuth(call: MethodCall, result: Result) {
    val args = call.arguments as? Map<*, *>
    val authUrlString = args?.get("authUrl") as? String
    val callbackUrlScheme = args?.get("callbackUrlScheme") as? String

    if (authUrlString.isNullOrBlank() || callbackUrlScheme.isNullOrBlank()) {
      result.error("INVALID_ARGS", "authUrl and callbackUrlScheme are required", null)
      return
    }

    val uri = try {
      Uri.parse(authUrlString)
    } catch (e: Exception) {
      result.error("INVALID_URL", "Invalid auth URL: ${e.message}", null)
      return
    }

    val currentActivity = activity
    if (currentActivity == null) {
      result.error("NO_ACTIVITY", "No activity available to launch Custom Tab", null)
      return
    }

    redirectReceived = false
    pendingMitIdResult = result
    mitIdActivity = currentActivity
    (currentActivity as? LifecycleOwner)?.lifecycle?.addObserver(mitIdResumeObserver)

    try {
      val customTabsIntent = CustomTabsIntent.Builder()
        .setShowTitle(true)
        .build()
      customTabsIntent.intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
      customTabsIntent.launchUrl(currentActivity, uri)
    } catch (e: Exception) {
      pendingMitIdResult = null
      (mitIdActivity as? LifecycleOwner)?.lifecycle?.removeObserver(mitIdResumeObserver)
      mitIdActivity = null
      result.error("LAUNCH_FAILED", "Failed to launch Custom Tab: ${e.message}", null)
    }
  }
}
