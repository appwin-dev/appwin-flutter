import 'package:appwin_core/appwin_core.dart';

import 'appwin_in_app_message.dart';
import 'appwin_notifications_platform_interface.dart';

/// Re-exports the foundation, so one import gives both `AppwinCore` and
/// notifications. Two Appwin products re-exporting the same library cannot
/// contradict each other: it is the same declaration.
export 'package:appwin_core/appwin_core.dart';

export 'appwin_in_app_message.dart';

/// Public facade of the Appwin Notifications SDK.
///
/// No UI: this product registers the device for push, reports the events that
/// trigger automations, and hands you the in-app messages to render yourself.
/// Unlike Support and Community, nothing here draws a screen.
class AppwinNotifications {
  AppwinNotifications._();

  /// Shared instance.
  static final AppwinNotifications instance = AppwinNotifications._();

  /// Prepares Notifications, and says whether it may be used.
  ///
  /// Call it after `AppwinCore.instance.configure()` and **before** asking the
  /// system for push permission: a prompt for a product the studio cannot use
  /// spends the single "allow" a user grants, and neither iOS nor Android asks
  /// twice.
  ///
  /// ```dart
  /// final notifications = await AppwinNotifications.instance.initialize();
  /// debugPrint('Appwin Notifications: $notifications');
  ///
  /// if (notifications.isReady) {
  ///   // Ask for permission, then register the token below.
  /// }
  /// ```
  Future<AppwinInitResult> initialize() {
    return AppwinNotificationsPlatform.instance.initialize();
  }

  /// Registers this device's push token. Call it again on every rotation.
  ///
  /// Pass `pushOptIn: false` rather than skipping the call when the user
  /// declines: that distinguishes "declined" from "never asked", which are two
  /// different audiences on the studio's side.
  Future<void> registerPushToken({
    required String token,
    bool pushOptIn = true,
  }) {
    return AppwinNotificationsPlatform.instance.registerPushToken(
      token: token,
      pushOptIn: pushOptIn,
    );
  }

  /// Reports a lifecycle event, which may trigger an automation server-side.
  Future<void> trackEvent({
    required AppwinAutomationEvent event,
    String? eventName,
  }) {
    return AppwinNotificationsPlatform.instance.trackEvent(
      event: event,
      eventName: eventName,
    );
  }

  /// In-app messages waiting for this device. You render them; the SDK does
  /// not.
  Future<List<AppwinInAppMessage>> fetchPendingMessages() {
    return AppwinNotificationsPlatform.instance.fetchPendingMessages();
  }

  /// Reports what the user did with a message, using its `deliveryId`.
  ///
  /// Without this the campaign has no read rate, and an automation that waits
  /// on "opened" never fires.
  Future<void> track({
    required String deliveryId,
    required AppwinTrackEvent event,
  }) {
    return AppwinNotificationsPlatform.instance.track(
      deliveryId: deliveryId,
      event: event,
    );
  }

  /// Reports an app open and returns what is pending, in one round trip.
  ///
  /// The convenient call for a launch: it does what `trackEvent` plus
  /// `fetchPendingMessages` would, without two requests.
  Future<List<AppwinInAppMessage>> syncOnAppOpen() {
    return AppwinNotificationsPlatform.instance.syncOnAppOpen();
  }

  /// Sanity check of the Dart-to-native bridge, returning e.g. "iOS 18.0".
  Future<String?> getPlatformVersion() {
    return AppwinNotificationsPlatform.instance.getPlatformVersion();
  }
}
