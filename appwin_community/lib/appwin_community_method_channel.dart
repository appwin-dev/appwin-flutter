/// Default implementation of [AppwinCommunityPlatform], over a method channel.
///
/// Every call forwards to the native Appwin SDK, which owns the feed and its
/// UI: the Dart side holds no state of its own.
library;

import 'package:appwin_core/appwin_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'appwin_community_platform_interface.dart';
import 'appwin_community_user.dart';

/// Method-channel implementation of [AppwinCommunityPlatform].
///
/// Registered automatically; you should not need to construct one. It is
/// public so a test can reach [methodChannel] and stub the native side.
class AppwinCommunityMethodChannel extends AppwinCommunityPlatform {
  /// Creates the default implementation.
  AppwinCommunityMethodChannel();

  /// Channel shared with the native plugins, named `appwin_community` on both
  /// sides. Exposed for tests, which stub it rather than the whole platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('appwin_community');

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
  Future<void> presentCommunity() async {
    await methodChannel.invokeMethod<void>('presentCommunity');
  }

  @override
  Future<void> login({required String externalId}) async {
    await methodChannel.invokeMethod<void>('login', {'externalId': externalId});
  }

  @override
  Future<void> logout() async {
    await methodChannel.invokeMethod<void>('logout');
  }

  @override
  Future<AppwinCommunityUser?> setUser({
    String? nickname,
    String? avatarUrl,
    String? bio,
  }) async {
    // `null` fields are stripped: natively, absent means "do not touch", while
    // an explicit `null` would mean "clear".
    final attributes = <String, dynamic>{
      'nickname': ?nickname,
      'avatarUrl': ?avatarUrl,
      'bio': ?bio,
    };
    final raw = await methodChannel.invokeMethod<Map<dynamic, dynamic>>(
      'setUser',
      attributes,
    );
    if (raw == null) return null;
    return AppwinCommunityUser.fromMap(raw);
  }

  @override
  Future<int> unreadNotificationCount() async {
    final count = await methodChannel.invokeMethod<int>(
      'unreadNotificationCount',
    );
    return count ?? 0;
  }
}
