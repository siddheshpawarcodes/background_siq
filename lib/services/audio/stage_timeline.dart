import '../../domain/entities/background_profile.dart';
import '../../domain/entities/enums.dart';

/// Maps overall render progress (0..1) to a representative [JobStage].
///
/// The pipeline runs as a single FFmpeg pass (SRS §10.4), so discrete stage
/// boundaries are synthetic: we list the stages the profile actually enables
/// and interpolate the label across the render so the UI advances naturally.
class StageTimeline {
  StageTimeline(BackgroundProfile profile, {required bool hasMusic})
      : _stages = _build(profile, hasMusic);

  final List<JobStage> _stages;

  static List<JobStage> _build(BackgroundProfile p, bool hasMusic) {
    return [
      if (p.noiseReduction != NoiseLevel.off) JobStage.denoising,
      if (p.voiceEnhancementEnabled) JobStage.enhancing,
      if (hasMusic) JobStage.mixing,
      if (hasMusic && p.ducking != DuckingStrength.off) JobStage.ducking,
      if (p.fadeInSeconds > 0 || p.fadeOutSeconds > 0) JobStage.fading,
      if (p.normalizationEnabled) JobStage.normalizing,
      JobStage.exporting,
    ];
  }

  /// Representative stage for a render [fraction] in [0,1].
  JobStage stageFor(double fraction) {
    if (_stages.isEmpty) return JobStage.exporting;
    final clamped = fraction.clamp(0.0, 0.999);
    final index = (clamped * _stages.length).floor();
    return _stages[index];
  }
}
