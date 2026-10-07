/// Foundation of the Appwin SDKs for Flutter.
///
/// [Appwin](https://appwin.io) is a toolkit for mobile studios: a customer
/// support messenger, an in-app community feed and push notifications, each
/// rendered natively inside your app and steered from a web dashboard. The
/// studio changes a colour, a welcome message or the FAQ there, and the app
/// picks it up on the next open, with no release to ship.
///
/// This package is not a product of its own. It holds what the three share:
/// the device identity, the session and the network client. You depend on it
/// to call [AppwinCore.configure] once, then add the product packages you
/// need:
///
/// | Package | What it gives you |
/// | --- | --- |
/// | `appwin_support` | Messenger, conversations and FAQ |
/// | `appwin_community` | In-app feed, comments, member profiles |
/// | `appwin_notifications` | Push registration and in-app messages |
///
/// Each of those already depends on this one, so a single product needs a
/// single line in your `pubspec.yaml`.
///
/// ```dart
/// import 'package:appwin_core/appwin_core.dart';
///
/// Future<void> main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///   await AppwinCore.instance.configure(appId: 'your-app-id');
///   runApp(const MyApp());
/// }
/// ```
///
/// The App ID comes from your dashboard, under Settings then SDK. See the
/// `example/` directory for a runnable integration.
library;

import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;

import 'appwin_core_platform_interface.dart';
import 'appwin_init_result.dart';
import 'appwin_product.dart';
import 'appwin_user_attributes.dart';

/// Shared by the three products: what their `initialize()` answers.
export 'appwin_init_result.dart';
export 'appwin_product.dart';
export 'appwin_user_attributes.dart';

/// Facade no-throw contract: a bridge failure (missing native plugin,
/// platform exception) degrades to [fallback] instead of reaching the host
/// app. Integrators never need to wrap Appwin calls in try/catch, except
/// `identify` and `updateUser`: a sign-in that fails silently would leave the
/// studio believing its user is identified.
Future<T> _guard<T>(String method, Future<T> Function() body, T fallback) async {
  try {
    return await body();
  } catch (e) {
    if (kDebugMode) debugPrint('[Appwin] $method: bridge call failed: $e');
    return fallback;
  }
}

Future<void> _guardVoid(String method, Future<void> Function() body) async {
  try {
    await body();
  } catch (e) {
    if (kDebugMode) debugPrint('[Appwin] $method: bridge call failed: $e');
  }
}

/// Shared foundation for every Appwin SDK.
///
/// Owns the device id, the authenticated session and the network client. The
/// products - Support, Community, Notifications - depend on it and are only
/// consumers.
///
/// Firebase model: **one** `configure` at startup, then the products work. An
/// app integrating Support and Community does not pass its app id twice, and an
/// identified user is identified on both sides at once.
///
/// ```dart
/// void main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///   await AppwinCore.instance.configure(appId: 'your-app-id');
///   runApp(const MyApp());
/// }
/// ```
class AppwinCore {
  AppwinCore._();

  /// The one instance, and the entry point to every method below.
  ///
  /// A singleton because the state it guards is itself unique: one device
  /// identity, one session, one network client. Two instances would race each
  /// other for the same session token.
  static final AppwinCore instance = AppwinCore._();

  /// Prepares the SDK. Call once at startup, before using any product.
  /// Idempotent.
  ///
  /// The device identity and network client are ready immediately, then the
  /// session opens in the background: the `Future` resolves without waiting for
  /// the network. Blocking app startup on a round trip would be paid by every
  /// user, offline ones included.
  ///
  /// `baseUrl` is for development, to point at a local API
  /// (`http://localhost:3000` on the iOS simulator, `http://10.0.2.2:3000` on
  /// the Android emulator). Leave it `null` in production.
  Future<void> configure({
    required String appId,
    String? baseUrl,
    String? realtimeBaseUrl,
  }) {
    return _guardVoid(
      'configure',
      () => AppwinCorePlatform.instance.configure(
        appId: appId,
        baseUrl: baseUrl,
        realtimeBaseUrl: realtimeBaseUrl,
      ),
    );
  }

  /// Signs your app's user in to every Appwin product at once.
  ///
  /// The [externalId] is **yours**, the one in your database; Appwin never
  /// interprets it. It is kept on the device across launches, and the session
  /// is reopened under it: the anonymous visitor this device was until now is
  /// merged into the user, conversations included. Pass [attributes] to send what
  /// you know about them in the same call.
  ///
  /// Call it when the user signs in to your app, and again at launch if you
  /// like: identifying the user already identified is harmless.
  ///
  /// Throws an [ArgumentError] when [externalId] is blank, and a
  /// `PlatformException` when the native SDK fails (network, server
  /// rejection, missing plugin). The device then stays on its previous
  /// identity: retry, or keep the user on your sign-in path.
  Future<void> identify(String externalId, {AppwinUserAttributes? attributes}) async {
    if (externalId.trim().isEmpty) {
      throw ArgumentError.value(externalId, 'externalId', 'must not be blank');
    }
    await AppwinCorePlatform.instance.identify(externalId, attributes: attributes);
  }

  /// Sends what you know about the current user, identified or not.
  ///
  /// Only the non-null fields of [attributes] are written; the others keep their
  /// value on the server. The identity itself is not changed: use [identify]
  /// for that.
  ///
  /// Throws a `PlatformException` when the native SDK fails (network, server
  /// rejection, missing plugin); nothing was written then.
  Future<void> updateUser(AppwinUserAttributes attributes) async {
    await AppwinCorePlatform.instance.updateUser(attributes);
  }

  /// Signs the user out of every Appwin product and goes back to an anonymous
  /// visitor on the same device.
  ///
  /// Call it when the user signs out of **your** app, otherwise the next person
  /// on the device inherits their conversations. The session is revoked
  /// server-side when the network allows it, and the push token, if one was
  /// registered, is carried over to the new anonymous session.
  ///
  /// Never throws: the local sign-out happens even when the network does not.
  Future<void> logout() {
    return _guardVoid('logout', AppwinCorePlatform.instance.logout);
  }

  /// Device id, `null` until [configure] has run.
  ///
  /// Stable over time: keychain on iOS, where it survives an uninstall;
  /// encrypted preferences on Android, where it comes back after a reinstall if
  /// auto backup is on.
  Future<String?> deviceId() {
    return _guard('deviceId', AppwinCorePlatform.instance.deviceId, null);
  }

  /// Sanity check for the Dart-to-native bridge, returning e.g. "iOS 18.0".
  /// Answers even when [configure] was never called, which is what separates a
  /// broken native install from a wrong Appwin configuration.
  Future<String?> getPlatformVersion() {
    return _guard(
      'getPlatformVersion',
      AppwinCorePlatform.instance.getPlatformVersion,
      null,
    );
  }

  /// The verdict for [product], then each change to it.
  ///
  /// Emits the known verdict on listen (the cached one after a relaunch,
  /// [AppwinInitStatus.notConfigured] before [configure]), then a new value
  /// each time it changes: a plan that lapses, a switch flipped in the
  /// dashboard. Any product's `initialize()` refreshes it, and so does the app
  /// returning to the foreground while someone listens.
  ///
  /// Never errors: a bridge failure ends up as a stream that stays silent.
  ///
  /// ```dart
  /// AppwinCore.instance
  ///     .availabilityUpdates(AppwinProduct.community)
  ///     .listen((result) => setState(() => _showTab = result.isReady));
  /// ```
  Stream<AppwinInitResult> availabilityUpdates(AppwinProduct product) {
    try {
      return AppwinCorePlatform.instance
          .availabilityUpdates(product)
          .handleError((Object e) {
            if (kDebugMode) {
              debugPrint('[Appwin] availabilityUpdates: bridge call failed: $e');
            }
          });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[Appwin] availabilityUpdates: bridge call failed: $e');
      }
      return const Stream.empty();
    }
  }

  /// Whether [registerPushToken] has succeeded at least once this process.
  Future<bool> hasRegisteredPushToken() {
    return _guard(
      'hasRegisteredPushToken',
      AppwinCorePlatform.instance.hasRegisteredPushToken,
      false,
    );
  }

  /// Registers this device's push token with Appwin. Call again on every token
  /// rotation.
  ///
  /// Shared by Support, Community and Notifications. Uses the Support route so
  /// the token is stored without requiring the Notifications product.
  ///
  /// On iOS, prefer the APNs token in hex, not the FCM one. [platform] defaults
  /// to the device's so an FCM token is not sent labelled "ios".
  Future<void> registerPushToken({
    required String token,
    String? platform,
    bool pushOptIn = true,
  }) {
    return _guardVoid(
      'registerPushToken',
      () => AppwinCorePlatform.instance.registerPushToken(
        token: token,
        platform: platform,
        pushOptIn: pushOptIn,
      ),
    );
  }
}

/// Routes Appwin pushes to the product that owns them (a Support reply opens
/// that conversation, a campaign its link).
///
/// **Automatic mode** (default): with `appwin_notifications` started and no
/// push code of your own, the native SDK already calls this. Nothing to write.
///
/// **Forwarding mode**: your app owns its push stack, typically FlutterFire.
/// Forward each callback, and handle only what comes back `false`:
///
/// ```dart
/// @pragma('vm:entry-point')
/// Future<void> _onBackgroundMessage(RemoteMessage message) async {
///   await AppwinPush.instance.handleMessage(message.data);
/// }
///
/// Future<void> wirePush() async {
///   FirebaseMessaging.onBackgroundMessage(_onBackgroundMessage);
///
///   // The tap that launched the app.
///   final initial = await FirebaseMessaging.instance.getInitialMessage();
///   if (initial != null) await AppwinPush.instance.handleTap(initial.data);
///
///   // A tap while the app was in the background.
///   FirebaseMessaging.onMessageOpenedApp.listen((message) async {
///     if (await AppwinPush.instance.handleTap(message.data)) return;
///     // yours
///   });
///
///   // A push while the app is in the foreground.
///   FirebaseMessaging.onMessage.listen((message) async {
///     final push = AppwinPush.instance;
///     if (await push.handleMessage(message.data)) return;
///     final shown = await push.handleForeground(
///       message.data,
///       title: message.notification?.title,
///       body: message.notification?.body,
///     );
///     if (shown) return;
///     // yours, e.g. flutter_local_notifications
///   });
/// }
/// ```
///
/// On iOS, also pass `installsNotificationDelegate: false` to
/// `AppwinNotifications.instance.start()`, so FlutterFire keeps the
/// notification delegate. On Android, drop the SDK's messaging service from
/// your `AndroidManifest.xml` so FlutterFire's receives every message:
///
/// ```xml
/// <service
///   android:name="io.appwin.notifications.AppwinFirebaseMessagingService"
///   tools:node="remove" />
/// ```
///
/// Forwarding a tap the SDK already saw is harmless: a tap is routed once.
/// On Android the SDK reads the launch intent itself, so the forwarded copy
/// may arrive without the Appwin keys and come back `false`; there is then
/// nothing in it left to route.
///
/// Parsing and routing happen natively: this class only forwards. Mirrors
/// `AppwinPush` in the iOS and Android SDKs.
class AppwinPush {
  AppwinPush._();

  /// The one instance, and the entry point to every method below.
  static final AppwinPush instance = AppwinPush._();

  /// Whether [data] (FlutterFire's `RemoteMessage.data`) is an Appwin push.
  Future<bool> isAppwinPush(Map<String, dynamic> data) {
    return _guard(
      'isAppwinPush',
      () => AppwinCorePlatform.instance.isAppwinPush(data),
      false,
    );
  }

  /// The user tapped a notification. `true` when it was Appwin's, which then
  /// handles it: do not route it yourself.
  ///
  /// Safe at launch, before any product is initialized: the tap is kept and
  /// replayed as soon as its product is ready.
  Future<bool> handleTap(Map<String, dynamic> data) {
    return _guard(
      'handleTap',
      () => AppwinCorePlatform.instance.handlePushTap(data),
      false,
    );
  }

  /// A push arrived while the app is in the foreground. `true` when Appwin
  /// showed its own UI for it (e.g. the Support in-app banner) or it has
  /// nothing to show: do not display a notification then.
  ///
  /// [title] and [body] are the notification's, which FCM keeps apart from
  /// `data`: pass them, or the in-app banner has no text to show.
  Future<bool> handleForeground(
    Map<String, dynamic> data, {
    String? title,
    String? body,
  }) {
    return _guard(
      'handleForeground',
      () => AppwinCorePlatform.instance.handlePushForeground(
        data,
        title: title,
        body: body,
      ),
      false,
    );
  }

  /// A data or silent message reached the app (e.g. new in-app messages to
  /// fetch). `true` when Appwin consumed it.
  Future<bool> handleMessage(Map<String, dynamic> data) {
    return _guard(
      'handleMessage',
      () => AppwinCorePlatform.instance.handlePushMessage(data),
      false,
    );
  }
}
