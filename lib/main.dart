import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config/env.dart';
import 'core/logging/app_logger.dart';
import 'core/logging/crashlytics_reporter.dart';
import 'app.dart';

/// Instancia de SharedPreferences disponible de forma síncrona en el router.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
      'sharedPreferencesProvider debe ser sobreescrito en main');
});

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Env.load(AppEnvironment.values.byName(
    const String.fromEnvironment('ENV', defaultValue: 'dev'),
  ));

  final prefs = await SharedPreferences.getInstance();

  try {
    await Supabase.initialize(
      url: Env.supabaseUrl,
      publishableKey: Env.supabaseAnonKey,
    );
  } catch (e) {
    AppLogger.warning('Error initializing Supabase', e);
  }

  // Observabilidad: conecta Crashlytics solo si Firebase está configurado.
  if (Env.firebaseProjectId.isNotEmpty) {
    try {
      registerCrashlyticsReporter();
    } catch (e) {
      AppLogger.warning('No se pudo registrar el reportero de crashes', e);
    }
  }

  // Captura de errores no manejados para logs centralizados + crash reporting.
  FlutterError.onError = (details) {
    AppLogger.fatal(details.exception, details.stack);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    AppLogger.fatal(error, stack);
    return true;
  };

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const PlayerGoApp(),
    ),
  );
}

final supabaseProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});
