/// AgriSutra NE — Theme Provider
/// ================================
/// Manages the light/dark theme preference using SharedPreferences so the
/// farmer's choice persists across app restarts.
///
/// Usage:
///   context.watch<ThemeProvider>().isDark   — read current state
///   context.read<ThemeProvider>().toggle()  — switch theme

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDark = false; // default: light theme

  bool get isDark => _isDark;

  ThemeProvider() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _isDark = prefs.getBool('is_dark_theme') ?? true;
    notifyListeners();
  }

  Future<void> toggle() async {
    _isDark = !_isDark;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_dark_theme', _isDark);
    notifyListeners();
  }
}
