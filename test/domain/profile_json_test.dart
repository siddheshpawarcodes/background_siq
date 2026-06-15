import 'package:background_siq/domain/entities/background_profile.dart';
import 'package:background_siq/domain/entities/enums.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final profile = BackgroundProfile(
    id: 'p1',
    name: 'Corporate Intro',
    description: 'Used for customer training videos',
    musicFilePath: '/music/corp.mp3',
    calibrationVoiceSamplePath: '/voice/example_voice.mp3',
    musicVolume: 18,
    noiseReduction: NoiseLevel.aggressive,
    voiceEnhancementEnabled: true,
    ducking: DuckingStrength.strong,
    fadeInSeconds: 1.5,
    fadeOutSeconds: 2.0,
    normalizationEnabled: true,
    exportFormat: ExportFormat.aac,
    createdDate: DateTime(2026, 6, 15, 9),
    modifiedDate: DateTime(2026, 6, 15, 10),
  );

  test('round-trips through JSON preserving all fields (export/import)', () {
    final restored = BackgroundProfile.fromJson(profile.toJson());
    expect(restored, profile);
  });

  test('enums serialize as readable strings', () {
    final json = profile.toJson();
    expect(json['noiseReduction'], 'aggressive');
    expect(json['ducking'], 'strong');
    expect(json['exportFormat'], 'aac');
    expect(json['description'], 'Used for customer training videos');
    expect(json['calibrationVoiceSamplePath'], '/voice/example_voice.mp3');
  });
}
