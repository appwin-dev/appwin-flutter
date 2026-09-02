/// Platform contract behind `AppwinCore`.
///
/// Split out so the Dart API and the native implementation can move apart:
/// tests swap in a fake, and a future federated platform (web, desktop)
/// registers its own without touching the calling code.
library;

import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'appwin_core_method_channel.dart';

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

  /// Opens the session and returns its token. See
  /// `AppwinCore.bootstrapSession`.
  Future<String> bootstrapSession({String? externalId}) {
    throw UnimplementedError('bootstrapSession() has not been implemented.');
  }

  /// Attaches the device to one of your users. See `AppwinCore.identify`.
  Future<void> identify({required String externalId}) {
    throw UnimplementedError('identify() has not been implemented.');
  }

  /// Forgets the local identity without revoking anything server-side. See
  /// `AppwinCore.clearIdentity`.
  Future<void> clearIdentity() {
    throw UnimplementedError('clearIdentity() has not been implemented.');
  }

  /// Revokes the session and returns to an anonymous profile. See
  /// `AppwinCore.signOut`.
  Future<void> signOut() {
    throw UnimplementedError('signOut() has not been implemented.');
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
}
