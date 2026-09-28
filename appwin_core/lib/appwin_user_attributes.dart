/// What your app knows about its user, sent to Appwin by
/// `AppwinCore.instance.identify` and `AppwinCore.instance.updateUser`.
///
/// Every field is optional, and a `null` field is left untouched on the
/// server: sending only [plan] does not erase a previously sent [email]. There
/// is no way to clear a field from the SDK.
///
/// Shared by every product: Support shows it next to the conversation,
/// Notifications segments on [plan] and [language].
///
/// ```dart
/// await AppwinCore.instance.identify(
///   user.id,
///   attributes: AppwinUserAttributes(email: user.email, name: user.displayName),
/// );
/// ```
class AppwinUserAttributes {
  /// Creates a set of attributes. Pass only what you know.
  const AppwinUserAttributes({
    this.email,
    this.name,
    this.avatarUrl,
    this.language,
    this.timezone,
    this.location,
    this.plan,
  });

  /// Contact email, shown to your support team.
  final String? email;

  /// Display name, shown to your support team instead of an anonymous label.
  final String? name;

  /// URL of the user's photo.
  final String? avatarUrl;

  /// Preferred language, as a BCP 47 tag (`fr`, `en-US`).
  final String? language;

  /// IANA time zone (`Europe/Paris`).
  final String? timezone;

  /// Free-form location (`Lyon, France`). Stored on the device, not the user:
  /// the same person may sign in from several places.
  final String? location;

  /// Your plan or tier for this user (`free`, `premium`), for segmentation.
  final String? plan;

  /// Method-channel payload. `null` fields are omitted so the native side can
  /// tell "not sent" from "sent", which is what keeps them untouched.
  Map<String, String> toMap() => {
    'email': ?email,
    'name': ?name,
    'avatarUrl': ?avatarUrl,
    'language': ?language,
    'timezone': ?timezone,
    'location': ?location,
    'plan': ?plan,
  };

  @override
  bool operator ==(Object other) =>
      other is AppwinUserAttributes &&
      other.email == email &&
      other.name == name &&
      other.avatarUrl == avatarUrl &&
      other.language == language &&
      other.timezone == timezone &&
      other.location == location &&
      other.plan == plan;

  @override
  int get hashCode =>
      Object.hash(email, name, avatarUrl, language, timezone, location, plan);

  @override
  String toString() => 'AppwinUserAttributes(${toMap()})';
}
