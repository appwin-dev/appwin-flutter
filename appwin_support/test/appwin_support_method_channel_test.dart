import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:appwin_support/appwin_support_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  AppwinSupportMethodChannel platform = AppwinSupportMethodChannel();
  const MethodChannel channel = MethodChannel('appwin_support');
  final calls = <MethodCall>[];

  setUp(() {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          calls.add(methodCall);
          return methodCall.method == 'getPlatformVersion' ? '42' : null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('getPlatformVersion', () async {
    expect(await platform.getPlatformVersion(), '42');
  });

  test('presentConversation sends the conversation id', () async {
    await platform.presentConversation('conv-1');

    expect(calls.single.method, 'presentConversation');
    expect(calls.single.arguments, {'conversationId': 'conv-1'});
  });

  test('presentConversation rejects a blank id without reaching native', () {
    expect(() => platform.presentConversation('  '), throwsArgumentError);
    expect(calls, isEmpty);
  });

  test('initialize carries the pause the native side answers', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          return {
            'status': 'ready',
            'pause': {'since': '2026-11-15T10:00:00.000Z', 'title': 'On fait une pause', 'message': 'Dites-lui.'},
          };
        });

    final result = await platform.initialize();

    expect(result.isReady, isTrue);
    expect(result.pause?.since, '2026-11-15T10:00:00.000Z');
    expect(result.pause?.title, 'On fait une pause');
    expect(result.pause?.message, 'Dites-lui.');
  });
}
