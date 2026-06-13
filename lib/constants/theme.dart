import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color backgroundDark = Color(0xFF0B1121);
  static const Color glassPanel = Color(0x1AFFFFFF); // 10% White
  static const Color glassBorder = Color(0x33FFFFFF); // 20% White
  
  static const Color flagRed = Color(0xFFFF4B4B);
  static const Color flagOrange = Color(0xFFFF9500);
  static const Color flagYellow = Color(0xFFFFCC00);
  static const Color flagBlue = Color(0xFF00C7FF);

  static ThemeData get darkTheme {
    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: backgroundDark,
      primaryColor: flagBlue,
      colorScheme: const ColorScheme.dark(
        primary: flagBlue,
        surface: backgroundDark,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
    );
  }
}
