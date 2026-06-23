import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/errors/failures.dart';
import '../../core/result/result.dart';
import '../../domain/entities/background_profile.dart';

/// Exports/imports a profile as a `.echobugprofile` JSON file (design §6).
class ProfileTransferService {
  const ProfileTransferService();

  /// Writes the profile to a temp `.echobugprofile` and opens the OS share sheet.
  Future<Result<void>> export(BackgroundProfile profile) async {
    try {
      final dir = await getTemporaryDirectory();
      final safe = profile.name.isEmpty
          ? 'backdrop'
          : profile.name.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
      final file = File(p.join(dir.path, '$safe.echobugprofile'));
      await file.writeAsString(jsonEncode(profile.toJson()));
      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path)], subject: profile.name),
      );
      return const Result.ok(null);
    } catch (e) {
      return Result.err(ExportFailure(debugDetail: e.toString()));
    }
  }

  /// Lets the user pick a `.echobugprofile`/JSON and parses it. Returns null when
  /// the user cancels.
  Future<Result<BackgroundProfile?>> pickAndParse() async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.any);
      final path = result?.files.singleOrNull?.path;
      if (path == null) return const Result.ok(null);
      final json = jsonDecode(await File(path).readAsString()) as Map<String, dynamic>;
      return Result.ok(BackgroundProfile.fromJson(json));
    } catch (e) {
      return Result.err(
        ValidationFailure('That file is not a valid EchoBug backdrop.'),
      );
    }
  }
}
