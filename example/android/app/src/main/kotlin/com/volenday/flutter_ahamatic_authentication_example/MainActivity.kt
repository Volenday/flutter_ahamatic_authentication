package com.volenday.flutter_ahamatic_authentication_example

import android.content.Intent
import com.volenday.flutter_ahamatic_authentication.FlutterAhamaticAuthenticationPlugin
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {

  override fun onNewIntent(intent: Intent) {
    super.onNewIntent(intent)
    intent.data?.toString()?.takeIf { it.startsWith("app://") }?.let { url ->
      FlutterAhamaticAuthenticationPlugin.deliverRedirectUri(url)
    }
  }

  override fun onCreate(savedInstanceState: android.os.Bundle?) {
    super.onCreate(savedInstanceState)
    intent?.data?.toString()?.takeIf { it.startsWith("app://") }?.let { url ->
      FlutterAhamaticAuthenticationPlugin.deliverRedirectUri(url)
    }
  }
}
