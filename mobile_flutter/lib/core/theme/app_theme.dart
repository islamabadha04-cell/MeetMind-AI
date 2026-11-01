import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/colors.dart';
import '../localization/language_provider.dart';

class AppTheme {
  static bool enableGoogleFonts = true;

  static ThemeData getLightTheme(AppLanguage lang) {
    final isUrdu = lang == AppLanguage.urdu;
    final baseTextTheme = ThemeData.light().textTheme;
    final textTheme = enableGoogleFonts
        ? (isUrdu
            ? GoogleFonts.notoNastaliqUrduTextTheme(baseTextTheme)
            : GoogleFonts.interTextTheme(baseTextTheme))
        : baseTextTheme;

    final titleStyle = enableGoogleFonts
        ? (isUrdu
            ? GoogleFonts.notoNastaliqUrdu(
                color: AppColors.textMainLight,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              )
            : GoogleFonts.inter(
                color: AppColors.textMainLight,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ))
        : const TextStyle(
            color: AppColors.textMainLight,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.bgLight,
      cardColor: AppColors.cardLight,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.cardLight,
        error: AppColors.error,
      ),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.cardLight,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textMainLight),
        titleTextStyle: titleStyle,
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.borderLight),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
    );
  }

  static ThemeData getDarkTheme(AppLanguage lang) {
    final isUrdu = lang == AppLanguage.urdu;
    final baseTextTheme = ThemeData.dark().textTheme;
    final textTheme = enableGoogleFonts
        ? (isUrdu
            ? GoogleFonts.notoNastaliqUrduTextTheme(baseTextTheme)
            : GoogleFonts.interTextTheme(baseTextTheme))
        : baseTextTheme;

    final titleStyle = enableGoogleFonts
        ? (isUrdu
            ? GoogleFonts.notoNastaliqUrdu(
                color: AppColors.textMainDark,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              )
            : GoogleFonts.inter(
                color: AppColors.textMainDark,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ))
        : const TextStyle(
            color: AppColors.textMainDark,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.bgDark,
      cardColor: AppColors.cardDark,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.cardDark,
        error: AppColors.error,
      ),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.cardDark,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textMainDark),
        titleTextStyle: titleStyle,
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.borderDark),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
    );
  }
}
