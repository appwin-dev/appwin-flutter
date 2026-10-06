/// Default implementation of [AppwinAnalyticsPlatform], over a method channel.
///
/// Every call forwards to the native Appwin SDK, which owns the pipeline: the
/// Dart side holds no state of its own.
library;

import 'package:appwin_core/appwin_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'appwin_analytics.dart' show AppwinAnalyticsConsent;
import 'appwin_analytics_platform_interface.dart';

/// An implementation of [AppwinAnalyticsPlatform] that uses method channels.
class AppwinAnalyticsMethodChannel extends AppwinAnalyticsPlatform {
  /// Creates the default implementation.
  AppwinAnalyticsMethodChannel();

  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('appwin_analytics');

  @override
  Future<String?> getPlatformVersion() async {
    return methodChannel.invokeMethod<String>('getPlatformVersion');
  }

  @override
  Future<AppwinInitResult> initialize({
    bool crashReporting = true,
    bool sessionReplay = true,
  }) async {
    final raw = await methodChannel.invokeMethod<Map<Object?, Object?>>(
      'initialize',
      {'crashReporting': crashReporting, 'sessionReplay': sessionReplay},
    );
    return AppwinInitResult.fromMap(raw);
  }

  @override
  Future<ReplayMaskRules?> replayMaskRules() async {
    final raw = await methodChannel.invokeMethod<Map<Object?, Object?>>(
      'replayMaskRules',
    );
    if (raw == null) return null;
    // A missing key masks: the rules must never fail open.
    return ReplayMaskRules(
      maskAllText: raw['maskAllText'] as bool? ?? true,
      maskAllImages: raw['maskAllImages'] as bool? ?? true,
    );
  }

  @override
  Future<void> setReplayMasks(List<double> rects) async {
    await methodChannel.invokeMethod<void>('setReplayMasks', {'rects': rects});
  }

  @override
  Future<void> track(String name, {Map<String, Object?>? props}) async {
    await methodChannel.invokeMethod<void>('track', {
      'name': name,
      'props': ?props,
    });
  }

  @override
  Future<void> screen(String name) async {
    await methodChannel.invokeMethod<void>('screen', {'name': name});
  }

  @override
  Future<void> flush() async {
    await methodChannel.invokeMethod<void>('flush');
  }

  @override
  Future<void> recordBridgedError({
    required bool fatal,
    required String type,
    String? message,
    required List<Map<String, Object>> frames,
  }) async {
    await methodChannel.invokeMethod<void>('recordBridgedError', {
      'fatal': fatal,
      'type': type,
      'message': ?message,
      'frames': frames,
    });
  }

  @override
  Future<void> setConsent(AppwinAnalyticsConsent consent) async {
    await methodChannel.invokeMethod<void>('setConsent', {
      'consent': consent.name,
    });
  }
}
