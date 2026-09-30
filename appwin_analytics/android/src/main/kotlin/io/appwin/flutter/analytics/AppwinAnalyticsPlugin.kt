package io.appwin.flutter.analytics

import android.os.Build
import io.appwin.analytics.AnalyticsConsent
import io.appwin.analytics.AppwinAnalytics
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
 * Dart-to-Kotlin glue for the Analytics product.
 *
 * Mirrors `AppwinAnalyticsPlugin.swift`: same method names, same arguments,
 * same result shapes. One Dart implementation serves both platforms, so any
 * drift here is paid by the studio that only tests on one phone.
 */
class AppwinAnalyticsPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {

  private var channel: MethodChannel? = null
  private var scope: CoroutineScope? = null

  override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    scope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)
    channel = MethodChannel(binding.binaryMessenger, "appwin_analytics").also {
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
          result.success(encode(AppwinAnalytics.initialize()))
        }
      }
      "track" -> {
        val name = call.argument<String>("name")
          ?: return result.error("bad_args", "name manquant", null)
        AppwinAnalytics.track(name, call.argument<Map<String, Any?>>("props"))
        result.success(null)
      }
      "screen" -> {
        val name = call.argument<String>("name")
          ?: return result.error("bad_args", "name manquant", null)
        AppwinAnalytics.screen(name)
        result.success(null)
      }
      "flush" -> {
        AppwinAnalytics.flush()
        result.success(null)
      }
      "setConsent" -> {
        AppwinAnalytics.setConsent(parseConsent(call.argument<String>("consent")))
        result.success(null)
      }
      else -> result.notImplemented()
    }
  }

  private fun parseConsent(raw: String?): AnalyticsConsent = when (raw) {
    "granted" -> AnalyticsConsent.GRANTED
    "denied" -> AnalyticsConsent.DENIED
    else -> AnalyticsConsent.UNKNOWN
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
