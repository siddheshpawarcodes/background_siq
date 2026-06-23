import 'dart:io';

import 'package:permission_handler/permission_handler.dart';

/// Requests the storage access the Dataset Batch flow needs to **read** the
/// user-picked source folder and **write** output into the public `Music/`
/// folder.
///
/// The folder is chosen via the SAF directory picker, but the scanner reads it
/// with `dart:io` (`Directory.list`) — and `dart:io` cannot use a SAF tree
/// grant. On Android 11+ that means reading an arbitrary path requires
/// **All-files access** (`MANAGE_EXTERNAL_STORAGE`); Android 9 and below use the
/// legacy `WRITE_EXTERNAL_STORAGE` grant. On non-Android platforms nothing is
/// needed.
class StoragePermissionService {
  const StoragePermissionService();

  /// Returns `true` when storage access is granted (or not required). A `false`
  /// result is non-fatal for output (the flow falls back to app-private
  /// storage), but without it the scanner cannot read a folder outside the
  /// app's own sandbox, so the run will find 0 files.
  Future<bool> ensurePublicStorageAccess() async {
    if (!Platform.isAndroid) return true;
    try {
      // All-files access is what lets dart:io read an arbitrary picked folder
      // and write a custom public folder on Android 11+.
      if (await Permission.manageExternalStorage.isGranted) return true;
      if ((await Permission.manageExternalStorage.request()).isGranted) {
        return true;
      }
      // Fallback for Android ≤10, where the legacy grant is sufficient.
      return (await Permission.storage.request()).isGranted;
    } catch (_) {
      return false;
    }
  }
}
