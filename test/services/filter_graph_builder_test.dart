import 'package:echobug/domain/entities/background_profile.dart';
import 'package:echobug/domain/entities/enums.dart';
import 'package:echobug/services/audio/filter_graph_builder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const builder = FilterGraphBuilder();
  final now = DateTime(2026, 1, 1);

  BackgroundProfile profile({
    int volume = 20,
    int voiceVolume = 100,
    NoiseLevel noise = NoiseLevel.medium,
    bool enhance = true,
    DuckingStrength ducking = DuckingStrength.medium,
    double fadeIn = 0,
    double fadeOut = 0,
    double eqBass = 0,
    double eqMid = 0,
    double eqTreble = 0,
    bool normalize = true,
    ExportFormat format = ExportFormat.mp3,
    int? bitrate,
  }) =>
      BackgroundProfile(
        id: 'x',
        name: 'X',
        voiceVolume: voiceVolume,
        musicVolume: volume,
        noiseReduction: noise,
        voiceEnhancementEnabled: enhance,
        ducking: ducking,
        fadeInSeconds: fadeIn,
        fadeOutSeconds: fadeOut,
        eqBassDb: eqBass,
        eqMidDb: eqMid,
        eqTrebleDb: eqTreble,
        normalizationEnabled: normalize,
        exportFormat: format,
        audioBitrateKbps: bitrate,
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
    // Must mix for the VOICE length, not the infinitely-looped music, or a
    // full (un-trimmed) render never finishes — see FilterGraphBuilder.build.
    expect(cmd.filterComplex, contains('amix=inputs=2:duration=shortest'));
    expect(cmd.filterComplex, isNot(contains('duration=first')));
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

  test('applies a volume filter to the voice chain below 100%', () {
    final cmd = builder.build(
      voicePath: 'voice.wav',
      outputPath: 'out.wav',
      profile: profile(
          voiceVolume: 60,
          noise: NoiseLevel.off,
          enhance: false,
          normalize: false,
          ducking: DuckingStrength.off),
      totalDuration: const Duration(seconds: 30),
    );
    expect(cmd.filterComplex, contains('[0:a]volume=0.60[mixed]'));
  });

  test('voice chain has no volume filter at 100%', () {
    final cmd = builder.build(
      voicePath: 'voice.wav',
      outputPath: 'out.wav',
      profile: profile(ducking: DuckingStrength.off),
      totalDuration: const Duration(seconds: 30),
    );
    expect(cmd.filterComplex, isNot(contains('[0:a]volume=')));
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

  test('no tone-EQ filter at default (0 dB) — preserves the anull fast path', () {
    final cmd = builder.build(
      voicePath: 'voice.wav',
      outputPath: 'out.wav',
      profile: profile(
          noise: NoiseLevel.off, enhance: false, normalize: false, ducking: DuckingStrength.off),
      totalDuration: const Duration(seconds: 30),
    );
    expect(cmd.filterComplex, contains('[0:a]anull[mixed]'));
  });

  test('emits only the tone-EQ bands that are non-zero', () {
    final cmd = builder.build(
      voicePath: 'voice.wav',
      outputPath: 'out.wav',
      profile: profile(
          eqBass: 4,
          eqTreble: -3,
          noise: NoiseLevel.off,
          enhance: false,
          normalize: false,
          ducking: DuckingStrength.off),
      totalDuration: const Duration(seconds: 30),
    );
    expect(cmd.filterComplex, contains('equalizer=f=100:t=q:w=1:g=4.0'));
    expect(cmd.filterComplex, contains('equalizer=f=8000:t=q:w=1:g=-3.0'));
    // Mid band left at 0 → no 1 kHz band emitted.
    expect(cmd.filterComplex, isNot(contains('equalizer=f=1000')));
  });

  test('default bitrate is unchanged (320k mp3 / 256k aac)', () {
    final mp3 = builder.build(
      voicePath: 'v.wav', outputPath: 'o.mp3',
      profile: profile(ducking: DuckingStrength.off),
      totalDuration: const Duration(seconds: 10));
    expect(mp3.arguments, containsAllInOrder(['-b:a', '320k']));

    final aac = builder.build(
      voicePath: 'v.wav', outputPath: 'o.m4a',
      profile: profile(ducking: DuckingStrength.off),
      totalDuration: const Duration(seconds: 10));
    expect(aac.arguments, containsAllInOrder(['-b:a', '256k']));
  });

  test('honors an explicit bitrate override for lossy formats', () {
    final mp3 = builder.build(
      voicePath: 'v.wav', outputPath: 'o.mp3',
      profile: profile(bitrate: 192, ducking: DuckingStrength.off),
      totalDuration: const Duration(seconds: 10));
    expect(mp3.arguments, containsAllInOrder(['-c:a', 'libmp3lame', '-b:a', '192k']));

    // WAV is lossless: bitrate is ignored, encoder stays PCM.
    final wav = builder.build(
      voicePath: 'v.wav', outputPath: 'o.wav',
      profile: profile(bitrate: 192, format: ExportFormat.wav, ducking: DuckingStrength.off),
      totalDuration: const Duration(seconds: 10));
    expect(wav.arguments, containsAllInOrder(['-c:a', 'pcm_s24le']));
    expect(wav.arguments, isNot(contains('192k')));
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

  test('embeds cover art for a supported output (mp3)', () {
    final cmd = builder.build(
      voicePath: 'v.wav',
      coverImagePath: 'cover.jpg',
      outputPath: 'o.mp3',
      profile: profile(ducking: DuckingStrength.off),
      totalDuration: const Duration(seconds: 60),
    );
    // Image appended as the last input → index 1 with no music.
    expect(cmd.arguments, containsAllInOrder(['-i', 'cover.jpg']));
    expect(cmd.arguments, containsAllInOrder(['-map', '1:v']));
    expect(cmd.arguments, containsAllInOrder(['-c:v', 'copy']));
    expect(cmd.arguments, containsAllInOrder(['-disposition:v', 'attached_pic']));
    expect(cmd.arguments, containsAllInOrder(['-id3v2_version', '3']));
  });

  test('cover image index is 2 when music is also present', () {
    final cmd = builder.build(
      voicePath: 'v.wav',
      musicPath: 'music.mp3',
      coverImagePath: 'cover.png',
      outputPath: 'o.m4a',
      profile: profile(ducking: DuckingStrength.off),
      totalDuration: const Duration(seconds: 60),
    );
    expect(cmd.arguments, containsAllInOrder(['-i', 'cover.png']));
    expect(cmd.arguments, containsAllInOrder(['-map', '2:v']));
    expect(cmd.arguments, containsAllInOrder(['-disposition:v', 'attached_pic']));
    // ID3 tags are mp3-only.
    expect(cmd.arguments, isNot(contains('-id3v2_version')));
  });

  test('skips cover art for an unsupported output (wav)', () {
    final cmd = builder.build(
      voicePath: 'v.wav',
      coverImagePath: 'cover.jpg',
      outputPath: 'o.wav',
      profile: profile(format: ExportFormat.wav, ducking: DuckingStrength.off),
      totalDuration: const Duration(seconds: 60),
    );
    expect(cmd.arguments, isNot(contains('cover.jpg')));
    expect(cmd.arguments, isNot(contains('attached_pic')));
    expect(cmd.arguments, isNot(contains('1:v')));
  });

  test('no cover args when no image is set', () {
    final cmd = builder.build(
      voicePath: 'v.wav',
      outputPath: 'o.mp3',
      profile: profile(ducking: DuckingStrength.off),
      totalDuration: const Duration(seconds: 60),
    );
    expect(cmd.arguments, isNot(contains('attached_pic')));
    expect(cmd.arguments, isNot(contains('-disposition:v')));
  });
}
