import 'package:freezed_annotation/freezed_annotation.dart';

part 'audio_file_ref.freezed.dart';

/// Reference to a user-picked audio file (SRS §7.1).
@freezed
abstract class AudioFileRef with _$AudioFileRef {
  const factory AudioFileRef({
    required String path,
    required String name,
    required String ext, // lower-case, no dot
    int? sizeBytes,
    Duration? duration,
  }) = _AudioFileRef;
}
