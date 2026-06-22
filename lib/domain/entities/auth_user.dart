import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_user.freezed.dart';

/// The signed-in user (SRS §7.1 — Account).
///
/// Identity fields ([id], [email], [googleDisplayName], [googlePhotoUrl]) come
/// from the Google account and are never edited by the user. The remaining
/// fields are local, user-editable overrides/extras persisted on-device — no
/// backend is involved. Use the [AuthUserX] getters to resolve the values that
/// the UI should actually display.
@freezed
abstract class AuthUser with _$AuthUser {
  const factory AuthUser({
    /// Stable account id (the Google `sub`). Used as the storage key so a
    /// returning user keeps their previously-edited profile.
    required String id,
    required String email,

    /// Name/photo as reported by Google (read-only).
    String? googleDisplayName,
    String? googlePhotoUrl,

    /// User-editable overrides and extra local fields.
    String? displayNameOverride,
    String? photoPath, // local file path to a picked avatar image
    String? phone,
    String? company,
    String? role,
    required DateTime signedInAt,
  }) = _AuthUser;
}

extension AuthUserX on AuthUser {
  /// The name to show: the user's override, else the Google name, else email.
  String get effectiveName {
    final override = displayNameOverride?.trim();
    if (override != null && override.isNotEmpty) return override;
    final google = googleDisplayName?.trim();
    if (google != null && google.isNotEmpty) return google;
    return email;
  }

  /// First letter of the display name, for the avatar fallback.
  String get initial {
    final name = effectiveName.trim();
    return name.isEmpty ? '?' : name.substring(0, 1).toUpperCase();
  }

  /// True when the user has filled in at least one of the optional extras.
  bool get hasContactDetails =>
      (phone?.isNotEmpty ?? false) ||
      (company?.isNotEmpty ?? false) ||
      (role?.isNotEmpty ?? false);
}
