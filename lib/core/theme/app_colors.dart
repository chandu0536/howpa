import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary & Brand Colors
  static const Color primary = Color(0xFF0052FF);
  static const Color primaryDark = Color(0xFF003ECB);
  static const Color primaryLight = Color(0xFFE6EEFF);
  static const Color secondary = Color(0xFFFF5C00);
  static const Color secondaryLight = Color(0xFFFFF0E6);
  static const Color accent = Color(0xFF06B6D4);

  // Gradient Colors
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF0052FF), Color(0xFFFF5C00)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient blueGradient = LinearGradient(
    colors: [Color(0xFF0052FF), Color(0xFF3B82F6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient orangeGradient = LinearGradient(
    colors: [Color(0xFFFF5C00), Color(0xFFFF8A00)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Neutral / Text Colors
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textLight = Colors.white;

  // Background Colors
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Colors.white;
  static const Color cardBackground = Colors.white;

  // Border & Divider
  static const Color border = Color(0xFFE2E8F0);
  static const Color divider = Color(0xFFF1F5F9);

  // Status & Feedback Colors
  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFFDCFCE7);
  static const Color successText = Color(0xFF15803D);

  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color warningText = Color(0xFFB45309);

  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color errorText = Color(0xFFB91C1C);

  static const Color info = Color(0xFF3B82F6);
  static const Color infoLight = Color(0xFFEFF6FF);

  // Tag & Chip Colors
  static const Color purpleBg = Color(0xFFF3E8FF);
  static const Color purpleText = Color(0xFF7E22CE);
  static const Color orangeBg = Color(0xFFFFEDD5);
  static const Color orangeText = Color(0xFFC2410C);
  static const Color tealBg = Color(0xFFCCFBF1);
  static const Color tealText = Color(0xFF0F766E);
}
