import 'package:background_siq/domain/entities/background_profile.dart';
import 'package:background_siq/domain/entities/enums.dart';
import 'package:background_siq/services/audio/filter_graph_builder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const builder = FilterGraphBuilder();
  final now = DateTime(2026, 1, 1);

  BackgroundProfile profile({
    int volume = 20,
    NoiseLevel noise = NoiseLevel.medium,
    bool enhance = true,
    DuckingStrength ducking = DuckingStrength.medium,
    double fadeIn = 0,
    double fadeOut = 0,
    bool normalize = true,
    ExportFormat format = ExportFormat.mp3,
  }) =>
      BackgroundProfile(
        id: 'x',
        name: 'X',
        musicVolume: volume,
        noiseReduction: noise,
        voiceEnhancementEnabled: enhance,
        ducking: ducking,
        fadeInSeconds: fadeIn,
        fadeOutSeconds: fadeOut,
        normalizationEnabled: normalize,
        exportFormat: format,
        createdDate: now,
        modifiedDate: now,
      );

  test('voice-only chain when no music is set', () {
    final cmd = builder.build(
      voicePath: 'voice.wav',
      outputPath: 'out.mp3',
      profile: profile(ducking: DuckingStrength.off),
      totalDuration: const Duration(seconds: 60),
    );
    expect(cmd.filterComplex, contains('afftdn'));
    expect(cmd.filterComplex, isNot(contains('amix')));
    expect(cmd.arguments, isNot(contains('-stream_loop')));
    expect(cmd.arguments, containsAllInOrder(['-map', '[out]']));
  });

  test('mixes and loops music when a track is set', () {
    final cmd = builder.build(
      voicePath: 'voice.wav',
      musicPath: 'music.mp3',
      outputPath: 'out.mp3',
      profile: profile(volume: 20, ducking: DuckingStrength.off),
      totalDuration: const Duration(seconds: 60),
    );
    expect(cmd.arguments, containsAllInOrder(['-stream_loop', '-1', '-i', 'music.mp3']));
    expect(cmd.filterComplex, contains('volume=0.20'));
    expect(cmd.filterComplex, contains('amix=inputs=2:duration=first'));
    expect(cmd.filterComplex, isNot(contains('sidechaincompress')));
  });

  test('adds sidechain ducking when enabled', () {
    final cmd = builder.build(
      voicePath: 'voice.wav',
      musicPath: 'music.mp3',
      outputPath: 'out.mp3',
      profile: profile(ducking: DuckingStrength.strong),
      totalDuration: const Duration(seconds: 60),
    );
    expect(cmd.filterComplex, contains('asplit=2[v_mix][v_sc]'));
    expect(cmd.filterComplex, contains('sidechaincompress=threshold=0.02:ratio=20'));
  });

  test('no voice filters when noise off and enhancement off', () {
    final cmd = builder.build(
      voicePath: 'voice.wav',
      outputPath: 'out.wav',
      profile: profile(
          noise: NoiseLevel.off, enhance: false, normalize: false, ducking: DuckingStrength.off),
      totalDuration: const Duration(seconds: 30),
    );
    expect(cmd.filterComplex, contains('[0:a]anull[mixed]'));
  });

  test('fade-out start is computed from duration', () {
    final cmd = builder.build(
      voicePath: 'voice.wav',
      outputPath: 'out.mp3',
      profile: profile(fadeIn: 2, fadeOut: 3, ducking: DuckingStrength.off),
      totalDuration: const Duration(seconds: 60),
    );
    expect(cmd.filterComplex, contains('afade=t=in:st=0:d=2.00'));
    expect(cmd.filterComplex, contains('afade=t=out:st=57.00:d=3.00'));
  });

  test('loudnorm targets -16 LUFS when normalization enabled', () {
    final cmd = builder.build(
      voicePath: 'voice.wav',
      outputPath: 'out.mp3',
      profile: profile(ducking: DuckingStrength.off),
      totalDuration: const Duration(seconds: 60),
    );
    expect(cmd.filterComplex, contains('loudnorm=I=-16.0:TP=-1.5:LRA=11.0'));
  });

  test('encoder args vary by format', () {
    final mp3 = builder.build(
      voicePath: 'v.wav', outputPath: 'o.mp3',
      profile: profile(format: ExportFormat.mp3, ducking: DuckingStrength.off),
      totalDuration: const Duration(seconds: 10));
    expect(mp3.arguments, containsAllInOrder(['-c:a', 'libmp3lame', '-b:a', '320k']));

    final wav = builder.build(
      voicePath: 'v.wav', outputPath: 'o.wav',
      profile: profile(format: ExportFormat.wav, ducking: DuckingStrength.off),
      totalDuration: const Duration(seconds: 10));
    expect(wav.arguments, containsAllInOrder(['-c:a', 'pcm_s24le']));
  });

  test('preview adds a trim limit', () {
    final cmd = builder.build(
      voicePath: 'v.wav', outputPath: 'o.mp3',
      profile: profile(ducking: DuckingStrength.off),
      totalDuration: const Duration(seconds: 300),
      trim: const Duration(seconds: 15));
    expect(cmd.arguments, containsAllInOrder(['-t', '15.00']));
  });
}
