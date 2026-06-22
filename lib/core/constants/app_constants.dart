/// Application-wide constants for Window Background Music (WBM).
///
/// Centralizes values referenced across layers so there are no magic strings.
class AppConstants {
  AppConstants._();

  static const String appName = 'Window Background Music';
  static const String appShortName = 'WBM';

  /// Folder that holds every processed output file. Created on first use and
  /// reused thereafter; when a user export folder is chosen, this is nested
  /// inside it so all files still land in one "Srotas Audio" folder.
  static const String outputFolderName = 'Srotas Audio';

  /// Suffix appended to every processed output file (before the extension).
  /// e.g. `meeting.mp3` -> `meeting_WBM.mp3`.
  static const String outputSuffix = '_WBM';

  /// Audio container extensions the app can ingest (lower-case, no dot).
  static const Set<String> supportedInputExtensions = {
    'mp3',
    'wav',
    'm4a',
    'aac',
    'flac',
    'ogg',
  };

  /// Image extensions accepted for a profile's embedded cover art (thumbnail).
  /// Restricted to JPEG/PNG so the picture can be copied losslessly into every
  /// supported container without re-encoding.
  static const Set<String> supportedCoverImageExtensions = {
    'jpg',
    'jpeg',
    'png',
  };

  /// Output containers that can carry embedded cover art (an `attached_pic`
  /// stream). WAV and OGG are intentionally excluded — they have no widely
  /// supported cover-art slot — so exports in those formats simply skip the
  /// thumbnail instead of failing.
  static const Set<String> coverArtCapableFormats = {
    'mp3',
    'm4a',
    'aac',
    'flac',
  };

  /// Default background-music volume (percent) for new profiles.
  static const int defaultMusicVolume = 20;

  /// Default audio (spoken/voice track) volume (percent) for new profiles.
  static const int defaultVoiceVolume = 100;

  /// Preview duration rendered for the 15-second sample.
  static const Duration previewDuration = Duration(seconds: 15);

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

  /// Key for the single in-progress wizard draft (auto-save).
  static const String draftKey = 'current';

  /// Singleton key for the settings box.
  static const String settingsKey = 'app';
}
