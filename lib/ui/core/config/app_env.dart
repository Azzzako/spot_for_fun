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

  /// OAuth *Web* client ID from Google Cloud. google_sign_in needs it as
  /// serverClientId to return the idToken that Supabase verifies.
  static String get googleWebClientId {
    final fromEnv = const String.fromEnvironment(
      'GOOGLE_WEB_CLIENT_ID',
      defaultValue: '',
    );
    if (fromEnv.isNotEmpty) return fromEnv;
    return dotenv.env['GOOGLE_WEB_CLIENT_ID'] ?? '';
  }

  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabasePublishableKey.isNotEmpty;
}
