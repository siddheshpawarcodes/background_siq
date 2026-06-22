import 'package:hive_ce/hive.dart';

part 'user_model.g.dart';

/// Hive persistence DTO for the signed-in account (SRS §8.2). Singleton row,
/// stored under [AppConstants.userKey]. Fields mirror [AuthUser]; the Google
/// identity fields are read-only, the rest are user-editable.
@HiveType(typeId: 4)
class UserModel extends HiveObject {
  UserModel({
    required this.id,
    required this.email,
    this.googleDisplayName,
    this.googlePhotoUrl,
    this.displayNameOverride,
    this.photoPath,
    this.phone,
    this.company,
    this.role,
    required this.signedInAt,
  });

  @HiveField(0)
  String id;
  @HiveField(1)
  String email;
  @HiveField(2)
  String? googleDisplayName;
  @HiveField(3)
  String? googlePhotoUrl;
  @HiveField(4)
  String? displayNameOverride;
  @HiveField(5)
  String? photoPath;
  @HiveField(6)
  String? phone;
  @HiveField(7)
  String? company;
  @HiveField(8)
  String? role;
  @HiveField(9)
  DateTime signedInAt;
}
