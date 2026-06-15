import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/errors/failures.dart';
import '../../core/result/result.dart';
import '../../domain/entities/audio_file_ref.dart';
import '../../domain/ports/file_system_port.dart';

/// Default [FileSystemPort] implementation (SRS §3.1, §13.3).
///
/// On mobile, scoped storage usually prevents writing back to the picked
/// file's original folder, so the app output folder is the safe default; a
/// user-chosen [preferredDir] is honored only when actually writable.
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

      Directory dir;
      if (preferredDir != null && await _isWritable(preferredDir)) {
        dir = Directory(preferredDir);
      } else {
        final docs = await getApplicationDocumentsDirectory();
        dir = Directory(p.join(docs.path, AppConstants.appShortName));
        await dir.create(recursive: true);
      }

      return Result.ok(_uniquify(p.join(dir.path, fileName)));
    } catch (e) {
      return Result.err(ExportFailure(debugDetail: e.toString()));
    }
  }

  @override
  Future<String> previewPath(String extension) async {
    final tmp = await getTemporaryDirectory();
    return p.join(tmp.path, 'wbm_preview.$extension');
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
      final probe = File(p.join(dirPath, '.wbm_write_test'));
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
