/// Default implementation of [AppwinAttributionPlatform], over a method
/// channel. Every call forwards to the native Appwin SDK; the Dart side
/// holds no state of its own.
library;

import 'package:appwin_core/appwin_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'appwin_attribution.dart' show AppwinAdvertisingConsent;
import 'appwin_attribution_platform_interface.dart';

/// An implementation of [AppwinAttributionPlatform] that uses method channels.
class AppwinAttributionMethodChannel extends AppwinAttributionPlatform {
  /// Creates the default implementation.
  AppwinAttributionMethodChannel();

  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('appwin_attribution');

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
  Future<void> setAdvertisingConsent(AppwinAdvertisingConsent consent) async {
    await methodChannel.invokeMethod<void>('setAdvertisingConsent', {
      'consent': consent.name,
    });
  }

  @override
  Future<bool> requestTrackingAuthorization() async {
    final granted = await methodChannel.invokeMethod<bool>(
      'requestTrackingAuthorization',
    );
    return granted ?? false;
  }

  @override
  Future<void> setAdSignalsDebugMode(bool enabled) async {
    await methodChannel.invokeMethod<void>('setAdSignalsDebugMode', {
      'enabled': enabled,
    });
  }
}
