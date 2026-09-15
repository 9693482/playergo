import 'package:flutter_dotenv/flutter_dotenv.dart';

enum AppEnvironment { dev, staging, prod }

class Env {
  static AppEnvironment _environment = AppEnvironment.dev;

  static AppEnvironment get environment => _environment;

  static String get fileName {
    switch (_environment) {
      case AppEnvironment.staging:
        return '.env.staging';
      case AppEnvironment.prod:
        return '.env.prod';
      case AppEnvironment.dev:
        return '.env.dev';
    }
  }

  static Future<void> load([AppEnvironment environment = AppEnvironment.dev]) async {
    _environment = environment;
    await dotenv.load(fileName: fileName, isOptional: true);
  }

  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';
  static String get stripePublishableKey => dotenv.env['STRIPE_PUBLISHABLE_KEY'] ?? '';
  static String get firebaseProjectId => dotenv.env['FIREBASE_PROJECT_ID'] ?? '';
  static String get mapsApiKey => dotenv.env['MAPS_API_KEY'] ?? '';

  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  static String get environmentName => _environment.name.toUpperCase();
}
