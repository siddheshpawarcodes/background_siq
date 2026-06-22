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

  /// Picks a JPEG/PNG image to embed as a profile's cover art (thumbnail).
  /// Returns null when the user cancels.
  Future<String?> pickImagePath() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: AppConstants.supportedCoverImageExtensions.toList(),
    );
    return result?.files.singleOrNull?.path;
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

  /// Prompts for a directory (used for the default export folder). Returns
  /// null when the user cancels or the platform has no directory picker.
  Future<String?> pickDirectory() => FilePicker.platform.getDirectoryPath();
}
