import 'dart:io';
import 'dart:ui';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';

/// Keeps a Dataset Batch run alive while the app is backgrounded by running an
/// Android foreground service with an ongoing progress notification.
///
/// Without this, switching apps / pressing home / turning off the screen lets
/// the OS reclaim the process and silently kill a long run. A foreground
/// service is the standard Android mechanism that prevents that and surfaces a
/// persistent, tap-to-return notification.
///
/// Android-only: every method is a safe no-op on other platforms. iOS suspends
/// background apps (and destroys the task on force-close), so true background
/// processing isn't possible there — the run simply continues only while the
/// app is in the foreground, as before.
class ForegroundTaskService {
  ForegroundTaskService();

  bool _initialized = false;

  static const String _channelId = 'dataset_batch_processing';
  static const String _channelName = 'Dataset processing';

  /// White-on-transparent firefly silhouette used as the notification small
  /// icon. Resolved by the plugin from the matching `<meta-data>` entry in
  /// AndroidManifest.xml (name must stay in sync). Without this the plugin
  /// falls back to the colored launcher icon, which Android masks to its alpha
  /// channel and renders as a meaningless blob in the notification.
  static const NotificationIcon _notificationIcon = NotificationIcon(
    metaDataName: 'notification_icon',
    backgroundColor: Color(0xFF2E6CF6), // brand seed (AppTheme.brandSeed)
  );

  void _ensureInitialized() {
    if (_initialized) return;
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: _channelId,
        channelName: _channelName,
        channelDescription:
            'Keeps dataset batch processing running in the background.',
        onlyAlertOnce: true,
      ),
      iosNotificationOptions: const IOSNotificationOptions(),
      foregroundTaskOptions: ForegroundTaskOptions(
        // No background callback/isolate — the existing pipeline keeps running
        // in the main isolate; the service exists only to keep the process
        // alive and show progress.
        eventAction: ForegroundTaskEventAction.nothing(),
        allowWakeLock: true,
        allowWifiLock: false,
      ),
    );
    _initialized = true;
  }

  /// Starts (or, if already running, refreshes) the foreground service with an
  /// initial notification. Best-effort: requests the notification permission
  /// first, but the service still runs if it's denied — only the notification
  /// is suppressed. Returns true once the service is running; no-op → false off
  /// Android.
  Future<bool> start({required String title, required String text}) async {
    if (!Platform.isAndroid) return false;
    _ensureInitialized();
    // Android 13+ needs POST_NOTIFICATIONS to display the ongoing notification.
    await FlutterForegroundTask.requestNotificationPermission();

    if (await FlutterForegroundTask.isRunningService) {
      await update(title: title, text: text);
      return true;
    }

    final result = await FlutterForegroundTask.startService(
      serviceTypes: const [ForegroundServiceTypes.dataSync],
      notificationTitle: title,
      notificationText: text,
      notificationIcon: _notificationIcon,
    );
    return result is ServiceRequestSuccess;
  }

  /// Updates the ongoing notification (e.g. with progress). No-op off Android
  /// or when no service is running.
  Future<void> update({required String title, required String text}) async {
    if (!Platform.isAndroid) return;
    if (!await FlutterForegroundTask.isRunningService) return;
    await FlutterForegroundTask.updateService(
      notificationTitle: title,
      notificationText: text,
      // Re-supply on every update: the plugin reloads notification content from
      // scratch each refresh, so omitting it would revert to the launcher-icon
      // blob on the next progress tick.
      notificationIcon: _notificationIcon,
    );
  }

  /// Stops the foreground service and clears the notification. Safe to call
  /// even when nothing is running.
  Future<void> stop() async {
    if (!Platform.isAndroid) return;
    if (!await FlutterForegroundTask.isRunningService) return;
    await FlutterForegroundTask.stopService();
  }
}
