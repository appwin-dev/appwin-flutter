import 'package:appwin_core/appwin_core.dart';

import 'appwin_in_app_message.dart';
import 'appwin_notifications_platform_interface.dart';

export 'package:appwin_core/appwin_core.dart';
export 'appwin_in_app_message.dart';

/// Public facade of the Appwin Notifications SDK.
///
/// After `configure` + `initialize`, call [start] once: the native SDK owns
/// lifecycle events, push (iOS), realtime and in-app UI.
class AppwinNotifications {
  AppwinNotifications._();

  static final AppwinNotifications instance = AppwinNotifications._();

  Future<AppwinInitResult> initialize() {
    return AppwinNotificationsPlatform.instance.initialize();
  }

  /// Starts lifecycle hooks, push (iOS) and native in-app presentation.
  Future<void> start({bool requestPushPermission = true}) {
    return AppwinNotificationsPlatform.instance.start(
      requestPushPermission: requestPushPermission,
    );
  }

  Future<void> stop() {
    return AppwinNotificationsPlatform.instance.stop();
  }

  Future<void> registerPushToken({
    required String token,
    bool pushOptIn = true,
  }) {
    return AppwinCore.instance.registerPushToken(
      token: token,
      pushOptIn: pushOptIn,
    );
  }

  Future<void> trackEvent({
    required AppwinAutomationEvent event,
    String? eventName,
    Map<String, String>? properties,
  }) {
    return AppwinNotificationsPlatform.instance.trackEvent(
      event: event,
      eventName: eventName,
      properties: properties,
    );
  }

  Future<List<AppwinInAppMessage>> fetchPendingMessages() {
    return AppwinNotificationsPlatform.instance.fetchPendingMessages();
  }

  Future<void> track({
    required String deliveryId,
    required AppwinTrackEvent event,
    int? buttonIndex,
  }) {
    return AppwinNotificationsPlatform.instance.track(
      deliveryId: deliveryId,
      event: event,
      buttonIndex: buttonIndex,
    );
  }

  Future<List<AppwinInAppMessage>> syncOnAppOpen() {
    return AppwinNotificationsPlatform.instance.syncOnAppOpen();
  }

  Future<void> presentPendingMessages() {
    return AppwinNotificationsPlatform.instance.presentPendingMessages();
  }

  Future<String?> getPlatformVersion() {
    return AppwinNotificationsPlatform.instance.getPlatformVersion();
  }
}
