import 'dart:developer' as dev;
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  static String? _currentScreen;

  /// Conecta un servicio de reporte de crashes (Crashlytics/Sentry).
  static void setCrashReporter(CrashReporter reporter) => _reporter = reporter;

  /// Establece la pantalla actual para contexto en logs.
  static void setCurrentScreen(String screen) => _currentScreen = screen;

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
      _logToSupabase('ERROR', message, error, stack);
    }
  }

  /// Error fatal (crash de la app).
  static void fatal(Object error, StackTrace? stack) {
    _log('FATAL', 'Crash de la aplicación', error, stack);
    _report(error, stack, fatal: true);
    _logToSupabase('FATAL', 'Crash de la aplicación', error, stack);
  }

  static void _report(Object error, StackTrace? stack, {required bool fatal}) {
    try {
      _reporter?.call(error, stack, fatal: fatal);
    } catch (_) {
      // Nunca dejar que el reportero rompa la app.
    }
  }

  /// Registra errores en Supabase para monitoreo sin Firebase.
  static void _logToSupabase(
    String level,
    String message,
    Object error,
    StackTrace? stack,
  ) {
    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;

      client.from('app_errors').insert({
        'level': level,
        'message': message,
        'error_text': error.toString(),
        'stack_trace': stack?.toString().substring(0, 2000),
        'screen': _currentScreen,
        'user_id': user?.id,
        'platform': kIsWeb ? 'web' : defaultTargetPlatform.name,
        'app_version': '1.0.0',
      }).then((_) {}).catchError((_) {});
    } catch (_) {
      // Nunca dejar que el logging rompa la app.
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
