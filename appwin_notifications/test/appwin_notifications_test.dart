import 'package:appwin_core/appwin_core_platform_interface.dart';
import 'package:appwin_notifications/appwin_notifications.dart';
import 'package:appwin_notifications/appwin_notifications_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class _MockPlatform
    with MockPlatformInterfaceMixin
    implements AppwinNotificationsPlatform {
  AppwinAutomationEvent? lastEvent;
  String? lastDeliveryId;
  bool? lastOptIn;

  @override
  Future<String?> getPlatformVersion() async => '42';

  @override
  Future<AppwinInitResult> initialize() async =>
      const AppwinInitResult(AppwinInitStatus.ready);

  @override
  Future<void> start({bool requestPushPermission = true}) async {}

  @override
  Future<void> stop() async {}

  @override
  Future<void> registerPushToken({
    required String token,
    bool pushOptIn = true,
  }) async {
    lastOptIn = pushOptIn;
  }

  @override
  Future<void> trackEvent({
    required AppwinAutomationEvent event,
    String? eventName,
    Map<String, String>? properties,
  }) async {
    lastEvent = event;
  }

  @override
  Future<List<AppwinInAppMessage>> fetchPendingMessages() async => const [];

  @override
  Future<void> track({
    required String deliveryId,
    required AppwinTrackEvent event,
    int? buttonIndex,
  }) async {
    lastDeliveryId = deliveryId;
  }

  @override
  Future<List<AppwinInAppMessage>> syncOnAppOpen() async => const [];

  @override
  Future<void> presentPendingMessages() async {}
}

/// Since `registerPushToken` moved to the foundation, the call to observe
/// leaves through `AppwinCorePlatform`, not this plugin's channel.
class _MockCorePlatform extends AppwinCorePlatform {
  String? lastToken;
  bool? lastOptIn;

  @override
  Future<void> registerPushToken({
    required String token,
    String? platform,
    bool pushOptIn = true,
  }) async {
    lastToken = token;
    lastOptIn = pushOptIn;
  }
}

void main() {
  late _MockPlatform platform;
  late _MockCorePlatform core;

  setUp(() {
    platform = _MockPlatform();
    AppwinNotificationsPlatform.instance = platform;
    core = _MockCorePlatform();
    AppwinCorePlatform.instance = core;
  });

  test('initialize reports whether the product may be used', () async {
    final result = await AppwinNotifications.instance.initialize();

    expect(result.isReady, isTrue);
  });

  test('registerPushToken defaults to opted in', () async {
    await AppwinNotifications.instance.registerPushToken(token: 'abc');

    expect(core.lastOptIn, isTrue);
  });

  test('a declined user is registered, not skipped', () async {
    await AppwinNotifications.instance.registerPushToken(
      token: 'abc',
      pushOptIn: false,
    );

    expect(core.lastOptIn, isFalse);
  });

  test('track carries the delivery id, not the campaign id', () async {
    await AppwinNotifications.instance.track(
      deliveryId: 'delivery-1',
      event: AppwinTrackEvent.opened,
    );

    expect(platform.lastDeliveryId, 'delivery-1');
  });

  test('automation events travel as the server spells them', () async {
    await AppwinNotifications.instance.trackEvent(
      event: AppwinAutomationEvent.sessionStart,
    );

    expect(platform.lastEvent?.wireValue, 'session_start');
  });
}
