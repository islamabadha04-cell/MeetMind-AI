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

  // Dark Mode / Cosmic Void Theme (Phase 6C)
  static const Color bgDark = Color(0xFF0B0E1B);
  static const Color cardDark = Color(0xFF141728);
  static const Color surfaceDark = Color(0xFF1C2035);
  static const Color textMainDark = Color(0xFFF8FAFC);
  static const Color textMutedDark = Color(0xFF94A3B8);
  static const Color borderDark = Color(0xFF232742);

  // Cosmic Tokens from Design Inspiration
  static const Color cosmicBg = Color(0xFF0B0E1B);
  static const Color cosmicCard = Color(0xFF141728);
  static const Color cosmicCardBorder = Color(0xFF232742);
  static const Color cosmicSurface = Color(0xFF1C2035);
  static const Color cosmicPillGlow = Color(0xFF7C3AED);
  static const Color cosmicCyan = Color(0xFF06B6D4);
  static const Color cosmicPink = Color(0xFFEC4899);
  static const Color cosmicGreen = Color(0xFF10B981);
  static const Color cosmicAmber = Color(0xFFF59E0B);

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

  static const LinearGradient cosmicNavGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF8B5CF6), Color(0xFF6D5AE5)],
  );

  static const LinearGradient cosmicHeroCard = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1A1F3B), Color(0xFF121528)],
  );
}
