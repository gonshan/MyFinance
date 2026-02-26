import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color background = Color(0xFFF2F5F9);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color primaryMint = Color(0xFF6BCCAA);
  static const Color secondarySalmon = Color(0xFFFF8A71);
  static const Color textDark = Color(0xFF2D3142);
  static const Color textGrey = Color(0xFF9EA6BE);
  static const Color shadowDark = Color(0xFFD3DBE9);
  static const Color shadowLight = Color(0xFFFFFFFF);
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.primaryMint,
      textTheme: GoogleFonts.nunitoTextTheme().apply(
        bodyColor: AppColors.textDark,
        displayColor: AppColors.textDark,
      ),
      useMaterial3: true,
    );
  }
}