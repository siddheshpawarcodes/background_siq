import '../../domain/entities/audio_file_ref.dart';
import '../models/recent_file_model.dart';

/// Maps [RecentFileModel] (Hive) ⇄ [AudioFileRef] (domain).
extension RecentFileModelMapper on RecentFileModel {
  AudioFileRef toEntity() => AudioFileRef(
        path: path,
        name: name,
        ext: ext,
        sizeBytes: sizeBytes,
        duration:
            durationMillis == null ? null : Duration(milliseconds: durationMillis!),
      );
}

extension AudioFileRefMapper on AudioFileRef {
  RecentFileModel toModel({required DateTime lastUsed}) => RecentFileModel(
        path: path,
        name: name,
        ext: ext,
        sizeBytes: sizeBytes,
        durationMillis: duration?.inMilliseconds,
        lastUsed: lastUsed,
      );
}
