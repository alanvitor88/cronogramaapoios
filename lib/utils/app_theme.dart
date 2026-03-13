import 'package:flutter/material.dart';
import '../models/app_data.dart';

class AppTheme {
  static const Color primary = Color(0xFF1565C0);       // Azul escuro
  static const Color primaryLight = Color(0xFF1E88E5);
  static const Color accent = Color(0xFF43A047);         // Verde
  static const Color warning = Color(0xFFF57C00);        // Laranja
  static const Color danger = Color(0xFFD32F2F);         // Vermelho
  static const Color surface = Color(0xFFF5F7FA);
  static const Color cardBg = Colors.white;

  static Color areaColor(String area) {
    return Color(kAreaColor[area] ?? 0xFFE0E0E0);
  }

  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: surface,
      appBarTheme: const AppBarTheme(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          letterSpacing: 0.5,
        ),
      ),
      cardTheme: CardThemeData(
        color: cardBg,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
