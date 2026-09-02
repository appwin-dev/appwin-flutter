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

import 'package:appwin_core/appwin_core.dart';
import 'appwin_community_platform_interface.dart';
import 'appwin_community_user.dart';

/// Re-exports the foundation, so one import gives both `AppwinCore` and the
/// feed. Two Appwin products re-exporting the same library cannot contradict
/// each other: it is the same declaration.
export 'package:appwin_core/appwin_core.dart';

export 'appwin_community_user.dart';
export 'appwin_community_view.dart';

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
/// await AppwinCommunity.instance.initialize(appId: 'your-app-id');
///
/// // When the user signs in to YOUR app
/// await AppwinCommunity.instance.login(externalId: user.id);
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
    return AppwinCommunityPlatform.instance.getPlatformVersion();
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
  Future<AppwinInitResult> initialize() {
    return AppwinCommunityPlatform.instance.initialize();
  }

  /// Presents the community full screen over the app.
  ///
  /// For apps with no dedicated tab. Otherwise prefer [AppwinCommunityView].
  Future<void> presentCommunity() {
    return AppwinCommunityPlatform.instance.presentCommunity();
  }

  /// Attaches the member to your app's user id.
  ///
  /// The identity is shared with the other Appwin SDKs: the same user is
  /// recognised by Support.
  Future<void> login({required String externalId}) {
    return AppwinCommunityPlatform.instance.login(externalId: externalId);
  }

  /// Signs the member out and goes back to an anonymous profile.
  Future<void> logout() {
    return AppwinCommunityPlatform.instance.logout();
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
    return AppwinCommunityPlatform.instance.setUser(
      nickname: nickname,
      avatarUrl: avatarUrl,
      bio: bio,
    );
  }

  /// Unread notification count, for a badge on your tab. Returns `0` rather
  /// than failing.
  Future<int> unreadNotificationCount() {
    return AppwinCommunityPlatform.instance.unreadNotificationCount();
  }
}
