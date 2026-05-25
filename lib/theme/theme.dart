import 'package:flutter/material.dart';

class AppTheme {

  // ── Colores base ──────────────────────────────────────────────────────────
  static const Color background    = Color(0xFF0B0F19);
  static const Color surface       = Color(0xFF151D30);
  static const Color surfaceLight  = Color(0xFF202C45);

  static const Color primaryGold     = Color(0xFFF59E0B);
  static const Color primaryGoldDark = Color(0xFFD97706);

  static const Color completedRed   = Color(0xFFEF4444);
  static const Color neededGreen    = Color(0xFF10B981);
  static const Color repeatedYellow = Color(0xFFEAB308);

  static const Color infoBlue   = Color(0xFF3B82F6);
  static const Color eventGreen = Color(0xFF22C55E);

  // ── Gradientes ────────────────────────────────────────────────────────────
  static const LinearGradient goldGradient = LinearGradient(
    colors: [primaryGold, primaryGoldDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF1E3A8A), Color(0xFF0F172A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [background, Color(0xFF0C1220), background],
  );

  // ── Sombras ───────────────────────────────────────────────────────────────
  // hex alpha: 0x4D = 77 ≈ 30 %, 0x66 = 102 ≈ 40 %, 0x40 = 64 ≈ 25 %
  static const List<BoxShadow> shadowGold = [
    BoxShadow(
      color: Color(0x4DF59E0B), // primaryGold 30 %
      blurRadius: 24,
      spreadRadius: 4,
    ),
  ];

  static const List<BoxShadow> shadowDark = [
    BoxShadow(
      color: Color(0x66000000), // black 40 %
      blurRadius: 16,
      offset: Offset(0, 6),
    ),
  ];

  static const List<BoxShadow> shadowCard = [
    BoxShadow(
      color: Color(0x33000000), // black 20 %
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
  ];

  // ── Glassmorphism ─────────────────────────────────────────────────────────
  /// Decoración de tarjeta glass. [accent] tiñe el borde con el color del widget.
  static BoxDecoration glassCard({double radius = 20, Color? accent}) {
    return BoxDecoration(
      color: const Color(0x0DFFFFFF), // white 5 %
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: accent ?? const Color(0x1AFFFFFF), // white 10 %
        width: 1.0,
      ),
      boxShadow: const [
        BoxShadow(
          color: Color(0x40000000), // black 25 %
          blurRadius: 20,
          offset: Offset(0, 8),
        ),
      ],
    );
  }

  // ── ThemeData ─────────────────────────────────────────────────────────────
  static ThemeData get darkTheme {

    const textTheme = TextTheme(
      displayLarge:  TextStyle(fontFamily: 'Bebas Neue', fontSize: 72, color: Colors.white, letterSpacing: 1.5),
      displayMedium: TextStyle(fontFamily: 'Bebas Neue', fontSize: 56, color: Colors.white, letterSpacing: 1.0),
      displaySmall:  TextStyle(fontFamily: 'Bebas Neue', fontSize: 44, color: Colors.white, letterSpacing: 0.5),
      headlineLarge: TextStyle(fontFamily: 'Bebas Neue', fontSize: 36, color: Colors.white),
      headlineMedium: TextStyle(
        fontFamily: 'Inter',
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        letterSpacing: -0.5,
      ),
      titleLarge: TextStyle(
        fontFamily: 'Inter',
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      bodyLarge:  TextStyle(fontFamily: 'Inter', fontSize: 16, color: Colors.white),
      bodyMedium: TextStyle(fontFamily: 'Inter', fontSize: 14, color: Colors.white70),
      bodySmall:  TextStyle(fontFamily: 'Inter', fontSize: 12, color: Colors.white54),
      labelLarge: TextStyle(
        fontFamily: 'Inter',
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );

    return ThemeData(

      brightness: Brightness.dark,
      primaryColor: primaryGold,
      scaffoldBackgroundColor: background,

      colorScheme: const ColorScheme.dark(
        primary: primaryGold,
        secondary: primaryGold,
        surface: surface,
        error: completedRed,
      ),

      textTheme: textTheme,

      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: 'Inter',
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: primaryGold,
        unselectedItemColor: Colors.white60,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),

      cardTheme: CardThemeData(
        color: surface,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGold,
          foregroundColor: background,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryGold, width: 1.5),
        ),
        hintStyle: const TextStyle(color: Colors.white38),
      ),

    );

  }

}
