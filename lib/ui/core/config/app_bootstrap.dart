import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_env.dart';

class AppBootstrap {
  AppBootstrap._();

  static const String prefsKeyThemeMode = 'theme_mode_pref';

  static Future<({SharedPreferences prefs, bool supabaseReady})> init() async {
    WidgetsFlutterBinding.ensureInitialized();

    await dotenv.load(fileName: '.env');

    final prefs = await SharedPreferences.getInstance();

    var supabaseReady = false;
    if (AppEnv.isConfigured) {
      await Supabase.initialize(
        url: AppEnv.supabaseUrl,
        publishableKey: AppEnv.supabasePublishableKey,
      );
      supabaseReady = true;
    } else {
      debugPrint(
        '[SpotForFun] Supabase no configurado. Define SUPABASE_URL y SUPABASE_PUBLISHABLE_KEY en .env o --dart-define.',
      );
    }

    return (prefs: prefs, supabaseReady: supabaseReady);
  }
}
