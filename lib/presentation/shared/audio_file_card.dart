import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../core/di/usecase_providers.dart';

/// Card showing a selected audio file with its name, duration, and size, plus
/// pick/change/clear actions. Probes duration via the audio engine (design §2).
class AudioFileCard extends ConsumerStatefulWidget {
  const AudioFileCard({
    super.key,
    required this.icon,
    required this.emptyTitle,
    required this.emptySubtitle,
    required this.path,
    required this.onPick,
    this.onClear,
  });

  final IconData icon;
  final String emptyTitle;
  final String emptySubtitle;
  final String? path;
  final VoidCallback onPick;
  final VoidCallback? onClear;

  @override
  ConsumerState<AudioFileCard> createState() => _AudioFileCardState();
}

class _AudioFileCardState extends ConsumerState<AudioFileCard> {
  String? _details;

  @override
  void didUpdateWidget(AudioFileCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path) _loadDetails();
  }

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    final path = widget.path;
    if (path == null) {
      setState(() => _details = null);
      return;
    }
    final parts = <String>[];
    try {
      final size = await File(path).length();
      parts.add(_formatSize(size));
    } catch (_) {/* missing file handled below */}
    final probe = await ref.read(audioProcessorProvider).probe(path);
    probe.fold(
      (meta) => parts.add(_formatDuration(meta.duration)),
      (_) => parts.add('unreadable'),
    );
    if (mounted) setState(() => _details = parts.join(' · '));
  }

  @override
  Widget build(BuildContext context) {
    final path = widget.path;
    final exists = path != null && File(path).existsSync();
    return Card(
      child: ListTile(
        leading: Icon(widget.icon),
        title: Text(path == null ? widget.emptyTitle : p.basename(path),
            maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          path == null
              ? widget.emptySubtitle
              : (!exists ? 'File missing — tap to re-select' : (_details ?? 'Reading…')),
          style: !exists && path != null
              ? TextStyle(color: Theme.of(context).colorScheme.error)
              : null,
        ),
        trailing: path != null && widget.onClear != null
            ? IconButton(icon: const Icon(Icons.clear), onPressed: widget.onClear)
            : const Icon(Icons.folder_open),
        onTap: widget.onPick,
      ),
    );
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }
}
