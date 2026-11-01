import 'package:flutter/material.dart';

class AppColors {
  // Brand Palette from MeetMind AI Specification
  static const Color primary = Color(0xFF6D5AE5);
  static const Color primaryHover = Color(0xFF5B47DC);
  static const Color secondary = Color(0xFF8B5CF6);
  static const Color accent = Color(0xFFA78BFA);
  
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);

  // Light Mode
  static const Color bgLight = Color(0xFFF7F9FC);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color surfaceLight = Color(0xFFF1F4F9);
  static const Color textMainLight = Color(0xFF172033);
  static const Color textMutedLight = Color(0xFF64748B);
  static const Color borderLight = Color(0xFFE2E8F0);

  // Dark Mode
  static const Color bgDark = Color(0xFF0E1117);
  static const Color cardDark = Color(0xFF161B26);
  static const Color surfaceDark = Color(0xFF1E2536);
  static const Color textMainDark = Color(0xFFF8FAFC);
  static const Color textMutedDark = Color(0xFF94A3B8);
  static const Color borderDark = Color(0xFF262F42);

  // Linear Gradients
  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF6D5AE5), Color(0xFF8B5CF6), Color(0xFFA78BFA)],
  );

  static const LinearGradient buttonGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF7C3AED), Color(0xFF6366F1)],
  );
}
