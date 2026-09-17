/// Acquisition attribution for [Appwin](https://appwin.io).
///
/// The acquisition signals of an app: SKAdNetwork conversion values and the
/// advertising identity (IDFA) on iOS, the Play Install Referrer and GAID on
/// Android, plus the optional embedded ad-network adapters (TikTok). The
/// native SDK owns everything; this layer only relays the app's decisions.
///
/// Depends on `appwin_core`, which it re-exports: one `configure()` covers
/// this package and its siblings.
///
/// ```dart
/// import 'package:appwin_attribution/appwin_attribution.dart';
///
/// Future<void> main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///   await AppwinCore.instance.configure(appId: 'your-app-id');
///
///   AppwinAttribution.instance.setAdvertisingConsent(
///     AppwinAdvertisingConsent.granted,
///   );
///   await AppwinAttribution.instance.initialize();
///   await AppwinAttribution.instance.requestTrackingAuthorization();
/// }
/// ```
library;

import 'package:appwin_core/appwin_core.dart';
import 'appwin_attribution_platform_interface.dart';

/// Re-exports the foundation, so one import gives both `AppwinCore` and the
/// attribution surface.
export 'package:appwin_core/appwin_core.dart';

/// Advertising consent (opt-in): whether conversion signals may be activated
/// towards the ad networks and whether the advertising identifier may be
/// collected.
enum AppwinAdvertisingConsent { granted, denied, unknown }

/// Public facade of the Appwin Attribution SDK.
class AppwinAttribution {
  AppwinAttribution._();

  /// Shared instance.
  static final AppwinAttribution instance = AppwinAttribution._();

  /// Sanity check for the Dart-to-native bridge, returning e.g. "iOS 18.0".
  Future<String?> getPlatformVersion() {
    return AppwinAttributionPlatform.instance.getPlatformVersion();
  }

  /// Starts the acquisition signals, availability permitting.
  ///
  /// Call it after `AppwinCore.instance.configure()`. The server verdict
  /// (plan, product toggle) gates the start; the result is cached on disk so
  /// an offline launch falls back to the last known answer.
  Future<AppwinInitResult> initialize() {
    return AppwinAttributionPlatform.instance.initialize();
  }

  /// Relays your consent flow's verdict. Callable before [initialize]
  /// (buffered natively).
  ///
  /// The rule: this decides IF signals reach the networks at all; on iOS,
  /// ATT decides only whether the IDFA enriches them.
  Future<void> setAdvertisingConsent(AppwinAdvertisingConsent consent) {
    return AppwinAttributionPlatform.instance.setAdvertisingConsent(consent);
  }

  /// Presents the ATT prompt on iOS and resolves with the answer. The app
  /// decides WHEN to ask, and must declare `NSUserTrackingUsageDescription`
  /// in its Info.plist. A refused ATT does not stop attribution; it only
  /// removes the IDFA from the signals.
  ///
  /// Android has no ATT: resolves `true` without showing anything.
  Future<bool> requestTrackingAuthorization() {
    return AppwinAttributionPlatform.instance.requestTrackingAuthorization();
  }

  /// Debug mode for the embedded ad-network adapters (TikTok test events):
  /// events sent while enabled show up in real time in the network's test
  /// console and are flagged as TEST data, excluded from campaign
  /// optimisation.
  ///
  /// Call it BEFORE [initialize]; never ship a release build with this
  /// enabled.
  Future<void> setAdSignalsDebugMode(bool enabled) {
    return AppwinAttributionPlatform.instance.setAdSignalsDebugMode(enabled);
  }
}
