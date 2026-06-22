import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/constants/app_constants.dart';
import '../../core/errors/failures.dart';
import '../../core/result/result.dart';
import '../../domain/entities/audio_file_ref.dart';
import '../../domain/ports/file_system_port.dart';

/// Default [FileSystemPort] implementation (SRS §3.1, §13.3).
///
/// Processed files are written to a user-visible "Srotas Audio" folder on the
/// device's shared storage (Android), so they show up in a file manager rather
/// than app-private storage. A user-chosen [preferredDir] is honored when
/// writable; if shared storage is unavailable or the storage permission is
/// denied, it falls back to the app documents folder so export never fails.
class FileSystemService implements FileSystemPort {
  const FileSystemService();

  @override
  Future<Result<String>> resolveOutputPath({
    required AudioFileRef source,
    String? preferredDir,
  }) async {
    try {
      final base = p.basenameWithoutExtension(source.name);
      final ext = source.ext.isNotEmpty ? source.ext : 'mp3';
      final fileName = '$base${AppConstants.outputSuffix}.$ext';

      // Reuse the "Srotas Audio" folder if it already exists, create it
      // (recursively) if not.
      final dir = await _outputDir(preferredDir);
      await dir.create(recursive: true);

      return Result.ok(_uniquify(p.join(dir.path, fileName)));
    } catch (e) {
      return Result.err(ExportFailure(debugDetail: e.toString()));
    }
  }

  /// Resolves the parent "Srotas Audio" folder, preferring a user-chosen
  /// export folder, then device shared storage, then app-private storage.
  Future<Directory> _outputDir(String? preferredDir) async {
    // 1. Honor a writable user-chosen export folder.
    if (preferredDir != null && await _isWritable(preferredDir)) {
      return Directory(p.join(preferredDir, AppConstants.outputFolderName));
    }

    // 2. Android: a visible folder on the device's shared (local) storage.
    if (Platform.isAndroid && await _ensureStoragePermission()) {
      final root = await _sharedStorageRoot();
      if (root != null) {
        return Directory(p.join(root, AppConstants.outputFolderName));
      }
    }

    // 3. Fallback so export never fails (iOS/desktop, or permission denied).
    final docs = await getApplicationDocumentsDirectory();
    return Directory(p.join(docs.path, AppConstants.outputFolderName));
  }

  /// Root of the device's shared storage, e.g. `/storage/emulated/0`, derived
  /// from the app-specific external dir (`.../Android/data/<pkg>/files`).
  Future<String?> _sharedStorageRoot() async {
    try {
      final ext = await getExternalStorageDirectory();
      if (ext == null) return null;
      final idx = ext.path.indexOf('/Android/');
      return idx == -1 ? null : ext.path.substring(0, idx);
    } catch (_) {
      return null;
    }
  }

  /// Requests storage access. Android 11+ needs All-files access to write a
  /// custom top-level folder; older versions use the legacy storage grant.
  Future<bool> _ensureStoragePermission() async {
    try {
      if (await Permission.manageExternalStorage.isGranted) return true;
      if ((await Permission.manageExternalStorage.request()).isGranted) {
        return true;
      }
      return (await Permission.storage.request()).isGranted;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<String> previewPath(String extension) async {
    final tmp = await getTemporaryDirectory();
    return p.join(tmp.path, 'echobug_preview.$extension');
  }

  @override
  Future<bool> exists(String path) async {
    // content:// URIs from the Android file picker are valid but can't be
    // checked via File(); trust that the picker already validated them.
    if (path.startsWith('content://')) return true;
    return File(path).exists();
  }

  Future<bool> _isWritable(String dirPath) async {
    try {
      final dir = Directory(dirPath);
      if (!await dir.exists()) return false;
      final probe = File(p.join(dirPath, '.echobug_write_test'));
      await probe.writeAsString('ok');
      await probe.delete();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Appends `_1`, `_2`, ... before the extension if the file already exists.
  String _uniquify(String path) {
    if (!File(path).existsSync()) return path;
    final dir = p.dirname(path);
    final ext = p.extension(path);
    final base = p.basenameWithoutExtension(path);
    var i = 1;
    String candidate;
    do {
      candidate = p.join(dir, '${base}_$i$ext');
      i++;
    } while (File(candidate).existsSync());
    return candidate;
  }
}
