import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppEnv {
  AppEnv._();

  static String get supabaseUrl {
    final fromEnv = const String.fromEnvironment(
      'SUPABASE_URL',
      defaultValue: '',
    );
    if (fromEnv.isNotEmpty) return fromEnv;
    return dotenv.env['SUPABASE_URL'] ?? '';
  }

  static String get supabasePublishableKey {
    final fromEnv = const String.fromEnvironment(
      'SUPABASE_PUBLISHABLE_KEY',
      defaultValue: '',
    );
    if (fromEnv.isNotEmpty) return fromEnv;
    return dotenv.env['SUPABASE_PUBLISHABLE_KEY'] ?? '';
  }

  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabasePublishableKey.isNotEmpty;
}
