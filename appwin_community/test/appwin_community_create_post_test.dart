import 'package:appwin_community/appwin_community.dart';
import 'package:appwin_community/appwin_community_method_channel.dart';
import 'package:appwin_community/appwin_community_platform_interface.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class _ThrowingPlatform extends AppwinCommunityPlatform
    with MockPlatformInterfaceMixin {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('appwin_community');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
    AppwinCommunity.instance.resetForTesting();
  });

  test('createPost sends text, images and group, and decodes the post', () async {
    MethodCall? sent;
    messenger.setMockMethodCallHandler(channel, (call) async {
      sent = call;
      return {'id': 'p1', 'status': 'pendingReview'};
    });
    AppwinCommunityPlatform.instance = AppwinCommunityMethodChannel();
    final image = Uint8List.fromList([1, 2, 3]);

    final post = await AppwinCommunity.instance.createPost(
      text: 'Super séance',
      images: [image],
      groupId: 'g1',
    );

    expect(
      post,
      const AppwinCommunityCreatedPost(
        id: 'p1',
        status: AppwinCommunityPostStatus.pendingReview,
      ),
    );
    expect(sent?.method, 'createPost');
    final args = sent!.arguments as Map;
    expect(args['text'], 'Super séance');
    expect(args['groupId'], 'g1');
    expect(args['images'], [image]);
  });

  test('a refused post is null, never an exception', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      throw PlatformException(code: 'create_post_failed', message: 'http(403)');
    });
    AppwinCommunityPlatform.instance = AppwinCommunityMethodChannel();
    expect(await AppwinCommunity.instance.createPost(text: 'x'), isNull);

    AppwinCommunityPlatform.instance = _ThrowingPlatform();
    expect(await AppwinCommunity.instance.createPost(text: 'x'), isNull);
  });

  test('an unknown status reads as published', () {
    expect(
      AppwinCommunityCreatedPost.fromMap({'id': 'p', 'status': 'later'}).status,
      AppwinCommunityPostStatus.published,
    );
  });
}
