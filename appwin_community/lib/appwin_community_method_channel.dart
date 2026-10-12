/// Default implementation of [AppwinCommunityPlatform], over a method channel.
///
/// Every call forwards to the native Appwin SDK, which owns the feed and its
/// UI: the Dart side holds no state of its own.
library;

import 'dart:async';

import 'package:appwin_core/appwin_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'appwin_community_event.dart';
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

  /// The member's own actions. Exposed for tests.
  @visibleForTesting
  final eventsChannel = const EventChannel('appwin_community/events');

  /// The live unread count. Exposed for tests.
  @visibleForTesting
  final unreadCountChannel = const EventChannel('appwin_community/unread_count');

  void Function(AppwinCommunityPostTarget target)? _onNotificationTap;
  void Function()? _onEditProfile;

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

  @override
  Future<void> openPost(String postId, {String? commentId}) async {
    if (postId.trim().isEmpty) {
      throw ArgumentError.value(postId, 'postId', 'must not be blank');
    }
    await methodChannel.invokeMethod<void>('openPost', <String, dynamic>{
      'postId': postId,
      'commentId': ?commentId,
    });
  }

  @override
  Future<void> setHostCallbacks({
    void Function(AppwinCommunityPostTarget target)? onNotificationTap,
    void Function()? onEditProfile,
  }) async {
    _onNotificationTap = onNotificationTap;
    _onEditProfile = onEditProfile;
    // Installed before telling native, so a tap native replays as soon as it
    // knows about the handler already finds one here.
    methodChannel.setMethodCallHandler(_handleNativeCall);
    await methodChannel.invokeMethod<void>('setHostCallbacks', <String, bool>{
      'notificationTap': onNotificationTap != null,
      'editProfile': onEditProfile != null,
    });
  }

  /// Native reads `false` as "nobody here", and falls back to its own
  /// behaviour: after a hot restart it can still believe a handler exists.
  Future<Object?> _handleNativeCall(MethodCall call) async {
    switch (call.method) {
      case 'onNotificationTap':
        final handler = _onNotificationTap;
        final target = AppwinCommunityPostTarget.fromMap(
          call.arguments as Map<Object?, Object?>?,
        );
        if (handler == null || target == null) return false;
        _runHostCallback('onNotificationTap', () => handler(target));
        return true;
      case 'onEditProfile':
        final handler = _onEditProfile;
        if (handler == null) return false;
        _runHostCallback('onEditProfile', handler);
        return true;
      default:
        throw MissingPluginException('${call.method} is not handled by Dart');
    }
  }

  /// A throwing host handler must not come back to native as a bridge error.
  void _runHostCallback(String name, void Function() body) {
    try {
      body();
    } catch (e, stack) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: e,
          stack: stack,
          library: 'appwin_community',
          context: ErrorDescription('while running AppwinCommunity.$name'),
        ),
      );
    }
  }

  // Cached: an event channel carries one native subscription, and a second
  // `receiveBroadcastStream` would silently take it over from the first.
  @override
  late final Stream<AppwinCommunityEvent> events = eventsChannel
      .receiveBroadcastStream()
      .map((raw) => AppwinCommunityEvent.fromMap(raw as Map<Object?, Object?>?))
      .where((event) => event != null)
      .cast<AppwinCommunityEvent>();

  final Set<MultiStreamController<int>> _unreadWatchers = {};
  StreamSubscription<Object?>? _unreadNative;
  int? _unreadLatest;

  @override
  Stream<int> get unreadNotificationCountStream {
    return Stream.multi((listener) {
      _unreadWatchers.add(listener);
      // Native emits the known count only to a fresh subscription, which a
      // second listener does not cause.
      final known = _unreadLatest;
      if (known != null) listener.add(known);
      _unreadNative ??= unreadCountChannel.receiveBroadcastStream().listen(
        (raw) {
          if (raw is! int || raw == _unreadLatest) return;
          _unreadLatest = raw;
          for (final watcher in _unreadWatchers.toList()) {
            watcher.add(raw);
          }
        },
        onError: (Object error) {
          if (kDebugMode) {
            debugPrint('[Appwin] unreadNotificationCountStream: bridge error: $error');
          }
        },
      );
      listener.onCancel = () {
        _unreadWatchers.remove(listener);
        if (_unreadWatchers.isNotEmpty) return;
        _unreadNative?.cancel();
        _unreadNative = null;
        _unreadLatest = null;
      };
    });
  }
}
