import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'appwin_community_platform_interface.dart';
import 'appwin_community_user.dart';

/// Method-channel implementation of [AppwinCommunityPlatform].
class AppwinCommunityMethodChannel extends AppwinCommunityPlatform {
  @visibleForTesting
  final methodChannel = const MethodChannel('appwin_community');

  @override
  Future<String?> getPlatformVersion() {
    return methodChannel.invokeMethod<String>('getPlatformVersion');
  }

  @override
  Future<void> initialize({required String appId, String? baseUrl}) async {
    final args = <String, dynamic>{'appId': appId};
    if (baseUrl != null) args['baseUrl'] = baseUrl;
    await methodChannel.invokeMethod<void>('initialize', args);
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
