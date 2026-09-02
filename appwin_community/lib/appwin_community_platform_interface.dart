/// Platform contract behind `AppwinCommunity`.
///
/// Split out so the Dart API and the native implementation can move apart:
/// tests swap in a fake, and a future platform registers its own without
/// touching the calling code.
library;

import 'package:appwin_core/appwin_core.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'appwin_community_method_channel.dart';
import 'appwin_community_user.dart';

/// Contract each platform implements.
///
/// Host apps go through `AppwinCommunity.instance` instead. It is public so a
/// platform package, or a test, can provide its own [instance].
abstract class AppwinCommunityPlatform extends PlatformInterface {
  /// Constructs an implementation, registering the token that
  /// [PlatformInterface] uses to reject subclasses built by other means.
  AppwinCommunityPlatform() : super(token: _token);

  static final Object _token = Object();

  static AppwinCommunityPlatform _instance = AppwinCommunityMethodChannel();

  /// The implementation in use, method channel by default.
  static AppwinCommunityPlatform get instance => _instance;

  /// Platform-specific implementations register their own instance here.
  static set instance(AppwinCommunityPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Host OS and version, for checking the bridge is alive. See
  /// `AppwinCommunity.getPlatformVersion`.
  Future<String?> getPlatformVersion() {
    throw UnimplementedError('getPlatformVersion() has not been implemented.');
  }

  /// Initialises the SDK. `baseUrl` serves development, to point at a local API.
  /// locale ; en prod, laisser `null`.
  /// Whether this app may use Community. See `AppwinCommunity.initialize`.
  Future<AppwinInitResult> initialize() {
    throw UnimplementedError('initialize() has not been implemented.');
  }

  /// Presents the community full screen over the app.
  ///
  /// For apps with no dedicated tab; the expected integration goes through
  /// le widget [AppwinCommunityView].
  /// Presents the feed full screen. See `AppwinCommunity.presentCommunity`.
  Future<void> presentCommunity() {
    throw UnimplementedError('presentCommunity() has not been implemented.');
  }

  /// Attaches the member to one of your users. See `AppwinCommunity.login`.
  Future<void> login({required String externalId}) {
    throw UnimplementedError('login() has not been implemented.');
  }

  /// Returns to an anonymous profile. See `AppwinCommunity.logout`.
  Future<void> logout() {
    throw UnimplementedError('logout() has not been implemented.');
  }

  /// Pushes the identity the host app knows to the community profile.
  /// Pushes nickname, photo and bio. See `AppwinCommunity.setUser`.
  Future<AppwinCommunityUser?> setUser({
    String? nickname,
    String? avatarUrl,
    String? bio,
  }) {
    throw UnimplementedError('setUser() has not been implemented.');
  }

  /// Unread notifications, for a badge on the tab.
  /// Unread count for a badge. See
  /// `AppwinCommunity.unreadNotificationCount`.
  Future<int> unreadNotificationCount() {
    throw UnimplementedError(
      'unreadNotificationCount() has not been implemented.',
    );
  }
}
