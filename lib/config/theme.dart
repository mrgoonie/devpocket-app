import 'package:flutter/material.dart';

class AppTheme {
  // Neobrutalism Color Palette (Dark Mode)
  static const Color primaryBlack = Color(0xFF000000);
  static const Color primaryWhite = Color(0xFFFFFFFF);
  static const Color neonGreen = Color(0xFF00FF41);
  static const Color neonPink = Color(0xFFFF006B);
  static const Color neonBlue = Color(0xFF0070F3);
  static const Color neonYellow = Color(0xFFFFD700);
  static const Color neonPurple = Color(0xFF9D4EDD);

  // Dark Background Colors
  static const Color darkBackground = Color(0xFF0A0A0A);
  static const Color darkSurface = Color(0xFF1A1A1A);
  static const Color darkCard = Color(0xFF2A2A2A);
  static const Color darkBorder = Color(0xFF3A3A3A);

  // Text Colors
  static const Color primaryText = Color(0xFFFFFFFF);
  static const Color secondaryText = Color(0xFFB0B0B0);
  static const Color mutedText = Color(0xFF808080);

  // Status Colors
  static const Color successColor = Color(0xFF00FF41);
  static const Color errorColor = Color(0xFFFF006B);
  static const Color warningColor = Color(0xFFFFD700);
  static const Color infoColor = Color(0xFF0070F3);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      // Color Scheme
      colorScheme: const ColorScheme.dark(
        brightness: Brightness.dark,
        primary: neonGreen,
        onPrimary: primaryBlack,
        secondary: neonPink,
        onSecondary: primaryBlack,
        tertiary: neonBlue,
        onTertiary: primaryBlack,
        surface: darkSurface,
        onSurface: primaryText,
        error: errorColor,
        onError: primaryBlack,
        outline: darkBorder,
        surfaceContainerHighest: darkCard,
        onSurfaceVariant: secondaryText,
      ),

      // App Bar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: darkBackground,
        foregroundColor: primaryText,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: primaryText,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          fontFamily: 'Inter',
        ),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: darkCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(
            color: darkBorder,
            width: 2,
          ),
        ),
        margin: const EdgeInsets.all(8),
      ),

      // Elevated Button Theme (Neobrutalism style)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: neonGreen,
          foregroundColor: primaryBlack,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(
              color: primaryBlack,
              width: 3,
            ),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            fontFamily: 'Inter',
          ),
        ).copyWith(
          // Add shadow offset for brutalism effect
          elevation: WidgetStateProperty.all(8),
          shadowColor: WidgetStateProperty.all(primaryBlack),
        ),
      ),

      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryText,
          backgroundColor: Colors.transparent,
          side: const BorderSide(color: neonGreen, width: 2),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            fontFamily: 'Inter',
          ),
        ),
      ),

      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: neonPink,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            fontFamily: 'Inter',
          ),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: darkBorder, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: darkBorder, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: neonGreen, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: errorColor, width: 2),
        ),
        labelStyle: const TextStyle(
          color: secondaryText,
          fontFamily: 'Inter',
        ),
        hintStyle: const TextStyle(
          color: mutedText,
          fontFamily: 'Inter',
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),

      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: darkSurface,
        selectedItemColor: neonGreen,
        unselectedItemColor: mutedText,
        selectedLabelStyle: TextStyle(
          fontWeight: FontWeight.bold,
          fontFamily: 'Inter',
        ),
        unselectedLabelStyle: TextStyle(
          fontFamily: 'Inter',
        ),
      ),

      // Tab Bar Theme
      tabBarTheme: const TabBarThemeData(
        labelColor: neonGreen,
        unselectedLabelColor: mutedText,
        indicatorColor: neonGreen,
        labelStyle: TextStyle(
          fontWeight: FontWeight.bold,
          fontFamily: 'Inter',
        ),
        unselectedLabelStyle: TextStyle(
          fontFamily: 'Inter',
        ),
      ),

      // Text Theme
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: primaryText,
          fontSize: 32,
          fontWeight: FontWeight.bold,
          fontFamily: 'Inter',
        ),
        displayMedium: TextStyle(
          color: primaryText,
          fontSize: 28,
          fontWeight: FontWeight.bold,
          fontFamily: 'Inter',
        ),
        displaySmall: TextStyle(
          color: primaryText,
          fontSize: 24,
          fontWeight: FontWeight.bold,
          fontFamily: 'Inter',
        ),
        headlineLarge: TextStyle(
          color: primaryText,
          fontSize: 22,
          fontWeight: FontWeight.bold,
          fontFamily: 'Inter',
        ),
        headlineMedium: TextStyle(
          color: primaryText,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          fontFamily: 'Inter',
        ),
        headlineSmall: TextStyle(
          color: primaryText,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          fontFamily: 'Inter',
        ),
        titleLarge: TextStyle(
          color: primaryText,
          fontSize: 16,
          fontWeight: FontWeight.w600,
          fontFamily: 'Inter',
        ),
        titleMedium: TextStyle(
          color: primaryText,
          fontSize: 14,
          fontWeight: FontWeight.w500,
          fontFamily: 'Inter',
        ),
        titleSmall: TextStyle(
          color: secondaryText,
          fontSize: 12,
          fontWeight: FontWeight.w500,
          fontFamily: 'Inter',
        ),
        bodyLarge: TextStyle(
          color: primaryText,
          fontSize: 16,
          fontFamily: 'Inter',
        ),
        bodyMedium: TextStyle(
          color: secondaryText,
          fontSize: 14,
          fontFamily: 'Inter',
        ),
        bodySmall: TextStyle(
          color: mutedText,
          fontSize: 12,
          fontFamily: 'Inter',
        ),
        labelLarge: TextStyle(
          color: primaryText,
          fontSize: 14,
          fontWeight: FontWeight.w500,
          fontFamily: 'Inter',
        ),
        labelMedium: TextStyle(
          color: secondaryText,
          fontSize: 12,
          fontWeight: FontWeight.w500,
          fontFamily: 'Inter',
        ),
        labelSmall: TextStyle(
          color: mutedText,
          fontSize: 10,
          fontWeight: FontWeight.w500,
          fontFamily: 'Inter',
        ),
      ),

      // Scaffold Background
      scaffoldBackgroundColor: darkBackground,

      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: darkBorder,
        thickness: 1,
      ),

      // Icon Theme
      iconTheme: const IconThemeData(
        color: primaryText,
        size: 24,
      ),

      // Floating Action Button Theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: neonPink,
        foregroundColor: primaryBlack,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          side: BorderSide(color: primaryBlack, width: 3),
        ),
      ),
    );
  }

  // Terminal Theme
  static const terminalTheme = {
    'background': Color(0xFF0A0A0A),
    'foreground': Color(0xFF00FF41),
    'cursor': Color(0xFFFFFFFF),
    'selection': Color(0xFF3A3A3A),
    'black': Color(0xFF000000),
    'red': Color(0xFFFF006B),
    'green': Color(0xFF00FF41),
    'yellow': Color(0xFFFFD700),
    'blue': Color(0xFF0070F3),
    'magenta': Color(0xFF9D4EDD),
    'cyan': Color(0xFF00FFFF),
    'white': Color(0xFFFFFFFF),
    'brightBlack': Color(0xFF3A3A3A),
    'brightRed': Color(0xFFFF4081),
    'brightGreen': Color(0xFF40FF80),
    'brightYellow': Color(0xFFFFF040),
    'brightBlue': Color(0xFF4080FF),
    'brightMagenta': Color(0xFFBD6EFF),
    'brightCyan': Color(0xFF40FFFF),
    'brightWhite': Color(0xFFFFFFFF),
  };
}
