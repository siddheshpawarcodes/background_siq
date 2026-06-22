import '../../core/result/result.dart';
import '../entities/background_profile.dart';
import '../repositories/profile_repository.dart';
import '../../services/profile/profile_transfer_service.dart';

/// Exports a profile via the share sheet (design §6).
class ExportProfileUseCase {
  const ExportProfileUseCase(this._transfer);
  final ProfileTransferService _transfer;

  Future<Result<void>> call(BackgroundProfile profile) => _transfer.export(profile);
}

/// Imports a profile from a `.echobugprofile` file, assigns a fresh id + timestamps,
/// and saves it. Returns null if the user cancelled (design §6, edge E5: paths
/// that don't exist on this device are kept but flagged when the profile is used).
class ImportProfileUseCase {
  ImportProfileUseCase({
    required ProfileTransferService transfer,
    required ProfileRepository repository,
    required String Function() idGenerator,
  })  : _transfer = transfer,
        _repository = repository,
        _newId = idGenerator;

  final ProfileTransferService _transfer;
  final ProfileRepository _repository;
  final String Function() _newId;

  Future<Result<BackgroundProfile?>> call() async {
    final parsed = await _transfer.pickAndParse();
    if (parsed.isErr) return Result.err(parsed.failureOrNull!);

    final profile = parsed.valueOrNull;
    if (profile == null) return const Result.ok(null); // cancelled

    final now = DateTime.now();
    final imported = profile.copyWith(
      id: _newId(),
      createdDate: now,
      modifiedDate: now,
    );
    final saved = await _repository.save(imported);
    if (saved.isErr) return Result.err(saved.failureOrNull!);
    return Result.ok(imported);
  }
}
