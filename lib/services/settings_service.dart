import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ChangeNotifier service for app-wide settings: dark mode, language, and scan tips.
class SettingsService extends ChangeNotifier {
  static const String _darkModeKey = 'nutrileaf_dark_mode';
  static const String _languageKey = 'nutrileaf_language';
  static const String _showScanTipsKey = 'nutrileaf_show_scan_tips';

  bool _isDarkMode = false;
  String _language = 'en';
  bool _isLoaded = false;
  bool _showScanTips = true;

  bool get isDarkMode => _isDarkMode;
  String get language => _language;
  bool get isLoaded => _isLoaded;
  /// Whether the Pre-Scan Guidance Modal should be shown before each scan.
  bool get showScanTips => _showScanTips;

  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  /// Load persisted settings from SharedPreferences.
  Future<void> load() async {
    if (_isLoaded) return;
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool(_darkModeKey) ?? false;
    _language = prefs.getString(_languageKey) ?? 'en';
    _showScanTips = prefs.getBool(_showScanTipsKey) ?? true;
    _isLoaded = true;
    notifyListeners();
  }

  /// Toggle dark mode on/off.
  Future<void> toggleDarkMode() async {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_darkModeKey, _isDarkMode);
  }

  /// Set dark mode explicitly.
  Future<void> setDarkMode(bool value) async {
    if (_isDarkMode == value) return;
    _isDarkMode = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_darkModeKey, _isDarkMode);
  }

  /// Set language ('en' or 'fil').
  Future<void> setLanguage(String lang) async {
    if (_language == lang) return;
    _language = lang;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, _language);
  }

  /// Persist whether the Pre-Scan Guidance Modal should appear.
  Future<void> setShowScanTips(bool value) async {
    if (_showScanTips == value) return;
    _showScanTips = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_showScanTipsKey, value);
  }
}
