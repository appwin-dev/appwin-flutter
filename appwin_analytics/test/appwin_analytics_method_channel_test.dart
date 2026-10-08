import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:appwin_analytics/appwin_analytics_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  AppwinAnalyticsMethodChannel platform = AppwinAnalyticsMethodChannel();
  const MethodChannel channel = MethodChannel('appwin_analytics');

  final calls = <MethodCall>[];

  setUp(() {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          calls.add(methodCall);
          if (methodCall.method == 'initialize') return {'status': 'ready'};
          return '42';
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('getPlatformVersion', () async {
    expect(await platform.getPlatformVersion(), '42');
  });

  test('initialize carries crashReporting and sessionReplay', () async {
    final result = await platform.initialize(crashReporting: false, sessionReplay: false);
    expect(result.isReady, true);
    expect(calls.single.arguments, {'crashReporting': false, 'sessionReplay': false});
  });

  test('replay mask rules: null when nothing records, masking by default', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async => null);
    expect(await platform.replayMaskRules(), isNull);

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async => {'maskAllText': false});
    final rules = await platform.replayMaskRules();
    expect(rules?.maskAllText, false);
    expect(rules?.maskAllImages, true);
  });

  test('frames are rendered on the Dart side only when the native side asks', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async => {'maskAllText': true});
    expect((await platform.replayMaskRules())?.captureFrames, false);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async => {'captureFrames': true});
    expect((await platform.replayMaskRules())?.captureFrames, true);
  });

  test('setReplayFrame payload', () async {
    final rgba = Uint8List.fromList([1, 2, 3, 4]);
    await platform.setReplayFrame(rgba, width: 1, height: 1, rects: [0, 1, 2, 3]);
    expect(calls.single.method, 'setReplayFrame');
    expect(calls.single.arguments, {
      'rgba': rgba,
      'width': 1,
      'height': 1,
      'rects': [0.0, 1.0, 2.0, 3.0],
    });
  });

  test('setReplayMasks payload', () async {
    await platform.setReplayMasks([0, 1, 2, 3]);
    expect(calls.single.method, 'setReplayMasks');
    expect(calls.single.arguments, {'rects': [0.0, 1.0, 2.0, 3.0]});
  });

  test('recordBridgedError payload', () async {
    await platform.recordBridgedError(
      fatal: false,
      type: 'StateError',
      message: 'Bad state: boom',
      frames: [
        {
          'fn': 'Cart.add',
          'file': 'package:my_shop/cart.dart',
          'line': 3,
          'inApp': true,
        },
      ],
    );
    expect(calls.single.method, 'recordBridgedError');
    expect(calls.single.arguments, {
      'fatal': false,
      'type': 'StateError',
      'message': 'Bad state: boom',
      'frames': [
        {
          'fn': 'Cart.add',
          'file': 'package:my_shop/cart.dart',
          'line': 3,
          'inApp': true,
        },
      ],
    });
  });

  test('recordBridgedError omits a null message', () async {
    await platform.recordBridgedError(fatal: true, type: 'X', frames: const []);
    expect(calls.single.arguments, {'fatal': true, 'type': 'X', 'frames': []});
  });
}
