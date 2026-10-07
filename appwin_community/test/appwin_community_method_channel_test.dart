import 'package:appwin_community/appwin_community.dart';
import 'package:appwin_community/appwin_community_method_channel.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const channel = MethodChannel('appwin_community');
  const eventsChannel = EventChannel('appwin_community/events');
  const unreadChannel = EventChannel('appwin_community/unread_count');

  late AppwinCommunityMethodChannel platform;
  final calls = <MethodCall>[];

  setUp(() {
    platform = AppwinCommunityMethodChannel();
    calls.clear();
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return switch (call.method) {
        'initialize' => {'status': 'unavailable', 'reason': 'plan'},
        _ => null,
      };
    });
  });

  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
    messenger.setMockStreamHandler(eventsChannel, null);
    messenger.setMockStreamHandler(unreadChannel, null);
  });

  /// Plays the native side calling Dart, and returns what Dart answered.
  Future<Object?> nativeCalls(String method, [Object? arguments]) async {
    final reply = await messenger.handlePlatformMessage(
      channel.name,
      const StandardMethodCodec().encodeMethodCall(MethodCall(method, arguments)),
      null,
    );
    return const StandardMethodCodec().decodeEnvelope(reply!);
  }

  test('initialize parses the verdict', () async {
    expect(
      await platform.initialize(),
      const AppwinInitResult(
        AppwinInitStatus.unavailable,
        reason: AppwinUnavailableReason.plan,
      ),
    );
  });

  test('openPost sends the comment only when there is one', () async {
    await platform.openPost('p1');
    await platform.openPost('p1', commentId: 'c1');

    expect(calls[0].method, 'openPost');
    expect(calls[0].arguments, {'postId': 'p1'});
    expect(calls[1].arguments, {'postId': 'p1', 'commentId': 'c1'});
  });

  test('openPost refuses a blank post id without touching native', () {
    expect(() => platform.openPost(' '), throwsArgumentError);
    expect(calls, isEmpty);
  });

  test('setHostCallbacks tells native which handlers exist', () async {
    await platform.setHostCallbacks(onNotificationTap: (_) {});
    await platform.setHostCallbacks();

    expect(calls[0].method, 'setHostCallbacks');
    expect(calls[0].arguments, {'notificationTap': true, 'editProfile': false});
    expect(calls[1].arguments, {'notificationTap': false, 'editProfile': false});
  });

  test('a native tap reaches the Dart handler, which claims it', () async {
    final taps = <AppwinCommunityPostTarget>[];
    var edits = 0;
    await platform.setHostCallbacks(
      onNotificationTap: taps.add,
      onEditProfile: () => edits++,
    );

    expect(
      await nativeCalls('onNotificationTap', {'postId': 'p1', 'commentId': 'c1'}),
      isTrue,
    );
    expect(await nativeCalls('onEditProfile'), isTrue);
    expect(taps, const [AppwinCommunityPostTarget(postId: 'p1', commentId: 'c1')]);
    expect(edits, 1);
  });

  test('without a Dart handler the tap goes back to native', () async {
    await platform.setHostCallbacks(onEditProfile: () {});

    expect(await nativeCalls('onNotificationTap', {'postId': 'p1'}), isFalse);
  });

  test('events are parsed, and unknown ones dropped', () async {
    messenger.setMockStreamHandler(
      eventsChannel,
      MockStreamHandler.inline(
        onListen: (_, sink) {
          sink.success({'type': 'pollVoted', 'postId': 'p1'});
          sink.success({'type': 'postCreated', 'postId': 'p1'});
          sink.endOfStream();
        },
      ),
    );

    expect(
      await platform.events.toList(),
      const [AppwinCommunityPostCreated(postId: 'p1')],
    );
  });

  test('the unread count drops repeats and replays the last value', () async {
    MockStreamHandlerEventSink? sink;
    var listens = 0;
    messenger.setMockStreamHandler(
      unreadChannel,
      MockStreamHandler.inline(
        onListen: (_, events) {
          listens++;
          sink = events;
        },
      ),
    );

    final first = <int>[];
    final a = platform.unreadNotificationCountStream.listen(first.add);
    await pumpEventQueue();
    sink!.success(2);
    sink!.success(2);
    sink!.success(3);
    await pumpEventQueue();

    final second = <int>[];
    final b = platform.unreadNotificationCountStream.listen(second.add);
    await pumpEventQueue();

    expect(first, [2, 3]);
    expect(second, [3]);
    expect(listens, 1);
    await a.cancel();
    await b.cancel();
  });
}
