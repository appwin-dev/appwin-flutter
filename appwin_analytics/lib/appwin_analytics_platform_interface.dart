/// Platform contract behind `AppwinAnalytics`.
library;

import 'dart:typed_data';

import 'package:appwin_core/appwin_core.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'appwin_analytics.dart' show AppwinAnalyticsConsent;
import 'appwin_analytics_method_channel.dart';
import 'src/replay_masks.dart' show ReplayMaskRules;

export 'src/replay_masks.dart' show ReplayMaskRules;

/// Contract each platform implements. Host apps go through
/// `AppwinAnalytics.instance` instead.
abstract class AppwinAnalyticsPlatform extends PlatformInterface {
  /// Constructs a AppwinAnalyticsPlatform.
  AppwinAnalyticsPlatform() : super(token: _token);

  static final Object _token = Object();

  static AppwinAnalyticsPlatform _instance = AppwinAnalyticsMethodChannel();

  /// The implementation in use, method channel by default.
  static AppwinAnalyticsPlatform get instance => _instance;

  static set instance(AppwinAnalyticsPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Host OS and version. See `AppwinAnalytics.getPlatformVersion`.
  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  /// Whether this app may use Analytics. See `AppwinAnalytics.initialize`.
  Future<AppwinInitResult> initialize({
    bool crashReporting = true,
    bool sessionReplay = true,
  }) {
    throw UnimplementedError('initialize() has not been implemented.');
  }

  /// `maskAllText` and `maskAllImages` of the running session replay, `null`
  /// when nothing records.
  Future<ReplayMaskRules?> replayMaskRules() {
    throw UnimplementedError('replayMaskRules() has not been implemented.');
  }

  /// Hands the native recorder what to paint over in Flutter's surface:
  /// flat `[left, top, right, bottom, ...]` in logical pixels of the view,
  /// replacing the previous set.
  Future<void> setReplayMasks(List<double> rects) {
    throw UnimplementedError('setReplayMasks() has not been implemented.');
  }

  /// Hands the native recorder a frame Flutter rendered: RGBA, premultiplied,
  /// [width] x [height], with the masks of that same frame as in
  /// [setReplayMasks]. Only while [ReplayMaskRules.captureFrames] says so.
  Future<void> setReplayFrame(
    Uint8List rgba, {
    required int width,
    required int height,
    required List<double> rects,
  }) {
    throw UnimplementedError('setReplayFrame() has not been implemented.');
  }

  /// Queues a custom event. See `AppwinAnalytics.track`.
  Future<void> track(String name, {Map<String, Object?>? props}) {
    throw UnimplementedError('track() has not been implemented.');
  }

  /// Emits a `screen_view`. See `AppwinAnalytics.screen`.
  Future<void> screen(String name) {
    throw UnimplementedError('screen() has not been implemented.');
  }

  /// Uploads the pending queue now. See `AppwinAnalytics.flush`.
  Future<void> flush() {
    throw UnimplementedError('flush() has not been implemented.');
  }

  /// Hands a Dart error to the native crash pipeline, which stores and
  /// uploads it with runtime `flutter`. See `AppwinAnalytics.recordError`.
  Future<void> recordBridgedError({
    required bool fatal,
    required String type,
    String? message,
    required List<Map<String, Object>> frames,
  }) {
    throw UnimplementedError('recordBridgedError() has not been implemented.');
  }

  /// Relays the analytics consent. See `AppwinAnalytics.setConsent`.
  Future<void> setConsent(AppwinAnalyticsConsent consent) {
    throw UnimplementedError('setConsent() has not been implemented.');
  }
}
