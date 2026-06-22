import 'dart:io';

import 'package:permission_handler/permission_handler.dart';

/// Requests the storage access needed to publish Dataset Batch output into the
/// public `Music/` folder.
///
/// On Android 10+ (API 29+) writing into a public media collection via
/// MediaStore needs **no** permission. Only Android 9 and below require the
/// legacy `WRITE_EXTERNAL_STORAGE` grant. On non-Android platforms nothing is
/// needed. This call is best-effort: on modern devices the request is a no-op.
class StoragePermissionService {
  const StoragePermissionService();

  /// Returns `true` when public-storage writes are allowed (or not required). A
  /// `false` result is non-fatal: the dataset flow keeps output in app-private
  /// storage, so the run still completes — just not visible in `Music/`.
  Future<bool> ensurePublicStorageAccess() async {
    if (!Platform.isAndroid) return true;

    // No-op on Android 10+ (MediaStore handles it); meaningful only on ≤9,
    // where this maps to the legacy WRITE_EXTERNAL_STORAGE grant.
    final status = await Permission.storage.request();
    return status.isGranted;
  }
}
