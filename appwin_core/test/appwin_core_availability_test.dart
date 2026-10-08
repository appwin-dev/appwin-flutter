import 'dart:async';

import 'package:appwin_core/appwin_core.dart';
import 'package:appwin_core/appwin_core_method_channel.dart';
import 'package:appwin_core/appwin_core_platform_interface.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class _ThrowingPlatform extends AppwinCorePlatform
    with MockPlatformInterfaceMixin {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = EventChannel('appwin_core/availability');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  late AppwinCoreMethodChannel platform;
  late List<Object?> listens;
  late int cancels;
  MockStreamHandlerEventSink? sink;

  setUp(() {
    platform = AppwinCoreMethodChannel();
    listens = [];
    cancels = 0;
    sink = null;
    messenger.setMockStreamHandler(
      channel,
      MockStreamHandler.inline(
        onListen: (arguments, events) {
          listens.add(arguments);
          sink = events;
        },
        onCancel: (_) => cancels++,
      ),
    );
  });

  tearDown(() => messenger.setMockStreamHandler(channel, null));

  Map<String, Object?> verdict(String product, String status, [String? reason]) =>
      {'product': product, 'status': status, 'reason': ?reason};

  group('AppwinInitResult', () {
    test('fromMap reads status and reason', () {
      expect(
        AppwinInitResult.fromMap({'status': 'unavailable', 'reason': 'plan'}),
        const AppwinInitResult(
          AppwinInitStatus.unavailable,
          reason: AppwinUnavailableReason.plan,
        ),
      );
      expect(
        AppwinInitResult.fromMap({'status': 'ready'}).isReady,
        isTrue,
      );
    });

    test('fromMap degrades an unknown status instead of throwing', () {
      expect(
        AppwinInitResult.fromMap({'status': 'later'}).status,
        AppwinInitStatus.unknown,
      );
      expect(AppwinInitResult.fromMap(null).status, AppwinInitStatus.unknown);
    });
  });

  test('AppwinProduct.fromKey ignores products it does not know', () {
    expect(AppwinProduct.fromKey('community'), AppwinProduct.community);
    expect(AppwinProduct.fromKey('later'), isNull);
  });

  test('forwards only the watched product, without repeats', () async {
    final received = <AppwinInitResult>[];
    final sub = platform
        .availabilityUpdates(AppwinProduct.community)
        .listen(received.add);
    await pumpEventQueue();

    expect(listens.single, {
      'products': ['community'],
    });
    sink!.success(verdict('community', 'ready'));
    sink!.success(verdict('support', 'unavailable', 'plan'));
    sink!.success(verdict('community', 'ready'));
    sink!.success(verdict('community', 'unavailable', 'disabled'));
    await pumpEventQueue();

    expect(received, const [
      AppwinInitResult(AppwinInitStatus.ready),
      AppwinInitResult(
        AppwinInitStatus.unavailable,
        reason: AppwinUnavailableReason.disabled,
      ),
    ]);
    await sub.cancel();
  });

  test('a second watcher of the same product gets the known verdict', () async {
    final first = platform.availabilityUpdates(AppwinProduct.community).listen(
      (_) {},
    );
    await pumpEventQueue();
    sink!.success(verdict('community', 'ready'));
    await pumpEventQueue();

    final second = <AppwinInitResult>[];
    final sub = platform
        .availabilityUpdates(AppwinProduct.community)
        .listen(second.add);
    await pumpEventQueue();

    expect(second, const [AppwinInitResult(AppwinInitStatus.ready)]);
    expect(listens, hasLength(1));
    await first.cancel();
    await sub.cancel();
  });

  test('a new product restarts the native subscription with both', () async {
    final a = platform.availabilityUpdates(AppwinProduct.community).listen(
      (_) {},
    );
    await pumpEventQueue();
    final b = platform.availabilityUpdates(AppwinProduct.support).listen(
      (_) {},
    );
    await pumpEventQueue();

    expect(cancels, 1);
    expect(
      (listens.last! as Map)['products'],
      unorderedEquals(['community', 'support']),
    );

    await a.cancel();
    await b.cancel();
    await pumpEventQueue();
    expect(listens, hasLength(3));
    expect(cancels, 3);
  });

  test('the facade stays silent when the bridge throws', () async {
    AppwinCorePlatform.instance = _ThrowingPlatform();
    addTearDown(() => AppwinCorePlatform.instance = AppwinCoreMethodChannel());

    final done = Completer<void>();
    AppwinCore.instance
        .availabilityUpdates(AppwinProduct.community)
        .listen((_) {}, onError: (_) => fail('no error expected'), onDone: done.complete);
    await done.future;
  });
}
