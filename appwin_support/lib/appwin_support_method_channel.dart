/// Default implementation of [AppwinSupportPlatform], over a method channel.
///
/// Every call forwards to the native Appwin SDK, which owns the messenger UI:
/// the Dart side holds no state of its own.
library;

import 'package:appwin_core/appwin_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'appwin_support_platform_interface.dart';

/// An implementation of [AppwinSupportPlatform] that uses method channels.
///
/// Registered automatically; you should not need to construct one. It is
/// public so a test can reach [methodChannel] and stub the native side.
class AppwinSupportMethodChannel extends AppwinSupportPlatform {
  /// Creates the default implementation.
  AppwinSupportMethodChannel();

  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('appwin_support');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>(
      'getPlatformVersion',
    );
    return version;
  }

  @override
  Future<void> presentMessenger() async {
    await methodChannel.invokeMethod<void>('presentMessenger');
  }

  @override
  Future<void> presentConversation(String conversationId) async {
    if (conversationId.trim().isEmpty) {
      throw ArgumentError.value(
        conversationId,
        'conversationId',
        'must not be blank',
      );
    }
    await methodChannel.invokeMethod<void>('presentConversation', {
      'conversationId': conversationId,
    });
  }

  @override
  Future<AppwinInitResult> initialize() async {
    final raw = await methodChannel.invokeMethod<Map<Object?, Object?>>(
      'initialize',
    );
    return AppwinInitResult.fromMap(raw);
  }
}
