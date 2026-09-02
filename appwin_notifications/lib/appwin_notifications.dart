/// Push notifications and in-app messages for [Appwin](https://appwin.io).
///
/// The studio builds campaigns in the dashboard - a push, a modal, a banner -
/// and targets them at moments in the app: a first open, a purchase, an event
/// only your app knows about. This package delivers them; the native SDK
/// presents them, so there is no UI for you to build.
///
/// Depends on `appwin_core`, which it re-exports: one `configure()` covers
/// this package and its siblings `appwin_support` and `appwin_community`.
///
/// ```dart
/// import 'package:appwin_notifications/appwin_notifications.dart';
///
/// Future<void> main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///   await AppwinCore.instance.configure(appId: 'your-app-id');
///
///   final notifications = await AppwinNotifications.instance.initialize();
///   if (notifications.isReady) {
///     // Hooks the lifecycle, asks for push permission, presents in-app.
///     await AppwinNotifications.instance.start();
///   }
///
///   runApp(const MyApp());
/// }
/// ```
///
/// See the `example/` directory for a runnable integration.
library;

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

  /// The one instance, and the entry point to every method below.
  static final AppwinNotifications instance = AppwinNotifications._();

  /// Says whether this app may use Notifications, and prepares it if so.
  ///
  /// Call it after `AppwinCore.configure()` and gate your own setup on the
  /// answer: the SDK cannot know what your app does on a campaign.
  ///
  /// A value rather than an exception, because "not entitled" is an ordinary
  /// outcome of a normal launch. See [AppwinInitResult].
  Future<AppwinInitResult> initialize() {
    return AppwinNotificationsPlatform.instance.initialize();
  }

  /// Starts lifecycle hooks, push (iOS) and native in-app presentation.
  Future<void> start({bool requestPushPermission = true}) {
    return AppwinNotificationsPlatform.instance.start(
      requestPushPermission: requestPushPermission,
    );
  }

  /// Unhooks everything [start] installed.
  ///
  /// For a host app that wants campaigns off for part of its life, a kids
  /// mode or a paused account. Not needed on sign-out: use
  /// `AppwinCore.signOut()`, which drops the identity behind the targeting.
  Future<void> stop() {
    return AppwinNotificationsPlatform.instance.stop();
  }

  /// Registers this device's push token. Call again on every rotation.
  ///
  /// Forwards to `AppwinCore.registerPushToken()`: the token is shared with
  /// Support and Community, and registering it twice would have them fight
  /// over the same device.
  ///
  /// [start] already does this on iOS. Call it yourself when you own the
  /// token, typically from Firebase Messaging on Android.
  Future<void> registerPushToken({
    required String token,
    bool pushOptIn = true,
  }) {
    return AppwinCore.instance.registerPushToken(
      token: token,
      pushOptIn: pushOptIn,
    );
  }

  /// Reports a moment a campaign can trigger on.
  ///
  /// The lifecycle events are already reported by the native SDK after
  /// [start]. What is yours to send is what only your app knows: a purchase,
  /// a level finished, an onboarding step.
  ///
  /// `eventName` names an [AppwinAutomationEvent.customEvent]; `properties`
  /// carries what the campaign segments on.
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

  /// The messages waiting for this device, without presenting them.
  ///
  /// Only for a host app rendering in-app messages in its own design. Taking
  /// this route makes [track] yours to call too, otherwise the campaign
  /// reports nothing. To let the SDK draw them, use [presentPendingMessages].
  Future<List<AppwinInAppMessage>> fetchPendingMessages() {
    return AppwinNotificationsPlatform.instance.fetchPendingMessages();
  }

  /// Reports what became of a message you presented yourself.
  ///
  /// `deliveryId` comes from [AppwinInAppMessage.deliveryId]. `buttonIndex`
  /// says which call to action was tapped, for an
  /// [AppwinTrackEvent.clicked].
  ///
  /// Unnecessary after [presentPendingMessages], which reports on its own.
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

  /// Reports an app open and returns whatever it triggered, in one round trip.
  ///
  /// Redundant after [start], which already reports the lifecycle. Useful when
  /// you drive campaigns by hand and want the open and its messages together
  /// rather than as two calls.
  Future<List<AppwinInAppMessage>> syncOnAppOpen() {
    return AppwinNotificationsPlatform.instance.syncOnAppOpen();
  }

  /// Presents the waiting messages in the SDK's own UI, and reports on them.
  ///
  /// The normal route: nothing to build, and opens, clicks and dismissals are
  /// tracked for you. Reach for [fetchPendingMessages] only to render them
  /// yourself.
  Future<void> presentPendingMessages() {
    return AppwinNotificationsPlatform.instance.presentPendingMessages();
  }

  /// Sanity check for the Dart-to-native bridge, returning e.g. "iOS 18.0".
  /// Answers even before `configure`, which is what separates a broken native
  /// install from a wrong Appwin configuration.
  Future<String?> getPlatformVersion() {
    return AppwinNotificationsPlatform.instance.getPlatformVersion();
  }
}
