import 'dart:io';

import 'package:flutter/services.dart';

import '../../domain/ports/media_store_port.dart';

/// Android implementation of [MediaStorePort] backed by a platform channel that
/// inserts files into MediaStore (see `MainActivity.kt`). No special storage
/// permission is needed on Android 10+; on older versions the legacy write
/// permission is requested separately before a run.
class MediaStoreService implements MediaStorePort {
  const MediaStoreService();

  static const MethodChannel _channel = MethodChannel('echobug/media_store');

  @override
  Future<String?> publishToMusic({
    required String sourcePath,
    required String relativeDir,
    required String displayName,
    required String mimeType,
  }) async {
    if (!Platform.isAndroid) return null;
    try {
      return await _channel.invokeMethod<String>('publishAudio', {
        'sourcePath': sourcePath,
        // Android's RELATIVE_PATH wants forward slashes regardless of platform.
        'relativePath': relativeDir.replaceAll(r'\', '/'),
        'displayName': displayName,
        'mimeType': mimeType,
      });
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  /// Maps a lower-case extension (no dot) to an audio MIME type for MediaStore.
  static String mimeForExtension(String ext) {
    switch (ext.toLowerCase()) {
      case 'mp3':
        return 'audio/mpeg';
      case 'm4a':
        return 'audio/mp4';
      case 'aac':
        return 'audio/aac';
      case 'wav':
        return 'audio/x-wav';
      case 'flac':
        return 'audio/flac';
      case 'ogg':
        return 'audio/ogg';
      default:
        return 'audio/*';
    }
  }
}
