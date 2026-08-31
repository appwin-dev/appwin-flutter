import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'appwin_core_platform_interface.dart';

/// Method-channel implementation of [AppwinCorePlatform].
class AppwinCoreMethodChannel extends AppwinCorePlatform {
  @visibleForTesting
  final methodChannel = const MethodChannel('appwin_core');

  @override
  Future<void> configure({
    required String appId,
    String? baseUrl,
    String? realtimeBaseUrl,
  }) async {
    if (appId.trim().isEmpty) {
      // Checked here rather than natively: the error surfaces with a usable
      // Dart stack instead of an opaque bridge exception.
      throw ArgumentError.value(appId, 'appId', 'ne doit pas être vide');
    }
    await methodChannel.invokeMethod<void>('configure', <String, dynamic>{
      'appId': appId,
      'baseUrl': ?baseUrl,
      'realtimeBaseUrl': ?realtimeBaseUrl,
    });
  }

  @override
  Future<String> bootstrapSession({String? externalId}) async {
    final token = await methodChannel.invokeMethod<String>(
      'bootstrapSession',
      <String, dynamic>{'externalId': ?externalId},
    );
    return token ?? '';
  }

  @override
  Future<void> identify({required String externalId}) async {
    await methodChannel.invokeMethod<void>('identify', {
      'externalId': externalId,
    });
  }

  @override
  Future<void> clearIdentity() async {
    await methodChannel.invokeMethod<void>('clearIdentity');
  }

  @override
  Future<void> signOut() async {
    await methodChannel.invokeMethod<void>('signOut');
  }

  @override
  Future<String?> deviceId() {
    return methodChannel.invokeMethod<String>('deviceId');
  }

  @override
  Future<String?> getPlatformVersion() {
    return methodChannel.invokeMethod<String>('getPlatformVersion');
  }
}
