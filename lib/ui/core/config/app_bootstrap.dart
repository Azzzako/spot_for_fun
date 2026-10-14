import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_env.dart';

class AppBootstrap {
  AppBootstrap._();

  static Future<({bool supabaseReady})> init() async {
    WidgetsFlutterBinding.ensureInitialized();

    await dotenv.load(fileName: '.env');

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

    return (supabaseReady: supabaseReady);
  }
}
