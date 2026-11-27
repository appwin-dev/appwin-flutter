/// A post created from the host app's own screen.
library;

/// Where moderation put a post created by `AppwinCommunity.createPost`.
enum AppwinCommunityPostStatus {
  /// Online: the community sees it.
  published,

  /// Held for review (or the member is shadow banned): only its author sees
  /// it, until a moderator publishes it.
  pendingReview,

  /// Refused by moderation as it was written. Its author is told why in the
  /// feed's notifications.
  removed,
}

/// A post created by `AppwinCommunity.createPost`.
class AppwinCommunityCreatedPost {
  /// Builds a created post. The SDK decodes them for you; this is here for tests.
  const AppwinCommunityCreatedPost({required this.id, required this.status});

  /// Decodes the map the native SDKs send over the channel.
  factory AppwinCommunityCreatedPost.fromMap(Map<dynamic, dynamic> map) {
    final status = AppwinCommunityPostStatus.values.firstWhere(
      (s) => s.name == map['status'],
      orElse: () => AppwinCommunityPostStatus.published,
    );
    return AppwinCommunityCreatedPost(id: map['id'] as String, status: status);
  }

  /// The post's id, for `AppwinCommunity.openPost`.
  final String id;

  /// Where moderation put the post.
  final AppwinCommunityPostStatus status;

  @override
  bool operator ==(Object other) =>
      other is AppwinCommunityCreatedPost &&
      other.id == id &&
      other.status == status;

  @override
  int get hashCode => Object.hash(id, status);

  @override
  String toString() => 'AppwinCommunityCreatedPost($id, ${status.name})';
}
