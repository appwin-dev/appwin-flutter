package io.appwin.flutter.core

import android.content.Context
import android.os.Build
import io.appwin.core.AppwinCore
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
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
class AppwinCorePlugin : FlutterPlugin, MethodChannel.MethodCallHandler {
  private var channel: MethodChannel? = null
  private var context: Context? = null

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
        result.success(null)
      }

      "bootstrapSession" -> {
        val externalId = call.argument<String>("externalId")
        launch(result, "bootstrap_failed") {
          result.success(AppwinCore.bootstrapSession(externalId = externalId))
        }
      }

      "identify" -> {
        val externalId = call.argument<String>("externalId")
        if (externalId.isNullOrEmpty()) {
          result.error("bad_args", "externalId manquant", null)
          return
        }
        AppwinCore.identify(externalId)
        result.success(null)
      }

      "clearIdentity" -> {
        AppwinCore.clearIdentity()
        result.success(null)
      }

      "signOut" -> launch(result, "sign_out_failed") {
        AppwinCore.signOut()
        result.success(null)
      }

      "deviceId" -> result.success(AppwinCore.deviceId)

      else -> result.notImplemented()
    }
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
