import 'package:appwin_community/appwin_community.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppwinCommunityEvent.fromMap', () {
    test('parses every event type', () {
      expect(
        AppwinCommunityEvent.fromMap({'type': 'postCreated', 'postId': 'p1'}),
        const AppwinCommunityPostCreated(postId: 'p1'),
      );
      expect(
        AppwinCommunityEvent.fromMap({
          'type': 'commentCreated',
          'commentId': 'c1',
          'postId': 'p1',
        }),
        const AppwinCommunityCommentCreated(commentId: 'c1', postId: 'p1'),
      );
      expect(
        AppwinCommunityEvent.fromMap({
          'type': 'replyCreated',
          'replyId': 'r1',
          'commentId': 'c1',
          'postId': 'p1',
        }),
        const AppwinCommunityReplyCreated(
          replyId: 'r1',
          commentId: 'c1',
          postId: 'p1',
        ),
      );
      expect(
        AppwinCommunityEvent.fromMap({
          'type': 'reactionModified',
          'postId': 'p1',
          'commentId': 'c1',
          'reaction': 'love',
        }),
        const AppwinCommunityReactionModified(
          postId: 'p1',
          commentId: 'c1',
          reaction: 'love',
        ),
      );
      expect(
        AppwinCommunityEvent.fromMap({'type': 'profileUpdated', 'profileId': 'm1'}),
        const AppwinCommunityProfileUpdated(profileId: 'm1'),
      );
    });

    test('a removed reaction on a post has neither comment nor reaction', () {
      expect(
        AppwinCommunityEvent.fromMap({
          'type': 'reactionModified',
          'postId': 'p1',
          'commentId': null,
          'reaction': null,
        }),
        const AppwinCommunityReactionModified(postId: 'p1'),
      );
    });

    test('ignores unknown types and incomplete payloads instead of throwing', () {
      expect(AppwinCommunityEvent.fromMap({'type': 'pollVoted', 'postId': 'p1'}), isNull);
      expect(AppwinCommunityEvent.fromMap({'type': 'commentCreated', 'postId': 'p1'}), isNull);
      expect(
        AppwinCommunityEvent.fromMap({
          'type': 'replyCreated',
          'commentId': 'c1',
          'postId': 'p1',
        }),
        isNull,
      );
      expect(AppwinCommunityEvent.fromMap({'type': 'profileUpdated'}), isNull);
      expect(AppwinCommunityEvent.fromMap(null), isNull);
    });
  });

  group('AppwinCommunityPostTarget.fromMap', () {
    test('reads the post and the optional comment', () {
      expect(
        AppwinCommunityPostTarget.fromMap({'postId': 'p1', 'commentId': 'c1'}),
        const AppwinCommunityPostTarget(postId: 'p1', commentId: 'c1'),
      );
      expect(
        AppwinCommunityPostTarget.fromMap({'postId': 'p1', 'commentId': null}),
        const AppwinCommunityPostTarget(postId: 'p1'),
      );
    });

    test('is null without a post id', () {
      expect(AppwinCommunityPostTarget.fromMap({'commentId': 'c1'}), isNull);
      expect(AppwinCommunityPostTarget.fromMap(null), isNull);
    });
  });
}
