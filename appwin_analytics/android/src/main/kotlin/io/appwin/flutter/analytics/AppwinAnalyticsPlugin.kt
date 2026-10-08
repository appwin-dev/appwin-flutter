package io.appwin.flutter.analytics

import android.app.Activity
import android.graphics.Rect
import android.os.Build
import android.view.View
import android.view.ViewGroup
import io.appwin.analytics.AnalyticsConsent
import io.appwin.analytics.AppwinAnalytics
import io.appwin.analytics.AppwinReplay
import io.appwin.core.AppwinInternalApi
import io.appwin.core.availability.AppwinInitResult
import io.appwin.core.availability.AppwinInitStatus
import io.flutter.embedding.android.FlutterView
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.lang.ref.WeakReference
import kotlin.math.ceil
import kotlin.math.floor

/**
 * Dart-to-Kotlin glue for the Analytics product.
 *
 * Mirrors `AppwinAnalyticsPlugin.swift`: same method names, same arguments,
 * same result shapes. One Dart implementation serves both platforms, so any
 * drift here is paid by the studio that only tests on one phone.
 */
class AppwinAnalyticsPlugin : FlutterPlugin, MethodChannel.MethodCallHandler, ActivityAware {

  private var channel: MethodChannel? = null
  private var scope: CoroutineScope? = null
  private var activity: Activity? = null
  private var flutterView = WeakReference<View>(null)

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

  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    activity = binding.activity
    flutterView = WeakReference(null)
  }

  override fun onDetachedFromActivityForConfigChanges() = onDetachedFromActivity()

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) =
    onAttachedToActivity(binding)

  override fun onDetachedFromActivity() {
    activity = null
    flutterView = WeakReference(null)
  }

  override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
    when (call.method) {
      "getPlatformVersion" -> result.success("Android ${Build.VERSION.RELEASE}")
      "initialize" -> {
        val scope = scope ?: return result.error("not_attached", "plugin detached", null)
        // Only the switch crosses: `inAppPackages` on the Dart side names Dart
        // packages, the native one Java packages.
        val crashReporting = call.argument<Boolean>("crashReporting") ?: true
        val sessionReplay = call.argument<Boolean>("sessionReplay") ?: true
        setBridgeRuntime()
        scope.launch {
          result.success(
            encode(
              AppwinAnalytics.initialize(
                crashReporting = crashReporting,
                sessionReplay = sessionReplay,
              ),
            ),
          )
        }
      }
      "replayMaskRules" -> result.success(replayMaskRules())
      "setReplayMasks" -> {
        setReplayMasks(call.argument<List<Number>>("rects").orEmpty())
        result.success(null)
      }
      "recordBridgedError" -> recordBridgedError(call, result)
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

  @OptIn(AppwinInternalApi::class)
  private fun recordBridgedError(call: MethodCall, result: MethodChannel.Result) {
    val scope = scope ?: return result.error("not_attached", "plugin detached", null)
    val type = call.argument<String>("type")
      ?: return result.error("bad_args", "missing type", null)
    val fatal = call.argument<Boolean>("fatal") ?: false
    val message = call.argument<String>("message")
    val frames = call.argument<List<Map<String, Any?>>>("frames").orEmpty()
    // The report is written to disk before the call returns: off the main
    // thread, so a burst of framework errors never janks the UI.
    scope.launch {
      withContext(Dispatchers.IO) {
        AppwinAnalytics.recordBridgedError("flutter", fatal, type, message, frames)
      }
      result.success(null)
    }
  }

  @OptIn(AppwinInternalApi::class)
  private fun setBridgeRuntime() = AppwinReplay.setBridgeRuntime("flutter")

  @OptIn(AppwinInternalApi::class)
  private fun replayMaskRules(): Map<String, Boolean>? = AppwinReplay.bridgeMaskRules

  /**
   * Logical pixels of the Flutter view to window pixels. Without the view,
   * nothing is sent: the recorder keeps the whole window masked until a set
   * it can place arrives.
   */
  @OptIn(AppwinInternalApi::class)
  private fun setReplayMasks(flat: List<Number>) {
    val view = findFlutterView() ?: return
    val location = IntArray(2)
    view.getLocationInWindow(location)
    val density = view.resources.displayMetrics.density
    val rects = (0 until flat.size / 4).map { i ->
      val (left, top, right, bottom) = flat.subList(i * 4, i * 4 + 4).map { it.toFloat() * density }
      Rect(
        location[0] + floor(left).toInt(),
        location[1] + floor(top).toInt(),
        location[0] + ceil(right).toInt(),
        location[1] + ceil(bottom).toInt(),
      )
    }
    AppwinReplay.setBridgedMasks(rects)
  }

  private fun findFlutterView(): View? {
    flutterView.get()?.takeIf { it.isAttachedToWindow }?.let { return it }
    val decor = activity?.window?.peekDecorView() ?: return null
    return findFlutterView(decor)?.also { flutterView = WeakReference(it) }
  }

  private fun findFlutterView(view: View): View? {
    if (view is FlutterView) return view
    if (view !is ViewGroup) return null
    for (index in 0 until view.childCount) {
      findFlutterView(view.getChildAt(index))?.let { return it }
    }
    return null
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
