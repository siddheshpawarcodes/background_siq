import 'package:freezed_annotation/freezed_annotation.dart';

part 'audio_meta.freezed.dart';

/// Technical metadata probed from an audio file (SRS §10.4 — used for
/// progress calculation and pre-flight validation).
@freezed
abstract class AudioMeta with _$AudioMeta {
  const factory AudioMeta({
    required Duration duration,
    int? sampleRate,
    int? channels,
    String? codec,
  }) = _AudioMeta;
}
