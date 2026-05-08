// lib/config/app_theme.dart
import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF4a7c59);
  static const primaryDark = Color(0xFF365e47);
  static const primaryDeep = Color(0xFF2e5240);
  static const surface = Color(0xFFd6e8db);
  static const background = Color(0xFFf0f7f2);
  static const white = Color(0xFFFFFFFF);
  static const textDark = Color(0xFF1a2e24);
  static const textGray = Color(0xFF6b8c7a);
  static const error = Color(0xFFe74c3c);
  static const warning = Color(0xFFf39c12);
  static const success = Color(0xFF27ae60);
  static const cardShadow = Color(0x1A4a7c59);
}

class AppTheme {
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        fontFamily: 'Poppins',
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          secondary: AppColors.primaryDark,
          surface: AppColors.surface,
            //background: AppColors.background,
        ),
        scaffoldBackgroundColor: AppColors.background,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: AppColors.white,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
            textStyle: const TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.surface),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.surface),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
          labelStyle: const TextStyle(color: AppColors.textGray, fontFamily: 'Poppins'),
        ),
         cardTheme: CardThemeData(
          color: AppColors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          shadowColor: AppColors.cardShadow,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: AppColors.white,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textGray,
          type: BottomNavigationBarType.fixed,
          elevation: 16,
        ),
        chipTheme: ChipThemeData(
          backgroundColor: AppColors.surface,
          selectedColor: AppColors.primary,
          labelStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
      );
}

// Text styles
class AppTextStyles {
  static const h1 = TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.textDark, fontFamily: 'Poppins');
  static const h2 = TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textDark, fontFamily: 'Poppins');
  static const h3 = TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textDark, fontFamily: 'Poppins');
  static const body = TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.textDark, fontFamily: 'Poppins');
  static const bodyMedium = TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textDark, fontFamily: 'Poppins');
  static const small = TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.textGray, fontFamily: 'Poppins');
  static const caption = TextStyle(fontSize: 11, fontWeight: FontWeight.w400, color: AppColors.textGray, fontFamily: 'Poppins');
}