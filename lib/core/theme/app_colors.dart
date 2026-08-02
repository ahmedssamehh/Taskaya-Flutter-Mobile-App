import 'package:flutter/material.dart';

@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.background,
    required this.surface,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.accent,
    required this.onAccent,
    required this.border,
    required this.borderStrong,
    required this.error,
    required this.disabled,
    required this.scrim,
  });

  final Color background;
  final Color surface;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color accent;
  final Color onAccent;
  final Color border;
  final Color borderStrong;
  final Color error;
  final Color disabled;
  final Color scrim;

  static const light = AppColors(
    background: Color(0xFFFFFFFF),
    surface: Color(0xFFFAFAFA),
    textPrimary: Color(0xFF000000),
    textSecondary: Color(0xFF616161),
    textTertiary: Color(0xFF757575),
    accent: Color(0xFF000000),
    onAccent: Color(0xFFFFFFFF),
    border: Color(0xFFE0E0E0),
    borderStrong: Color(0xFF000000),
    error: Color(0xFFB00020),
    disabled: Color(0xFFBDBDBD),
    scrim: Color(0x80000000),
  );

  static const dark = AppColors(
    background: Color(0xFF000000),
    surface: Color(0xFF121212),
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xFFB0B0B0),
    textTertiary: Color(0xFF8A8A8A),
    accent: Color(0xFFFFFFFF),
    onAccent: Color(0xFF000000),
    border: Color(0xFF2C2C2C),
    borderStrong: Color(0xFFFFFFFF),
    error: Color(0xFFCF6679),
    disabled: Color(0xFF3A3A3A),
    scrim: Color(0x99000000),
  );

  @override
  AppColors copyWith({
    Color? background,
    Color? surface,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? accent,
    Color? onAccent,
    Color? border,
    Color? borderStrong,
    Color? error,
    Color? disabled,
    Color? scrim,
  }) {
    return AppColors(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      accent: accent ?? this.accent,
      onAccent: onAccent ?? this.onAccent,
      border: border ?? this.border,
      borderStrong: borderStrong ?? this.borderStrong,
      error: error ?? this.error,
      disabled: disabled ?? this.disabled,
      scrim: scrim ?? this.scrim,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderStrong: Color.lerp(borderStrong, other.borderStrong, t)!,
      error: Color.lerp(error, other.error, t)!,
      disabled: Color.lerp(disabled, other.disabled, t)!,
      scrim: Color.lerp(scrim, other.scrim, t)!,
    );
  }
}

extension AppColorsContext on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
}
