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
}
