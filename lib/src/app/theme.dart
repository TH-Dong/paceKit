import 'package:flutter/material.dart';

const _seed = Color(0xFF34C071);

ThemeData buildLightTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: _seed,
    brightness: Brightness.light,
    surface: Colors.white,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: const Color(0xFFF5F7F6),
    fontFamily: 'SimHei',
    textTheme: _compactTextTheme(Brightness.light, scheme),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: _seed.withValues(alpha: 0.12),
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(
          fontFamily: 'SimHei',
          fontWeight: FontWeight.w400,
          fontSize: 11,
        ),
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
  );
}

ThemeData buildDarkTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: _seed,
    brightness: Brightness.dark,
    surface: const Color(0xFF181C1A),
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: const Color(0xFF101311),
    fontFamily: 'SimHei',
    textTheme: _compactTextTheme(Brightness.dark, scheme),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: const Color(0xFF181C1A),
      indicatorColor: _seed.withValues(alpha: 0.2),
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(
          fontFamily: 'SimHei',
          fontWeight: FontWeight.w400,
          fontSize: 11,
        ),
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: const Color(0xFF1A1F1C),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
  );
}

TextTheme _compactTextTheme(Brightness brightness, ColorScheme scheme) {
  final base = ThemeData(
    useMaterial3: true,
    brightness: brightness,
  ).textTheme.apply(
        fontFamily: 'SimHei',
        bodyColor: scheme.onSurface,
        displayColor: scheme.onSurface,
      );

  TextStyle? normal(TextStyle? style) => style?.copyWith(
        fontWeight: FontWeight.w400,
        fontSize: style.fontSize == null
            ? null
            : (style.fontSize! * 0.96).roundToDouble(),
        letterSpacing: 0,
      );

  return base.copyWith(
    displayLarge: normal(base.displayLarge),
    displayMedium: normal(base.displayMedium),
    displaySmall: normal(base.displaySmall),
    headlineLarge: normal(base.headlineLarge),
    headlineMedium: normal(base.headlineMedium),
    headlineSmall: normal(base.headlineSmall),
    titleLarge: normal(base.titleLarge),
    titleMedium: normal(base.titleMedium),
    titleSmall: normal(base.titleSmall),
    bodyLarge: normal(base.bodyLarge),
    bodyMedium: normal(base.bodyMedium),
    bodySmall: normal(base.bodySmall),
    labelLarge: normal(base.labelLarge),
    labelMedium: normal(base.labelMedium),
    labelSmall: normal(base.labelSmall),
  );
}
