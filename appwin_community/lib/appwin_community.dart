/// In-app community feed for [Appwin](https://appwin.io).
///
/// Gives your app a social space of its own: posts, comments, reactions and
/// member profiles, rendered natively by the SDK and moderated from the web
/// dashboard. Your app supplies an entry point, usually a tab holding an
/// [AppwinCommunityView]; the SDK draws everything inside it.
///
/// Depends on `appwin_core`, which it re-exports: one `configure()` covers
/// this package and its siblings `appwin_support` and `appwin_notifications`,
/// and a member identified here is identified there too.
///
/// ```dart
/// import 'package:appwin_community/appwin_community.dart';
///
/// Future<void> main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///   await AppwinCore.instance.configure(appId: 'your-app-id');
///
///   final community = await AppwinCommunity.instance.initialize();
///   runApp(MyApp(showCommunityTab: community.isReady));
/// }
/// ```
///
/// See the `example/` directory for a runnable integration.
library;

import 'dart:async';

import 'package:appwin_core/appwin_core.dart';
import 'package:flutter/foundation.dart'
    show debugPrint, kDebugMode, visibleForTesting;

import 'appwin_community_event.dart';
import 'appwin_community_platform_interface.dart';
import 'appwin_community_user.dart';
import 'src/community_verdict.dart';

/// Re-exports the foundation, so one import gives both `AppwinCore` and the
/// feed. Two Appwin products re-exporting the same library cannot contradict
/// each other: it is the same declaration.
export 'package:appwin_core/appwin_core.dart';

export 'appwin_community_event.dart';
export 'appwin_community_user.dart';
export 'appwin_community_view.dart';

/// Facade no-throw contract: a bridge failure (missing native plugin,
/// platform exception) degrades to [fallback] instead of reaching the host
/// app. Integrators never need to wrap Appwin calls in try/catch.
Future<T> _guard<T>(String method, Future<T> Function() body, T fallback) async {
  try {
    return await body();
  } catch (e) {
    if (kDebugMode) debugPrint('[Appwin] $method: bridge call failed: $e');
    return fallback;
  }
}

Future<void> _guardVoid(String method, Future<void> Function() body) async {
  try {
    await body();
  } catch (e) {
    if (kDebugMode) debugPrint('[Appwin] $method: bridge call failed: $e');
  }
}

/// Public facade of the Appwin Community SDK.
///
/// Intercom/Octopus style: a singleton, with the UI living in the native SDK.
/// The host app provides an entry point - usually a tab rendering
/// [AppwinCommunityView] - and the SDK draws everything else.
///
/// Typical lifecycle:
///
/// ```dart
/// // At app boot
/// await AppwinCore.instance.configure(appId: 'your-app-id');
/// await AppwinCommunity.instance.initialize();
///
/// // When the user signs in to YOUR app (identity is owned by the foundation)
/// await AppwinCore.instance.identify(user.id);
/// await AppwinCommunity.instance.setUser(
///   nickname: user.displayName,
///   avatarUrl: user.photoUrl,
/// );
///
/// // In your navigation
/// const AppwinCommunityView()
/// ```
class AppwinCommunity {
  AppwinCommunity._();

  /// Shared instance.
  static final AppwinCommunity instance = AppwinCommunity._();

  /// Sanity check for the Dart-to-native bridge, returning e.g. "iOS 18.0".
  Future<String?> getPlatformVersion() {
    return _guard(
      'getPlatformVersion',
      AppwinCommunityPlatform.instance.getPlatformVersion,
      null,
    );
  }

  /// Prepares Community for this app, and says whether it may be used.
  ///
  /// Call it after `AppwinCore.instance.configure()` and **before** mounting the feed,
  /// then gate your own UI on the result: the SDK cannot hide your button or
  /// your tab, it does not own your navigation.
  ///
  /// ```dart
  /// final result = await AppwinCommunity.instance.initialize();
  /// if (result.isReady) {
  ///   _tabs.add(communityTab);
  /// }
  /// ```
  ///
  /// Idempotent, and cheap after the first call: the three products share one
  /// server round trip and its cached verdict.
  ///
  /// Set [onNotificationTap] **before** this call: a notification tap that
  /// launched the app is replayed right after it returns ready.
  Future<AppwinInitResult> initialize() async {
    final result = await _guard(
      'initialize',
      AppwinCommunityPlatform.instance.initialize,
      const AppwinInitResult(AppwinInitStatus.unknown),
    );
    communityVerdict.value = result;
    _followVerdict();
    return result;
  }

  StreamSubscription<AppwinInitResult>? _verdictSubscription;

  /// Keeps [lastResult] on the native verdict once [initialize] has run, the
  /// way the native `lastResult` does.
  void _followVerdict() {
    _verdictSubscription ??= AppwinCore.instance
        .availabilityUpdates(AppwinProduct.community)
        .listen((result) => communityVerdict.value = result);
  }

  /// The latest verdict: the result of [initialize], then kept current as the
  /// server's answer changes (a plan that lapses, a switch in the dashboard).
  ///
  /// `null` until [initialize] has returned.
  AppwinInitResult? get lastResult => communityVerdict.value;

  /// Whether [lastResult] is ready.
  bool get isReady => lastResult?.isReady ?? false;

  /// Presents the community full screen over the app.
  ///
  /// For apps with no dedicated tab. Otherwise prefer [AppwinCommunityView].
  Future<void> presentCommunity() {
    return _guardVoid(
      'presentCommunity',
      AppwinCommunityPlatform.instance.presentCommunity,
    );
  }

  /// Pushes the nickname and photo your app already knows, so the member does
  /// not type them twice.
  ///
  /// Every field is optional and an omitted one is not overwritten. Supplying a
  /// `nickname` takes the profile out of anonymity.
  Future<AppwinCommunityUser?> setUser({
    String? nickname,
    String? avatarUrl,
    String? bio,
  }) {
    return _guard(
      'setUser',
      () => AppwinCommunityPlatform.instance.setUser(
        nickname: nickname,
        avatarUrl: avatarUrl,
        bio: bio,
      ),
      null,
    );
  }

  /// Unread notification count, for a badge on your tab. Returns `0` rather
  /// than failing.
  Future<int> unreadNotificationCount() {
    return _guard(
      'unreadNotificationCount',
      AppwinCommunityPlatform.instance.unreadNotificationCount,
      0,
    );
  }

  /// The unread notification count, live, for a badge on your tab.
  ///
  /// Emits the known count on listen, refreshes it from the server, then
  /// emits each change (never the same value twice in a row). Kept current by
  /// Community pushes and by the app returning to the foreground, while at
  /// least one listener is attached. Never errors.
  ///
  /// ```dart
  /// StreamBuilder<int>(
  ///   stream: AppwinCommunity.instance.unreadNotificationCountStream,
  ///   builder: (context, snapshot) => Badge.count(count: snapshot.data ?? 0),
  /// )
  /// ```
  Stream<int> get unreadNotificationCountStream => _guardStream(
    'unreadNotificationCountStream',
    () => AppwinCommunityPlatform.instance.unreadNotificationCountStream,
  );

  /// What the current member does in Community: posts, comments, replies,
  /// reactions and profile changes, each once the server has accepted it.
  ///
  /// A broadcast stream without replay: listen for as long as you want to hear
  /// about actions, typically from app start. Never errors.
  ///
  /// ```dart
  /// AppwinCommunity.instance.events.listen((event) {
  ///   if (event is AppwinCommunityPostCreated) rewards.grant(Reward.firstPost);
  /// });
  /// ```
  Stream<AppwinCommunityEvent> get events => _guardStream(
    'events',
    () => AppwinCommunityPlatform.instance.events,
  );

  /// Opens a post, and the reply thread under [commentId] when given.
  ///
  /// Opens in the mounted [AppwinCommunityView] when there is one (switch to
  /// its tab yourself first), otherwise full screen over the app. Does
  /// nothing, and logs why, while Community is not ready. The usual caller is
  /// your [onNotificationTap] handler.
  Future<void> openPost(String postId, {String? commentId}) {
    return _guardVoid(
      'openPost',
      () => AppwinCommunityPlatform.instance.openPost(
        postId,
        commentId: commentId,
      ),
    );
  }

  void Function(AppwinCommunityPostTarget target)? _onNotificationTap;
  void Function()? _onEditProfile;

  /// Takes over navigation when the member taps a Community notification.
  ///
  /// `null` (the default), the SDK opens the post itself: in the feed when it
  /// is on screen, otherwise full screen over the app. Set, the SDK does not
  /// navigate: it calls this, and your app typically selects its Community
  /// tab then calls [openPost].
  ///
  /// Set it **before** [initialize], so a tap that launched the app reaches
  /// it.
  ///
  /// ```dart
  /// AppwinCommunity.instance.onNotificationTap = (target) {
  ///   setState(() => _tab = Tab.community);
  ///   AppwinCommunity.instance.openPost(
  ///     target.postId,
  ///     commentId: target.commentId,
  ///   );
  /// };
  /// ```
  void Function(AppwinCommunityPostTarget target)? get onNotificationTap =>
      _onNotificationTap;

  set onNotificationTap(
    void Function(AppwinCommunityPostTarget target)? handler,
  ) {
    _onNotificationTap = handler;
    _syncHostCallbacks();
  }

  /// Replaces the SDK's profile editor with your own.
  ///
  /// When set, every SDK entry point that edits the nickname, photo or bio
  /// calls it instead of opening the SDK's editor. Push the result with
  /// [setUser], which refreshes the mounted screens. `null` (the default)
  /// keeps the SDK's editor.
  void Function()? get onEditProfile => _onEditProfile;

  set onEditProfile(void Function()? handler) {
    _onEditProfile = handler;
    _syncHostCallbacks();
  }

  void _syncHostCallbacks() {
    unawaited(
      _guardVoid(
        'setHostCallbacks',
        () => AppwinCommunityPlatform.instance.setHostCallbacks(
          onNotificationTap: _onNotificationTap,
          onEditProfile: _onEditProfile,
        ),
      ),
    );
  }

  /// Forgets the Dart-side state between tests: the facade is a singleton.
  @visibleForTesting
  void resetForTesting() {
    _verdictSubscription?.cancel();
    _verdictSubscription = null;
    _onNotificationTap = null;
    _onEditProfile = null;
    communityVerdict.value = null;
  }
}

/// Stream flavour of the no-throw contract: a bridge failure logs and ends up
/// as a silent stream instead of an error in the host's listener.
Stream<T> _guardStream<T>(String name, Stream<T> Function() body) {
  void log(Object e) {
    if (kDebugMode) debugPrint('[Appwin] $name: bridge call failed: $e');
  }

  try {
    return body().handleError(log);
  } catch (e) {
    log(e);
    return const Stream.empty();
  }
}
