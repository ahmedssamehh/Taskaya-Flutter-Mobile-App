import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_text_styles.dart';

class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    required this.label,
    this.controller,
    this.hint,
    this.obscureText = false,
    this.keyboardType,
    this.autofillHints,
    this.textInputAction,
    this.maxLines = 1,
    this.autofocus = false,
    this.validator,
    this.maxLength,
    this.trailingIcon,
    this.trailingLabel,
    this.onTrailingTap,
  });

  final String label;
  final TextEditingController? controller;
  final String? hint;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Iterable<String>? autofillHints;
  final TextInputAction? textInputAction;
  final int maxLines;
  final bool autofocus;
  final String? Function(String?)? validator;
  final int? maxLength;

  /// Optional trailing icon button (e.g. a mic for voice input) shown
  /// when [obscureText] is false. Requires [trailingLabel] and
  /// [onTrailingTap].
  final IconData? trailingIcon;
  final String? trailingLabel;
  final VoidCallback? onTrailingTap;

  @override
  State<AppTextField> createState() => AppTextFieldState();
}

class AppTextFieldState extends State<AppTextField> {
  bool _obscured = true;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: AppTextStyles.label.copyWith(color: c.textPrimary),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextFormField(
          controller: widget.controller,
          obscureText: widget.obscureText && _obscured,
          keyboardType: widget.keyboardType,
          autofillHints: widget.autofillHints,
          textInputAction: widget.textInputAction,
          maxLines: widget.obscureText ? 1 : widget.maxLines,
          maxLength: widget.maxLength,
          autofocus: widget.autofocus,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          validator: widget.validator,
          style: AppTextStyles.body.copyWith(color: c.textPrimary),
          decoration: InputDecoration(
            hintText: widget.hint,
            counterText: '',
            suffixIcon: widget.obscureText
                ? Semantics(
                    label: _obscured ? 'Show password' : 'Hide password',
                    button: true,
                    child: IconButton(
                      icon: Icon(
                        _obscured
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: c.textSecondary,
                        size: 20,
                      ),
                      onPressed: () => setState(() => _obscured = !_obscured),
                    ),
                  )
                : widget.trailingIcon != null
                ? Semantics(
                    label: widget.trailingLabel,
                    button: true,
                    child: IconButton(
                      icon: Icon(
                        widget.trailingIcon,
                        color: c.textSecondary,
                        size: 20,
                      ),
                      onPressed: widget.onTrailingTap,
                    ),
                  )
                : null,
          ),
        ),
      ],
    );
  }
}
