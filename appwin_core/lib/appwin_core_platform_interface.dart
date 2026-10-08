/// Platform contract behind `AppwinCore`.
///
/// Split out so the Dart API and the native implementation can move apart:
/// tests swap in a fake, and a future federated platform (web, desktop)
/// registers its own without touching the calling code.
library;

import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'appwin_core_method_channel.dart';
import 'appwin_init_result.dart';
import 'appwin_product.dart';
import 'appwin_user_attributes.dart';

/// Contract each platform implements.
///
/// Host apps do not use this directly; they go through `AppwinCore.instance`.
/// It is public so a platform package, or a test, can provide its own
/// [instance].
abstract class AppwinCorePlatform extends PlatformInterface {
  /// Constructs an implementation, registering the token that
  /// [PlatformInterface] uses to reject subclasses built by other means.
  AppwinCorePlatform() : super(token: _token);

  static final Object _token = Object();

  static AppwinCorePlatform _instance = AppwinCoreMethodChannel();

  /// The implementation in use, method channel by default.
  static AppwinCorePlatform get instance => _instance;

  /// Platform-specific implementations register their own instance here.
  static set instance(AppwinCorePlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Prepares the SDK for this app. See `AppwinCore.configure`.
  Future<void> configure({
    required String appId,
    String? baseUrl,
    String? realtimeBaseUrl,
  }) {
    throw UnimplementedError('configure() has not been implemented.');
  }

  /// Signs a user in. See `AppwinCore.identify`.
  Future<void> identify(String externalId, {AppwinUserAttributes? attributes}) {
    throw UnimplementedError('identify() has not been implemented.');
  }

  /// Writes user attributes. See `AppwinCore.updateUser`.
  Future<void> updateUser(AppwinUserAttributes attributes) {
    throw UnimplementedError('updateUser() has not been implemented.');
  }

  /// Signs the user out. See `AppwinCore.logout`.
  Future<void> logout() {
    throw UnimplementedError('logout() has not been implemented.');
  }

  /// The stable device id, `null` before [configure]. See
  /// `AppwinCore.deviceId`.
  Future<String?> deviceId() {
    throw UnimplementedError('deviceId() has not been implemented.');
  }

  /// Host OS and version, for checking the bridge is alive. See
  /// `AppwinCore.getPlatformVersion`.
  Future<String?> getPlatformVersion() {
    throw UnimplementedError('getPlatformVersion() has not been implemented.');
  }

  /// Whether a push token was registered in this process. See
  /// `AppwinCore.hasRegisteredPushToken`.
  Future<bool> hasRegisteredPushToken() {
    throw UnimplementedError(
      'hasRegisteredPushToken() has not been implemented.',
    );
  }

  /// Registers this device's push token. See `AppwinCore.registerPushToken`.
  Future<void> registerPushToken({
    required String token,
    String? platform,
    bool pushOptIn = true,
  }) {
    throw UnimplementedError('registerPushToken() has not been implemented.');
  }

  /// The verdict for [product], then each change to it. See
  /// `AppwinCore.availabilityUpdates`.
  Stream<AppwinInitResult> availabilityUpdates(AppwinProduct product) {
    throw UnimplementedError('availabilityUpdates() has not been implemented.');
  }

  /// Whether [data] is an Appwin push. See `AppwinPush.isAppwinPush`.
  Future<bool> isAppwinPush(Map<String, dynamic> data) {
    throw UnimplementedError('isAppwinPush() has not been implemented.');
  }

  /// Routes a tap on a notification. See `AppwinPush.handleTap`.
  Future<bool> handlePushTap(Map<String, dynamic> data) {
    throw UnimplementedError('handlePushTap() has not been implemented.');
  }

  /// Routes a push received in the foreground. See
  /// `AppwinPush.handleForeground`.
  Future<bool> handlePushForeground(
    Map<String, dynamic> data, {
    String? title,
    String? body,
  }) {
    throw UnimplementedError(
      'handlePushForeground() has not been implemented.',
    );
  }

  /// Routes a data or silent message. See `AppwinPush.handleMessage`.
  Future<bool> handlePushMessage(Map<String, dynamic> data) {
    throw UnimplementedError('handlePushMessage() has not been implemented.');
  }
}
