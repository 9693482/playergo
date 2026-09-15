import 'dart:developer' as dev;
import 'package:flutter/foundation.dart';

/// Reportero de crashes pluggable (Crashlytics/Sentry se conectan aquí).
typedef CrashReporter = void Function(
  Object error,
  StackTrace? stack, {
  bool fatal,
});

class AppLogger {
  AppLogger._();

  static const String _tag = 'PlayerGO';
  static CrashReporter? _reporter;

  /// Conecta un servicio de reporte de crashes (Crashlytics/Sentry).
  static void setCrashReporter(CrashReporter reporter) => _reporter = reporter;

  static void debug(String message) => _log('DEBUG', message);

  static void info(String message) => _log('INFO', message);

  static void warning(String message, [Object? error, StackTrace? stack]) =>
      _log('WARN', message, error, stack);

  static void error(
    String message, [
    Object? error,
    StackTrace? stack,
  ]) {
    _log('ERROR', message, error, stack);
    if (error != null) {
      _report(error, stack, fatal: false);
    }
  }

  /// Error fatal (crash de la app).
  static void fatal(Object error, StackTrace? stack) {
    _log('FATAL', 'Crash de la aplicación', error, stack);
    _report(error, stack, fatal: true);
  }

  static void _report(Object error, StackTrace? stack, {required bool fatal}) {
    try {
      _reporter?.call(error, stack, fatal: fatal);
    } catch (_) {
      // Nunca dejar que el reportero rompa la app.
    }
  }

  static void _log(
    String level,
    String message, [
    Object? error,
    StackTrace? stack,
  ]) {
    if (kDebugMode) {
      dev.log(
        '[$level] $message',
        name: _tag,
        error: error,
        stackTrace: stack,
      );
    } else {
      // En release solo reenviamos errores al reportero (sin spam de consola).
      if (error != null) _report(error, stack, fatal: false);
    }
  }
}
