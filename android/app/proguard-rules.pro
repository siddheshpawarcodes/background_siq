# FFmpeg Kit (antonkarpenko fork) — uses JNI + reflection for native callbacks.
# Strip these and the audio engine crashes at runtime, so keep them whole.
-keep class com.antonkarpenko.ffmpegkit.** { *; }
-keep class com.arthenica.ffmpegkit.** { *; }
-dontwarn com.antonkarpenko.ffmpegkit.**
-dontwarn com.arthenica.ffmpegkit.**

# Flutter embedding (defensive; the Flutter Gradle plugin also supplies rules).
-keep class io.flutter.** { *; }
-dontwarn io.flutter.**
