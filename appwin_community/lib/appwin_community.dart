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

  /// Initialises the SDK. Call once at startup, before showing
  /// [AppwinCommunityView].
  ///
  /// `baseUrl` is for development, to point at a local API. Leave it `null` in
  /// production.
  ///
  /// If the app already integrates `appwin_support`, one `initialize` is
  /// enough: both SDKs share the device identity owned by AppwinCore.
  Future<void> initialize({required String appId, String? baseUrl}) {
    return AppwinCommunityPlatform.instance.initialize(
      appId: appId,
      baseUrl: baseUrl,
    );
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
