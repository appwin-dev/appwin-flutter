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
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;

import 'appwin_analytics_platform_interface.dart';
import 'src/crash_handlers.dart';
import 'src/dart_stack.dart';
import 'src/replay_reporter.dart';

/// Re-exports the foundation, so one import gives both `AppwinCore` and the
/// analytics surface.
export 'package:appwin_core/appwin_core.dart';

export 'src/navigator_observer.dart';
export 'src/replay_masks.dart' show AppwinMask, AppwinUnmask;

/// Analytics consent, relayed to the native pipeline.
///
/// `granted` is the default posture (opt-out analytics); a consent-screen app
/// starts at `unknown` and settles it after the user answers.
enum AppwinAnalyticsConsent { granted, denied, unknown }

/// Facade no-throw contract: a bridge failure (missing native plugin,
/// platform exception) degrades to [fallback] instead of reaching the host
/// app. Integrators never need to wrap Appwin calls in try/catch.
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

/// Public facade of the Appwin Analytics SDK.
class AppwinAnalytics {
  AppwinAnalytics._();

  /// Shared instance.
  static final AppwinAnalytics instance = AppwinAnalytics._();

  /// Sanity check for the Dart-to-native bridge, returning e.g. "iOS 18.0".
  Future<String?> getPlatformVersion() {
    return _guard(
      'getPlatformVersion',
      AppwinAnalyticsPlatform.instance.getPlatformVersion,
      null,
    );
  }

  /// Starts the analytics pipeline, availability permitting.
  ///
  /// Call it after `AppwinCore.instance.configure()`. The server verdict
  /// (plan, product toggle) gates the start; the result is cached on disk so
  /// an offline launch falls back to the last known answer.
  ///
  /// Crash reporting rides on the same verdict. With [crashReporting] on (the
  /// default), the native SDK captures native crashes and ANRs, and uncaught
  /// Dart errors are reported through `FlutterError.onError` and
  /// `PlatformDispatcher.onError`. Handlers already installed (Crashlytics,
  /// Sentry, your own) keep running after Appwin's.
  ///
  /// [inAppPackages] names your own Dart packages (`['my_app']`): only their
  /// frames group errors into issues. Left empty, every `package:` frame
  /// counts except Flutter's and Appwin's.
  ///
  /// [sessionReplay] `false` never records this app's screen, even when
  /// session replay is switched on in the dashboard. When it is on, a share
  /// of the sessions (set in the dashboard) is recorded as video, one frame
  /// per second, under the same consent as the events. Text fields are always
  /// masked on the device, texts and images by default; wrap a widget in
  /// [AppwinMask] or [AppwinUnmask] to adjust it.
  Future<AppwinInitResult> initialize({
    bool crashReporting = true,
    List<String> inAppPackages = const [],
    bool sessionReplay = true,
  }) async {
    final result = await _guard(
      'initialize',
      () => AppwinAnalyticsPlatform.instance.initialize(
        crashReporting: crashReporting,
        sessionReplay: sessionReplay,
      ),
      const AppwinInitResult(AppwinInitStatus.unknown),
    );
    if (sessionReplay && result.isReady) {
      try {
        _replayMasks.start();
      } catch (e) {
        // No widgets binding: no Flutter UI to mask either.
        if (kDebugMode) debugPrint('[Appwin] session replay masks: $e');
      }
    }
    // Not before the verdict: the native reporter only exists once Analytics
    // is ready, and would drop each error with a warning until then.
    if (crashReporting && result.isReady) {
      _inAppPackages = List.unmodifiable(inAppPackages);
      // A hook without a stack has no better one to offer: the current stack
      // would only show the error dispatch path.
      installCrashHandlers(
        (error, stack) => recordError(error, stack ?? StackTrace.empty),
      );
    }
    return result;
  }

  List<String> _inAppPackages = const [];

  final ReplayMaskReporter _replayMasks = ReplayMaskReporter(
    readRules: () => AppwinAnalyticsPlatform.instance.replayMaskRules(),
    writeMasks: (rects) => AppwinAnalyticsPlatform.instance.setReplayMasks(rects),
  );

  /// Reports a caught Dart error, shown under Crashes as a non-fatal issue
  /// (or a crash with [fatal]). Pass the [stack] from the `catch` clause;
  /// without it the report falls back to the current stack.
  ///
  /// Requires [initialize] with crash reporting on; dropped otherwise.
  /// Never throws.
  Future<void> recordError(
    Object error, [
    StackTrace? stack,
    bool fatal = false,
  ]) {
    return _guardVoid('recordError', () {
      return AppwinAnalyticsPlatform.instance.recordBridgedError(
        fatal: fatal,
        type: error.runtimeType.toString(),
        message: describeError(error),
        frames: parseDartStack(
          stack ?? StackTrace.current,
          inAppPackages: _inAppPackages,
        ),
      );
    });
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
    return _guardVoid(
      'track',
      () => AppwinAnalyticsPlatform.instance.track(name, props: props),
    );
  }

  /// Emits the reserved `screen_view` event for [name]. Screen names feed
  /// funnel steps and breakdowns in the dashboard.
  Future<void> screen(String name) {
    return _guardVoid(
      'screen',
      () => AppwinAnalyticsPlatform.instance.screen(name),
    );
  }

  /// Forces an immediate upload of the pending queue. Rarely needed: the
  /// pipeline flushes on its own cadence and on backgrounding.
  Future<void> flush() {
    return _guardVoid('flush', AppwinAnalyticsPlatform.instance.flush);
  }

  /// Analytics consent. Callable before [initialize] (buffered natively).
  Future<void> setConsent(AppwinAnalyticsConsent consent) {
    return _guardVoid(
      'setConsent',
      () => AppwinAnalyticsPlatform.instance.setConsent(consent),
    );
  }
}
