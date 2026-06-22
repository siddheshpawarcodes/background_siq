import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// Centralized logger for EchoBug.
///
/// Logging can be toggled from Settings (SRS §11). When disabled, only
/// warnings and errors are emitted; when enabled, full debug output is shown.
/// In release builds nothing below [Level.warning] is logged regardless.
class AppLogger {
  AppLogger._();

  static bool _verbose = kDebugMode;

  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 6,
      lineLength: 100,
      colors: false,
      printEmojis: true,
    ),
    level: kDebugMode ? Level.debug : Level.warning,
  );

  /// Reflects the user's "Enable logging" setting.
  static void setVerbose(bool value) => _verbose = value;

  static void d(Object? message) {
    if (_verbose) _logger.d(message);
  }

  static void i(Object? message) {
    if (_verbose) _logger.i(message);
  }

  static void w(Object? message, {Object? error, StackTrace? stackTrace}) =>
      _logger.w(message, error: error, stackTrace: stackTrace);

  static void e(Object? message, {Object? error, StackTrace? stackTrace}) =>
      _logger.e(message, error: error, stackTrace: stackTrace);
}
