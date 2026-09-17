package io.appwin.flutter.attribution

import android.os.Build
import io.appwin.attribution.AdvertisingConsent
import io.appwin.attribution.AppwinAttribution
import io.appwin.core.availability.AppwinInitResult
import io.appwin.core.availability.AppwinInitStatus
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch

/**
 * Dart-to-Kotlin glue for the Attribution product.
 *
 * Mirrors `AppwinAttributionPlugin.swift`: same method names, same arguments,
 * same result shapes. `requestTrackingAuthorization` resolves `true` here -
 * Android has no ATT, tracking is not OS-gated.
 */
class AppwinAttributionPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {

  private var channel: MethodChannel? = null
  private var scope: CoroutineScope? = null

  override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    scope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)
    channel = MethodChannel(binding.binaryMessenger, "appwin_attribution").also {
      it.setMethodCallHandler(this)
    }
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel?.setMethodCallHandler(null)
    channel = null
    scope?.cancel()
    scope = null
  }

  override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
    when (call.method) {
      "getPlatformVersion" -> result.success("Android ${Build.VERSION.RELEASE}")
      "initialize" -> {
        val scope = scope ?: return result.error("not_attached", "plugin detached", null)
        scope.launch {
          result.success(encode(AppwinAttribution.initialize()))
        }
      }
      "setAdvertisingConsent" -> {
        AppwinAttribution.setAdvertisingConsent(parseConsent(call.argument<String>("consent")))
        result.success(null)
      }
      "requestTrackingAuthorization" -> result.success(true)
      "setAdSignalsDebugMode" -> {
        AppwinAttribution.setAdSignalsDebugMode(call.argument<Boolean>("enabled") ?: false)
        result.success(null)
      }
      else -> result.notImplemented()
    }
  }

  private fun parseConsent(raw: String?): AdvertisingConsent = when (raw) {
    "granted" -> AdvertisingConsent.GRANTED
    "denied" -> AdvertisingConsent.DENIED
    else -> AdvertisingConsent.UNKNOWN
  }

  /** Same shape as the iOS plugin: status + optional reason. */
  private fun encode(result: AppwinInitResult): Map<String, Any?> = when (result.status) {
    AppwinInitStatus.READY -> mapOf("status" to "ready")
    AppwinInitStatus.NOT_CONFIGURED -> mapOf("status" to "notConfigured")
    AppwinInitStatus.UNKNOWN -> mapOf("status" to "unknown")
    AppwinInitStatus.UNAVAILABLE ->
      mapOf("status" to "unavailable", "reason" to result.reason?.key)
  }
}
