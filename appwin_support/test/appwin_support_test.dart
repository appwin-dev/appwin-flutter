import 'package:flutter_test/flutter_test.dart';
import 'package:appwin_support/appwin_support.dart';
import 'package:appwin_support/appwin_support_platform_interface.dart';
import 'package:appwin_support/appwin_support_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockAppwinSupportPlatform
    with MockPlatformInterfaceMixin
    implements AppwinSupportPlatform {
  bool messengerPresented = false;
  String? presentedConversationId;

  @override
  Future<String?> getPlatformVersion() => Future.value('42');

  @override
  Future<AppwinInitResult> initialize() async =>
      const AppwinInitResult(AppwinInitStatus.ready);

  @override
  Future<void> presentMessenger() async {
    messengerPresented = true;
  }

  @override
  Future<void> presentConversation(String conversationId) async {
    presentedConversationId = conversationId;
  }
}

void main() {
  final AppwinSupportPlatform initialPlatform = AppwinSupportPlatform.instance;

  test('$AppwinSupportMethodChannel is the default instance', () {
    expect(initialPlatform, isInstanceOf<AppwinSupportMethodChannel>());
  });

  test('getPlatformVersion', () async {
    MockAppwinSupportPlatform fakePlatform = MockAppwinSupportPlatform();
    AppwinSupportPlatform.instance = fakePlatform;

    expect(await AppwinSupport.instance.getPlatformVersion(), '42');
  });

  test('presentMessenger délègue à la plateforme', () async {
    MockAppwinSupportPlatform fakePlatform = MockAppwinSupportPlatform();
    AppwinSupportPlatform.instance = fakePlatform;

    await AppwinSupport.instance.presentMessenger();

    expect(fakePlatform.messengerPresented, isTrue);
  });

  test('presentConversation opens the conversation it was given', () async {
    MockAppwinSupportPlatform fakePlatform = MockAppwinSupportPlatform();
    AppwinSupportPlatform.instance = fakePlatform;

    await AppwinSupport.instance.presentConversation('conv-1');

    expect(fakePlatform.presentedConversationId, 'conv-1');
  });
}
