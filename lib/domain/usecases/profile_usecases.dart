import '../../core/errors/failures.dart';
import '../../core/result/result.dart';
import '../entities/background_profile.dart';
import '../repositories/profile_repository.dart';

/// Validates and persists a profile (SRS §7.2). Business rules (non-empty
/// name, clamped ranges) live here — never in widgets.
class SaveProfileUseCase {
  const SaveProfileUseCase(this._repo);
  final ProfileRepository _repo;

  Future<Result<void>> call(BackgroundProfile profile) {
    final name = profile.name.trim();
    if (name.isEmpty) {
      return Future.value(
        const Result.err(ValidationFailure('Please enter a profile name.')),
      );
    }
    final sanitized = profile.copyWith(
      name: name,
      musicVolume: profile.musicVolume.clamp(0, 100),
      fadeInSeconds: profile.fadeInSeconds.clamp(0.0, 10.0),
      fadeOutSeconds: profile.fadeOutSeconds.clamp(0.0, 10.0),
      modifiedDate: DateTime.now(),
    );
    return _repo.save(sanitized);
  }
}

class DeleteProfileUseCase {
  const DeleteProfileUseCase(this._repo);
  final ProfileRepository _repo;

  Future<Result<void>> call(String id) => _repo.delete(id);
}

class DuplicateProfileUseCase {
  const DuplicateProfileUseCase(this._repo);
  final ProfileRepository _repo;

  Future<Result<BackgroundProfile>> call(String id) => _repo.duplicate(id);
}
