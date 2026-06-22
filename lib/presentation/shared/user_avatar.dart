import 'dart:io';

import 'package:flutter/material.dart';

import '../../domain/entities/auth_user.dart';

/// Circular avatar for the signed-in user. Prefers a locally-picked photo,
/// falls back to the Google photo URL, then to the name initial.
class UserAvatar extends StatelessWidget {
  const UserAvatar({super.key, required this.user, this.radius = 20});

  final AuthUser user;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final localPhoto = user.photoPath;
    final googlePhoto = user.googlePhotoUrl;

    ImageProvider? image;
    if (localPhoto != null && localPhoto.isNotEmpty && File(localPhoto).existsSync()) {
      image = FileImage(File(localPhoto));
    } else if (googlePhoto != null && googlePhoto.isNotEmpty) {
      image = NetworkImage(googlePhoto);
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: scheme.primaryContainer,
      foregroundImage: image,
      child: image == null
          ? Text(
              user.initial,
              style: TextStyle(
                color: scheme.onPrimaryContainer,
                fontWeight: FontWeight.w600,
                fontSize: radius * 0.8,
              ),
            )
          : null,
    );
  }
}
