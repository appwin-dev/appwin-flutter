/// What the current member does in Community, and the posts the SDK opens.
library;

/// A post to open, from a notification tap or `AppwinCommunity.openPost`.
///
/// Mirrors `AppwinCommunityPostTarget` in the iOS and Android SDKs.
class AppwinCommunityPostTarget {
  /// Builds a target. The SDK hands them to your `onNotificationTap`; build
  /// one yourself only in a test.
  const AppwinCommunityPostTarget({required this.postId, this.commentId});

  /// The post to open.
  final String postId;

  /// The root comment whose reply thread opens over the post, `null` to open
  /// the post alone.
  final String? commentId;

  /// Parses what the native side sends over the method channel. `null` when
  /// the map carries no post id.
  static AppwinCommunityPostTarget? fromMap(Map<Object?, Object?>? map) {
    final postId = map?['postId'];
    if (postId is! String) return null;
    final commentId = map?['commentId'];
    return AppwinCommunityPostTarget(
      postId: postId,
      commentId: commentId is String ? commentId : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is AppwinCommunityPostTarget &&
      other.postId == postId &&
      other.commentId == commentId;

  @override
  int get hashCode => Object.hash(postId, commentId);

  @override
  String toString() =>
      'AppwinCommunityPostTarget($postId${commentId == null ? '' : ', $commentId'})';
}

/// Something the current member did in Community, reported through
/// `AppwinCommunity.events`.
///
/// Only the member's own actions, and only once the server has accepted
/// them: an optimistic update that fails is never reported, and other
/// members' activity never goes through here. Mirrors `AppwinCommunityEvent`
/// in the iOS and Android SDKs.
///
/// ```dart
/// AppwinCommunity.instance.events.listen((event) {
///   switch (event) {
///     case AppwinCommunityPostCreated():
///       rewards.grant(Reward.firstPost);
///     default:
///       break;
///   }
/// });
/// ```
sealed class AppwinCommunityEvent {
  const AppwinCommunityEvent();

  /// Parses what the native side sends over the event channel.
  ///
  /// `null` for an event type this package does not know, rather than a
  /// throw: a native SDK newer than this package may report more kinds of
  /// events, and those must not break the host app.
  static AppwinCommunityEvent? fromMap(Map<Object?, Object?>? map) {
    String? field(String key) {
      final value = map?[key];
      return value is String ? value : null;
    }

    final postId = field('postId');
    final commentId = field('commentId');
    switch (map?['type']) {
      case 'postCreated' when postId != null:
        return AppwinCommunityPostCreated(postId: postId);
      case 'commentCreated' when postId != null && commentId != null:
        return AppwinCommunityCommentCreated(
          commentId: commentId,
          postId: postId,
        );
      case 'replyCreated' when postId != null && commentId != null:
        final replyId = field('replyId');
        if (replyId == null) return null;
        return AppwinCommunityReplyCreated(
          replyId: replyId,
          commentId: commentId,
          postId: postId,
        );
      case 'reactionModified' when postId != null:
        return AppwinCommunityReactionModified(
          postId: postId,
          commentId: commentId,
          reaction: field('reaction'),
        );
      case 'profileUpdated':
        final profileId = field('profileId');
        if (profileId == null) return null;
        return AppwinCommunityProfileUpdated(profileId: profileId);
      default:
        return null;
    }
  }
}

/// The member published a post.
final class AppwinCommunityPostCreated extends AppwinCommunityEvent {
  /// Builds the event. The SDK emits them; build one yourself only in a test.
  const AppwinCommunityPostCreated({required this.postId});

  /// The new post.
  final String postId;

  @override
  bool operator ==(Object other) =>
      other is AppwinCommunityPostCreated && other.postId == postId;

  @override
  int get hashCode => postId.hashCode;

  @override
  String toString() => 'AppwinCommunityPostCreated($postId)';
}

/// The member commented on a post.
final class AppwinCommunityCommentCreated extends AppwinCommunityEvent {
  /// Builds the event. The SDK emits them; build one yourself only in a test.
  const AppwinCommunityCommentCreated({
    required this.commentId,
    required this.postId,
  });

  /// The new comment.
  final String commentId;

  /// The post it was written on.
  final String postId;

  @override
  bool operator ==(Object other) =>
      other is AppwinCommunityCommentCreated &&
      other.commentId == commentId &&
      other.postId == postId;

  @override
  int get hashCode => Object.hash(commentId, postId);

  @override
  String toString() => 'AppwinCommunityCommentCreated($commentId, $postId)';
}

/// The member replied to a comment.
final class AppwinCommunityReplyCreated extends AppwinCommunityEvent {
  /// Builds the event. The SDK emits them; build one yourself only in a test.
  const AppwinCommunityReplyCreated({
    required this.replyId,
    required this.commentId,
    required this.postId,
  });

  /// The new reply.
  final String replyId;

  /// The comment replied to.
  final String commentId;

  /// The post the thread belongs to.
  final String postId;

  @override
  bool operator ==(Object other) =>
      other is AppwinCommunityReplyCreated &&
      other.replyId == replyId &&
      other.commentId == commentId &&
      other.postId == postId;

  @override
  int get hashCode => Object.hash(replyId, commentId, postId);

  @override
  String toString() =>
      'AppwinCommunityReplyCreated($replyId, $commentId, $postId)';
}

/// The member added, changed or removed their reaction.
final class AppwinCommunityReactionModified extends AppwinCommunityEvent {
  /// Builds the event. The SDK emits them; build one yourself only in a test.
  const AppwinCommunityReactionModified({
    required this.postId,
    this.commentId,
    this.reaction,
  });

  /// The post reacted to, or the post of the comment reacted to.
  final String postId;

  /// Set when the reaction is on a comment of [postId], `null` when it is on
  /// the post itself.
  final String? commentId;

  /// The reaction key as the API names it (`like`, `love`...), `null` when
  /// the reaction was removed.
  final String? reaction;

  @override
  bool operator ==(Object other) =>
      other is AppwinCommunityReactionModified &&
      other.postId == postId &&
      other.commentId == commentId &&
      other.reaction == reaction;

  @override
  int get hashCode => Object.hash(postId, commentId, reaction);

  @override
  String toString() =>
      'AppwinCommunityReactionModified($postId, $commentId, $reaction)';
}

/// The member's profile changed, from the SDK's editor or through
/// `AppwinCommunity.setUser`.
final class AppwinCommunityProfileUpdated extends AppwinCommunityEvent {
  /// Builds the event. The SDK emits them; build one yourself only in a test.
  const AppwinCommunityProfileUpdated({required this.profileId});

  /// The member's community profile id.
  final String profileId;

  @override
  bool operator ==(Object other) =>
      other is AppwinCommunityProfileUpdated && other.profileId == profileId;

  @override
  int get hashCode => profileId.hashCode;

  @override
  String toString() => 'AppwinCommunityProfileUpdated($profileId)';
}
