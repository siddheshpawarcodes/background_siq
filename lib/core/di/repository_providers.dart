import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/app_boxes.dart';
import '../../data/repositories/draft_repository_impl.dart';
import '../../data/repositories/history_repository_impl.dart';
import '../../data/repositories/profile_repository_impl.dart';
import '../../data/repositories/recent_files_repository_impl.dart';
import '../../data/repositories/settings_repository_impl.dart';
import '../../domain/entities/app_settings.dart';
import '../../domain/entities/audio_file_ref.dart';
import '../../domain/entities/background_profile.dart';
import '../../domain/entities/history_entry.dart';
import '../../domain/repositories/draft_repository.dart';
import '../../domain/repositories/history_repository.dart';
import '../../domain/repositories/profile_repository.dart';
import '../../domain/repositories/recent_files_repository.dart';
import '../../domain/repositories/settings_repository.dart';

/// Opened Hive boxes — overridden in `main` with the bootstrap result.
final appBoxesProvider = Provider<AppBoxes>(
  (ref) => throw UnimplementedError('appBoxesProvider must be overridden in main()'),
);

// --- Repository providers (SRS §9) ---

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepositoryImpl(ref.watch(appBoxesProvider).profiles),
);

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => SettingsRepositoryImpl(ref.watch(appBoxesProvider).settings),
);

final historyRepositoryProvider = Provider<HistoryRepository>(
  (ref) => HistoryRepositoryImpl(ref.watch(appBoxesProvider).history),
);

final recentFilesRepositoryProvider = Provider<RecentFilesRepository>(
  (ref) => RecentFilesRepositoryImpl(ref.watch(appBoxesProvider).recentFiles),
);

final draftRepositoryProvider = Provider<DraftRepository>(
  (ref) => DraftRepositoryImpl(ref.watch(appBoxesProvider).profileDraft),
);

// --- Convenience stream providers consumed by the UI ---

final profilesProvider = StreamProvider<List<BackgroundProfile>>(
  (ref) => ref.watch(profileRepositoryProvider).watchAll(),
);

final settingsStreamProvider = StreamProvider<AppSettings>(
  (ref) => ref.watch(settingsRepositoryProvider).watch(),
);

final historyProvider = StreamProvider<List<HistoryEntry>>(
  (ref) => ref.watch(historyRepositoryProvider).watchAll(),
);

final recentFilesProvider = StreamProvider<List<AudioFileRef>>(
  (ref) => ref.watch(recentFilesRepositoryProvider).watch(),
);
