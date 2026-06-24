import '../../../core/logging/app_logger.dart';

/// Tagged navigation / lifecycle events for the "Crash vs Navigation"
/// investigation (App-Wide Navigation Safety).
///
/// Centralized so every guard logs identically and the tags are greppable in
/// `flutter logs` — e.g. `BACK_BUTTON_PRESSED`, `ROUTE_POPPED`. Emitted via
/// [AppLogger.i], so they surface when "Enable logging" is on, matching the
/// existing lifecycle logs in the processing controllers.
enum NavEvent {
  backButtonPressed('BACK_BUTTON_PRESSED'),
  navigationGuardTriggered('NAVIGATION_GUARD_TRIGGERED'),
  userChoseStay('USER_CHOSE_STAY'),
  userChoseLeave('USER_CHOSE_LEAVE'),
  routePopped('ROUTE_POPPED'),
  appExitRequested('APP_EXIT_REQUESTED'),
  processingScreenExited('PROCESSING_SCREEN_EXITED'),
  foregroundServiceActive('FOREGROUND_SERVICE_ACTIVE'),
  appMovedToBackground('APP_MOVED_TO_BACKGROUND'),
  appResumed('APP_RESUMED');

  const NavEvent(this.tag);

  /// The stable, greppable tag written to the log.
  final String tag;
}

/// Thin wrapper so navigation/lifecycle events are logged in one consistent
/// place rather than ad-hoc strings scattered across screens.
abstract final class NavLog {
  /// Logs [event], optionally with a short [detail] (e.g. a screen label).
  static void event(NavEvent event, [String? detail]) =>
      AppLogger.i(detail == null ? event.tag : '${event.tag} · $detail');
}
