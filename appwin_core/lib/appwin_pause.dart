/// The pause an organisation put on its subscription.
///
/// Exported by `package:appwin_core/appwin_core.dart`.
library;

/// The organisation behind this app has paused its subscription.
///
/// Support and Community still answer ready (see `AppwinInitResult.isReady`):
/// their screens say so. [title] and [message] are empty when the server sent
/// none, the SDK screens then use their own text.
class AppwinPause {
  /// Builds a pause. The SDK returns one on `AppwinInitResult.pause`; you
  /// rarely construct it yourself, outside a test double.
  const AppwinPause({required this.since, this.title = '', this.message = ''});

  /// When the pause began, as an ISO 8601 string, kept as the server sent it.
  final String since;

  /// The heading the studio wrote, empty when none.
  final String title;

  /// The body the studio wrote, empty when none.
  final String message;

  /// Parses what the native side sends over the channel.
  ///
  /// Returns `null` when [raw] is not a map or has no string `since`, so a
  /// malformed pause reads as no pause rather than crashing the host app.
  static AppwinPause? fromMap(Object? raw) {
    if (raw is! Map) return null;
    final since = raw['since'];
    if (since is! String) return null;
    final title = raw['title'];
    final message = raw['message'];
    return AppwinPause(
      since: since,
      title: title is String ? title : '',
      message: message is String ? message : '',
    );
  }

  @override
  bool operator ==(Object other) =>
      other is AppwinPause &&
      other.since == since &&
      other.title == title &&
      other.message == message;

  @override
  int get hashCode => Object.hash(since, title, message);

  @override
  String toString() => 'AppwinPause($since, "$title", "$message")';
}
