package io.appwin.flutter.support

import android.app.Activity
import android.app.Application
import android.content.Context
import android.os.Build
import android.os.Bundle
import io.appwin.core.AppwinCore
import io.appwin.core.availability.AppwinInitResult
import io.appwin.core.availability.AppwinInitStatus
import io.appwin.support.AppwinSupport
import io.appwin.support.domain.SupportUserAttributes
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

/**
 * Dart-to-Kotlin glue for the Support product.
 *
 * Mirrors `AppwinSupportPlugin.swift`: same method names, same arguments, same
 * error codes, same endpoints. One Dart implementation serves both platforms, so
 * any drift here is paid by the studio that only tests on one phone.
 */
class AppwinSupportPlugin :
  FlutterPlugin, ActivityAware, MethodChannel.MethodCallHandler {

  private var channel: MethodChannel? = null
  private var context: Context? = null
  private var activity: Activity? = null
  private var scope: CoroutineScope? = null

  override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    context = binding.applicationContext
    scope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)
    channel = MethodChannel(binding.binaryMessenger, "appwin_support").also {
      it.setMethodCallHandler(this)
    }
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel?.setMethodCallHandler(null)
    channel = null
    scope?.cancel()
    scope = null
    context = null
  }

  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    activity = binding.activity
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    activity = binding.activity
  }

  override fun onDetachedFromActivityForConfigChanges() {
    activity = null
  }

  override fun onDetachedFromActivity() {
    activity = null
  }

  override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
    when (call.method) {
      "getPlatformVersion" -> result.success("Android ${Build.VERSION.RELEASE}")

      "initialize" -> {
        // Availability, not configuration: `AppwinCore.configure` is the host
        // app's job and runs through the appwin_core plugin.
        launch(result, "availability_failed") {
          result.success(encodeInitResult(AppwinSupport.initialize()))
        }
      }

      "presentMessenger" -> {
        // Use an activity when we have one: `startActivity` from the
        // application context would need `FLAG_ACTIVITY_NEW_TASK` and would
        // take the messenger out of the app's own stack.
        val host = activity ?: context
        if (host == null) {
          result.error("no_context", "Aucune activité attachée", null)
          return
        }
        AppwinSupport.presentMessenger(host)
        result.success(null)
      }

      "loginUnidentifiedUser" -> launch(result, "login_failed") {
        // Counterpart of the iOS glue's anonymous visitor: create the customer
        // record server-side with no identity from the host app.
        AppwinSupport.updateUser(
          SupportUserAttributes(name = "Visitor anonyme ${AppwinCore.deviceId}"),
        )
        result.success(null)
      }

      "loginIdentifiedUser" -> {
        val externalId = call.argument<String>("externalId")
        if (externalId.isNullOrEmpty()) {
          result.error("bad_args", "externalId manquant", null)
          return
        }
        launch(result, "login_failed") {
          AppwinSupport.loginIdentifiedUser(externalId)
          // Empty identify: promotes the lead to a user server-side without
          // overwriting attributes. Same sequence as on iOS.
          AppwinSupport.updateUser(SupportUserAttributes())
          result.success(null)
        }
      }

      "updateUser" -> {
        val attributes = call.argument<Map<String, Any?>>("attributes").orEmpty()
        launch(result, "update_user_failed") {
          AppwinSupport.updateUser(
            SupportUserAttributes(
              email = attributes["email"] as? String,
              name = attributes["name"] as? String,
              avatarUrl = attributes["avatarUrl"] as? String,
              language = attributes["language"] as? String,
              timezone = attributes["timezone"] as? String,
              location = attributes["location"] as? String,
            ),
          )
          result.success(null)
        }
      }

      else -> result.notImplemented()
    }
  }

  /**
   * Runs a suspending call and surfaces the failure: an exception not caught
   * here would leave the Dart `Future` pending forever.
   */
  private fun launch(result: MethodChannel.Result, errorCode: String, block: suspend () -> Unit) {
    val scope = this.scope
    if (scope == null) {
      result.error("detached", "Le plugin n'est attaché à aucun moteur", null)
      return
    }
    scope.launch {
      runCatching { block() }.onFailure { result.error(errorCode, it.toString(), null) }
    }
  }
}

/**
 * Maps the native result onto what the Dart side parses.
 *
 * A map rather than a bare string: the reason travels with the status, and the
 * two must not drift apart across the channel.
 */
private fun encodeInitResult(result: AppwinInitResult): Map<String, Any> =
  when (result.status) {
    AppwinInitStatus.READY -> mapOf("status" to "ready")
    AppwinInitStatus.NOT_CONFIGURED -> mapOf("status" to "notConfigured")
    AppwinInitStatus.UNKNOWN -> mapOf("status" to "unknown")
    AppwinInitStatus.UNAVAILABLE ->
      mapOf("status" to "unavailable", "reason" to (result.reason?.key ?: "disabled"))
  }
