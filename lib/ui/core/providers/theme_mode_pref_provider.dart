import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:spot_for_fun/ui/core/config/app_bootstrap.dart';

enum ThemeModePref { system, light, dark }

class ThemeModePrefNotifier extends ChangeNotifier {
  ThemeModePrefNotifier(this._prefs) {
    final raw = _prefs.getString(AppBootstrap.prefsKeyThemeMode);
    _mode = switch (raw) {
      'light' => ThemeModePref.light,
      'dark' => ThemeModePref.dark,
      _ => ThemeModePref.system,
    };
  }

  final SharedPreferences _prefs;
  late ThemeModePref _mode;

  ThemeModePref get mode => _mode;

  Future<void> setMode(ThemeModePref mode) async {
    if (_mode == mode) return;
    _mode = mode;
    await _prefs.setString(AppBootstrap.prefsKeyThemeMode, mode.name);
    notifyListeners();
  }

  ThemeMode toMaterialMode() => switch (_mode) {
        ThemeModePref.light => ThemeMode.light,
        ThemeModePref.dark => ThemeMode.dark,
        ThemeModePref.system => ThemeMode.system,
      };
}

final themeModePrefProvider = ChangeNotifierProvider<ThemeModePrefNotifier>(
  (ref) => throw UnimplementedError('Override con prefs.'),
);
