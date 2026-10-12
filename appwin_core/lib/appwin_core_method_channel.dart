/// Default implementation of [AppwinCorePlatform], over a method channel.
///
/// Every call here forwards to the native Appwin SDK, which is where the work
/// actually happens: the Dart side holds no state of its own.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'appwin_core_platform_interface.dart';
import 'appwin_init_result.dart';
import 'appwin_product.dart';
import 'appwin_user_attributes.dart';

/// Method-channel implementation of [AppwinCorePlatform].
///
/// Registered automatically; you should not need to construct one. It is
/// public so a test can reach [methodChannel] and stub the native side.
class AppwinCoreMethodChannel extends AppwinCorePlatform {
  /// Creates the default implementation.
  AppwinCoreMethodChannel();

  /// Channel shared with the native plugins, named `appwin_core` on both
  /// sides. Exposed for tests, which stub it rather than the whole platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('appwin_core');

  /// Verdict stream, one native subscription covering every watched product.
  /// Exposed for tests, which mock its stream handler.
  @visibleForTesting
  final availabilityChannel = const EventChannel('appwin_core/availability');

  final Map<AppwinProduct, Set<MultiStreamController<AppwinInitResult>>>
  _watchers = {};
  final Map<AppwinProduct, AppwinInitResult> _latest = {};
  Set<AppwinProduct> _subscribed = const {};
  StreamSubscription<Object?>? _native;

  @override
  Stream<AppwinInitResult> availabilityUpdates(AppwinProduct product) {
    return Stream.multi((listener) {
      final watchers = _watchers.putIfAbsent(product, () => {});
      watchers.add(listener);
      // Native replays the current verdict only on a fresh subscription, and
      // a second watcher of the same product does not cause one.
      final known = _latest[product];
      if (known != null) listener.add(known);
      _syncNativeSubscription();
      listener.onCancel = () {
        watchers.remove(listener);
        if (watchers.isEmpty) {
          _watchers.remove(product);
          _latest.remove(product);
        }
        _syncNativeSubscription();
      };
    });
  }

  /// An event channel carries a single native subscription: a second `listen`
  /// on the same name replaces the first on both sides. So every product
  /// shares one, restarted with the new product list when that list changes.
  void _syncNativeSubscription() {
    final wanted = _watchers.keys.toSet();
    if (setEquals(wanted, _subscribed)) return;
    _native?.cancel();
    _native = null;
    _subscribed = wanted;
    if (wanted.isEmpty) return;
    _native = availabilityChannel
        .receiveBroadcastStream(<String, dynamic>{
          'products': [for (final product in wanted) product.key],
        })
        .listen(
          _onNativeVerdict,
          onError: (Object error) {
            if (kDebugMode) {
              debugPrint('[Appwin] availabilityUpdates: bridge error: $error');
            }
          },
        );
  }

  void _onNativeVerdict(Object? event) {
    if (event is! Map) return;
    final product = AppwinProduct.fromKey(event['product']);
    final watchers = _watchers[product];
    if (product == null || watchers == null) return;
    final result = AppwinInitResult.fromMap(event);
    if (_latest[product] == result) return;
    _latest[product] = result;
    for (final watcher in watchers.toList()) {
      watcher.add(result);
    }
  }

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
  Future<void> identify(String externalId, {AppwinUserAttributes? attributes}) async {
    if (externalId.trim().isEmpty) {
      throw ArgumentError.value(externalId, 'externalId', 'must not be blank');
    }
    await methodChannel.invokeMethod<void>('identify', <String, dynamic>{
      'externalId': externalId,
      'attributes': ?attributes?.toMap(),
    });
  }

  @override
  Future<void> updateUser(AppwinUserAttributes attributes) async {
    await methodChannel.invokeMethod<void>('updateUser', <String, dynamic>{
      'attributes': attributes.toMap(),
    });
  }

  @override
  Future<void> logout() async {
    await methodChannel.invokeMethod<void>('logout');
  }

  @override
  Future<String?> deviceId() {
    return methodChannel.invokeMethod<String>('deviceId');
  }

  @override
  Future<String?> getPlatformVersion() {
    return methodChannel.invokeMethod<String>('getPlatformVersion');
  }

  @override
  Future<bool> hasRegisteredPushToken() async {
    final registered = await methodChannel.invokeMethod<bool>(
      'hasRegisteredPushToken',
    );
    return registered ?? false;
  }

  @override
  Future<void> registerPushToken({
    required String token,
    String? platform,
    bool pushOptIn = true,
  }) async {
    if (token.trim().isEmpty) {
      throw ArgumentError.value(token, 'token', 'must not be blank');
    }
    await methodChannel.invokeMethod<void>('registerPushToken', {
      'token': token,
      'platform': platform ?? _devicePlatform,
      'pushOptIn': pushOptIn,
    });
  }

  @override
  Future<bool> isAppwinPush(Map<String, dynamic> data) =>
      _invokePush('isAppwinPush', {'data': data});

  @override
  Future<bool> handlePushTap(Map<String, dynamic> data) =>
      _invokePush('handlePushTap', {'data': data});

  @override
  Future<bool> handlePushForeground(
    Map<String, dynamic> data, {
    String? title,
    String? body,
  }) => _invokePush('handlePushForeground', {
    'data': data,
    'title': ?title,
    'body': ?body,
  });

  @override
  Future<bool> handlePushMessage(Map<String, dynamic> data) =>
      _invokePush('handlePushMessage', {'data': data});

  /// The payload goes over as received: nested values stay structured for
  /// iOS, where `userInfo` nests `data` as a dictionary, and the Android
  /// plugin flattens them to the strings FCM carries.
  Future<bool> _invokePush(String method, Map<String, dynamic> args) async {
    final consumed = await methodChannel.invokeMethod<bool>(method, args);
    return consumed ?? false;
  }

  /// The server routes the send to APNs or FCM from this value.
  String get _devicePlatform =>
      defaultTargetPlatform == TargetPlatform.android ? 'android' : 'ios';
}
