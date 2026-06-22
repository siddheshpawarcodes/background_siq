import 'package:file_picker/file_picker.dart';

import '../../core/constants/app_constants.dart';

/// Thin wrapper over the system file picker (SRS §11). Restricts selection to
/// the supported audio extensions. Returns null when the user cancels.
class FilePickService {
  const FilePickService();

  Future<String?> pickAudioPath() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: AppConstants.supportedInputExtensions.toList(),
    );
    final path = result?.files.singleOrNull?.path;
    return path;
  }

  /// Multi-select for batch mode (SRS §15). Returns the chosen file paths.
  Future<List<String>> pickAudioPaths() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: AppConstants.supportedInputExtensions.toList(),
      allowMultiple: true,
    );
    if (result == null) return const [];
    return result.files.map((f) => f.path).whereType<String>().toList();
  }

  /// Picks an image to embed as cover art (thumbnail). Restricted to the
  /// raster formats that embed cleanly in audio containers. Returns null when
  /// the user cancels.
  Future<String?> pickImagePath() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png'],
    );
    return result?.files.singleOrNull?.path;
  }

  /// Prompts for a directory (used for the default export folder). Returns
  /// null when the user cancels or the platform has no directory picker.
  Future<String?> pickDirectory() => FilePicker.platform.getDirectoryPath();
}
