/// Default implementation of [AppwinNotificationsPlatform], over a method
/// channel.
///
/// Every call forwards to the native Appwin SDK, which owns the lifecycle
/// hooks, the push registration and the in-app presentation: the Dart side
/// holds no state of its own.
library;

import 'package:appwin_core/appwin_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'appwin_in_app_message.dart';
import 'appwin_notifications_platform_interface.dart';

/// Method-channel implementation of [AppwinNotificationsPlatform].
///
/// Registered automatically; you should not need to construct one. It is
/// public so a test can reach [methodChannel] and stub the native side.
class AppwinNotificationsMethodChannel extends AppwinNotificationsPlatform {
  /// Creates the default implementation.
  AppwinNotificationsMethodChannel();

  /// Channel shared with the native plugins, named `appwin_notifications` on
  /// both sides. Exposed for tests, which stub it rather than the whole
  /// platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('appwin_notifications');

  @override
  Future<String?> getPlatformVersion() {
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
  Future<void> start({bool requestPushPermission = true}) async {
    await methodChannel.invokeMethod<void>('start', {
      'requestPushPermission': requestPushPermission,
    });
  }

  @override
  Future<void> stop() async {
    await methodChannel.invokeMethod<void>('stop');
  }

  @override
  Future<void> registerPushToken({
    required String token,
    bool pushOptIn = true,
  }) async {
    await methodChannel.invokeMethod<void>('registerPushToken', {
      'token': token,
      'pushOptIn': pushOptIn,
    });
  }

  @override
  Future<void> trackEvent({
    required AppwinAutomationEvent event,
    String? eventName,
    Map<String, String>? properties,
  }) async {
    await methodChannel.invokeMethod<void>('trackEvent', {
      'event': event.wireValue,
      'eventName': ?eventName,
      'properties': ?properties,
    });
  }

  @override
  Future<List<AppwinInAppMessage>> fetchPendingMessages() async {
    final raw = await methodChannel.invokeMethod<List<Object?>>(
      'fetchPendingMessages',
    );
    return _decode(raw);
  }

  @override
  Future<void> track({
    required String deliveryId,
    required AppwinTrackEvent event,
    int? buttonIndex,
  }) async {
    await methodChannel.invokeMethod<void>('track', {
      'deliveryId': deliveryId,
      'event': event.name,
      'buttonIndex': ?buttonIndex,
    });
  }

  @override
  Future<List<AppwinInAppMessage>> syncOnAppOpen() async {
    final raw = await methodChannel.invokeMethod<List<Object?>>(
      'syncOnAppOpen',
    );
    return _decode(raw);
  }

  @override
  Future<void> presentPendingMessages() async {
    await methodChannel.invokeMethod<void>('presentPendingMessages');
  }

  List<AppwinInAppMessage> _decode(List<Object?>? raw) {
    if (raw == null) return const [];
    final messages = <AppwinInAppMessage>[];
    for (final entry in raw) {
      if (entry is! Map) continue;
      try {
        messages.add(AppwinInAppMessage.fromMap(entry));
      } catch (_) {
        continue;
      }
    }
    return messages;
  }
}
