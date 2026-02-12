import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Палитра 2: Muted Finance
  static const Color background = Color(0xFFF2F5F9); // Светлый серо-голубой
  static const Color surface = Color(0xFFFFFFFF);    // Белый
  static const Color primaryMint = Color(0xFF6BCCAA); // Мятный (Доход)
  static const Color secondarySalmon = Color(0xFFFF8A71); // Лососевый (Расход)
  static const Color textDark = Color(0xFF2D3142);   // Темный текст
  static const Color textGrey = Color(0xFF9EA6BE);   // Серый текст
  static const Color shadowDark = Color(0xFFD3DBE9); // Тень (темная часть)
  static const Color shadowLight = Color(0xFFFFFFFF); // Блик (светлая часть)
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


// Прописываем палитру и настраиваем Soft UI