import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../../core/theme/app_theme.dart';

/// Card showing a profile's selected cover-art image (the thumbnail embedded
/// into every export) with a small preview plus pick/change/clear actions.
///
/// Mirrors [AudioFileCard] in shape so the wizard and editor read consistently,
/// but renders the picked file as an image rather than probing it as audio.
class CoverImageCard extends StatelessWidget {
  const CoverImageCard({
    super.key,
    required this.path,
    required this.onPick,
    this.onClear,
  });

  final String? path;
  final VoidCallback onPick;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final path = this.path;
    final exists = path != null && File(path).existsSync();
    return Card(
      child: ListTile(
        leading: _leading(context, path, exists),
        title: Text(
          path == null ? 'No cover art' : p.basename(path),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          path == null
              ? 'Tap to choose a thumbnail (optional)'
              : (!exists
                  ? 'File missing — tap to re-select'
                  : 'Embedded in every export from this backdrop'),
          style: !exists && path != null
              ? TextStyle(color: Theme.of(context).colorScheme.error)
              : null,
        ),
        trailing: path != null && onClear != null
            ? IconButton(icon: const Icon(Icons.clear), onPressed: onClear)
            : const Icon(Icons.folder_open),
        onTap: onPick,
      ),
    );
  }

  Widget _leading(BuildContext context, String? path, bool exists) {
    if (path != null && exists) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(Spacing.xs),
        child: Image.file(
          File(path),
          width: 48,
          height: 48,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => const Icon(Icons.broken_image_outlined),
        ),
      );
    }
    return const Icon(Icons.image_outlined);
  }
}
