import 'package:flutter/material.dart';

class AppColors {
  // Primary brand colors
  static const Color primary = Color(0xFFE53935);
  static const Color primaryDark = Color(0xFFB71C1C);
  static const Color primaryLight = Color(0xFFFF8A80);
  static const Color accent = Color(0xFFFF6D00);

  // Background colors
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Colors.white;
  static const Color cardBackground = Colors.white;

  // Text colors
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textHint = Color(0xFFBDBDBD);
  static const Color textOnPrimary = Colors.white;

  // Status colors
  static const Color available = Color(0xFF4CAF50);
  static const Color occupied = Color(0xFFE53935);
  static const Color reserved = Color(0xFFFF9800);

  // Order status colors
  static const Color statusOpen = Color(0xFF2196F3);
  static const Color statusServed = Color(0xFF4CAF50);
  static const Color statusPaid = Color(0xFF9C27B0);
  static const Color statusVoided = Color(0xFF9E9E9E);

  // Item status colors
  static const Color itemQueued = Color(0xFFFF9800);
  static const Color itemPrinted = Color(0xFF2196F3);
  static const Color itemServed = Color(0xFF4CAF50);
  static const Color itemVoided = Color(0xFF9E9E9E);

  // Utility colors
  static const Color divider = Color(0xFFEEEEEE);
  static const Color error = Color(0xFFD32F2F);
  static const Color success = Color(0xFF388E3C);
  static const Color warning = Color(0xFFF57C00);
  static const Color info = Color(0xFF1976D2);

  // Cart/badge
  static const Color cartBadge = Color(0xFFE53935);
  static const Color cartBackground = Color(0xFF1A237E);
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.surface,
        error: AppColors.error,
      ),
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.textOnPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.15,
        ),
        iconTheme: IconThemeData(color: AppColors.textOnPrimary),
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardBackground,
        elevation: 2,
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnPrimary,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        hintStyle: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.7)),
      ),
      chipTheme: ChipThemeData(
        selectedColor: AppColors.primary,
        backgroundColor: Colors.grey.shade100,
        labelStyle: const TextStyle(fontSize: 13),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        elevation: 8,
        type: BottomNavigationBarType.fixed,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        displayMedium: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        displaySmall: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        headlineLarge: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
        headlineMedium: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
        headlineSmall: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
        titleLarge: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500),
        titleSmall: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500),
        bodyLarge: TextStyle(color: AppColors.textPrimary),
        bodyMedium: TextStyle(color: AppColors.textPrimary),
        bodySmall: TextStyle(color: AppColors.textSecondary),
        labelLarge: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  static Color tableStatusColor(String status) {
    switch (status) {
      case 'available': return AppColors.available;
      case 'occupied': return AppColors.occupied;
      case 'reserved': return AppColors.reserved;
      default: return AppColors.textSecondary;
    }
  }

  static Color orderStatusColor(String status) {
    switch (status) {
      case 'open': return AppColors.statusOpen;
      case 'served': return AppColors.statusServed;
      case 'paid': return AppColors.statusPaid;
      case 'voided': return AppColors.statusVoided;
      default: return AppColors.textSecondary;
    }
  }

  static Color itemStatusColor(String status) {
    switch (status) {
      case 'queued': return AppColors.itemQueued;
      case 'printed': return AppColors.itemPrinted;
      case 'served': return AppColors.itemServed;
      case 'voided': return AppColors.itemVoided;
      default: return AppColors.textSecondary;
    }
  }
}
