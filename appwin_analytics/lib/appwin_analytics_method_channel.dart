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
  Future<AppwinInitResult> initialize() async {
    final raw = await methodChannel.invokeMethod<Map<Object?, Object?>>(
      'initialize',
    );
    return AppwinInitResult.fromMap(raw);
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
  Future<void> setConsent(AppwinAnalyticsConsent consent) async {
    await methodChannel.invokeMethod<void>('setConsent', {
      'consent': consent.name,
    });
  }
}
