/// Domain enums for EchoBug (SRS §7.1).
///
/// Persisted as their `index` in Hive models for migration safety; the
/// mapper layer converts between index and enum. Each carries a [label] for
/// display and, where relevant, the parameters used by the FFmpeg pipeline.
library;

/// Noise-reduction intensity (pipeline step 2).
enum NoiseLevel {
  off('Off'),
  mild('Mild'),
  medium('Medium'),
  aggressive('Aggressive');

  const NoiseLevel(this.label);
  final String label;
}

/// Side-chain ducking strength (pipeline step 5).
enum DuckingStrength {
  off('Off'),
  light('Light'),
  medium('Medium'),
  strong('Strong');

  const DuckingStrength(this.label);
  final String label;
}

/// Export encoder selection (pipeline step 9).
enum ExportFormat {
  mp3('MP3 320kbps', 'mp3'),
  aac('AAC 256kbps', 'm4a'),
  wav('WAV lossless', 'wav');

  const ExportFormat(this.label, this.containerExtension);

  final String label;

  /// File extension for this format's container.
  final String containerExtension;
}

/// Discrete stages reported during processing (SRS §11.2).
enum JobStage {
  preparing('Preparing...'),
  denoising('Reducing noise...'),
  enhancing('Enhancing voice...'),
  mixing('Mixing music...'),
  ducking('Applying ducking...'),
  fading('Applying fades...'),
  normalizing('Normalizing...'),
  exporting('Exporting...'),
  completed('Completed'),
  failed('Failed');

  const JobStage(this.label);
  final String label;
}

/// Terminal status recorded in processing history.
enum JobStatus {
  success('Success'),
  failed('Failed');

  const JobStatus(this.label);
  final String label;
}
