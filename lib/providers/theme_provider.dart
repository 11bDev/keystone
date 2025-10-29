import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AppTheme {
  light,
  dark,
  sepia,
}

final themeProvider = StateNotifierProvider<ThemeNotifier, AppTheme>((ref) {
  return ThemeNotifier();
});

class ThemeNotifier extends StateNotifier<AppTheme> {
  ThemeNotifier() : super(AppTheme.light);

  void setTheme(AppTheme theme) {
    state = theme;
  }

  void toggleTheme() {
    switch (state) {
      case AppTheme.light:
        state = AppTheme.dark;
        break;
      case AppTheme.dark:
        state = AppTheme.sepia;
        break;
      case AppTheme.sepia:
        state = AppTheme.light;
        break;
    }
  }
}

class AppThemes {
  // Light Theme - Original grey scheme
  static ThemeData lightTheme = ThemeData(
    primarySwatch: Colors.grey,
    brightness: Brightness.light,
    scaffoldBackgroundColor: Colors.white,
    visualDensity: VisualDensity.adaptivePlatformDensity,
    textTheme: const TextTheme(
      bodyLarge: TextStyle(fontSize: 18.0, fontFamily: 'Roboto'),
      bodyMedium: TextStyle(fontSize: 16.0, fontFamily: 'Roboto'),
      titleLarge: TextStyle(
        fontSize: 22.0,
        fontWeight: FontWeight.bold,
        fontFamily: 'Roboto',
      ),
    ),
    colorScheme: ColorScheme.fromSeed(seedColor: Colors.grey),
  );

  // Dark Theme
  static ThemeData darkTheme = ThemeData(
    primarySwatch: Colors.grey,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF121212),
    visualDensity: VisualDensity.adaptivePlatformDensity,
    textTheme: const TextTheme(
      bodyLarge: TextStyle(fontSize: 18.0, fontFamily: 'Roboto', color: Colors.white70),
      bodyMedium: TextStyle(fontSize: 16.0, fontFamily: 'Roboto', color: Colors.white70),
      titleLarge: TextStyle(
        fontSize: 22.0,
        fontWeight: FontWeight.bold,
        fontFamily: 'Roboto',
        color: Colors.white,
      ),
    ),
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blueGrey,
      brightness: Brightness.dark,
      surface: const Color(0xFF1E1E1E),
      background: const Color(0xFF121212),
      primary: Colors.blueGrey.shade600,
      secondary: Colors.blueGrey.shade400,
    ),
    cardColor: const Color(0xFF1E1E1E),
    cardTheme: CardThemeData(
      color: const Color(0xFF1E1E1E),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1E1E1E),
      foregroundColor: Colors.white,
      elevation: 0,
    ),
  );

  // Sepia/Parchment Theme
  static ThemeData sepiaTheme = ThemeData(
    primarySwatch: Colors.brown,
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFF5EBD7), // Light parchment
    visualDensity: VisualDensity.adaptivePlatformDensity,
    textTheme: const TextTheme(
      bodyLarge: TextStyle(
        fontSize: 18.0,
        fontFamily: 'Roboto',
        color: Color(0xFF2C1810), // Very dark brown for body text
      ),
      bodyMedium: TextStyle(
        fontSize: 16.0,
        fontFamily: 'Roboto',
        color: Color(0xFF3E2415), // Dark brown
      ),
      titleLarge: TextStyle(
        fontSize: 22.0,
        fontWeight: FontWeight.bold,
        fontFamily: 'Roboto',
        color: Color(0xFF2C1810), // Very dark brown
      ),
    ),
    colorScheme: const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xFF8D6E63), // Medium brown for primary elements
      onPrimary: Color(0xFF2C1810), // Dark brown text on primary
      secondary: Color(0xFF8D6E63), // Medium brown
      onSecondary: Color(0xFF2C1810), // Dark brown text
      error: Color(0xFF8B4513), // Saddle brown
      onError: Color(0xFFFFFBF5),
      background: Color(0xFFF5EBD7), // Light parchment
      onBackground: Color(0xFF2C1810), // Very dark brown
      surface: Color(0xFFEBD9BE), // Darker parchment for cards
      onSurface: Color(0xFF2C1810), // Very dark brown
    ),
    cardColor: const Color(0xFFEBD9BE), // Darker parchment for contrast
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFBCAAA4), // Light brown/taupe - much lighter
      foregroundColor: Color(0xFF2C1810), // Dark brown text for contrast
      iconTheme: IconThemeData(color: Color(0xFF2C1810)), // Dark brown icons
    ),
    iconTheme: const IconThemeData(
      color: Color(0xFF6D4C41), // Rich brown icons
    ),
    dividerColor: const Color(0xFFD4C4A8), // Visible divider
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFEBD9BE),
      labelStyle: const TextStyle(color: Color(0xFF3E2415)),
      hintStyle: const TextStyle(color: Color(0xFF6D5D4B)),
      border: OutlineInputBorder(
        borderSide: const BorderSide(color: Color(0xFF8D6E63)),
        borderRadius: BorderRadius.circular(8),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Color(0xFFA68A6D)),
        borderRadius: BorderRadius.circular(8),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Color(0xFF6D4C41), width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
    ),
    // Better button colors for visibility
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF8D6E63), // Medium brown
        foregroundColor: const Color(0xFFFFFBF5), // Light text
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xFF6D4C41), // Dark brown
      ),
    ),
  );

  static ThemeData getTheme(AppTheme theme) {
    switch (theme) {
      case AppTheme.light:
        return lightTheme;
      case AppTheme.dark:
        return darkTheme;
      case AppTheme.sepia:
        return sepiaTheme;
    }
  }
}
