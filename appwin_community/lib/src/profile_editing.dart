import 'package:flutter/foundation.dart';

/// The profile editing handlers of one `AppwinCommunityView`, or of
/// `presentCommunity`. Native only learns which ones exist ([toFlags]) and
/// asks for one by field name.
@immutable
class ProfileEditingHandlers {
  const ProfileEditingHandlers({
    this.onEditProfile,
    this.onEditProfilePhoto,
    this.onEditProfileName,
  });

  final VoidCallback? onEditProfile;
  final VoidCallback? onEditProfilePhoto;
  final VoidCallback? onEditProfileName;

  /// The `profileEditing` creation parameter of the native view.
  Map<String, bool> toFlags() => <String, bool>{
    'profile': onEditProfile != null,
    'photo': onEditProfilePhoto != null,
    'name': onEditProfileName != null,
  };

  /// The handler native asked for, `null` when there is none (any more).
  VoidCallback? forField(Object? field) => switch (field) {
    'profile' => onEditProfile,
    'photo' => onEditProfilePhoto,
    'name' => onEditProfileName,
    _ => null,
  };
}
