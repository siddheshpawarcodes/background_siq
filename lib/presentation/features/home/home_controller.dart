import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../../core/di/repository_providers.dart';
import '../../../core/di/usecase_providers.dart';
import '../../../domain/entities/audio_file_ref.dart';

/// Home screen selection state: the chosen voice file and profile.
class HomeState {
  const HomeState({this.file, this.profileId});

  final AudioFileRef? file;
  final String? profileId;

  bool get canApply => file != null && profileId != null;

  HomeState copyWith({AudioFileRef? file, String? profileId}) =>
      HomeState(file: file ?? this.file, profileId: profileId ?? this.profileId);
}

final homeControllerProvider =
    NotifierProvider<HomeController, HomeState>(HomeController.new);

class HomeController extends Notifier<HomeState> {
  @override
  HomeState build() => const HomeState();

  void selectProfile(String id) => state = state.copyWith(profileId: id);

  void selectFileRef(AudioFileRef file) {
    state = state.copyWith(file: file);
    ref.read(recentFilesRepositoryProvider).push(file);
  }

  /// Opens the system picker and records the selection. Returns false if the
  /// user cancelled.
  Future<bool> pickFile() async {
    final path = await ref.read(filePickServiceProvider).pickAudioPath();
    if (path == null) return false;
    selectFileRef(_refFromPath(path));
    return true;
  }

  AudioFileRef _refFromPath(String path) => AudioFileRef(
        path: path,
        name: p.basename(path),
        ext: p.extension(path).replaceFirst('.', '').toLowerCase(),
      );
}
