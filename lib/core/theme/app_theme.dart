import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/brand_colors.dart';

final appThemeProvider = Provider<AppTheme>((_) => const AppTheme());

class AppTheme {
  const AppTheme();

  ThemeData get lightTheme {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: BrandColors.primary,
        brightness: Brightness.light,
        primary: BrandColors.primary,
        secondary: BrandColors.secondary,
        tertiary: BrandColors.accent,
      ),
      scaffoldBackgroundColor: BrandColors.neutralBackground,
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );

    return base.copyWith(
      textTheme: GoogleFonts.urbanistTextTheme(base.textTheme)
          .apply(bodyColor: BrandColors.neutralForeground),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: BrandColors.neutralForeground,
        centerTitle: false,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 0,
        margin: const EdgeInsets.symmetric(vertical: 8),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: BrandColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  ThemeData get darkTheme {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: BrandColors.primary,
        brightness: Brightness.dark,
        primary: BrandColors.primary,
        secondary: BrandColors.secondary,
        tertiary: BrandColors.accent,
      ),
    );

    return base.copyWith(
      textTheme: GoogleFonts.urbanistTextTheme(base.textTheme),
      appBarTheme: const AppBarTheme(centerTitle: false),
      cardTheme: CardThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}

