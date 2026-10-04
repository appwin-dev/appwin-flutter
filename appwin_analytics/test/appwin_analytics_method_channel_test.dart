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

  test('initialize carries crashReporting', () async {
    final result = await platform.initialize(crashReporting: false);
    expect(result.isReady, true);
    expect(calls.single.arguments, {'crashReporting': false});
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
