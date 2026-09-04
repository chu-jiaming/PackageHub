import 'package:flutter/material.dart';

abstract final class PHColors {
  // Legacy light-mode aliases. New production components should use
  // PHColorScheme.of(context) so Light and Dark modes stay distinct.
  static const bgSurface = Color(0xFFFFFFFF);
  static const bgSurfaceSecondary = Color(0xFFF9F9FB);
  static const textPrimary = Color(0xFF000000);
  static const textSecondary = Color(0xFF636366);
  static const textTertiary = Color(0xFF8E8E93);
  static const borderDefault = Color(0xFFE5E5EA);
  static const separatorDefault = Color(0xFFE5E5EA);
  static const accent = Color(0xFF007AFF);
  static const success = Color(0xFF34C759);
  static const warning = Color(0xFFFF9500);
  static const destructive = Color(0xFFFF3B30);
}
