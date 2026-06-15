import 'package:path/path.dart' as p;

import '../../core/constants/app_constants.dart';
import '../../domain/entities/background_profile.dart';
import '../../domain/entities/enums.dart';

/// A fully-assembled FFmpeg invocation: the ordered argument list plus the
/// `filter_complex` graph (exposed separately for testing/inspection).
class FfmpegCommand {
  const FfmpegCommand({required this.arguments, required this.filterComplex});

  final List<String> arguments;
  final String filterComplex;

  @override
  String toString() => arguments.join(' ');
}

/// Translates a [BackgroundProfile] into a single-invocation FFmpeg command
/// implementing the 9-step pipeline (SRS §10.2). Pure and deterministic — no
/// IO — so it can be unit-tested without a device.
class FilterGraphBuilder {
  const FilterGraphBuilder();

  /// Builds the command. [totalDuration] is the voice length (needed for
  /// fade-out timing); for a preview pass the trimmed length and set [trim].
  FfmpegCommand build({
    required String voicePath,
    String? musicPath,
    required String outputPath,
    required BackgroundProfile profile,
    required Duration totalDuration,
    Duration? trim,
  }) {
    final hasMusic = musicPath != null && musicPath.isNotEmpty;
    final effectiveDuration = trim ?? totalDuration;

    final voiceFilters = _voiceFilters(profile);
    final voiceChain = voiceFilters.isEmpty ? 'anull' : voiceFilters.join(',');

    final parts = <String>[];

    if (hasMusic) {
      final volume = (profile.musicVolume / 100).toStringAsFixed(2);
      if (profile.ducking == DuckingStrength.off) {
        parts.add('[0:a]$voiceChain[v]');
        parts.add('[1:a]volume=$volume[mus]');
        parts.add('[mus][v]amix=inputs=2:duration=first:dropout_transition=0[mixed]');
      } else {
        parts.add('[0:a]$voiceChain,asplit=2[v_mix][v_sc]');
        parts.add('[1:a]volume=$volume[mus]');
        parts.add('[mus][v_sc]${_duckingFilter(profile.ducking)}[ducked]');
        parts.add('[ducked][v_mix]amix=inputs=2:duration=first:dropout_transition=0[mixed]');
      }
    } else {
      parts.add('[0:a]$voiceChain[mixed]');
    }

    // Post chain: fades + loudness normalization.
    final post = _postFilters(profile, effectiveDuration);
    final String mapLabel;
    if (post.isEmpty) {
      mapLabel = '[mixed]';
    } else {
      parts.add('[mixed]${post.join(',')}[out]');
      mapLabel = '[out]';
    }

    final filterComplex = parts.join(';');

    final args = <String>[
      '-y',
      '-i', voicePath,
      if (hasMusic) ...['-stream_loop', '-1', '-i', musicPath],
      '-filter_complex', filterComplex,
      '-map', mapLabel,
      if (trim != null) ...['-t', _seconds(trim)],
      ..._encoderArgsForExtension(outputPath),
      outputPath,
    ];

    return FfmpegCommand(arguments: args, filterComplex: filterComplex);
  }

  /// Steps 2 & 3: noise reduction + voice enhancement.
  List<String> _voiceFilters(BackgroundProfile profile) {
    final filters = <String>[];
    var addedHighpass = false;

    switch (profile.noiseReduction) {
      case NoiseLevel.off:
        break;
      case NoiseLevel.mild:
        filters.add('afftdn=nr=10:nf=-25');
      case NoiseLevel.medium:
        filters.add('afftdn=nr=20:nf=-30');
      case NoiseLevel.aggressive:
        filters.add('highpass=f=80');
        addedHighpass = true;
        filters.add('afftdn=nr=30:nf=-35');
    }

    if (profile.voiceEnhancementEnabled) {
      if (!addedHighpass) filters.add('highpass=f=80');
      filters
        ..add('equalizer=f=200:t=q:w=1:g=-2') // tame low-mid mud
        ..add('equalizer=f=3000:t=q:w=1.5:g=4') // presence/intelligibility
        ..add('acompressor=threshold=-18dB:ratio=3:attack=5:release=60:makeup=2');
    }
    return filters;
  }

  /// Step 5: side-chain ducking parameters by strength.
  String _duckingFilter(DuckingStrength strength) => switch (strength) {
        DuckingStrength.off => 'acopy', // unreachable; off handled by caller
        DuckingStrength.light =>
          'sidechaincompress=threshold=0.05:ratio=4:attack=20:release=300',
        DuckingStrength.medium =>
          'sidechaincompress=threshold=0.03:ratio=8:attack=15:release=250',
        DuckingStrength.strong =>
          'sidechaincompress=threshold=0.02:ratio=20:attack=10:release=200',
      };

  /// Steps 6, 7, 8: fade in/out + loudness normalization.
  List<String> _postFilters(BackgroundProfile profile, Duration duration) {
    final post = <String>[];
    if (profile.fadeInSeconds > 0) {
      post.add('afade=t=in:st=0:d=${profile.fadeInSeconds.toStringAsFixed(2)}');
    }
    if (profile.fadeOutSeconds > 0) {
      final start = (duration.inMilliseconds / 1000) - profile.fadeOutSeconds;
      final safeStart = start < 0 ? 0.0 : start;
      post.add('afade=t=out:st=${safeStart.toStringAsFixed(2)}:'
          'd=${profile.fadeOutSeconds.toStringAsFixed(2)}');
    }
    if (profile.normalizationEnabled) {
      post.add('loudnorm=I=${AppConstants.loudnessTargetLufs}:'
          'TP=${AppConstants.loudnessTruePeakDbtp}:'
          'LRA=${AppConstants.loudnessRange}');
    }
    return post;
  }

  /// Step 9: encoder arguments derived from the OUTPUT container extension.
  ///
  /// Per the mirror-source decision (SRS §3.1), the output keeps the source
  /// container, so the codec must match that container rather than the
  /// profile's advisory export format.
  List<String> _encoderArgsForExtension(String outputPath) {
    final ext = p.extension(outputPath).replaceFirst('.', '').toLowerCase();
    return switch (ext) {
      'mp3' => ['-c:a', 'libmp3lame', '-b:a', '320k'],
      'm4a' || 'aac' => ['-c:a', 'aac', '-b:a', '256k', '-movflags', '+faststart'],
      'wav' => ['-c:a', 'pcm_s24le'],
      'flac' => ['-c:a', 'flac'],
      'ogg' => ['-c:a', 'libvorbis', '-q:a', '6'],
      _ => ['-c:a', 'libmp3lame', '-b:a', '320k'], // safe default
    };
  }

  String _seconds(Duration d) => (d.inMilliseconds / 1000).toStringAsFixed(2);
}
