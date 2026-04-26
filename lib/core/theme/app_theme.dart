import 'package:flutter/material.dart';

class AppTheme {
  // تعریف پالت رنگی
  static const Color primary = Color(0xFF4CAF50); // سبز اصلی
  static const Color primaryVariant = Color(0xFF388E3C); // سبز تیره تر
  static const Color secondary = Color(0xFF2196F3); // آبی (برای موارد ثانویه)
  static const Color background = Color(0xFFF2F4F7); // پس‌زمینه صفحات
  static const Color surface = Colors.white; // سطح کارت‌ها و المان‌ها
  
  static const Color primaryTextColor = Color(0xFF1D2939); // متن اصلی (تیره)
  static const Color secondaryTextColor = Color(0xFF667085); // متن ثانویه (خاکستری)
  
  static const Color onPrimary = Colors.white; // متن روی رنگ اصلی
  static const Color onBackground = Color(0xFF1D2939); // متن روی پس‌زمینه
  static const Color onSurface = Color(0xFF1D2939); // متن روی سطوح سفید

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'IranYekan', 
      
      scaffoldBackgroundColor: background,
      
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: primary,
        onPrimary: onPrimary,
        primaryContainer: primaryVariant,
        secondary: secondary,
        onSecondary: Colors.white,
        background: background,
        onBackground: onBackground,
        surface: surface,
        onSurface: onSurface,
        error: Colors.red,
        onError: Colors.white,
      ),

      textTheme: const TextTheme(
        displayLarge: TextStyle(color: primaryTextColor, fontWeight: FontWeight.bold),
        bodyLarge: TextStyle(color: primaryTextColor),
        bodyMedium: TextStyle(color: secondaryTextColor),
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: surface,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: primaryTextColor),
        titleTextStyle: TextStyle(
          color: primaryTextColor,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          fontFamily: 'IranYekan',
        ),
      ),

      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFFEAECF0)),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          minimumSize: const Size(double.infinity, 48),
          textStyle: const TextStyle(fontFamily: 'IranYekan', fontWeight: FontWeight.bold),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFD0D5DD)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFD0D5DD)),
        ),
        labelStyle: const TextStyle(color: secondaryTextColor, fontSize: 14, fontFamily: 'IranYekan'),
      ),
    );
  }
}
