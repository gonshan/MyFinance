import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static Color background(Brightness brightness) =>
      brightness == Brightness.light ? const Color(0xFFF2F5F9) : const Color(0xFF121212);

  static Color surface(Brightness brightness) =>
      brightness == Brightness.light ? Colors.white : const Color(0xFF1E1E1E);

  static const Color primaryMint = Color(0xFF6BCCAA);
  static const Color secondarySalmon = Color(0xFFFF8A71);

  static Color textDark(Brightness brightness) =>
      brightness == Brightness.light ? const Color(0xFF2D3142) : const Color(0xFFE0E0E0);

  static Color textGrey(Brightness brightness) =>
      brightness == Brightness.light ? const Color(0xFF9EA6BE) : const Color(0xFFB0B0B0);

  static Color shadowDark(Brightness brightness) =>
      brightness == Brightness.light ? const Color(0xFFD3DBE9) : const Color(0xFF2A2A2A);

  static Color shadowLight(Brightness brightness) =>
      brightness == Brightness.light ? const Color(0xFFFFFFFF) : const Color(0xFF3A3A3A);
}

class AppTheme {
  static ThemeData get lightTheme {
    final brightness = Brightness.light;
    final colorScheme = ColorScheme.light(
      primary: AppColors.primaryMint,
      secondary: AppColors.secondarySalmon,
      surface: AppColors.surface(brightness),
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: AppColors.textDark(brightness),
    );

    return ThemeData(
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      primaryColor: colorScheme.primary,
      textTheme: GoogleFonts.nunitoTextTheme().apply(
        bodyColor: colorScheme.onSurface,
        displayColor: colorScheme.onSurface,
      ),
      useMaterial3: true,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: colorScheme.onSurface),
        titleTextStyle: GoogleFonts.nunito(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: colorScheme.onSurface,
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    final brightness = Brightness.dark;
    final colorScheme = ColorScheme.dark(
      primary: AppColors.primaryMint,
      secondary: AppColors.secondarySalmon,
      surface: AppColors.surface(brightness),
      onPrimary: Colors.black,
      onSecondary: Colors.black,
      onSurface: AppColors.textDark(brightness),
    );

    return ThemeData(
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      primaryColor: colorScheme.primary,
      textTheme: GoogleFonts.nunitoTextTheme().apply(
        bodyColor: colorScheme.onSurface,
        displayColor: colorScheme.onSurface,
      ),
      useMaterial3: true,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: colorScheme.onSurface),
        titleTextStyle: GoogleFonts.nunito(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: colorScheme.onSurface,
        ),
      ),
    );
  }
}