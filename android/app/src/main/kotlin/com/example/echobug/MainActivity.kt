package com.example.echobug

import android.content.ContentValues
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileInputStream

/// Hosts the platform channel that publishes processed audio into the public
/// `Music/` collection via MediaStore — the Play-compliant way to make files
/// visible in the device's Music app and file managers without broad storage
/// permissions on Android 10+.
class MainActivity : FlutterActivity() {
    private val channelName = "echobug/media_store"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "publishAudio" -> {
                        try {
                            val uri = publishAudio(
                                sourcePath = call.argument<String>("sourcePath")!!,
                                relativePath = call.argument<String>("relativePath")!!,
                                displayName = call.argument<String>("displayName")!!,
                                mimeType = call.argument<String>("mimeType") ?: "audio/*",
                            )
                            result.success(uri)
                        } catch (e: Exception) {
                            result.error("PUBLISH_FAILED", e.message, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    /// Copies [sourcePath] into the public Music collection at [relativePath]
    /// (e.g. "Music/EchoBug/music data/Amalki") as [displayName]. Returns the
    /// resulting MediaStore content URI (Q+) or absolute file path (legacy).
    private fun publishAudio(
        sourcePath: String,
        relativePath: String,
        displayName: String,
        mimeType: String,
    ): String {
        val source = File(sourcePath)
        if (!source.exists()) throw IllegalArgumentException("Source not found: $sourcePath")
        val resolver = applicationContext.contentResolver

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val collection =
                MediaStore.Audio.Media.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
            val values = ContentValues().apply {
                put(MediaStore.Audio.Media.DISPLAY_NAME, displayName)
                put(MediaStore.Audio.Media.MIME_TYPE, mimeType)
                // RELATIVE_PATH supports the full nested tree under Music/.
                put(MediaStore.Audio.Media.RELATIVE_PATH, relativePath)
                put(MediaStore.Audio.Media.IS_PENDING, 1)
            }
            val itemUri: Uri = resolver.insert(collection, values)
                ?: throw IllegalStateException("MediaStore insert returned null")
            resolver.openOutputStream(itemUri).use { out ->
                if (out == null) throw IllegalStateException("Could not open output stream")
                FileInputStream(source).use { input -> input.copyTo(out) }
            }
            values.clear()
            values.put(MediaStore.Audio.Media.IS_PENDING, 0)
            resolver.update(itemUri, values, null, null)
            return itemUri.toString()
        }

        // Legacy (API < 29): write directly into public Music/, then index it.
        @Suppress("DEPRECATION")
        val musicDir =
            Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_MUSIC)
        // relativePath begins with "Music/"; musicDir already points at Music/.
        val sub = relativePath.removePrefix("Music/").removePrefix("Music")
        val targetDir = File(musicDir, sub)
        if (!targetDir.exists()) targetDir.mkdirs()
        val targetFile = File(targetDir, displayName)
        FileInputStream(source).use { input ->
            targetFile.outputStream().use { out -> input.copyTo(out) }
        }
        @Suppress("DEPRECATION")
        val values = ContentValues().apply {
            put(MediaStore.Audio.Media.DATA, targetFile.absolutePath)
            put(MediaStore.Audio.Media.DISPLAY_NAME, displayName)
            put(MediaStore.Audio.Media.MIME_TYPE, mimeType)
        }
        resolver.insert(MediaStore.Audio.Media.EXTERNAL_CONTENT_URI, values)
        return targetFile.absolutePath
    }
}
