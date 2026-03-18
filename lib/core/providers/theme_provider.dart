import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kThemeKey = 'theme_mode';

class ThemeModeNotifier extends AsyncNotifier<ThemeMode> {
  @override
  Future<ThemeMode> build() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_kThemeKey);
    switch (stored) {
      case 'dark':
        return ThemeMode.dark;
      case 'light':
        return ThemeMode.light;
      default:
        return ThemeMode.system;
    }
  }

  Future<void> setDark(bool dark) async {
    final prefs = await SharedPreferences.getInstance();
    final mode = dark ? ThemeMode.dark : ThemeMode.light;
    await prefs.setString(_kThemeKey, dark ? 'dark' : 'light');
    state = AsyncData(mode);
  }

  Future<void> setSystem() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kThemeKey);
    state = const AsyncData(ThemeMode.system);
  }

  ThemeMode get current => state.asData?.value ?? ThemeMode.system;
  bool get isDark => current == ThemeMode.dark;
}

final themeModeProvider =
    AsyncNotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);
