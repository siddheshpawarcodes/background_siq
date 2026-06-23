import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Reusable scrub bar for previewing rendered audio. Tracks the player's
/// position via [positionStream] and lets the user seek with [onSeek]. A local
/// [_dragValue] holds the thumb while dragging so live position ticks don't
/// fight the gesture; it's committed on release.
///
/// Decoupled from any specific player so it can sit under every preview — the
/// calibration step (via its controller) and the home screen (via just_audio)
/// both feed it the same three streams/callback.
class AudioSeekBar extends StatefulWidget {
  const AudioSeekBar({
    super.key,
    required this.positionStream,
    required this.durationStream,
    required this.onSeek,
  });

  /// Live playback position.
  final Stream<Duration> positionStream;

  /// Total length of the loaded clip (null until known).
  final Stream<Duration?> durationStream;

  /// Jumps playback to the given position when the user releases the thumb.
  final Future<void> Function(Duration) onSeek;

  @override
  State<AudioSeekBar> createState() => _AudioSeekBarState();
}

class _AudioSeekBarState extends State<AudioSeekBar> {
  double? _dragValue;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Duration?>(
      stream: widget.durationStream,
      builder: (context, durSnap) {
        final duration = durSnap.data ?? Duration.zero;
        final maxMs = duration.inMilliseconds.toDouble();
        return StreamBuilder<Duration>(
          stream: widget.positionStream,
          builder: (context, posSnap) {
            final position = posSnap.data ?? Duration.zero;
            final posMs = position.inMilliseconds.toDouble();
            final value = (_dragValue ?? posMs).clamp(0.0, maxMs <= 0 ? 1.0 : maxMs);
            final shown = _dragValue == null
                ? position
                : Duration(milliseconds: _dragValue!.round());
            return Column(
              children: [
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 2,
                    thumbShape:
                        const RoundSliderThumbShape(enabledThumbRadius: 6),
                    overlayShape:
                        const RoundSliderOverlayShape(overlayRadius: 14),
                  ),
                  child: Slider(
                    value: value,
                    max: maxMs <= 0 ? 1.0 : maxMs,
                    onChanged: maxMs <= 0
                        ? null
                        : (v) => setState(() => _dragValue = v),
                    onChangeEnd: maxMs <= 0
                        ? null
                        : (v) async {
                            await widget.onSeek(Duration(milliseconds: v.round()));
                            if (mounted) setState(() => _dragValue = null);
                          },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Spacing.sm),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_formatDuration(shown),
                          style: Theme.of(context).textTheme.bodySmall),
                      Text(_formatDuration(duration),
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// `M:SS`, or `H:MM:SS` once the clip runs past an hour (full-length
  /// previews can, now that they're no longer trimmed to 15s).
  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:$seconds';
    }
    return '$minutes:$seconds';
  }
}
