import 'dart:async';

import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';

import '../../core/errors/failures.dart';
import '../../core/logging/app_logger.dart';
import '../../core/result/result.dart';
import '../../domain/entities/audio_meta.dart';
import '../../domain/entities/enums.dart';
import '../../domain/entities/process_request.dart';
import '../../domain/ports/audio_processor_port.dart';
import 'filter_graph_builder.dart';
import 'stage_timeline.dart';

/// FFmpeg-backed implementation of [AudioProcessorPort] (SRS §10.1).
///
/// Runs the full pipeline as a single native FFmpeg session on its own thread,
/// keeping the Flutter UI isolate responsive. Progress is derived from the
/// statistics callback against the probed source duration.
class FfmpegAudioProcessor implements AudioProcessorPort {
  FfmpegAudioProcessor({FilterGraphBuilder? builder})
      : _builder = builder ?? const FilterGraphBuilder();

  final FilterGraphBuilder _builder;

  /// Active session ids keyed by jobId, for cancellation.
  final Map<String, int> _sessions = {};

  @override
  Future<Result<AudioMeta>> probe(String path) async {
    try {
      final session = await FFprobeKit.getMediaInformation(path);
      final info = session.getMediaInformation();
      if (info == null) {
        return const Result.err(CorruptFileFailure(debugDetail: 'No media information'));
      }
      final durationSec = double.tryParse(info.getDuration() ?? '') ?? 0;
      final streams = info.getStreams();
      int? channels;
      int? sampleRate;
      String? codec;
      for (final s in streams) {
        if (s.getType() == 'audio') {
          channels = s.getProperty('channels') as int?;
          final sr = s.getProperty('sample_rate');
          sampleRate = sr is int ? sr : int.tryParse('$sr');
          codec = s.getCodec();
          break;
        }
      }
      return Result.ok(AudioMeta(
        duration: Duration(milliseconds: (durationSec * 1000).round()),
        channels: channels,
        sampleRate: sampleRate,
        codec: codec,
      ));
    } catch (e) {
      return Result.err(CorruptFileFailure(debugDetail: e.toString()));
    }
  }

  @override
  Stream<ProcessingProgress> process(ProcessRequest request) {
    final controller = StreamController<ProcessingProgress>();
    _run(request, controller);
    return controller.stream;
  }

  Future<void> _run(
    ProcessRequest request,
    StreamController<ProcessingProgress> controller,
  ) async {
    controller.add(const ProcessingProgress(stage: JobStage.preparing, progress: 0));

    // Probe to learn the duration that drives progress + fade timing.
    final probeResult = await probe(request.source.path);
    final totalDuration = probeResult.fold(
      (meta) => meta.duration,
      (_) => request.source.duration ?? Duration.zero,
    );
    final renderDuration = request.trim != null && request.trim! < totalDuration
        ? request.trim!
        : totalDuration;
    final totalMs = renderDuration.inMilliseconds;

    final hasMusic = request.profile.musicFilePath?.isNotEmpty ?? false;
    final timeline = StageTimeline(request.profile, hasMusic: hasMusic);

    final command = _builder.build(
      voicePath: request.source.path,
      musicPath: request.profile.musicFilePath,
      // Embed cover art on full renders only; previews (trimmed) skip it to
      // stay fast and avoid touching the image for a throwaway sample.
      coverImagePath: request.trim == null ? request.profile.coverImagePath : null,
      outputPath: request.outputPath,
      profile: request.profile,
      totalDuration: totalDuration,
      trim: request.trim,
    );

    AppLogger.d('FFmpeg args: ${command.arguments.join(' ')}');

    try {
      final session = await FFmpegKit.executeWithArgumentsAsync(
        command.arguments,
        (session) async {
          final code = await session.getReturnCode();
          if (ReturnCode.isSuccess(code)) {
            controller.add(
              const ProcessingProgress(stage: JobStage.completed, progress: 1),
            );
          } else if (ReturnCode.isCancel(code)) {
            controller.addError(const CancelledFailure());
          } else {
            final logs = await session.getAllLogsAsString();
            AppLogger.e('FFmpeg failed (${code?.getValue()}): $logs');
            controller.addError(FfmpegFailure(
              debugDetail: logs,
              exitCode: code?.getValue(),
            ));
          }
          _sessions.remove(request.jobId);
          await controller.close();
        },
        (log) => AppLogger.d(log.getMessage()),
        (statistics) {
          if (totalMs <= 0) return;
          final fraction = (statistics.getTime() / totalMs).clamp(0.0, 1.0);
          controller.add(ProcessingProgress(
            stage: timeline.stageFor(fraction),
            progress: fraction,
          ));
        },
      );
      _sessions[request.jobId] = session.getSessionId() ?? -1;
    } catch (e) {
      controller.addError(FfmpegFailure(debugDetail: e.toString()));
      await controller.close();
    }
  }

  @override
  Future<Result<String>> preview(ProcessRequest request) async {
    final completer = Completer<Result<String>>();
    final sub = process(request).listen(
      (progress) {
        if (progress.stage == JobStage.completed && !completer.isCompleted) {
          completer.complete(Result.ok(request.outputPath));
        }
      },
      onError: (Object error) {
        if (!completer.isCompleted) {
          final failure = error is Failure ? error : UnknownFailure(debugDetail: '$error');
          completer.complete(Result.err(failure));
        }
      },
    );
    final result = await completer.future;
    await sub.cancel();
    return result;
  }

  @override
  Future<void> cancel(String jobId) async {
    final sessionId = _sessions[jobId];
    if (sessionId != null && sessionId >= 0) {
      await FFmpegKit.cancel(sessionId);
    }
    _sessions.remove(jobId);
  }
}
