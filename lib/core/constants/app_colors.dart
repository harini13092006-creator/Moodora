import 'package:flutter/material.dart';

/// App color palette and semantic mood colors for Moodora.
/// Design style: Minimal, elegant, peaceful, and modern.
class AppColors {
  AppColors._();

  // Core Brand Palette
  static const Color primary = Color(0xFF9B7DE0);
  static const Color secondary = Color(0xFFE9DDFB);
  static const Color background = Color(0xFFFAF8FD);
  static const Color surface = Color(0xFFFFFFFF); // Pure white
  static const Color textMain = Color(0xFF0B0A10);
  static const Color textSecondary = Color(0xFF898494);
  static const Color textTertiary = Color(0xFFA5A0B4); // Light muted text

  // Subtle Borders and Dividers
  static const Color border = Color(0xFFEFEAF5);
  static const Color borderSubtle = Color(0xFFF3EFF8);

  // Soft Card Shadows
  static const Color cardShadow = Color(0x0D292633);
  static const Color cardShadowHover = Color(0x14292633);

  // Specified Mood Colors
  static const Color moodHappy = Color(0xFFE8BD59);
  static const Color moodNeutral = Color(0xFFAA95DC);
  static const Color moodProductive = Color(0xFF8964D5);
  static const Color moodPeaceful = Color(0xFFC4B5FD); // Soft pastel lavender
  static const Color moodReflective = Color(0xFFF5B7B1); // Soft peach / rose

  // Soft Pastel Background Container Tints for Mood Badges & Cards
  static const Color moodHappyLight = Color(0xFFFFF7E2);
  static const Color moodNeutralLight = Color(0xFFF1ECFC);
  static const Color moodProductiveLight = Color(0xFFEDE5FC);
  static const Color moodPeacefulLight = Color(0xFFF6F3FE);
  static const Color moodReflectiveLight = Color(0xFFFDF3F2);

  // Dark Theme Palette
  static const Color darkBackground = Color(0xFF0B0A10);
  static const Color darkSurface = Color(0xFF17151F);
  static const Color darkSurfaceVariant = Color(0xFF292533);
  static const Color darkTextMain = Color(0xFFF4F2F8);
  static const Color darkTextSecondary = Color(0xFFA7A2B6);
  static const Color darkBorder = Color(0xFF2E2A3A);
}
