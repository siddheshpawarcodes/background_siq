import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../domain/ports/audio_processor_port.dart';
import '../../domain/ports/file_system_port.dart';
import '../../domain/usecases/apply_profile_usecase.dart';
import '../../domain/usecases/generate_preview_usecase.dart';
import '../../domain/usecases/process_batch_usecase.dart';
import '../../domain/usecases/profile_transfer_usecases.dart';
import '../../domain/usecases/profile_usecases.dart';
import '../../domain/usecases/settings_usecases.dart';
import '../../services/audio/ffmpeg_audio_processor.dart';
import '../../services/profile/profile_transfer_service.dart';
import '../../services/filesystem/file_pick_service.dart';
import '../../services/filesystem/file_system_service.dart';
import '../../services/maintenance/maintenance_service.dart';
import '../../services/platform/open_file_service.dart';
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
