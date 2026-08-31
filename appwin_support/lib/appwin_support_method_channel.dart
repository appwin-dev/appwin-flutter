import 'package:appwin_core/appwin_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'appwin_support_platform_interface.dart';

/// An implementation of [AppwinSupportPlatform] that uses method channels.
class AppwinSupportMethodChannel extends AppwinSupportPlatform {
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
  Future<AppwinInitResult> initialize() async {
    final raw = await methodChannel.invokeMethod<Map<Object?, Object?>>('initialize');
    return AppwinInitResult.fromMap(raw);
  }

  @override
  Future<void> loginUnidentifiedUser() async {
    await methodChannel.invokeMethod<void>('loginUnidentifiedUser');
  }

  @override
  Future<void> loginIdentifiedUser({required String externalId}) async {
    await methodChannel.invokeMethod<void>('loginIdentifiedUser', {
      "externalId": externalId,
    });
  }

  @override
  Future<void> updateUser({
    String? email,
    String? name,
    String? avatarUrl,
    String? language,
    String? timezone,
    String? location,
  }) async {
    // Flat public params, serialised into an `attributes` map for transport,
    // since method channels only carry maps and primitives. On the Swift side,
    // `parseAttributes` rebuilds the AppwinSupportUserAttributes.
    await methodChannel.invokeMethod<void>('updateUser', {
      "attributes": {
        "email": email,
        "name": name,
        "avatarUrl": avatarUrl,
        "language": language,
        "timezone": timezone,
        "location": location,
      },
    });
  }

  @override
  Future<void> registerPushToken({
    required String token,
    String? platform,
    bool pushOptIn = true,
  }) async {
    await methodChannel.invokeMethod<void>('registerPushToken', {
      'token': token,
      'platform': platform ?? _devicePlatform,
      'pushOptIn': pushOptIn,
    });
  }

  /// The server routes the send to APNs or FCM from this value, so deriving it
  /// from the device stops an FCM token going out labelled "ios".
  String get _devicePlatform =>
      defaultTargetPlatform == TargetPlatform.android ? 'android' : 'ios';


}
