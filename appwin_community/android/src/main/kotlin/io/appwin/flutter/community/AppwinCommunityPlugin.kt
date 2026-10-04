package io.appwin.flutter.community

import android.app.Activity
import android.content.Context
import android.os.Build
import io.appwin.community.AppwinCommunity
import io.appwin.community.AppwinCommunityEvent
import io.appwin.community.AppwinCommunityPostTarget
import io.appwin.community.domain.CommunityProfile
import io.appwin.core.AppwinCore
import io.appwin.core.availability.AppwinInitResult
import io.appwin.core.availability.AppwinInitStatus
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.StandardMessageCodec
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.flow.Flow
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
  private var eventChannels: List<EventChannel> = emptyList()
  private var context: Context? = null
  private var activity: Activity? = null
  private var scope: CoroutineScope? = null

  override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    context = binding.applicationContext
    scope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)
    channel = MethodChannel(binding.binaryMessenger, "appwin_community").also {
      it.setMethodCallHandler(this)
    }
    eventChannels = listOf(
      EventChannel(binding.binaryMessenger, "appwin_community/events").also {
        it.setStreamHandler(FlowStreamHandler({ scope }, { AppwinCommunity.events }, ::encodeEvent))
      },
      EventChannel(binding.binaryMessenger, "appwin_community/unread_count").also {
        it.setStreamHandler(
          FlowStreamHandler({ scope }, { AppwinCommunity.unreadNotificationCountFlow }) { it },
        )
      },
    )
    // The factory is registered on the engine, not the activity: the Dart widget
    // can be mounted before an activity is attached. It reads the current
    // activity when each view is created.
    binding.platformViewRegistry.registerViewFactory(
      AppwinCommunityViewFactory.VIEW_TYPE,
      AppwinCommunityViewFactory(StandardMessageCodec.INSTANCE) { activity },
    )
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    // The SDK outlives the engine: handlers left behind would call a dead
    // channel and swallow every tap.
    setHostCallbacks(notificationTap = false, editProfile = false)
    channel?.setMethodCallHandler(null)
    channel = null
    eventChannels.forEach { it.setStreamHandler(null) }
    eventChannels = emptyList()
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

      "openPost" -> {
        val postId = call.argument<String>("postId")
        val host = activity ?: context
        if (postId.isNullOrEmpty()) {
          result.error("bad_args", "postId missing", null)
          return
        }
        if (host == null) {
          result.error("no_context", "plugin not attached to a Flutter engine", null)
          return
        }
        AppwinCommunity.openPost(host, postId, call.argument<String>("commentId"))
        result.success(null)
      }

      "setHostCallbacks" -> {
        setHostCallbacks(
          notificationTap = call.argument<Boolean>("notificationTap") == true,
          editProfile = call.argument<Boolean>("editProfile") == true,
        )
        result.success(null)
      }

      else -> result.notImplemented()
    }
  }

  /**
   * Dart owns the handlers; native only learns whether each one exists, and
   * calls back over the channel. The SDK invokes both on the main thread,
   * which is where a method channel must be called from.
   */
  private fun setHostCallbacks(notificationTap: Boolean, editProfile: Boolean) {
    AppwinCommunity.onNotificationTap = if (notificationTap) ::forwardNotificationTap else null
    AppwinCommunity.onEditProfile =
      if (editProfile) ({ channel?.invokeMethod("onEditProfile", null) }) else null
  }

  private fun forwardNotificationTap(target: AppwinCommunityPostTarget) {
    val args = mapOf("postId" to target.postId, "commentId" to target.commentId)
    val channel = channel ?: return openFallback(target)
    channel.invokeMethod(
      "onNotificationTap",
      args,
      object : MethodChannel.Result {
        override fun success(result: Any?) {
          if (result != true) openFallback(target)
        }

        override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) =
          openFallback(target)

        // After a hot restart Dart has no handler installed until the app
        // sets one again: the tap must still open.
        override fun notImplemented() = openFallback(target)
      },
    )
  }

  private fun openFallback(target: AppwinCommunityPostTarget) {
    val host = activity ?: context ?: return
    AppwinCommunity.openPost(host, target.postId, target.commentId)
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
 * Pipes a native flow into an event channel, one collection per Dart listen.
 * The plugin scope runs on the main thread, where an event sink must be fed.
 */
private class FlowStreamHandler<T>(
  private val scope: () -> CoroutineScope?,
  private val flow: () -> Flow<T>,
  private val encode: (T) -> Any,
) : EventChannel.StreamHandler {
  private var job: Job? = null

  override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
    job?.cancel()
    job = scope()?.launch { flow().collect { events.success(encode(it)) } }
  }

  override fun onCancel(arguments: Any?) {
    job?.cancel()
    job = null
  }
}

/** Maps an event onto what `AppwinCommunityEvent.fromMap` parses in Dart. */
private fun encodeEvent(event: AppwinCommunityEvent): Map<String, Any?> =
  when (event) {
    is AppwinCommunityEvent.PostCreated -> mapOf("type" to "postCreated", "postId" to event.postId)
    is AppwinCommunityEvent.CommentCreated ->
      mapOf("type" to "commentCreated", "commentId" to event.commentId, "postId" to event.postId)
    is AppwinCommunityEvent.ReplyCreated -> mapOf(
      "type" to "replyCreated",
      "replyId" to event.replyId,
      "commentId" to event.commentId,
      "postId" to event.postId,
    )
    is AppwinCommunityEvent.ReactionModified -> mapOf(
      "type" to "reactionModified",
      "postId" to event.postId,
      "commentId" to event.commentId,
      "reaction" to event.reaction,
    )
    is AppwinCommunityEvent.ProfileUpdated ->
      mapOf("type" to "profileUpdated", "profileId" to event.profileId)
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
