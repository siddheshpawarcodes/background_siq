import '../../domain/entities/auth_user.dart';
import '../models/user_model.dart';

/// Maps [UserModel] (Hive) ⇄ [AuthUser] (domain).
extension UserModelMapper on UserModel {
  AuthUser toEntity() => AuthUser(
        id: id,
        email: email,
        googleDisplayName: googleDisplayName,
        googlePhotoUrl: googlePhotoUrl,
        displayNameOverride: displayNameOverride,
        photoPath: photoPath,
        phone: phone,
        company: company,
        role: role,
        signedInAt: signedInAt,
      );
}

extension AuthUserMapper on AuthUser {
  UserModel toModel() => UserModel(
        id: id,
        email: email,
        googleDisplayName: googleDisplayName,
        googlePhotoUrl: googlePhotoUrl,
        displayNameOverride: displayNameOverride,
        photoPath: photoPath,
        phone: phone,
        company: company,
        role: role,
        signedInAt: signedInAt,
      );
}
