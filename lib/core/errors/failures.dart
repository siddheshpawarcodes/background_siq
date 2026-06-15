/// Sealed failure hierarchy for WBM (SRS §13).
///
/// Layers return [Failure] via [Result] instead of throwing across boundaries.
/// Each failure carries a user-facing [message]; technical detail stays in
/// [debugDetail] and is only surfaced in logs, never to end users.
sealed class Failure {
  const Failure({required this.message, this.debugDetail});

  /// Plain-language, user-facing message.
  final String message;

  /// Technical detail for logs (e.g. ffmpeg stderr). Never shown to users.
  final String? debugDetail;

  @override
  String toString() => '$runtimeType(message: $message, debugDetail: $debugDetail)';
}

class FileNotFoundFailure extends Failure {
  const FileNotFoundFailure({super.debugDetail})
      : super(
          message: 'The selected file could not be found. It may have been moved or deleted.',
        );
}

class CorruptFileFailure extends Failure {
  const CorruptFileFailure({super.debugDetail})
      : super(message: 'This file appears to be damaged and cannot be processed.');
}

class UnsupportedFormatFailure extends Failure {
  const UnsupportedFormatFailure({super.debugDetail})
      : super(
          message: 'This file format is not supported. Use MP3, WAV, M4A, AAC, FLAC, or OGG.',
        );
}

class InsufficientStorageFailure extends Failure {
  const InsufficientStorageFailure({super.debugDetail})
      : super(message: 'There is not enough free storage to save the processed file.');
}

class PermissionDeniedFailure extends Failure {
  const PermissionDeniedFailure({super.debugDetail})
      : super(message: 'Storage permission is required to read or save audio files.');
}

class FfmpegFailure extends Failure {
  const FfmpegFailure({super.debugDetail, this.exitCode})
      : super(message: 'Audio processing failed. Please try again.');

  final int? exitCode;
}

class ProfileNotFoundFailure extends Failure {
  const ProfileNotFoundFailure({super.debugDetail})
      : super(message: 'The selected profile could not be found.');
}

class ExportFailure extends Failure {
  const ExportFailure({super.debugDetail})
      : super(message: 'The processed file could not be saved.');
}

class CancelledFailure extends Failure {
  const CancelledFailure() : super(message: 'Processing was cancelled.');
}

/// A user-input validation error. Unlike other failures, the [message] is
/// supplied by the caller and is safe to show directly.
class ValidationFailure extends Failure {
  const ValidationFailure(String message) : super(message: message);
}

class UnknownFailure extends Failure {
  const UnknownFailure({super.debugDetail})
      : super(message: 'Something went wrong. Please try again.');
}
