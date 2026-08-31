import 'package:appwin_core/appwin_core.dart';
import 'appwin_in_app_message.dart';
import 'appwin_support_platform_interface.dart';

/// Re-exports the foundation, so one import gives both `AppwinCore` and the
/// messenger. Two Appwin products re-exporting the same library cannot
/// contradict each other: it is the same declaration.
export 'package:appwin_core/appwin_core.dart';

export 'appwin_in_app_message.dart';

/// Public facade of the Appwin Support SDK.
///
/// Intercom style: a singleton, with the UI living in the native SDK. The app
/// calls `AppwinSupport.instance.presentMessenger()` and a native screen appears
/// over it; nothing is rendered on the Flutter side.
class AppwinSupport {
  AppwinSupport._();

  /// Shared instance.
  static final AppwinSupport instance = AppwinSupport._();

  /// Sanity-check du pont Dart↔Swift (renvoie p.ex. "iOS 18.0").
  Future<String?> getPlatformVersion() {
    return AppwinSupportPlatform.instance.getPlatformVersion();
  }

  /// Prepares Support for this app, and says whether it may be used.
  ///
  /// Call it after `AppwinCore.instance.configure()` and **before** showing any Support entry point,
  /// then gate your own UI on the result: the SDK cannot hide your button or
  /// your tab, it does not own your navigation.
  ///
  /// ```dart
  /// final result = await AppwinSupport.instance.initialize();
  /// if (result.isReady) {
  ///   _showHelpButton = true;
  /// }
  /// ```
  ///
  /// Idempotent, and cheap after the first call: the three products share one
  /// server round trip and its cached verdict.
  Future<AppwinInitResult> initialize() {
    return AppwinSupportPlatform.instance.initialize();
  }

  /// Presents the native Appwin messenger over the host app.
  Future<void> presentMessenger() {
    return AppwinSupportPlatform.instance.presentMessenger();
  }

  Future<void> loginUnidentifiedUser() {
    return AppwinSupportPlatform.instance.loginUnidentifiedUser();
  }

  Future<void> loginIdentifiedUser({required String externalId}) {
    return AppwinSupportPlatform.instance.loginIdentifiedUser(externalId: externalId);
  }

  /// Updates the current customer's attributes, Intercom style. The identity
  /// (externalId) is **not** changed - use [loginIdentifiedUser] for that. Every
  /// field is optional.
  Future<void> updateUser({
    String? email,
    String? name,
    String? avatarUrl,
    String? language,
    String? timezone,
    String? location,
  }) {
    return AppwinSupportPlatform.instance.updateUser(
      email: email,
      name: name,
      avatarUrl: avatarUrl,
      language: language,
      timezone: timezone,
      location: location,
    );
  }

  /// Registers the push token with Appwin, through the Support endpoint.
  /// On iOS, prefer the APNs token in hex, not the FCM one.
  /// `platform` defaults to the device's: a hard-coded default would send FCM
  /// tokens labelled "ios", which the server would route to APNs.
  Future<void> registerPushToken({
    required String token,
    String? platform,
    bool pushOptIn = true,
  }) {
    return AppwinSupportPlatform.instance.registerPushToken(
      token: token,
      platform: platform,
      pushOptIn: pushOptIn,
    );
  }

  /// In-app messages pending for this device.
  Future<List<AppwinInAppMessage>> fetchPendingInAppMessages() {
    return AppwinSupportPlatform.instance.fetchPendingInAppMessages();
  }

  /// Tracks the opening or dismissal of an in-app message.
  Future<void> trackInAppDelivery({
    required String deliveryId,
    required String event,
  }) {
    return AppwinSupportPlatform.instance.trackInAppDelivery(
      deliveryId: deliveryId,
      event: event,
    );
  }
}
