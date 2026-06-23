/// Application-wide constants for EchoBug.
///
/// Centralizes values referenced across layers so there are no magic strings.
class AppConstants {
  AppConstants._();

  static const String appName = 'EchoBug';
  static const String appShortName = 'EchoBug';

  /// Folder that holds every processed output file. Created on first use and
  /// reused thereafter; when a user export folder is chosen, this is nested
  /// inside it so all files still land in one "Srotas Audio" folder.
  static const String outputFolderName = 'Srotas Audio';

  /// Suffix appended to every processed output file (before the extension).
  /// e.g. `meeting.mp3` -> `meeting_echobug.mp3`.
  static const String outputSuffix = '_echobug';

  /// Top-level public folder (under Music/) that the Dataset Batch feature
  /// mirrors processed output into, e.g. `Music/EchoBug/music data/Amalki/...`.
  static const String datasetOutputFolder = 'EchoBug';

  /// Audio container extensions the app can ingest (lower-case, no dot).
  static const Set<String> supportedInputExtensions = {
    'mp3',
    'wav',
    'm4a',
    'aac',
    'flac',
    'ogg',
  };

  /// Output container extensions that can carry an embedded cover-art image
  /// (the thumbnail). The output mirrors the source container (SRS §3.1), so
  /// a profile's cover image is only embedded when the file is one of these;
  /// `wav` and `ogg` have no reliable cover-art slot and are skipped.
  static const Set<String> coverArtCapableExtensions = {'mp3', 'm4a', 'aac', 'flac'};

  /// Human-readable list of cover-art-capable formats, for UI hints.
  static const String coverArtCapableLabel = 'MP3, M4A and FLAC';

  /// Image extensions accepted for a profile's embedded cover art (thumbnail).
  /// Restricted to JPEG/PNG so the picture can be copied losslessly into every
  /// supported container without re-encoding.
  static const Set<String> supportedCoverImageExtensions = {
    'jpg',
    'jpeg',
    'png',
  };

  /// Default background-music volume (percent) for new profiles.
  static const int defaultMusicVolume = 20;

  /// Default audio (spoken/voice track) volume (percent) for new profiles.
  static const int defaultVoiceVolume = 100;

  /// Maximum number of files in a single batch (SRS §15).
  static const int maxBatchFiles = 50;

  /// Loudness normalization targets (EBU R128) — see SRS §10.3.
  static const double loudnessTargetLufs = -16.0;
  static const double loudnessTruePeakDbtp = -1.5;
  static const double loudnessRange = 11.0;

  /// Hive box names.
  static const String profilesBox = 'profiles';
  static const String settingsBox = 'settings';
  static const String historyBox = 'history';
  static const String recentFilesBox = 'recent_files';
  static const String profileDraftBox = 'profile_draft';
  static const String userBox = 'user';

  /// Key for the single in-progress wizard draft (auto-save).
  static const String draftKey = 'current';

  /// Singleton key for the settings box.
  static const String settingsKey = 'app';

  /// Singleton key for the signed-in account in the user box.
  static const String userKey = 'current';
}
