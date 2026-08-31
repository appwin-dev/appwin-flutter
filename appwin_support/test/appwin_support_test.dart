import 'package:flutter_test/flutter_test.dart';
import 'package:appwin_support/appwin_support.dart';
import 'package:appwin_support/appwin_support_platform_interface.dart';
import 'package:appwin_support/appwin_support_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockAppwinSupportPlatform
    with MockPlatformInterfaceMixin
    implements AppwinSupportPlatform {
  bool messengerPresented = false;

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
  Future<void> loginUnidentifiedUser() async {}

  @override
  Future<void> loginIdentifiedUser({required String externalId}) async {}

  @override
  Future<void> updateUser({
    String? email,
    String? name,
    String? avatarUrl,
    String? language,
    String? timezone,
    String? location,
  }) async {}

  @override
  Future<void> registerPushToken({
    required String token,
    String? platform,
    bool pushOptIn = true,
  }) async {}


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
}
