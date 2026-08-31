import 'package:appwin_core/appwin_core.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'appwin_community_method_channel.dart';
import 'appwin_community_user.dart';

abstract class AppwinCommunityPlatform extends PlatformInterface {
  AppwinCommunityPlatform() : super(token: _token);

  static final Object _token = Object();

  static AppwinCommunityPlatform _instance = AppwinCommunityMethodChannel();

  static AppwinCommunityPlatform get instance => _instance;

  /// Platform-specific implementations register their own instance here.
  static set instance(AppwinCommunityPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('getPlatformVersion() has not been implemented.');
  }

  /// Initialises the SDK. `baseUrl` serves development, to point at a local API.
  /// locale ; en prod, laisser `null`.
  Future<AppwinInitResult> initialize() {
    throw UnimplementedError('initialize() has not been implemented.');
  }

  /// Presents the community full screen over the app.
  ///
  /// For apps with no dedicated tab; the expected integration goes through
  /// le widget [AppwinCommunityView].
  Future<void> presentCommunity() {
    throw UnimplementedError('presentCommunity() has not been implemented.');
  }

  Future<void> login({required String externalId}) {
    throw UnimplementedError('login() has not been implemented.');
  }

  Future<void> logout() {
    throw UnimplementedError('logout() has not been implemented.');
  }

  /// Pushes the identity the host app knows to the community profile.
  Future<AppwinCommunityUser?> setUser({
    String? nickname,
    String? avatarUrl,
    String? bio,
  }) {
    throw UnimplementedError('setUser() has not been implemented.');
  }

  /// Unread notifications, for a badge on the tab.
  Future<int> unreadNotificationCount() {
    throw UnimplementedError(
      'unreadNotificationCount() has not been implemented.',
    );
  }
}
