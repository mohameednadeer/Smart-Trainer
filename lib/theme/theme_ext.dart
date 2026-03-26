import 'package:flutter/material.dart';
import 'package:smart_trainer/theme/app_colors.dart';

extension ThemeColors on BuildContext {
  bool get isLight => Theme.of(this).brightness == Brightness.light;

  Color get bgColor => isLight ? const Color(0xFFF5F7FA) : AppColors.background;
  Color get surfaceColor => isLight ? Colors.white : AppColors.surface;
  Color get textColor => isLight ? Colors.black87 : Colors.white;
  Color get secondaryTextColor => isLight ? Colors.black54 : AppColors.textSecondary;
  Color get glassBorderColor => isLight ? Colors.grey.withOpacity(0.2) : AppColors.glassBorder;
  Color get glassBgColor => isLight ? Colors.white.withOpacity(0.4) : AppColors.glassBackground;
}
