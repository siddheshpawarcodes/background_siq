# FFmpeg Kit (antonkarpenko fork) — uses JNI + reflection for native callbacks.
# Strip these and the audio engine crashes at runtime, so keep them whole.
-keep class com.antonkarpenko.ffmpegkit.** { *; }
-keep class com.arthenica.ffmpegkit.** { *; }
-dontwarn com.antonkarpenko.ffmpegkit.**
-dontwarn com.arthenica.ffmpegkit.**

# Flutter embedding (defensive; the Flutter Gradle plugin also supplies rules).
-keep class io.flutter.** { *; }
-dontwarn io.flutter.**

# Plugin entry classes referenced by GeneratedPluginRegistrant. If any of these
# is stripped, registration fails for ALL plugins. The `jni` plugin in
# particular backs path_provider_android (Hive.initFlutter), and stripping it
# throws "No JNI instance is available" at startup.
-keep class com.github.dart_lang.jni.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn com.github.dart_lang.jni.**
