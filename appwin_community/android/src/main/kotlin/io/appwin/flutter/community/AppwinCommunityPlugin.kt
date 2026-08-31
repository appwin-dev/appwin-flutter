package io.appwin.flutter.community

import android.app.Activity
import android.content.Context
import android.os.Build
import io.appwin.community.AppwinCommunity
import io.appwin.community.domain.CommunityProfile
import io.appwin.core.AppwinCore
import io.appwin.core.availability.AppwinInitResult
import io.appwin.core.availability.AppwinInitStatus
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.StandardMessageCodec
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch

/**
 * Glue Dart↔Kotlin du produit Community.
 *
 * Mirrors `AppwinCommunityPlugin.swift`: same method names, same arguments,
 * same error codes, and the same view factory registered under the
 * `appwin_community_view` type - that name is what the Dart widget asks for, on
 * both sides.
 */
class AppwinCommunityPlugin :
  FlutterPlugin, ActivityAware, MethodChannel.MethodCallHandler {

  private var channel: MethodChannel? = null
  private var context: Context? = null
  private var activity: Activity? = null
  private var scope: CoroutineScope? = null

  override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    context = binding.applicationContext
    scope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)
    channel = MethodChannel(binding.binaryMessenger, "appwin_community").also {
      it.setMethodCallHandler(this)
    }
    // The factory is registered on the engine, not the activity: the Dart widget
    // can be mounted before an activity is attached. It reads the current
    // activity when each view is created.
    binding.platformViewRegistry.registerViewFactory(
      AppwinCommunityViewFactory.VIEW_TYPE,
      AppwinCommunityViewFactory(StandardMessageCodec.INSTANCE) { activity },
    )
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
          result.success(encodeInitResult(AppwinCommunity.initialize()))
        }
      }

      "presentCommunity" -> {
        // Use an activity when we have one: `startActivity` from the application
        // context would need `FLAG_ACTIVITY_NEW_TASK` and would take the feed out
        // of the app's own stack.
        val host = activity ?: context
        if (host == null) {
          result.error("no_context", "Aucune activité attachée", null)
          return
        }
        AppwinCommunity.presentCommunity(host)
        result.success(null)
      }

      "login" -> {
        val externalId = call.argument<String>("externalId")
        if (externalId.isNullOrEmpty()) {
          result.error("bad_args", "externalId manquant", null)
          return
        }
        launch(result, "login_failed") {
          // `login` records the identity **and** replays the bootstrap, as on
          // iOS: the glue has nothing to compensate for.
          AppwinCommunity.login(externalId)
          result.success(null)
        }
      }

      "logout" -> launch(result, "logout_failed") {
        AppwinCommunity.logout()
        result.success(null)
      }

      "setUser" -> launch(result, "set_user_failed") {
        val profile = AppwinCommunity.setUser(
          nickname = call.argument<String>("nickname"),
          avatarUrl = call.argument<String>("avatarUrl"),
          bio = call.argument<String>("bio"),
        )
        result.success(serialize(profile))
      }

      "unreadNotificationCount" -> launch(result, "unread_failed") {
        result.success(AppwinCommunity.unreadNotificationCount())
      }

      else -> result.notImplemented()
    }
  }

  /** Method-channel map, read by `AppwinCommunityUser`. */
  private fun serialize(profile: CommunityProfile): Map<String, Any?> = mapOf(
    "id" to profile.id,
    "nickname" to profile.nickname,
    "isAnonymous" to profile.isAnonymous,
    "postCount" to profile.postCount,
    "commentCount" to profile.commentCount,
    "avatarUrl" to profile.avatarUrl,
    "bio" to profile.bio,
  )

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
