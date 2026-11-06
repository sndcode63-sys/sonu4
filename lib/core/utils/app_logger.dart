import 'package:logger/logger.dart';

/// App me kahin bhi `print()` ke bajaye yeh use karo — clean, tagged,
/// colored console output milega with proper log levels.
class AppLogger {
  AppLogger._();

  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 6,
      lineLength: 90,
      colors: true,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
  );

  /// Debug info — normal flow tracking
  static void d(dynamic message) => _logger.d(message);

  /// General info — successful actions, milestones
  static void i(dynamic message) => _logger.i(message);

  /// Warnings — kuch expected nahi hua lekin crash nahi hoga
  static void w(dynamic message) => _logger.w(message);

  /// Errors — exceptions, failed API calls, etc.
  static void e(dynamic message, [Object? error, StackTrace? stackTrace]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }
}
