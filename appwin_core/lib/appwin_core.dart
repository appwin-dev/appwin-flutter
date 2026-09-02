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

import 'appwin_core_platform_interface.dart';

/// Shared by the three products: what their `initialize()` answers.
export 'appwin_init_result.dart';

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
    return AppwinCorePlatform.instance.configure(
      appId: appId,
      baseUrl: baseUrl,
      realtimeBaseUrl: realtimeBaseUrl,
    );
  }

  /// Forces the session open and returns the token.
  ///
  /// Rarely needed, since [configure] handles it in the background. Useful
  /// before a call that strictly requires an open session, or right after
  /// [identify] so the token carries the new identity.
  ///
  /// Concurrent callers share one round trip: the server keeps a single session
  /// per device, and two simultaneous inits would revoke each other's token.
  Future<String> bootstrapSession({String? externalId}) {
    return AppwinCorePlatform.instance.bootstrapSession(externalId: externalId);
  }

  /// Attaches the device to your app's user.
  ///
  /// The `externalId` is **yours**, the one in your database; Appwin never
  /// interprets it. The identity is shared by every product.
  ///
  /// [identify] records the identity locally; follow it with
  /// [bootstrapSession] so the open session carries it too.
  Future<void> identify({required String externalId}) {
    return AppwinCorePlatform.instance.identify(externalId: externalId);
  }

  /// Forgets the `externalId` locally, revoking nothing server-side.
  ///
  /// A testing tool. For a real logout, use [signOut].
  Future<void> clearIdentity() {
    return AppwinCorePlatform.instance.clearIdentity();
  }

  /// Revokes the session server-side, clears local storage and goes back to an
  /// anonymous profile.
  ///
  /// Call it when the user signs out of **your** app, otherwise the next person
  /// on the device inherits their identity.
  Future<void> signOut() {
    return AppwinCorePlatform.instance.signOut();
  }

  /// Device id, `null` until [configure] has run.
  ///
  /// Stable over time: keychain on iOS, where it survives an uninstall;
  /// encrypted preferences on Android, where it comes back after a reinstall if
  /// auto backup is on.
  Future<String?> deviceId() {
    return AppwinCorePlatform.instance.deviceId();
  }

  /// Sanity check for the Dart-to-native bridge, returning e.g. "iOS 18.0".
  /// Answers even when [configure] was never called, which is what separates a
  /// broken native install from a wrong Appwin configuration.
  Future<String?> getPlatformVersion() {
    return AppwinCorePlatform.instance.getPlatformVersion();
  }

  /// Whether [registerPushToken] has succeeded at least once this process.
  Future<bool> hasRegisteredPushToken() {
    return AppwinCorePlatform.instance.hasRegisteredPushToken();
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
    return AppwinCorePlatform.instance.registerPushToken(
      token: token,
      platform: platform,
      pushOptIn: pushOptIn,
    );
  }
}
