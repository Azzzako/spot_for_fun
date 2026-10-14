import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_env.dart';

class AppBootstrap {
  AppBootstrap._();

  static Future<({bool supabaseReady})> init() async {
    WidgetsFlutterBinding.ensureInitialized();

    await dotenv.load(fileName: '.env');

    // Dates read in Spanish everywhere ("12 OCT 2026").
    await initializeDateFormatting('es');
    Intl.defaultLocale = 'es';

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
