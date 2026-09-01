package io.appwin.flutter.notifications

import android.content.Context
import android.os.Build
import io.appwin.core.AppwinCore
import io.appwin.core.availability.AppwinInitResult
import io.appwin.core.availability.AppwinInitStatus
import io.appwin.notifications.AppwinNotifications
import io.appwin.notifications.AutomationEvent
import io.appwin.notifications.InAppMessage
import io.appwin.notifications.TrackEvent
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch

/**
 * Dart-to-Kotlin glue for the Notifications product.
 *
 * Mirrors `AppwinNotificationsPlugin.swift`: same method names, same arguments,
 * same error codes. A divergence between the two only shows on one platform,
 * which is the worst way to find it.
 */
class AppwinNotificationsPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {

  private var channel: MethodChannel? = null
  private var scope: CoroutineScope? = null
  private var appContext: Context? = null

  override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    appContext = binding.applicationContext
    scope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)
    channel = MethodChannel(binding.binaryMessenger, "appwin_notifications").also {
      it.setMethodCallHandler(this)
    }
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel?.setMethodCallHandler(null)
    channel = null
    scope?.cancel()
    scope = null
    appContext = null
  }

  override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
    when (call.method) {
      "getPlatformVersion" -> result.success("Android ${Build.VERSION.RELEASE}")

      "initialize" ->
        launch(result, "availability_failed") {
          result.success(encodeInitResult(AppwinNotifications.initialize()))
        }

      "registerPushToken" -> {
        val token = call.argument<String>("token")
        if (token.isNullOrBlank()) {
          result.error("bad_args", "token manquant", null)
          return
        }
        val optIn = call.argument<Boolean>("pushOptIn") ?: true
        launch(result, "register_failed") {
          AppwinCore.registerPushToken(token, pushOptIn = optIn)
          result.success(null)
        }
      }

      "trackEvent" -> {
        val raw = call.argument<String>("event")
        val event = AutomationEvent.entries.firstOrNull { it.wireValue == raw }
        if (event == null) {
          result.error("bad_args", "event manquant ou inconnu", null)
          return
        }
        val name = call.argument<String>("eventName")
        @Suppress("UNCHECKED_CAST")
        val properties = call.argument<Map<String, String>>("properties")
        launch(result, "track_event_failed") {
          AppwinNotifications.trackEvent(event, eventName = name, properties = properties)
          result.success(null)
        }
      }

      "fetchPendingMessages" ->
        launch(result, "fetch_failed") {
          result.success(AppwinNotifications.fetchPendingMessages().map(::encodeMessage))
        }

      "track" -> {
        val deliveryId = call.argument<String>("deliveryId")
        val raw = call.argument<String>("event")
        val event = TrackEvent.entries.firstOrNull { it.wireValue == raw }
        if (deliveryId.isNullOrBlank() || event == null) {
          result.error("bad_args", "deliveryId/event manquant", null)
          return
        }
        val buttonIndex = call.argument<Int>("buttonIndex")
        launch(result, "track_failed") {
          AppwinNotifications.track(deliveryId, event, buttonIndex)
          result.success(null)
        }
      }

      "syncOnAppOpen" ->
        launch(result, "sync_failed") {
          result.success(AppwinNotifications.syncOnAppOpen().map(::encodeMessage))
        }

      "start" -> {
        val ctx = appContext
        if (ctx == null) {
          result.error("detached", "plugin détaché du moteur Flutter", null)
          return
        }
        launch(result, "start_failed") {
          AppwinNotifications.start(ctx)
          result.success(null)
        }
      }

      "stop" -> {
        AppwinNotifications.stop()
        result.success(null)
      }

      "presentPendingMessages" ->
        launch(result, "present_failed") {
          AppwinNotifications.presentPendingMessages()
          result.success(null)
        }

      else -> result.notImplemented()
    }
  }

  private fun launch(result: MethodChannel.Result, code: String, block: suspend () -> Unit) {
    val current = scope
    if (current == null) {
      result.error("detached", "plugin détaché du moteur Flutter", null)
      return
    }
    current.launch {
      runCatching { block() }
        .onFailure { result.error(code, it.message, null) }
    }
  }
}

private fun encodeInitResult(result: AppwinInitResult): Map<String, Any> =
  when (result.status) {
    AppwinInitStatus.READY -> mapOf("status" to "ready")
    AppwinInitStatus.NOT_CONFIGURED -> mapOf("status" to "notConfigured")
    AppwinInitStatus.UNKNOWN -> mapOf("status" to "unknown")
    AppwinInitStatus.UNAVAILABLE ->
      mapOf("status" to "unavailable", "reason" to (result.reason?.key ?: "disabled"))
  }

private fun encodeMessage(message: InAppMessage): Map<String, Any?> {
  val content = mutableMapOf<String, Any?>(
    "title" to message.content.title,
    "body" to message.content.body,
    "imageUrl" to message.content.imageUrl,
    "deeplink" to message.content.deeplink,
  )
  message.content.buttons?.let { buttons ->
    content["buttons"] = buttons.map { button ->
      mapOf(
        "label" to button.label,
        "action" to button.action,
        "url" to button.url,
      )
    }
  }
  return mapOf(
    "id" to message.id,
    "campaignId" to message.campaignId,
    "deliveryId" to message.deliveryId,
    "channel" to message.channel,
    "format" to message.format,
    "content" to content,
  )
}
