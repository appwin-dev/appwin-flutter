/// Platform contract behind `AppwinNotifications`.
///
/// Split out so the Dart API and the native implementation can move apart:
/// tests swap in a fake, and a future platform registers its own without
/// touching the calling code.
library;

import 'package:appwin_core/appwin_core.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'appwin_in_app_message.dart';
import 'appwin_notifications_method_channel.dart';

/// Contract each platform implements.
///
/// Host apps go through `AppwinNotifications.instance` instead. It is public
/// so a platform package, or a test, can provide its own [instance].
abstract class AppwinNotificationsPlatform extends PlatformInterface {
  /// Constructs an implementation, registering the token that
  /// [PlatformInterface] uses to reject subclasses built by other means.
  AppwinNotificationsPlatform() : super(token: _token);

  static final Object _token = Object();

  static AppwinNotificationsPlatform _instance =
      AppwinNotificationsMethodChannel();

  /// The implementation in use, method channel by default.
  static AppwinNotificationsPlatform get instance => _instance;

  /// Platform-specific implementations register their own instance here.
  static set instance(AppwinNotificationsPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Host OS and version, for checking the bridge is alive. See
  /// `AppwinNotifications.getPlatformVersion`.
  Future<String?> getPlatformVersion() {
    throw UnimplementedError('getPlatformVersion() has not been implemented.');
  }

  /// Whether this app may use Notifications. See
  /// `AppwinNotifications.initialize`.
  Future<AppwinInitResult> initialize() {
    throw UnimplementedError('initialize() has not been implemented.');
  }

  /// Hooks lifecycle, push and in-app presentation. See
  /// `AppwinNotifications.start`.
  Future<void> start({bool requestPushPermission = true}) {
    throw UnimplementedError('start() has not been implemented.');
  }

  /// Unhooks what start installed. See `AppwinNotifications.stop`.
  Future<void> stop() {
    throw UnimplementedError('stop() has not been implemented.');
  }

  /// Registers this device's push token. See
  /// `AppwinNotifications.registerPushToken`.
  Future<void> registerPushToken({
    required String token,
    bool pushOptIn = true,
  }) {
    throw UnimplementedError('registerPushToken() has not been implemented.');
  }

  /// Reports a moment a campaign can trigger on. See
  /// `AppwinNotifications.trackEvent`.
  Future<void> trackEvent({
    required AppwinAutomationEvent event,
    String? eventName,
    Map<String, String>? properties,
  }) {
    throw UnimplementedError('trackEvent() has not been implemented.');
  }

  /// The messages waiting, unpresented. See
  /// `AppwinNotifications.fetchPendingMessages`.
  Future<List<AppwinInAppMessage>> fetchPendingMessages() {
    throw UnimplementedError(
      'fetchPendingMessages() has not been implemented.',
    );
  }

  /// Reports what became of a message. See `AppwinNotifications.track`.
  Future<void> track({
    required String deliveryId,
    required AppwinTrackEvent event,
    int? buttonIndex,
  }) {
    throw UnimplementedError('track() has not been implemented.');
  }

  /// Reports an app open and returns what it triggered. See
  /// `AppwinNotifications.syncOnAppOpen`.
  Future<List<AppwinInAppMessage>> syncOnAppOpen() {
    throw UnimplementedError('syncOnAppOpen() has not been implemented.');
  }

  /// Presents waiting messages in the SDK's UI. See
  /// `AppwinNotifications.presentPendingMessages`.
  Future<void> presentPendingMessages() {
    throw UnimplementedError(
      'presentPendingMessages() has not been implemented.',
    );
  }
}
