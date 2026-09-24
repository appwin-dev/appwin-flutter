package io.appwin.flutter.core

import android.content.Context
import android.content.Intent
import android.os.Build
import io.appwin.core.AppwinCore
import io.appwin.core.AppwinUserAttributes
import io.appwin.core.push.AppwinPush
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry
import org.json.JSONArray
import org.json.JSONObject
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch

/**
 * Glue Dart↔Kotlin du socle.
 *
 * Exact mirror of `AppwinCorePlugin.swift`: same method names, same arguments,
 * same error codes. The method channel contract is what lets one Dart
 * implementation serve both platforms - drift here is paid by the studio that
 * tests on one phone.
 */
class AppwinCorePlugin :
  FlutterPlugin, ActivityAware, MethodChannel.MethodCallHandler, PluginRegistry.NewIntentListener {
  private var channel: MethodChannel? = null
  private var context: Context? = null
  private var activityBinding: ActivityPluginBinding? = null

  /**
   * Scope for suspending calls, on the main thread.
   *
   * `Dispatchers.Main` rather than `IO`: Flutter requires `MethodChannel.Result`
   * callbacks to come from the main thread. The network work is already
   * dispatched by the native SDK.
   *
   * Recreated on each attach rather than held in a final field: a cancelled
   * scope stays cancelled, and a Flutter engine can be detached then reattached
   * (Add-to-App, hot restart).
   */
  private var scope: CoroutineScope? = null

  override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    // The application context, never an activity: the SDK outlives them.
    context = binding.applicationContext
    scope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)
    channel = MethodChannel(binding.binaryMessenger, "appwin_core").also {
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
    activityBinding = binding
    binding.addOnNewIntentListener(this)
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) =
    onAttachedToActivity(binding)

  override fun onDetachedFromActivityForConfigChanges() = onDetachedFromActivity()

  override fun onDetachedFromActivity() {
    activityBinding?.removeOnNewIntentListener(this)
    activityBinding = null
  }

  /**
   * A tap on a system-displayed push while the activity is alive. `false`
   * leaves the intent to the other plugins (FlutterFire reads it too).
   */
  override fun onNewIntent(intent: Intent): Boolean {
    activityBinding?.activity?.let { AppwinPush.handleTap(it, intent) }
    return false
  }

  override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
    when (call.method) {
      "getPlatformVersion" -> result.success("Android ${Build.VERSION.RELEASE}")

      "configure" -> {
        val appId = call.argument<String>("appId")
        val appContext = context
        if (appId.isNullOrBlank() || appContext == null) {
          result.error("bad_args", "appId manquant", null)
          return
        }
        // `configure` returns immediately on the native side: it prepares the
        // identity and the client, then opens the session in the background.
        AppwinCore.configure(
          appContext,
          projectAppId = appId,
          baseUrl = call.argument<String>("baseUrl"),
          realtimeBaseUrl = call.argument<String>("realtimeBaseUrl"),
        )
        // Core reads the launch intent on activity resume, but only from
        // `configure` onward, and Dart configures after MainActivity resumed:
        // without this, the tap that cold-started the app would be lost.
        activityBinding?.activity?.let { AppwinPush.handleTap(it, it.intent) }
        result.success(null)
      }

      "identify" -> {
        val externalId = call.argument<String>("externalId")
        if (externalId.isNullOrEmpty()) {
          result.error("bad_args", "externalId missing", null)
          return
        }
        val attributes = call.argument<Map<String, Any?>>("attributes")?.let(::userAttributes)
        launch(result, "identify_failed") {
          AppwinCore.identify(externalId, attributes)
          result.success(null)
        }
      }

      "updateUser" -> {
        val attributes = userAttributes(call.argument<Map<String, Any?>>("attributes").orEmpty())
        launch(result, "update_user_failed") {
          AppwinCore.updateUser(attributes)
          result.success(null)
        }
      }

      "logout" -> launch(result, "logout_failed") {
        AppwinCore.logout()
        result.success(null)
      }

      "deviceId" -> result.success(AppwinCore.deviceId)

      "hasRegisteredPushToken" -> result.success(AppwinCore.hasRegisteredPushToken)

      "registerPushToken" -> {
        val token = call.argument<String>("token")
        if (token.isNullOrBlank()) {
          result.error("bad_args", "token manquant", null)
          return
        }
        launch(result, "register_push_failed") {
          AppwinCore.registerPushToken(
            token = token,
            platform = call.argument<String>("platform") ?: "android",
            pushOptIn = call.argument<Boolean>("pushOptIn") ?: true,
          )
          result.success(null)
        }
      }

      "isAppwinPush" -> result.success(AppwinPush.isAppwinPush(pushData(call)))

      "handlePushTap" -> withPushContext(result) {
        result.success(AppwinPush.handleTap(it, pushData(call)))
      }

      "handlePushForeground" -> withPushContext(result) {
        result.success(
          AppwinPush.handleForeground(
            it,
            pushData(call),
            title = call.argument<String>("title"),
            body = call.argument<String>("body"),
          ),
        )
      }

      "handlePushMessage" -> withPushContext(result) {
        result.success(AppwinPush.handleMessage(it, pushData(call)))
      }

      else -> result.notImplemented()
    }
  }

  /** The activity when there is one: a tap may present UI right away. */
  private fun withPushContext(result: MethodChannel.Result, block: (Context) -> Unit) {
    val host = activityBinding?.activity ?: context
    if (host == null) {
      result.error("detached", "plugin not attached to a Flutter engine", null)
      return
    }
    block(host)
  }

  /**
   * Runs a suspending call and surfaces the failure rather than letting it
   * escape into the scope: an exception not caught here would leave the Dart
   * `Future` pending forever.
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

/** Dart omits null fields, so an absent key stays `null` and is left untouched server-side. */
private fun userAttributes(raw: Map<String, Any?>) = AppwinUserAttributes(
  email = raw["email"] as? String,
  name = raw["name"] as? String,
  avatarUrl = raw["avatarUrl"] as? String,
  language = raw["language"] as? String,
  timezone = raw["timezone"] as? String,
  location = raw["location"] as? String,
  plan = raw["plan"] as? String,
)

/**
 * FCM `data` is flat strings, and so is what the native parser reads. A Dart
 * map may carry numbers or a nested `data` map: nested values become JSON,
 * which is how the parser expects a nested `data` payload.
 */
private fun pushData(call: MethodCall): Map<String, String> {
  val raw = call.argument<Map<String, Any?>>("data").orEmpty()
  val data = LinkedHashMap<String, String>()
  for ((key, value) in raw) {
    data[key] = when (value) {
      null -> continue
      is String -> value
      is Map<*, *> -> JSONObject(value).toString()
      is List<*> -> JSONArray(value).toString()
      else -> value.toString()
    }
  }
  return data
}
