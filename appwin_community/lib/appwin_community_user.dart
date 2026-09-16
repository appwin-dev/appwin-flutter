/// The member profile the Community SDK exposes to the host app.
library;

/// Community profile as the native SDK returns it.
///
/// Dart mirror of Swift's `CommunityUser`. It carries only what the host app
/// might want to display itself (a badge, a counter in a menu); the rest lives
/// in the native UI.
class AppwinCommunityUser {
  /// Builds a profile. The SDK decodes them for you; this is here for tests.
  const AppwinCommunityUser({
    required this.id,
    required this.nickname,
    required this.isAnonymous,
    required this.postCount,
    required this.commentCount,
    this.avatarUrl,
    this.bio,
  });

  /// Community member id, stable across sessions. Not your `externalId`.
  final String id;

  /// Display name, either set through `setUser` or picked by the member.
  final String nickname;

  /// `true` while neither the host app nor the member has supplied an identity.
  final bool isAnonymous;

  /// Posts written, for a counter in your own UI.
  final int postCount;

  /// Comments written.
  final int commentCount;

  /// Profile picture, absent until one is set.
  final String? avatarUrl;

  /// Short self-description, absent until the member writes one.
  final String? bio;

  /// Rebuilt from a method channel map.
  ///
  /// Tolerant: a missing field or an unexpected type falls back to a neutral
  /// value rather than failing the call. A native binary newer than the Dart
  /// must not break the host app.
  static AppwinCommunityUser fromMap(Map<dynamic, dynamic> map) {
    return AppwinCommunityUser(
      id: map['id'] as String? ?? '',
      nickname: map['nickname'] as String? ?? '',
      isAnonymous: map['isAnonymous'] as bool? ?? true,
      postCount: map['postCount'] as int? ?? 0,
      commentCount: map['commentCount'] as int? ?? 0,
      avatarUrl: map['avatarUrl'] as String?,
      bio: map['bio'] as String?,
    );
  }

  @override
  String toString() =>
      'AppwinCommunityUser(id: $id, nickname: $nickname, anonymous: $isAnonymous)';
}
