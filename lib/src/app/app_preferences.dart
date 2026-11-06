import 'dart:convert';

import 'package:flutter/material.dart';

import '../data/app_storage.dart';

class AppPreferences {
  Future<ThemeMode> loadThemeMode() async {
    try {
      final data = await _readMap();
      return _themeModeFromName(data['themeMode'] as String?);
    } catch (_) {
      return ThemeMode.light;
    }
  }

  Future<void> saveThemeMode(ThemeMode mode) async {
    final data = await _readMap();
    data['themeMode'] = mode.name;
    await _writeMap(data);
  }

  Future<Locale> loadLocale() async {
    try {
      final data = await _readMap();
      final code = data['locale'] as String?;
      return switch (code) {
        'en' => const Locale('en'),
        _ => const Locale('zh'),
      };
    } catch (_) {
      return const Locale('zh');
    }
  }

  Future<void> saveLocale(Locale locale) async {
    final data = await _readMap();
    data['locale'] = locale.languageCode;
    await _writeMap(data);
  }

  Future<String> loadPetKind() async {
    try {
      final data = await _readMap();
      final value = data['petKind'] as String?;
      return switch (value) {
        'clouds' || 'strawberry' => value!,
        _ => 'leafbuds',
      };
    } catch (_) {
      return 'leafbuds';
    }
  }

  Future<void> savePetKind(String petKind) async {
    final data = await _readMap();
    data['petKind'] = petKind;
    await _writeMap(data);
  }

  ThemeMode _themeModeFromName(String? value) {
    return switch (value) {
      'dark' => ThemeMode.dark,
      'system' => ThemeMode.system,
      _ => ThemeMode.light,
    };
  }

  Future<Map<String, dynamic>> _readMap() async {
    final file = await getAppPreferencesFile();
    if (!await file.exists()) return <String, dynamic>{};
    final raw = await file.readAsString();
    final data = jsonDecode(raw);
    if (data is Map<String, dynamic>) return data;
    return <String, dynamic>{};
  }

  Future<void> _writeMap(Map<String, dynamic> data) async {
    final file = await getAppPreferencesFile();
    await file.writeAsString(jsonEncode(data));
  }
}
