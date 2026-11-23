import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Brand Blues
  static const Color primary = Color(0xFF1565C0);
  static const Color primaryMid = Color(0xFF1E88E5);
  static const Color primaryLight = Color(0xFF42A5F5);
  static const Color primaryDark = Color(0xFF0D47A1);

  // Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0D47A1), Color(0xFF1976D2), Color(0xFF42A5F5)],
  );

  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0A2472), Color(0xFF1565C0), Color(0xFF1E88E5)],
  );

  // Neutral
  static const Color background = Color(0xFFF0F4FF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFE8EEF9);
  static const Color divider = Color(0xFFE2E8F0);

  // Text
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textHint = Color(0xFFB0BEC5);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Semantic
  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFFD1FAE5);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color info = Color(0xFF3B82F6);
  static const Color infoLight = Color(0xFFEFF6FF);

  // Module Colors
  static const Color simpeg = Color(0xFF4F46E5);
  static const Color sippm = Color(0xFF0D9488);
  static const Color siakad = Color(0xFF2563EB);
  static const Color sikeu = Color(0xFF059669);
  static const Color sinapra = Color(0xFFD97706);
  static const Color arsip = Color(0xFF0891B2);
  static const Color lms = Color(0xFF6366F1);
  static const Color spmb = Color(0xFFE11D48);
  static const Color sso = Color(0xFF3B82F6);
}
