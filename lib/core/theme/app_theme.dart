import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_text_styles.dart';

class AppTheme {
  AppTheme._();

  static ThemeData light = _build(AppColors.light, Brightness.light);
  static ThemeData dark = _build(AppColors.dark, Brightness.dark);

  static ThemeData _build(AppColors c, Brightness brightness) {
    return ThemeData(
      brightness: brightness,
      scaffoldBackgroundColor: c.background,
      primaryColor: c.accent,
      splashFactory: InkRipple.splashFactory,
      colorScheme: brightness == Brightness.light
          ? ColorScheme.light(
              primary: c.accent,
              secondary: c.textSecondary,
              error: c.error,
              surface: c.surface,
            )
          : ColorScheme.dark(
              primary: c.accent,
              secondary: c.textSecondary,
              error: c.error,
              surface: c.surface,
            ),
      appBarTheme: AppBarTheme(
        backgroundColor: c.background,
        foregroundColor: c.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: AppTextStyles.titleMedium.copyWith(
          color: c.textPrimary,
        ),
        iconTheme: IconThemeData(color: c.textPrimary),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: c.accent,
        foregroundColor: c.onAccent,
        elevation: brightness == Brightness.light ? 6 : 0,
      ),
      dividerTheme: DividerThemeData(color: c.border, thickness: 1, space: 1),
      textTheme: TextTheme(
        displayLarge: AppTextStyles.display.copyWith(color: c.textPrimary),
        headlineLarge: AppTextStyles.titleLarge.copyWith(color: c.textPrimary),
        headlineMedium: AppTextStyles.titleMedium.copyWith(
          color: c.textPrimary,
        ),
        titleMedium: AppTextStyles.taskTitle.copyWith(color: c.textPrimary),
        bodyLarge: AppTextStyles.body.copyWith(color: c.textPrimary),
        bodyMedium: AppTextStyles.body.copyWith(color: c.textSecondary),
        labelLarge: AppTextStyles.label.copyWith(color: c.textPrimary),
        labelSmall: AppTextStyles.overline.copyWith(color: c.textTertiary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 14,
        ),
        hintStyle: AppTextStyles.body.copyWith(color: c.textSecondary),
        labelStyle: AppTextStyles.body.copyWith(color: c.textSecondary),
        floatingLabelStyle: AppTextStyles.meta.copyWith(color: c.textPrimary),
        prefixIconColor: c.textSecondary,
        suffixIconColor: c.textSecondary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.controlRadius),
          borderSide: BorderSide(
            color: c.border,
            width: AppSpacing.borderHairline,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.controlRadius),
          borderSide: BorderSide(
            color: c.border,
            width: AppSpacing.borderHairline,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.controlRadius),
          borderSide: BorderSide(
            color: c.borderStrong,
            width: AppSpacing.borderFocus,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.controlRadius),
          borderSide: BorderSide(color: c.error, width: AppSpacing.borderFocus),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.controlRadius),
          borderSide: BorderSide(color: c.error, width: AppSpacing.borderFocus),
        ),
        errorStyle: AppTextStyles.meta.copyWith(color: c.error),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: c.accent,
        contentTextStyle: AppTextStyles.body.copyWith(color: c.onAccent),
        actionTextColor: c.onAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.controlRadius),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        side: BorderSide(color: c.accent, width: 1.75),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          side: BorderSide(color: c.border, width: AppSpacing.borderHairline),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.background,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSpacing.sheetRadius),
          ),
        ),
      ),
      extensions: [c],
    );
  }
}
