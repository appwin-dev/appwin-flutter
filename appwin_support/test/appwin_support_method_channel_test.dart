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
}
