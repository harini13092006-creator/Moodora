import 'package:flutter/material.dart';

/// App color palette and semantic mood colors for Moodora.
/// Design style: Minimal, elegant, peaceful, and modern.
class AppColors {
  AppColors._();

  // Core Brand Palette
  static const Color primary = Color(0xFF9B8ACB); // Soft lavender
  static const Color secondary = Color(0xFFEAE4F5); // Light purple
  static const Color background = Color(0xFFFAF9FC); // Warm off-white
  static const Color surface = Color(0xFFFFFFFF); // Pure white
  static const Color textMain = Color(0xFF292633); // Dark charcoal
  static const Color textSecondary = Color(0xFF736D85); // Slate / muted charcoal
  static const Color textTertiary = Color(0xFFA5A0B4); // Light muted text

  // Subtle Borders and Dividers
  static const Color border = Color(0xFFEFEAF5);
  static const Color borderSubtle = Color(0xFFF3EFF8);

  // Soft Card Shadows
  static const Color cardShadow = Color(0x0D292633);
  static const Color cardShadowHover = Color(0x14292633);

  // Specified Mood Colors
  static const Color moodHappy = Color(0xFFFFD76A); // Soft yellow
  static const Color moodNeutral = Color(0xFF8CBCEB); // Soft blue
  static const Color moodProductive = Color(0xFF83C99A); // Soft green
  static const Color moodPeaceful = Color(0xFFC4B5FD); // Soft pastel lavender
  static const Color moodReflective = Color(0xFFF5B7B1); // Soft peach / rose

  // Soft Pastel Background Container Tints for Mood Badges & Cards
  static const Color moodHappyLight = Color(0xFFFFF9E8);
  static const Color moodNeutralLight = Color(0xFFEEF5FD);
  static const Color moodProductiveLight = Color(0xFFEDF8F1);
  static const Color moodPeacefulLight = Color(0xFFF6F3FE);
  static const Color moodReflectiveLight = Color(0xFFFDF3F2);

  // Dark Theme Palette
  static const Color darkBackground = Color(0xFF141219);
  static const Color darkSurface = Color(0xFF1D1A24);
  static const Color darkSurfaceVariant = Color(0xFF292533);
  static const Color darkTextMain = Color(0xFFF4F2F8);
  static const Color darkTextSecondary = Color(0xFFA7A2B6);
  static const Color darkBorder = Color(0xFF2E2A3A);
}
