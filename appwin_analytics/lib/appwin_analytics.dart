/// Product analytics for [Appwin](https://appwin.io).
///
/// Sessions, screens and custom events, ingested by the Appwin backend and
/// explored in the web dashboard (trends, funnels, retention). The native SDK
/// owns the pipeline: batching, offline persistence and upload all happen
/// below this thin Dart layer.
///
/// Depends on `appwin_core`, which it re-exports: one `configure()` covers
/// this package and its siblings.
///
/// ```dart
/// import 'package:appwin_analytics/appwin_analytics.dart';
///
/// Future<void> main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///   await AppwinCore.instance.configure(appId: 'your-app-id');
///
///   final analytics = await AppwinAnalytics.instance.initialize();
///   if (analytics.isReady) {
///     AppwinAnalytics.instance.track('level_completed', props: {'level': 3});
///   }
/// }
/// ```
library;

import 'package:appwin_core/appwin_core.dart';
import 'appwin_analytics_platform_interface.dart';

/// Re-exports the foundation, so one import gives both `AppwinCore` and the
/// analytics surface.
export 'package:appwin_core/appwin_core.dart';

/// Analytics consent, relayed to the native pipeline.
///
/// `granted` is the default posture (opt-out analytics); a consent-screen app
/// starts at `unknown` and settles it after the user answers.
enum AppwinAnalyticsConsent { granted, denied, unknown }

/// Public facade of the Appwin Analytics SDK.
class AppwinAnalytics {
  AppwinAnalytics._();

  /// Shared instance.
  static final AppwinAnalytics instance = AppwinAnalytics._();

  /// Sanity check for the Dart-to-native bridge, returning e.g. "iOS 18.0".
  Future<String?> getPlatformVersion() {
    return AppwinAnalyticsPlatform.instance.getPlatformVersion();
  }

  /// Starts the analytics pipeline, availability permitting.
  ///
  /// Call it after `AppwinCore.instance.configure()`. The server verdict
  /// (plan, product toggle) gates the start; the result is cached on disk so
  /// an offline launch falls back to the last known answer.
  Future<AppwinInitResult> initialize() {
    return AppwinAnalyticsPlatform.instance.initialize();
  }

  /// Queues a custom event. Never blocks and never throws: the event is
  /// persisted locally and uploaded in batches (offline included).
  ///
  /// `name` must match `^[a-z][a-z0-9_]{0,63}$` and not shadow a reserved
  /// name (`session_start`, `session_end`, `screen_view`, `app_install`,
  /// `app_update`). Props accept strings, numbers and booleans; anything else
  /// is stringified.
  ///
  /// The `purchase` convention: `{'value': 9.99, 'currency': 'EUR'}` makes
  /// the amount reach the ad networks (Meta CAPI, TikTok) and the SKAN
  /// conversion value when Attribution runs.
  Future<void> track(String name, {Map<String, Object?>? props}) {
    return AppwinAnalyticsPlatform.instance.track(name, props: props);
  }

  /// Emits the reserved `screen_view` event for [name]. Screen names feed
  /// funnel steps and breakdowns in the dashboard.
  Future<void> screen(String name) {
    return AppwinAnalyticsPlatform.instance.screen(name);
  }

  /// Forces an immediate upload of the pending queue. Rarely needed: the
  /// pipeline flushes on its own cadence and on backgrounding.
  Future<void> flush() {
    return AppwinAnalyticsPlatform.instance.flush();
  }

  /// Analytics consent. Callable before [initialize] (buffered natively).
  Future<void> setConsent(AppwinAnalyticsConsent consent) {
    return AppwinAnalyticsPlatform.instance.setConsent(consent);
  }
}
