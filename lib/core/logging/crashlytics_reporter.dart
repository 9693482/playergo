import 'package:firebase_crashlytics/firebase_crashlytics.dart';

import 'app_logger.dart';

/// Conecta Firebase Crashlytics como reportero de crashes.
/// Solo debe llamarse si Firebase fue inicializado correctamente.
void registerCrashlyticsReporter() {
  AppLogger.setCrashReporter((error, stack, {fatal = false}) {
    try {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: fatal);
    } catch (_) {
      // Si Crashlytics no está disponible, ignorar silenciosamente.
    }
  });
}
