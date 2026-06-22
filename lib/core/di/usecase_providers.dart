import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../domain/ports/audio_processor_port.dart';
import '../../domain/ports/file_system_port.dart';
import '../../domain/ports/media_store_port.dart';
import '../../domain/usecases/apply_profile_usecase.dart';
import '../../domain/usecases/generate_preview_usecase.dart';
import '../../domain/usecases/process_batch_usecase.dart';
import '../../domain/usecases/process_dataset_usecase.dart';
import '../../domain/usecases/profile_transfer_usecases.dart';
import '../../domain/usecases/profile_usecases.dart';
import '../../domain/usecases/settings_usecases.dart';
import '../../services/audio/ffmpeg_audio_processor.dart';
import '../../services/dataset/dataset_file_scanner.dart';
import '../../services/dataset/mirrored_output_file_system.dart';
import '../../services/profile/profile_transfer_service.dart';
import '../../services/filesystem/file_pick_service.dart';
import '../../services/filesystem/file_system_service.dart';
import '../../services/maintenance/maintenance_service.dart';
import '../../services/platform/media_store_service.dart';
import '../../services/platform/open_file_service.dart';
import '../../services/platform/storage_permission_service.dart';
import 'repository_providers.dart';

// --- Services ---

const _uuid = Uuid();
String _newId() => _uuid.v4();

final filePickServiceProvider = Provider<FilePickService>(
  (ref) => const FilePickService(),
);

final fileSystemProvider = Provider<FileSystemPort>(
  (ref) => const FileSystemService(),
);

final audioProcessorProvider = Provider<AudioProcessorPort>(
  (ref) => FfmpegAudioProcessor(),
);

final openFileServiceProvider = Provider<OpenFileService>(
  (ref) => const OpenFileService(),
);

final maintenanceServiceProvider = Provider<MaintenanceService>(
  (ref) => MaintenanceService(ref.watch(appBoxesProvider)),
);

// --- Processing use cases (SRS §7.2) ---

final applyProfileUseCaseProvider = Provider<ApplyProfileUseCase>(
  (ref) => ApplyProfileUseCase(
    processor: ref.watch(audioProcessorProvider),
    fileSystem: ref.watch(fileSystemProvider),
    settings: ref.watch(settingsRepositoryProvider),
    history: ref.watch(historyRepositoryProvider),
    idGenerator: _newId,
  ),
);

final generatePreviewUseCaseProvider = Provider<GeneratePreviewUseCase>(
  (ref) => GeneratePreviewUseCase(
    processor: ref.watch(audioProcessorProvider),
    fileSystem: ref.watch(fileSystemProvider),
    idGenerator: _newId,
  ),
);

final processBatchUseCaseProvider = Provider<ProcessBatchUseCase>(
  (ref) => ProcessBatchUseCase(ref.watch(applyProfileUseCaseProvider)),
);

// --- Dataset batch processing (additive; independent of the manual batch) ---

final datasetFileScannerProvider = Provider<DatasetFileScanner>(
  (ref) => const DatasetFileScanner(),
);

final storagePermissionServiceProvider = Provider<StoragePermissionService>(
  (ref) => const StoragePermissionService(),
);

final mediaStorePortProvider = Provider<MediaStorePort>(
  (ref) => const MediaStoreService(),
);

/// Builds, per run, an [ApplyProfileUseCase] whose engine writes to an
/// app-private staging mirror of the source tree (via [MirroredOutputFileSystem])
/// — reusing the full single-file engine (validation, processing) unchanged.
/// History recording is disabled: the dataset flow has its own results view and
/// staging paths are transient (the output is then published to Music/EchoBug/).
final datasetApplyBuilderProvider = Provider<DatasetApplyBuilder>((ref) {
  final processor = ref.watch(audioProcessorProvider);
  final inner = ref.watch(fileSystemProvider);
  final settings = ref.watch(settingsRepositoryProvider);
  final history = ref.watch(historyRepositoryProvider);
  return (sourceRoot) async {
    final stagingRoot = await MirroredOutputFileSystem.resolveStagingRoot();
    return ApplyProfileUseCase(
      processor: processor,
      fileSystem: MirroredOutputFileSystem(
        inner,
        sourceRoot: sourceRoot,
        outputRoot: stagingRoot,
      ),
      settings: settings,
      history: history,
      idGenerator: _newId,
      recordHistory: false,
    );
  };
});

final processDatasetUseCaseProvider = Provider<ProcessDatasetUseCase>(
  (ref) => ProcessDatasetUseCase(
    buildApply: ref.watch(datasetApplyBuilderProvider),
    profiles: ref.watch(profileRepositoryProvider),
    scanner: ref.watch(datasetFileScannerProvider),
    fileSystem: ref.watch(fileSystemProvider),
    mediaStore: ref.watch(mediaStorePortProvider),
  ),
);

// --- Profile use cases (SRS §7.2) ---

final saveProfileUseCaseProvider = Provider<SaveProfileUseCase>(
  (ref) => SaveProfileUseCase(ref.watch(profileRepositoryProvider)),
);

final deleteProfileUseCaseProvider = Provider<DeleteProfileUseCase>(
  (ref) => DeleteProfileUseCase(ref.watch(profileRepositoryProvider)),
);

final duplicateProfileUseCaseProvider = Provider<DuplicateProfileUseCase>(
  (ref) => DuplicateProfileUseCase(ref.watch(profileRepositoryProvider)),
);

final profileTransferServiceProvider = Provider<ProfileTransferService>(
  (ref) => const ProfileTransferService(),
);

final exportProfileUseCaseProvider = Provider<ExportProfileUseCase>(
  (ref) => ExportProfileUseCase(ref.watch(profileTransferServiceProvider)),
);

final importProfileUseCaseProvider = Provider<ImportProfileUseCase>(
  (ref) => ImportProfileUseCase(
    transfer: ref.watch(profileTransferServiceProvider),
    repository: ref.watch(profileRepositoryProvider),
    idGenerator: _newId,
  ),
);

// --- Settings use cases (SRS §7.2) ---

final updateSettingsUseCaseProvider = Provider<UpdateSettingsUseCase>(
  (ref) => UpdateSettingsUseCase(ref.watch(settingsRepositoryProvider)),
);
