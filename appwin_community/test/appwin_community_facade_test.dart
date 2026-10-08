import 'dart:async';

import 'package:appwin_community/appwin_community.dart';
import 'package:appwin_community/appwin_community_platform_interface.dart';
import 'package:appwin_core/appwin_core_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// Inherits the base class bodies, which all throw UnimplementedError: a
/// stand-in for any bridge failure (missing plugin, platform exception).
class _ThrowingPlatform extends AppwinCommunityPlatform
    with MockPlatformInterfaceMixin {}

class _FakePlatform extends AppwinCommunityPlatform
    with MockPlatformInterfaceMixin {
  _FakePlatform(this.verdict);

  final AppwinInitResult verdict;
  final hostCallbacks = <Map<String, bool>>[];

  @override
  Future<AppwinInitResult> initialize() async => verdict;

  @override
  Future<void> setHostCallbacks({
    void Function(AppwinCommunityPostTarget target)? onNotificationTap,
    void Function()? onEditProfile,
  }) async {
    hostCallbacks.add({
      'notificationTap': onNotificationTap != null,
      'editProfile': onEditProfile != null,
    });
  }
}

class _FakeCore extends AppwinCorePlatform with MockPlatformInterfaceMixin {
  final verdicts = StreamController<AppwinInitResult>.broadcast();

  @override
  Stream<AppwinInitResult> availabilityUpdates(AppwinProduct product) =>
      verdicts.stream;
}

const _ready = AppwinInitResult(AppwinInitStatus.ready);
const _plan = AppwinInitResult(
  AppwinInitStatus.unavailable,
  reason: AppwinUnavailableReason.plan,
);

void main() {
  late _FakeCore core;

  setUp(() {
    core = _FakeCore();
    AppwinCorePlatform.instance = core;
  });

  tearDown(AppwinCommunity.instance.resetForTesting);

  test('the facade never throws when the bridge does', () async {
    AppwinCommunityPlatform.instance = _ThrowingPlatform();
    final community = AppwinCommunity.instance;

    expect((await community.initialize()).status, AppwinInitStatus.unknown);
    await community.openPost('p1', commentId: 'c1');
    community.onNotificationTap = (_) {};
    community.onEditProfile = () {};
    expect(await community.events.toList(), isEmpty);
    expect(await community.unreadNotificationCountStream.toList(), isEmpty);
    expect(await community.unreadNotificationCount(), 0);
  });

  test('lastResult is null until initialize, then follows the verdict', () async {
    AppwinCommunityPlatform.instance = _FakePlatform(_ready);
    final community = AppwinCommunity.instance;

    expect(community.lastResult, isNull);
    expect(await community.initialize(), _ready);
    expect(community.lastResult, _ready);
    expect(community.isReady, isTrue);

    core.verdicts.add(_plan);
    await pumpEventQueue();
    expect(community.lastResult, _plan);
    expect(community.isReady, isFalse);
  });

  test('each handler change tells native which handlers exist', () async {
    final platform = _FakePlatform(_ready);
    AppwinCommunityPlatform.instance = platform;

    AppwinCommunity.instance.onNotificationTap = (_) {};
    AppwinCommunity.instance.onEditProfile = () {};
    AppwinCommunity.instance.onNotificationTap = null;
    await pumpEventQueue();

    expect(platform.hostCallbacks, [
      {'notificationTap': true, 'editProfile': false},
      {'notificationTap': true, 'editProfile': true},
      {'notificationTap': false, 'editProfile': true},
    ]);
  });

  group('AppwinCommunityView', () {
    // Linux renders the plain placeholder: a real platform view cannot be
    // created in a widget test.
    final linux = TargetPlatformVariant.only(TargetPlatform.linux);

    Widget view() => MaterialApp(
      home: AppwinCommunityView(
        unavailableBuilder: (context, result) => Text('closed: ${result.reason?.name}'),
      ),
    );

    testWidgets('keeps the native view until the verdict is known', (tester) async {
      await tester.pumpWidget(view());

      expect(find.textContaining('closed'), findsNothing);
    }, variant: linux);

    testWidgets('switches live between the builder and the native view', (
      tester,
    ) async {
      AppwinCommunityPlatform.instance = _FakePlatform(_plan);
      await tester.pumpWidget(view());

      await tester.runAsync(AppwinCommunity.instance.initialize);
      await tester.pump();
      expect(find.text('closed: plan'), findsOneWidget);

      core.verdicts.add(_ready);
      await tester.runAsync(pumpEventQueue);
      await tester.pump();
      expect(find.textContaining('closed'), findsNothing);
    }, variant: linux);
  });
}
