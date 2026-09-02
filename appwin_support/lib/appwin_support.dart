/// Customer support messenger for [Appwin](https://appwin.io).
///
/// Puts a native help centre in your app: conversations with your team, an
/// FAQ, and a messenger whose colours, welcome message and agent identity the
/// studio sets in the web dashboard, with no release to ship. Your app only
/// supplies the entry point; the SDK draws the rest.
///
/// Depends on `appwin_core`, which it re-exports: one `configure()` covers
/// this package and its siblings `appwin_community` and
/// `appwin_notifications`.
///
/// ```dart
/// import 'package:appwin_support/appwin_support.dart';
///
/// Future<void> main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///   await AppwinCore.instance.configure(appId: 'your-app-id');
///
///   final support = await AppwinSupport.instance.initialize();
///   runApp(MyApp(showHelpButton: support.isReady));
/// }
/// ```
///
/// See the `example/` directory for a runnable integration.
library;

import 'package:appwin_core/appwin_core.dart';
import 'appwin_support_platform_interface.dart';

/// Re-exports the foundation, so one import gives both `AppwinCore` and the
/// messenger. Two Appwin products re-exporting the same library cannot
/// contradict each other: it is the same declaration.
export 'package:appwin_core/appwin_core.dart';

/// Public facade of the Appwin Support SDK.
///
/// Intercom style: a singleton, with the UI living in the native SDK. The app
/// calls `AppwinSupport.instance.presentMessenger()` and a native screen appears
/// over it; nothing is rendered on the Flutter side.
class AppwinSupport {
  AppwinSupport._();

  /// Shared instance.
  static final AppwinSupport instance = AppwinSupport._();

  /// Sanity check for the Dart-to-native bridge, returning e.g. "iOS 18.0".
  /// Answers even before `configure`, which is what separates a broken native
  /// install from a wrong Appwin configuration.
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

  /// Opens a session for a visitor you cannot name.
  ///
  /// The conversation still belongs to a customer, one identified by the
  /// device alone. Use it when support is reachable before sign-in; call
  /// [loginIdentifiedUser] once you know who they are.
  Future<void> loginUnidentifiedUser() {
    return AppwinSupportPlatform.instance.loginUnidentifiedUser();
  }

  /// Attaches the conversation to your app's user.
  ///
  /// The `externalId` is **yours**, the one in your database; Appwin never
  /// interprets it. The identity is shared with the other products, so the
  /// same person is recognised by Community.
  Future<void> loginIdentifiedUser({required String externalId}) {
    return AppwinSupportPlatform.instance.loginIdentifiedUser(
      externalId: externalId,
    );
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
}
