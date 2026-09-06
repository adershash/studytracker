import 'package:flutter/material.dart';

class AppColors {
  // Backgrounds
  static const Color background = Color(0xFF121212);
  static const Color surface = Color(0xFF1E1E1E);
  static const Color surfaceLight = Color(0xFF2C2C2C);
  static const Color surfaceVariant = Color(0xFF242424);

  // Accents
  static const Color primary = Color(0xFF6366F1); // Indigo
  static const Color primaryVariant = Color(0xFF4F46E5);
  static const Color secondary = Color(0xFF10B981); // Emerald
  static const Color accent = Color(0xFFF59E0B); // Amber
  
  // Heatmap colors based on primary
  static const Color heatLevel0 = surfaceLight;
  static const Color heatLevel1 = Color(0xFF3730A3);
  static const Color heatLevel2 = Color(0xFF4338CA);
  static const Color heatLevel3 = Color(0xFF4F46E5);
  static const Color heatLevel4 = Color(0xFF6366F1);
  static const Color heatLevel5 = Color(0xFF818CF8);

  // Text
  static const Color textPrimary = Color(0xFFF9FAFB);
  static const Color textSecondary = Color(0xFF9CA3AF);
  static const Color textDisabled = Color(0xFF4B5563);

  // States
  static const Color error = Color(0xFFEF4444);
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);
  
  // Borders
  static const Color border = Color(0xFF374151);
}
