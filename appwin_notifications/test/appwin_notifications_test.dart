import 'package:appwin_notifications/appwin_notifications.dart';
import 'package:appwin_notifications/appwin_notifications_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class _MockPlatform
    with MockPlatformInterfaceMixin
    implements AppwinNotificationsPlatform {
  AppwinAutomationEvent? lastEvent;
  String? lastDeliveryId;
  bool? lastInstallsDelegate;

  @override
  Future<String?> getPlatformVersion() async => '42';

  @override
  Future<AppwinInitResult> initialize() async =>
      const AppwinInitResult(AppwinInitStatus.ready);

  @override
  Future<void> start({
    bool requestPushPermission = true,
    bool installsNotificationDelegate = true,
  }) async {
    lastInstallsDelegate = installsNotificationDelegate;
  }

  @override
  Future<void> stop() async {}

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

void main() {
  late _MockPlatform platform;

  setUp(() {
    platform = _MockPlatform();
    AppwinNotificationsPlatform.instance = platform;
  });

  test('initialize reports whether the product may be used', () async {
    final result = await AppwinNotifications.instance.initialize();

    expect(result.isReady, isTrue);
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

  test('start installs the notification delegate by default', () async {
    await AppwinNotifications.instance.start();

    expect(platform.lastInstallsDelegate, isTrue);
  });

  test('start leaves the delegate to a host that owns push', () async {
    await AppwinNotifications.instance.start(
      installsNotificationDelegate: false,
    );

    expect(platform.lastInstallsDelegate, isFalse);
  });
}
