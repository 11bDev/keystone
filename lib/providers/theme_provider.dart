import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

enum AppTheme { light, dark, sepia, parchment, newspaper }

final themeProvider = StateNotifierProvider<ThemeNotifier, AppTheme>((ref) {
  return ThemeNotifier();
});

class ThemeNotifier extends StateNotifier<AppTheme> {
  ThemeNotifier() : super(AppTheme.newspaper);

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
        state = AppTheme.parchment;
        break;
      case AppTheme.parchment:
        state = AppTheme.newspaper;
        break;
      case AppTheme.newspaper:
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
      bodyLarge: TextStyle(
        fontSize: 18.0,
        fontFamily: 'Roboto',
        color: Colors.white70,
      ),
      bodyMedium: TextStyle(
        fontSize: 16.0,
        fontFamily: 'Roboto',
        color: Colors.white70,
      ),
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
        side: BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
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

  // Parchment Theme - Beautiful reading and writing experience
  static final ThemeData parchmentTheme = ThemeData(
    primarySwatch: Colors.brown,
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFFDF6E3), // Warm cream parchment
    visualDensity: VisualDensity.adaptivePlatformDensity,
    textTheme: TextTheme(
      // Using Lora - elegant serif font perfect for reading
      bodyLarge: GoogleFonts.lora(
        fontSize: 18.0,
        color: const Color(0xFF3E2723), // Rich dark brown
        height: 1.6, // Generous line height for readability
      ),
      bodyMedium: GoogleFonts.lora(
        fontSize: 16.0,
        color: const Color(0xFF4E342E), // Warm dark brown
        height: 1.5,
      ),
      bodySmall: GoogleFonts.lora(
        fontSize: 14.0,
        color: const Color(0xFF5D4037), // Medium brown
        height: 1.4,
      ),
      titleLarge: GoogleFonts.cormorantGaramond(
        fontSize: 28.0,
        fontWeight: FontWeight.bold,
        color: const Color(0xFF3E2723),
        letterSpacing: 0.5,
      ),
      titleMedium: GoogleFonts.cormorantGaramond(
        fontSize: 22.0,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF3E2723),
        letterSpacing: 0.3,
      ),
      titleSmall: GoogleFonts.cormorantGaramond(
        fontSize: 18.0,
        fontWeight: FontWeight.w500,
        color: const Color(0xFF4E342E),
      ),
      labelLarge: GoogleFonts.lora(
        fontSize: 14.0,
        fontWeight: FontWeight.w500,
        color: const Color(0xFF5D4037),
        letterSpacing: 0.1,
      ),
      labelMedium: GoogleFonts.lora(
        fontSize: 12.0,
        fontWeight: FontWeight.w500,
        color: const Color(0xFF6D4C41),
      ),
      headlineLarge: GoogleFonts.cormorantGaramond(
        fontSize: 32.0,
        fontWeight: FontWeight.bold,
        color: const Color(0xFF3E2723),
      ),
      headlineMedium: GoogleFonts.cormorantGaramond(
        fontSize: 24.0,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF3E2723),
      ),
    ),
    colorScheme: const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xFF8D6E63), // Warm taupe
      onPrimary: Color(0xFFFFFBF5), // Cream white
      secondary: Color(0xFFA1887F), // Light taupe
      onSecondary: Color(0xFF3E2723), // Dark brown
      tertiary: Color(0xFFBCAAA4), // Very light taupe
      onTertiary: Color(0xFF3E2723),
      error: Color(0xFFD32F2F), // Rich red
      onError: Color(0xFFFFFBF5),
      background: Color(0xFFFDF6E3), // Warm cream parchment
      onBackground: Color(0xFF3E2723), // Rich dark brown
      surface: Color(0xFFFAF3E0), // Slightly darker cream for cards
      onSurface: Color(0xFF3E2723), // Rich dark brown
      surfaceVariant: Color(0xFFF5EBD7), // Light tan
      onSurfaceVariant: Color(0xFF4E342E),
    ),
    cardColor: const Color(0xFFFAF3E0), // Warm card background
    cardTheme: CardThemeData(
      color: const Color(0xFFFAF3E0),
      elevation: 2,
      shadowColor: Colors.brown.withOpacity(0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: const Color(0xFFD7CCC8).withOpacity(0.5),
          width: 1,
        ),
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: const Color(0xFFEFEBE9), // Very light taupe
      foregroundColor: const Color(0xFF3E2723), // Dark brown text
      elevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.cormorantGaramond(
        fontSize: 24.0,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF3E2723),
        letterSpacing: 0.5,
      ),
      iconTheme: const IconThemeData(
        color: Color(0xFF5D4037), // Medium brown icons
      ),
    ),
    iconTheme: const IconThemeData(
      color: Color(0xFF6D4C41), // Warm brown icons
    ),
    dividerColor: const Color(0xFFD7CCC8), // Soft brown divider
    dividerTheme: const DividerThemeData(
      color: Color(0xFFD7CCC8),
      thickness: 1,
      space: 1,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFFFFBF5), // Light cream
      labelStyle: GoogleFonts.lora(
        color: const Color(0xFF5D4037),
        fontSize: 16.0,
      ),
      hintStyle: GoogleFonts.lora(
        color: const Color(0xFF8D6E63),
        fontSize: 16.0,
      ),
      border: OutlineInputBorder(
        borderSide: const BorderSide(color: Color(0xFFBCAAA4), width: 1.5),
        borderRadius: BorderRadius.circular(8),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Color(0xFFD7CCC8), width: 1.5),
        borderRadius: BorderRadius.circular(8),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Color(0xFF8D6E63), width: 2.5),
        borderRadius: BorderRadius.circular(8),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF8D6E63), // Warm taupe
        foregroundColor: const Color(0xFFFFFBF5), // Light cream text
        textStyle: GoogleFonts.lora(
          fontSize: 16.0,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 2,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xFF6D4C41), // Rich brown
        textStyle: GoogleFonts.lora(
          fontSize: 16.0,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Color(0xFF8D6E63), // Warm taupe
      foregroundColor: Color(0xFFFFFBF5), // Light cream
      elevation: 4,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: const Color(0xFFEFEBE9),
      labelStyle: GoogleFonts.lora(
        fontSize: 14.0,
        color: const Color(0xFF3E2723),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFD7CCC8)),
      ),
    ),
  );

  // Newspaper Theme - Classic newspaper aesthetic with serif fonts
  static final ThemeData newspaperTheme = ThemeData(
    primarySwatch: Colors.grey,
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFF5F5F5), // Light gray newsprint
    visualDensity: VisualDensity.adaptivePlatformDensity,
    textTheme: TextTheme(
      // Using Libre Baskerville - classic newspaper serif font
      bodyLarge: GoogleFonts.libreBaskerville(
        fontSize: 18.0,
        color: const Color(0xFF1A1A1A), // Almost black for readability
        height: 1.7, // Newspaper-style line spacing
      ),
      bodyMedium: GoogleFonts.libreBaskerville(
        fontSize: 16.0,
        color: const Color(0xFF2B2B2B), // Dark gray
        height: 1.6,
      ),
      bodySmall: GoogleFonts.libreBaskerville(
        fontSize: 14.0,
        color: const Color(0xFF404040), // Medium dark gray
        height: 1.5,
      ),
      titleLarge: GoogleFonts.playfairDisplay(
        fontSize: 32.0,
        fontWeight: FontWeight.bold,
        color: const Color(0xFF000000), // Pure black for headlines
        letterSpacing: -0.5,
        height: 1.2,
      ),
      titleMedium: GoogleFonts.playfairDisplay(
        fontSize: 24.0,
        fontWeight: FontWeight.bold,
        color: const Color(0xFF1A1A1A),
        letterSpacing: -0.3,
      ),
      titleSmall: GoogleFonts.playfairDisplay(
        fontSize: 20.0,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF2B2B2B),
      ),
      labelLarge: GoogleFonts.libreBaskerville(
        fontSize: 14.0,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF404040),
        letterSpacing: 0.2,
      ),
      labelMedium: GoogleFonts.libreBaskerville(
        fontSize: 12.0,
        fontWeight: FontWeight.w500,
        color: const Color(0xFF5A5A5A),
      ),
      headlineLarge: GoogleFonts.playfairDisplay(
        fontSize: 36.0,
        fontWeight: FontWeight.bold,
        color: const Color(0xFF000000),
        letterSpacing: -0.8,
      ),
      headlineMedium: GoogleFonts.playfairDisplay(
        fontSize: 28.0,
        fontWeight: FontWeight.bold,
        color: const Color(0xFF1A1A1A),
        letterSpacing: -0.5,
      ),
    ),
    colorScheme: const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xFF424242), // Dark gray
      onPrimary: Color(0xFFFFFFFF), // White
      secondary: Color(0xFF616161), // Medium gray
      onSecondary: Color(0xFFFFFFFF), // White
      tertiary: Color(0xFF757575), // Light medium gray
      onTertiary: Color(0xFFFFFFFF),
      error: Color(0xFFC62828), // Deep red
      onError: Color(0xFFFFFFFF),
      background: Color(0xFFF5F5F5), // Light gray newsprint
      onBackground: Color(0xFF1A1A1A), // Almost black
      surface: Color(0xFFFFFFFF), // White for cards
      onSurface: Color(0xFF1A1A1A), // Almost black
      surfaceVariant: Color(0xFFEEEEEE), // Very light gray
      onSurfaceVariant: Color(0xFF2B2B2B),
    ),
    cardColor: const Color(0xFFFFFFFF), // Pure white cards on gray background
    cardTheme: CardThemeData(
      color: const Color(0xFFFFFFFF),
      elevation: 1,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          4,
        ), // Sharper corners for newspaper feel
        side: BorderSide(color: const Color(0xFFE0E0E0), width: 1),
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: const Color(0xFFEFEBE9), // Parchment header color
      foregroundColor: const Color(0xFF1A1A1A), // Almost black text
      elevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.playfairDisplay(
        fontSize: 26.0,
        fontWeight: FontWeight.bold,
        color: const Color(0xFF1A1A1A),
        letterSpacing: -0.3,
      ),
      iconTheme: const IconThemeData(
        color: Color(0xFF404040), // Dark gray icons
      ),
    ),
    iconTheme: const IconThemeData(
      color: Color(0xFF424242), // Dark gray icons
    ),
    dividerColor: const Color(0xFFBDBDBD), // Medium gray divider
    dividerTheme: const DividerThemeData(
      color: Color(0xFFBDBDBD),
      thickness: 1,
      space: 1,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFFFFFFF), // White input background
      labelStyle: GoogleFonts.libreBaskerville(
        color: const Color(0xFF5A5A5A),
        fontSize: 16.0,
      ),
      hintStyle: GoogleFonts.libreBaskerville(
        color: const Color(0xFF9E9E9E),
        fontSize: 16.0,
      ),
      border: OutlineInputBorder(
        borderSide: const BorderSide(color: Color(0xFFBDBDBD), width: 1.5),
        borderRadius: BorderRadius.circular(4),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Color(0xFFE0E0E0), width: 1.5),
        borderRadius: BorderRadius.circular(4),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Color(0xFF424242), width: 2.5),
        borderRadius: BorderRadius.circular(4),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF424242), // Dark gray
        foregroundColor: const Color(0xFFFFFFFF), // White text
        textStyle: GoogleFonts.libreBaskerville(
          fontSize: 16.0,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        elevation: 2,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xFF424242), // Dark gray
        textStyle: GoogleFonts.libreBaskerville(
          fontSize: 16.0,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Color(0xFF424242), // Dark gray
      foregroundColor: Color(0xFFFFFFFF), // White
      elevation: 4,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: const Color(0xFFEEEEEE),
      labelStyle: GoogleFonts.libreBaskerville(
        fontSize: 14.0,
        color: const Color(0xFF1A1A1A),
        fontWeight: FontWeight.w500,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
        side: const BorderSide(color: Color(0xFFBDBDBD)),
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
      case AppTheme.parchment:
        return parchmentTheme;
      case AppTheme.newspaper:
        return newspaperTheme;
    }
  }
}
